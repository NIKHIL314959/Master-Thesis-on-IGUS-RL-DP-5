function [success, log] = logMove(plc, mode, x, y, z, b, c, options)
%LOGMOVE  Wrapper around tcp_move() that records data during the move
%
% PURPOSE:
%   Drop-in replacement for tcp_move() that logs target/actual TCP, joint
%   angles, and status flags at 50 Hz throughout the move. Saves results
%   to a timestamped CSV + MAT file and produces tracking-error plots.
%
% USAGE:
%   logMove(plc, 'abs',  X, Y, Z)
%   logMove(plc, 'abs',  X, Y, Z, B, C)
%   logMove(plc, 'step', dX, dY, dZ)
%   [ok, log] = logMove(plc, 'abs', 300, 0, 450, 0, 0)
%
% INPUTS:  Same as tcp_move() — see tcp_move.m for full description.
%
% OUTPUTS:
%   success — true if move completed within tolerance
%   log     — struct with fields:
%               .t           [Nx1]  time vector (s)
%               .target      [1x5]  commanded TCP (X Y Z B C) [mm, deg]
%               .actualTCP   [Nx5]  measured TCP over time
%               .actualJoints[Nx5]  measured joint angles Q1..Q5 (deg)
%               .moving      [Nx1]  Moving flag
%               .inPosition  [Nx1]  InPosition flag
%               .errorMm     [Nx1]  Euclidean error to target (mm)
%               .filename    string  base name of saved CSV/MAT
%
% FILES PRODUCED (in current folder):
%   move_log_YYYY-MM-DD_HH-MM-SS.csv
%   move_log_YYYY-MM-DD_HH-MM-SS.mat
%
% NOTES:
%   - Sampling at 50 Hz (20 ms) — matches the 4 ms PLC cycle without aliasing
%   - Plots are produced automatically after the move (set options.plot=false to skip)
%   - The function blocks until the move completes or times out

    % ── Defaults ──────────────────────────────────────────────────────────────
    if nargin < 6 || isempty(b), b = []; end
    if nargin < 7 || isempty(c), c = []; end
    if nargin < 8, options = struct(); end
    if ~isfield(options, 'confirm'), options.confirm = false; end   % logger defaults to no confirm
    if ~isfield(options, 'timeout'), options.timeout = 60;    end
    if ~isfield(options, 'verbose'), options.verbose = true;  end
    if ~isfield(options, 'plot'),    options.plot    = true;  end
    if ~isfield(options, 'save'),    options.save    = true;  end

    SAMPLE_DT = 0.02;   % 50 Hz

    % ── Resolve target (must be done before logging starts) ──────────────────
    current_tcp = plc.getActualTCP();
    if isempty(b), b = current_tcp(4); end
    if isempty(c), c = current_tcp(5); end

    if strcmpi(mode, 'step')
        target = current_tcp + [x, y, z, b, c];
    else
        target = [x, y, z, b, c];
    end

    % ── Pre-flight checks (same as tcp_move) ─────────────────────────────────
    status = plc.getStatus();
    if status.error || ~status.homed || ~status.ready
        fprintf('[logMove] Robot not ready. Aborting.\n');
        plc.printStatus();
        success = false; log = struct();
        return
    end

    % ── Confirmation ─────────────────────────────────────────────────────────
    if options.confirm
        fprintf('\n[logMove] Target: X=%.2f Y=%.2f Z=%.2f B=%.2f C=%.2f\n', target);
        resp = input('  Send and log this move? (y/n): ', 's');
        if ~strcmpi(resp, 'y')
            fprintf('  Cancelled.\n');
            success = false; log = struct();
            return
        end
    end

    % ── Pre-allocate log buffers (15 s @ 50 Hz = 750 samples; grows if needed)
    nMax = ceil(options.timeout / SAMPLE_DT) + 50;
    t            = zeros(nMax, 1);
    actualTCP    = zeros(nMax, 5);
    actualJoints = zeros(nMax, 5);
    movingFlag   = false(nMax, 1);
    inPosFlag    = false(nMax, 1);

    % ── Trigger the move ─────────────────────────────────────────────────────
    if ~plc.setTargetTCP(target(1), target(2), target(3), target(4), target(5))
        fprintf('[logMove] Failed to write target.\n');
        success = false; log = struct();
        return
    end
    if ~plc.triggerMoveLinear()
        fprintf('[logMove] Failed to trigger move.\n');
        success = false; log = struct();
        return
    end

    if options.verbose
        fprintf('[logMove] Logging at %d Hz...\n', round(1/SAMPLE_DT));
    end

    % ── Sampling loop ────────────────────────────────────────────────────────
    n = 0;
    tStart = tic;
    settled = false;
    settleStart = NaN;

    while toc(tStart) < options.timeout
        sampleStart = tic;

        n = n + 1;
        if n > nMax
            % grow buffers
            t            = [t;            zeros(500, 1)];   %#ok<AGROW>
            actualTCP    = [actualTCP;    zeros(500, 5)];   %#ok<AGROW>
            actualJoints = [actualJoints; zeros(500, 5)];   %#ok<AGROW>
            movingFlag   = [movingFlag;   false(500, 1)];   %#ok<AGROW>
            inPosFlag    = [inPosFlag;    false(500, 1)];   %#ok<AGROW>
            nMax = numel(t);
        end

        t(n)               = toc(tStart);
        actualTCP(n, :)    = plc.getActualTCP();
        actualJoints(n, :) = plc.getActualJoints();
        st                 = plc.getStatus();
        movingFlag(n)      = st.moving;
        inPosFlag(n)       = st.inPosition;

        % Stop logging ~0.5 s after move reports InPosition (capture settling)
        if st.inPosition && ~st.moving
            if ~settled
                settled     = true;
                settleStart = t(n);
            elseif t(n) - settleStart > 0.5
                break
            end
        end

        % Pace the loop to SAMPLE_DT
        elapsed = toc(sampleStart);
        if elapsed < SAMPLE_DT
            pause(SAMPLE_DT - elapsed);
        end
    end

    % ── Trim buffers ─────────────────────────────────────────────────────────
    t            = t(1:n);
    actualTCP    = actualTCP(1:n, :);
    actualJoints = actualJoints(1:n, :);
    movingFlag   = movingFlag(1:n);
    inPosFlag    = inPosFlag(1:n);

    % ── Compute tracking error (XYZ only) ────────────────────────────────────
    errorMm = sqrt(sum((actualTCP(:, 1:3) - target(1:3)).^2, 2));

    % ── Build log struct ─────────────────────────────────────────────────────
    log = struct();
    log.t            = t;
    log.target       = target;
    log.actualTCP    = actualTCP;
    log.actualJoints = actualJoints;
    log.moving       = movingFlag;
    log.inPosition   = inPosFlag;
    log.errorMm      = errorMm;
    log.sampleHz     = 1/SAMPLE_DT;
    log.mode         = mode;

    % ── Save files ───────────────────────────────────────────────────────────
    if options.save
        ts = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
        baseName = sprintf('move_log_%s', ts);
        log.filename = baseName;

        % CSV
        T = table(t, actualTCP(:,1), actualTCP(:,2), actualTCP(:,3), actualTCP(:,4), actualTCP(:,5), actualJoints(:,1), actualJoints(:,2), actualJoints(:,3), actualJoints(:,4), actualJoints(:,5), errorMm, movingFlag, inPosFlag, 'VariableNames', {'time_s','X_mm','Y_mm','Z_mm','B_deg','C_deg', 'Q1_deg','Q2_deg','Q3_deg','Q4_deg','Q5_deg', 'error_mm','moving','inPosition'});
        writetable(T, [baseName '.csv']);

        % MAT
        save([baseName '.mat'], 'log');

        if options.verbose
            fprintf('[logMove] Saved %s.csv and %s.mat\n', baseName, baseName);
        end
    end

    % ── Final tolerance check ────────────────────────────────────────────────
    finalError = errorMm(end);
    success = finalError < 2.0;

    if options.verbose
        fprintf('[logMove] Move complete: %d samples, max error %.2f mm, final error %.2f mm\n', n, max(errorMm), finalError);
    end

    % ── Plot ─────────────────────────────────────────────────────────────────
    if options.plot
        plotMoveLog(log);
    end
end