function plotMoveLog(log)
%PLOTMOVELOG  Generate tracking-error plots from a logMove or logMonitor log
%
% USAGE:
%   plotMoveLog(log)                      % from logMove or logMonitor return
%   plotMoveLog(load('move_log_*.mat').log)
%
% PRODUCES THREE FIGURES:
%   Fig 1 — TCP target vs actual (X, Y, Z) over time
%   Fig 2 — Position tracking error (mm) over time
%   Fig 3 — Joint angles Q1..Q5 over time

    if nargin < 1 || isempty(log)
        error('plotMoveLog: provide a log struct from logMove or logMonitor');
    end

    t = log.t;

    % Resolve target source (logMove has scalar .target; logMonitor has .targetTCP per sample)
    if isfield(log, 'target')
        tgtX = log.target(1) * ones(size(t));
        tgtY = log.target(2) * ones(size(t));
        tgtZ = log.target(3) * ones(size(t));
    else
        tgtX = log.targetTCP(:, 1);
        tgtY = log.targetTCP(:, 2);
        tgtZ = log.targetTCP(:, 3);
    end

    actX = log.actualTCP(:, 1);
    actY = log.actualTCP(:, 2);
    actZ = log.actualTCP(:, 3);

    % ── Figure 1: Target vs Actual (X, Y, Z stacked) ─────────────────────────
    figure('Name', 'TCP Target vs Actual', 'Color', 'w');

    subplot(3, 1, 1);
    plot(t, tgtX, 'b--', 'LineWidth', 1.5); hold on;
    plot(t, actX, 'r-',  'LineWidth', 1.2);
    grid on; ylabel('X [mm]');
    legend('Target', 'Actual', 'Location', 'best');
    title('TCP Position — Target vs Actual');

    subplot(3, 1, 2);
    plot(t, tgtY, 'b--', 'LineWidth', 1.5); hold on;
    plot(t, actY, 'r-',  'LineWidth', 1.2);
    grid on; ylabel('Y [mm]');

    subplot(3, 1, 3);
    plot(t, tgtZ, 'b--', 'LineWidth', 1.5); hold on;
    plot(t, actZ, 'r-',  'LineWidth', 1.2);
    grid on; ylabel('Z [mm]'); xlabel('Time [s]');

    % ── Figure 2: Tracking error ─────────────────────────────────────────────
    figure('Name', 'Distance to Target', 'Color', 'w');
    plot(t, log.errorMm, 'k-', 'LineWidth', 1.4);
    grid on;
    xlabel('Time [s]'); ylabel('Distance to Target [mm]');
    title(sprintf('TCP Distance to Target (max = %.2f mm, final = %.2f mm)', max(log.errorMm), log.errorMm(end)));

    % ── Figure 3: Joint angles ───────────────────────────────────────────────
    figure('Name', 'Joint Angles', 'Color', 'w');
    plot(t, log.actualJoints(:, 1), 'LineWidth', 1.2); hold on;
    plot(t, log.actualJoints(:, 2), 'LineWidth', 1.2);
    plot(t, log.actualJoints(:, 3), 'LineWidth', 1.2);
    plot(t, log.actualJoints(:, 4), 'LineWidth', 1.2);
    plot(t, log.actualJoints(:, 5), 'LineWidth', 1.2);
    grid on;
    xlabel('Time [s]'); ylabel('Joint angle [deg]');
    title('Joint Angles Q1..Q5');
    legend('Q1','Q2','Q3','Q4','Q5', 'Location','best');
end