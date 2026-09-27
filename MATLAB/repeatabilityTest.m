function stats = repeatabilityTest(plc, posA, posB, varargin)
%REPEATABILITYTEST  Measures positional repeatability of the IGUS RL-DP-5
%
% USAGE:
%   stats = repeatabilityTest(plc, posA, posB)
%   stats = repeatabilityTest(plc, posA, posB, 'trials', 10, 'velocity', 50)
%
% INPUTS:
%   plc   — connected PLCController
%   posA  — 1x5 [X Y Z B C] target to measure (the "Pick" position)
%   posB  — 1x5 [X Y Z B C] auxiliary position (the "Place" position)
%
%   The robot bounces A -> B -> A -> B -> ... and after each return to A
%   the actual TCP is recorded. The spread of those measurements gives
%   the repeatability number.
%
% NAME-VALUE PAIRS:
%   'trials'   — number of round trips (default 10)
%   'velocity' — mm/s (default 50)
%   'settle_s' — wait after move before measuring (default 1.0)
%
% OUTPUTS / FILES / PLOTS — same as before
%
% EXAMPLES:
%   posA = [400  100 500 0 0];   % measurement point
%   posB = [400 -100 500 0 0];   % auxiliary
%   stats = repeatabilityTest(plc, posA, posB);

    % ── Validate inputs ──────────────────────────────────────────────────────
    if nargin < 3
        error(['repeatabilityTest needs both posA and posB.\n' 'Usage: repeatabilityTest(plc, posA, posB)\n' 'Where posA and posB are 1x5 vectors [X Y Z B C].']);
    end
    if numel(posA) ~= 5 || numel(posB) ~= 5
        error('posA and posB must each be 1x5 [X Y Z B C]');
    end
    posA = posA(:)';
    posB = posB(:)';

    % ── Parse name-value pairs ───────────────────────────────────────────────
    p = inputParser;
    addParameter(p, 'trials',   10);
    addParameter(p, 'velocity', 50);
    addParameter(p, 'settle_s', 1.0);
    parse(p, varargin{:});
    opts = p.Results;

    % ── Pre-flight ───────────────────────────────────────────────────────────
    fprintf('\n══════════════ Repeatability Test ══════════════\n');
    fprintf('  Point A (measured) : X=%.2f Y=%.2f Z=%.2f B=%.2f C=%.2f\n', posA);
    fprintf('  Point B (auxiliary): X=%.2f Y=%.2f Z=%.2f B=%.2f C=%.2f\n', posB);
    fprintf('  Trials   : %d\n', opts.trials);
    fprintf('  Velocity : %d mm/s\n', opts.velocity);
    fprintf('═════════════════════════════════════════════════\n\n');

    % Check robot is ready BEFORE prompting
    s = plc.getStatus();
    if ~s.ready || s.error
        fprintf('  Robot is NOT ready. Status:\n');
        plc.printStatus();
        if s.error
            fprintf('  Tip: call plc.resetError() to clear.\n\n');
        end
        stats = struct();
        return
    end

    resp = input('  Press ENTER to start, or n to cancel: ', 's');
    if strcmpi(resp, 'n')
        fprintf('  Cancelled.\n');
        stats = struct();
        return
    end

    % ── Setup motion params ──────────────────────────────────────────────────
    plc.setMotionParams(opts.velocity, opts.velocity * 4, 100);

    % ── Pre-allocate ─────────────────────────────────────────────────────────
    measured = zeros(opts.trials, 5);
    successful = false(opts.trials, 1);

    moveOpt.confirm = false;
    moveOpt.verbose = false;
    moveOpt.timeout = 60;

    % ── Run trials ───────────────────────────────────────────────────────────
    for k = 1:opts.trials
        fprintf('  Trial %2d/%d  ', k, opts.trials);

        % Check for residual error and bail clearly
        s = plc.getStatus();
        if s.error
            fprintf('-> ABORT (robot in error state, ID=%d)\n', s.errorID);
            fprintf('  Stopping the test. Call plc.resetError() before retrying.\n');
            break
        end

        % Go to B (away)
        ok1 = tcp_move(plc, 'abs', posB(1), posB(2), posB(3), posB(4), posB(5), moveOpt);

        % Return to A (the measured target)
        ok2 = tcp_move(plc, 'abs', posA(1), posA(2), posA(3), posA(4), posA(5), moveOpt);

        if ~ok1 || ~ok2
            fprintf('-> SKIP (move failed)\n');
            continue
        end

        % Settle, then measure
        pause(opts.settle_s);
        measured(k, :) = plc.getActualTCP();
        successful(k) = true;

        fprintf('-> X=%.3f  Y=%.3f  Z=%.3f\n', measured(k,1), measured(k,2), measured(k,3));
    end

    % ── Drop failed trials ───────────────────────────────────────────────────
    nGood = sum(successful);
    if nGood < 3
        fprintf('\n  Only %d successful trial(s) — cannot compute meaningful stats.\n', nGood);
        stats = struct('measured', measured, 'successful', successful);
        return
    end
    if nGood < opts.trials
        fprintf('\n  Note: %d/%d trials succeeded; using those for stats.\n', nGood, opts.trials);
    end
    measuredOK = measured(successful, :);

    % ── Stats ────────────────────────────────────────────────────────────────
    meanPos    = mean(measuredOK(:, 1:3));
    stdPos     = std(measuredOK(:, 1:3));
    deviations = measuredOK(:, 1:3) - meanPos;
    radial     = sqrt(sum(deviations.^2, 2));
    radialMean = mean(radial);
    radialStd  = std(radial);
    rep3sigma  = 3 * radialStd;

    stats = struct();
    stats.trials              = opts.trials;
    stats.successful          = nGood;
    stats.velocity_mm_s       = opts.velocity;
    stats.taughtA             = posA;
    stats.taughtB             = posB;
    stats.measured            = measuredOK;
    stats.meanPos             = meanPos;
    stats.stdPerAxis_mm       = stdPos;
    stats.radialMean_mm       = radialMean;
    stats.radialStd_mm        = radialStd;
    stats.repeatability_3sigma_mm = rep3sigma;

    % ── Print summary ────────────────────────────────────────────────────────
    fprintf('\n══════════════ Repeatability Result ══════════════\n');
    fprintf('  Successful trials   : %d / %d\n', nGood, opts.trials);
    fprintf('  Mean position       : X=%.3f  Y=%.3f  Z=%.3f mm\n', meanPos);
    fprintf('  Std per axis        : sX=%.4f  sY=%.4f  sZ=%.4f mm\n', stdPos);
    fprintf('  Mean radial dev     : %.4f mm\n', radialMean);
    fprintf('  Std  radial dev     : %.4f mm\n', radialStd);
    fprintf('  Repeatability ±3σ   : %.3f mm\n', rep3sigma);
    fprintf('═══════════════════════════════════════════════════\n\n');

    % ── Save ─────────────────────────────────────────────────────────────────
    ts       = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    baseName = sprintf('repeatability_%s', ts);

    T = table((1:nGood)', measuredOK(:,1), measuredOK(:,2), measuredOK(:,3), measuredOK(:,4), measuredOK(:,5), deviations(:,1), deviations(:,2), deviations(:,3), radial, 'VariableNames', {'trial','X_mm','Y_mm','Z_mm','B_deg','C_deg', 'devX_mm','devY_mm','devZ_mm','radial_mm'});
    writetable(T, [baseName '.csv']);
    save([baseName '.mat'], 'stats');

    fprintf('  Saved: %s.csv  and  %s.mat\n\n', baseName, baseName);

    % ── Plots ────────────────────────────────────────────────────────────────
    plotRepeatability(stats);
end


function plotRepeatability(stats)
    measured  = stats.measured;
    meanPos   = stats.meanPos;
    deviations = measured(:, 1:3) - meanPos;
    rep3s     = stats.repeatability_3sigma_mm;

    figure('Name', 'Repeatability — 3D scatter', 'Color', 'w');
    scatter3(measured(:,1), measured(:,2), measured(:,3), 60, 'filled', 'MarkerFaceColor', [0.1 0.5 0.9]);
    hold on;
    plot3(meanPos(1), meanPos(2), meanPos(3), 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
    grid on; axis equal;
    xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
    title(sprintf('Repeatability — %d trials,  ±3σ = %.3f mm', stats.successful, rep3s));
    legend('Measured points','Mean','Location','best');

    figure('Name', 'Repeatability — XY top view', 'Color', 'w');
    plot(deviations(:,1), deviations(:,2), 'o', 'MarkerFaceColor', [0.1 0.5 0.9], 'MarkerSize', 7); hold on;
    plot(0, 0, 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
    th = linspace(0, 2*pi, 100);
    plot(rep3s*cos(th), rep3s*sin(th), 'r--', 'LineWidth', 1.2);
    grid on; axis equal;
    xlabel('\Delta X [mm]'); ylabel('\Delta Y [mm]');
    title(sprintf('XY deviation from mean   (±3σ = %.3f mm)', rep3s));
    legend('Trials','Mean','±3σ boundary','Location','best');

    figure('Name', 'Repeatability — per-trial deviation', 'Color', 'w');
    n = (1:size(measured, 1))';
    subplot(3,1,1);
    plot(n, deviations(:,1), '-o', 'LineWidth', 1.4); grid on;
    ylabel('\Delta X [mm]'); title('Per-trial deviation from mean position');
    subplot(3,1,2);
    plot(n, deviations(:,2), '-o', 'LineWidth', 1.4, 'Color', [0.85 0.4 0.1]);
    grid on; ylabel('\Delta Y [mm]');
    subplot(3,1,3);
    plot(n, deviations(:,3), '-o', 'LineWidth', 1.4, 'Color', [0.2 0.6 0.2]);
    grid on; ylabel('\Delta Z [mm]'); xlabel('Trial number');
end