function plotLatency(latencyMatFile)
%PLOTLATENCY  Three-panel figure of latency test results
%
% USAGE:
%   plotLatency('latency_2026-05-10_20-28-45.mat');
%
% PRODUCES:
%   Figure with three panels:
%     1. Read latency histogram
%     2. Write latency histogram
%     3. Cmd-to-motion latency bar chart (per trial)
%
% REQUIRES:
%   .mat file must include raw arrays (saved by updated latencyTest.m)

    S = load(latencyMatFile);
    stats = S.stats;

    haveRaw = isfield(stats.read_ms, 'raw');

    if ~haveRaw
        error(['Raw sample arrays not found in %s.\n' 'Update latencyTest.m to save raw data and re-run.'], latencyMatFile);
    end

    figure('Name', 'Latency Characterization', 'Color', 'w', 'Position', [50 50 1400 450]);

    % ── Panel 1: Read latency histogram ──────────────────────────────────────
    subplot(1, 3, 1);
    h = histogram(stats.read_ms.raw, 'BinWidth', 2, 'FaceColor', [0.1 0.5 0.9], 'EdgeColor', 'k');
    hold on;
    h_mean = xline(stats.read_ms.mean, 'r-', 'LineWidth', 2);
    h_p95 =  xline(stats.read_ms.p95, 'k--', 'LineWidth', 1.5);
    % Compact text box in upper-right with both values
    text(0.97, 0.95, sprintf(['{\\color{red}—}  mean: %.1f ms\n' '{\\color[rgb]{0.3,0.3,0.3}- -}  p95:  %.1f ms\n' '       max:  %.1f ms'], stats.read_ms.mean, stats.read_ms.p95, stats.read_ms.max), 'Units','normalized', 'HorizontalAlignment','right', 'VerticalAlignment','top', 'BackgroundColor','white', 'EdgeColor', [0.5 0.5 0.5], 'FontSize', 10, 'Interpreter', 'tex');

    grid on;
    xlabel('Latency [ms]'); ylabel('Count');
    title(sprintf('OPC UA Read  (n=%d)', stats.read_ms.n));

    % ── Panel 2: Write latency histogram ─────────────────────────────────────
    subplot(1, 3, 2);
    h = histogram(stats.write_ms.raw, 'BinWidth', 2, 'FaceColor', [0.85 0.5 0.1], 'EdgeColor', 'k');
    hold on;
    h_mean = xline(stats.write_ms.mean, 'r-', 'LineWidth', 2);
    h_p95 =  xline(stats.write_ms.p95, 'k--', 'LineWidth', 1.5);
    % Compact text box in upper-right with both values
    text(0.97, 0.95, sprintf(['{\\color{red}—}  mean: %.1f ms\n' '{\\color[rgb]{0.3,0.3,0.3}- -}  p95:  %.1f ms\n' '       max:  %.1f ms'], stats.write_ms.mean, stats.write_ms.p95, stats.write_ms.max), 'Units','normalized', 'HorizontalAlignment','right', 'VerticalAlignment','top', 'BackgroundColor','white', 'EdgeColor', [0.5 0.5 0.5], 'FontSize', 10, 'Interpreter', 'tex');

    grid on;
    xlabel('Latency [ms]'); ylabel('Count');
    title(sprintf('OPC UA Write  (n=%d)', stats.write_ms.n));

    % ── Panel 3: Cmd-to-motion per trial ─────────────────────────────────────
    subplot(1, 3, 3);
    if isstruct(stats.cmd_to_motion_ms) && isfield(stats.cmd_to_motion_ms, 'raw')
        raw = stats.cmd_to_motion_ms.raw;
        nTrials = numel(raw);
        bar(1:nTrials, raw, 'FaceColor', [0.2 0.7 0.3], 'EdgeColor', 'k');
        hold on;
        yline(stats.cmd_to_motion_ms.median, 'k--', 'LineWidth', 1.5, 'Label', sprintf('median %.1f ms', stats.cmd_to_motion_ms.median));

        % Mark the outlier (trial with max)
        [maxVal, maxIdx] = max(raw);
        if maxVal > 2 * stats.cmd_to_motion_ms.median
            text(maxIdx, maxVal + 2, 'outlier', 'HorizontalAlignment', 'center', 'Color', [0.85 0.1 0.1], 'FontWeight', 'bold');
        end

        grid on;
        xlabel('Trial number'); ylabel('Latency [ms]');
        title(sprintf('Cmd \\rightarrow Motion  (n=%d)', nTrials));
        xticks(1:nTrials);
    else
        text(0.5, 0.5, 'Phase 4 was skipped', 'Units', 'normalized', 'HorizontalAlignment', 'center');
        axis off;
    end

    sgtitle('IGUS RL-DP-5 — MATLAB / PLC Latency Characterization', 'FontWeight', 'bold', 'FontSize', 13);
end