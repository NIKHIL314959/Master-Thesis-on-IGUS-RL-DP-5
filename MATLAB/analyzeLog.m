function stats = analyzeLog(input)
%ANALYZELOG  Compute and print summary statistics from a move log
%
% USAGE:
%   stats = analyzeLog(log)                          % from logMove/logMonitor
%   stats = analyzeLog('move_log_2026-05-06.mat')    % from saved MAT
%   stats = analyzeLog('move_log_2026-05-06.csv')    % from saved CSV
%
% PRINTS:
%   Move duration, max / mean / RMS / final Distance to Target,
%   settling time (time to enter ±2 mm band and stay), peak velocity.
%
% RETURNS:
%   stats — struct with all printed values (handy for batch analysis)

    % ── Load input ───────────────────────────────────────────────────────────
    if ischar(input) || isstring(input)
        [~, ~, ext] = fileparts(input);
        switch lower(ext)
            case '.mat'
                S = load(input);
                if isfield(S, 'log')
                    log = S.log;
                else
                    error('analyzeLog: MAT file must contain a variable named ''log''');
                end
            case '.csv'
                T = readtable(input);
                log.t            = T.time_s;
                log.actualTCP    = [T.X_mm T.Y_mm T.Z_mm T.B_deg T.C_deg];
                log.actualJoints = [T.Q1_deg T.Q2_deg T.Q3_deg T.Q4_deg T.Q5_deg];
                log.errorMm      = T.error_mm;
                log.moving       = logical(T.moving);
                log.inPosition   = logical(T.inPosition);
                if any(strcmp(T.Properties.VariableNames, 'tgtX'))
                    log.targetTCP = [T.tgtX T.tgtY T.tgtZ T.tgtB T.tgtC];
                end
            otherwise
                error('analyzeLog: file must be .mat or .csv');
        end
    elseif isstruct(input)
        log = input;
    else
        error('analyzeLog: input must be a struct, .mat path, or .csv path');
    end

    t   = log.t;
    err = log.errorMm;
    n   = numel(t);

    % ── Basic stats ──────────────────────────────────────────────────────────
    stats = struct();
    stats.numSamples   = n;
    stats.duration_s   = t(end) - t(1);
    stats.maxError_mm  = max(err);
    stats.meanError_mm = mean(err);
    stats.rmsError_mm  = sqrt(mean(err.^2));
    stats.finalError_mm = err(end);

    % ── Settling time (to ±2 mm and stays there) ─────────────────────────────
    TOL = 2.0;
    settled = err < TOL;
    settleIdx = find(~settled, 1, 'last');
    if isempty(settleIdx) || settleIdx == n
        stats.settlingTime_s = NaN;
    else
        stats.settlingTime_s = t(settleIdx + 1) - t(1);
    end

    % ── Peak TCP velocity (numerical derivative) ─────────────────────────────
    if n > 2
        dx = diff(log.actualTCP(:, 1:3));
        dt = diff(t);
        speed = sqrt(sum(dx.^2, 2)) ./ dt;     % mm/s
        stats.peakVelocity_mm_s = max(speed);
        stats.meanVelocity_mm_s = mean(speed(speed > 0.5));   % ignore stationary
    else
        stats.peakVelocity_mm_s = NaN;
        stats.meanVelocity_mm_s = NaN;
    end

    % ── Joint travel (max - min for each joint) ──────────────────────────────
    stats.jointTravel_deg = max(log.actualJoints) - min(log.actualJoints);

    % ── Print ────────────────────────────────────────────────────────────────
    fprintf('\n══════════════ Log Analysis ══════════════\n');
    fprintf('  Samples           : %d\n',         stats.numSamples);
    fprintf('  Duration          : %.2f s\n',     stats.duration_s);
    fprintf('  Distance to Target    :\n');
    fprintf('     initial        : %.3f mm\n',    stats.maxError_mm);
    fprintf('     mean           : %.3f mm\n',    stats.meanError_mm);
    fprintf('     final          : %.3f mm\n',    stats.finalError_mm);
    if isnan(stats.settlingTime_s)
        fprintf('  Time to reach     : did not reach ±%.1f mm of target\n', TOL);
    else
        fprintf('  Time to reach     : %.2f s (within ±%.1f mm)\n', stats.settlingTime_s, TOL);
    end
    fprintf('  Peak  TCP speed   : %.2f mm/s\n', stats.peakVelocity_mm_s);
    fprintf('  Mean  TCP speed   : %.2f mm/s\n', stats.meanVelocity_mm_s);
    fprintf('  Joint travel [deg]: Q1=%.2f Q2=%.2f Q3=%.2f Q4=%.2f Q5=%.2f\n', stats.jointTravel_deg);
    fprintf('═════════════════════════════════════════\n\n');
end