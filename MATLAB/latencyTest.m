function stats = latencyTest(plc, varargin)
%LATENCYTEST  Characterizes the MATLAB-PLC latency in four phases
%
% USAGE:
%   stats = latencyTest(plc);                    % 100 samples default
%   stats = latencyTest(plc, 'samples', 500);
%
% PHASES:
%   1. OPC UA read latency  — single-value reads
%   2. OPC UA write latency — single-value writes
%   3. Sensor refresh rate  — measured DURING motion
%   4. Command-to-motion    — measured with single-flag polling

    p = inputParser;
    addParameter(p, 'samples',  100);
    addParameter(p, 'velocity', 20);
    addParameter(p, 'lift_mm',  50);
    parse(p, varargin{:});
    opts = p.Results;

    fprintf('\n══════════════ Latency Test ══════════════\n');
    fprintf('  Samples per test : %d\n', opts.samples);

    s = plc.getStatus();
    if ~s.ready || s.error
        fprintf('  Robot NOT ready.\n');
        plc.printStatus();
        stats = struct();
        return
    end

    stats = struct();

    % =========================================================================
    % PHASE 1 — READ LATENCY
    % =========================================================================
    fprintf('\n  Phase 1/4: OPC UA single-value READ latency...\n');
    t_read = zeros(opts.samples, 1);
    for k = 1:opts.samples
        tic;
        plc.getActualTCP();
        t_read(k) = toc * 1000;
    end
    stats.read_ms = summarize(t_read, 'Read');
    stats.read_ms.raw = t_read;

    % =========================================================================
    % PHASE 2 — WRITE LATENCY
    % =========================================================================
    fprintf('\n  Phase 2/4: OPC UA single-value WRITE latency...\n');
    t_write = zeros(opts.samples, 1);
    currentTgt = plc.getTargetTCP();
    for k = 1:opts.samples
        tic;
        plc.setTargetTCP(currentTgt(1), currentTgt(2), currentTgt(3), currentTgt(4), currentTgt(5));
        t_write(k) = toc * 1000;
    end
    stats.write_ms = summarize(t_write, 'Write');
    stats.write_ms.raw = t_write;

    % =========================================================================
    % PHASE 3 — SENSOR REFRESH RATE (during motion)
    %   Start a slow Z move, poll gActual_X flat out for ~2.5 s,
    %   count how many times the reported value actually CHANGES.
    %   That's the effective digital twin update rate.
    % =========================================================================
    fprintf('\n  Phase 3/4: Sensor refresh rate (during motion)...\n');

    startTCP = plc.getActualTCP();
    bH = startTCP(4); cH = startTCP(5);
    fprintf('    Start TCP: X=%.1f Y=%.1f Z=%.1f\n', startTCP(1:3));

    resp = input('    Press ENTER to start Phase 3 (slow lift), or n to skip: ', 's');
    if strcmpi(resp, 'n')
        fprintf('    Phase 3 skipped.\n');
        stats.sensor_refresh_Hz = NaN;
        stats.poll_rate_Hz = NaN;
        stats.sample_count = 0;
        stats.change_count = 0;
    else
        % Start a slow upward move (no waitForInPosition — we poll during it)
        plc.setMotionParams(opts.velocity, opts.velocity * 4, 100);
        plc.setTargetTCP(startTCP(1), startTCP(2), startTCP(3) + opts.lift_mm, bH, cH);
        plc.triggerMoveLinear();
        pause(0.2);   % let the move start

        % Poll gActual_Z (not X — Z is the axis actually moving)
        dur = 2.5;
        zVals = [];
        tStart = tic;
        while toc(tStart) < dur
            tcp = plc.getActualTCP();
            zVals(end+1) = tcp(3); %#ok<AGROW>
        end

        % Count CHANGES (consecutive differences > tolerance)
        TOL = 0.01;   % mm
        nReads   = numel(zVals);
        nChanges = sum(abs(diff(zVals)) > TOL);
        pollRate    = nReads / dur;
        refreshRate = nChanges / dur;

        fprintf('    Polled  %d times in %.2f s\n', nReads, dur);
        fprintf('    Poll rate    : %.1f Hz\n', pollRate);
        fprintf('    Value changes: %d\n', nChanges);
        fprintf('    Refresh rate : %.1f Hz\n', refreshRate);

        stats.sensor_refresh_Hz = refreshRate;
        stats.poll_rate_Hz      = pollRate;
        stats.sample_count      = nReads;
        stats.change_count      = nChanges;

        % Wait for the move to actually finish
        plc.waitForInPosition(15);
        pause(0.3);

        % Return to start
        moveOpt.confirm = false; moveOpt.verbose = false; moveOpt.timeout = 15;
        tcp_move(plc, 'abs', startTCP(1), startTCP(2), startTCP(3), bH, cH, moveOpt);
    end

    % =========================================================================
    % PHASE 4 — COMMAND-TO-MOTION LATENCY (single-flag polling)
    % =========================================================================
    fprintf('\n  Phase 4/4: Command-to-motion latency...\n');

    startTCP = plc.getActualTCP();
    bH = startTCP(4); cH = startTCP(5);

    resp = input('    Press ENTER to start Phase 4 (3 lifts + 3 lowers), or n to skip: ', 's');
    if strcmpi(resp, 'n')
        fprintf('    Phase 4 skipped.\n');
        stats.cmd_to_motion_ms = NaN;
        printSummary(stats);
        return
    end

    plc.setMotionParams(opts.velocity, opts.velocity * 4, 100);

    targets = startTCP(3) + opts.lift_mm * [1 0 1 0 1 0]';
    cmdLatencies = nan(numel(targets), 1);

    for k = 1:numel(targets)
        fprintf('    Trial %d/%d ', k, numel(targets));

        % Write target
        plc.setTargetTCP(startTCP(1), startTCP(2), targets(k), bH, cH);

        % Make sure Moving=FALSE before triggering
        while plc.getMovingFlag()
            pause(0.01);
        end

        % Time from trigger to Moving=TRUE, using single-flag reads
        tic;
        plc.triggerMoveLinear();

        gotMoving = false;
        while toc < 1.0
            if plc.getMovingFlag()
                cmdLatencies(k) = toc * 1000;
                gotMoving = true;
                break
            end
        end

        if gotMoving
            fprintf('-> %.1f ms\n', cmdLatencies(k));
        else
            fprintf('TIMEOUT\n');
        end

        % Let the move finish before next trial
        plc.waitForInPosition(15);
        pause(0.3);
    end

    valid = ~isnan(cmdLatencies);
    if any(valid)
        stats.cmd_to_motion_ms = summarize(cmdLatencies(valid), 'Cmd->Motion');
        stats.cmd_to_motion_ms.raw = cmdLatencies;
    else
        stats.cmd_to_motion_ms = NaN;
    end

    % Return to start
    moveOpt.confirm = false; moveOpt.verbose = false; moveOpt.timeout = 15;
    tcp_move(plc, 'abs', startTCP(1), startTCP(2), startTCP(3), bH, cH, moveOpt);

    % =========================================================================
    printSummary(stats);
    ts = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    save(sprintf('latency_%s.mat', ts), 'stats');
    fprintf('  Saved latency_%s.mat\n\n', ts);
end


% ════════════════════════════════════════════════════════════════════════════
function s = summarize(values, label)
    s = struct();
    s.n      = numel(values);
    s.mean   = mean(values);
    s.median = median(values);
    s.min    = min(values);
    s.max    = max(values);
    s.std    = std(values);
    s.p95    = prctile(values, 95);
    fprintf('    %s latency: mean=%.2f ms  median=%.2f ms  min=%.2f  max=%.2f  p95=%.2f  std=%.2f\n', label, s.mean, s.median, s.min, s.max, s.p95, s.std);
end


function printSummary(stats)
    fprintf('\n══════════════ Latency Summary ══════════════\n');
    if isfield(stats, 'read_ms') && isstruct(stats.read_ms)
        fprintf('  OPC UA read    : mean %.2f ms,  p95 %.2f ms\n', stats.read_ms.mean, stats.read_ms.p95);
    end
    if isfield(stats, 'write_ms') && isstruct(stats.write_ms)
        fprintf('  OPC UA write   : mean %.2f ms,  p95 %.2f ms\n', stats.write_ms.mean, stats.write_ms.p95);
    end
    if isfield(stats, 'poll_rate_Hz') && ~isnan(stats.poll_rate_Hz)
        fprintf('  Poll rate      : %.0f Hz\n', stats.poll_rate_Hz);
    end
    if isfield(stats, 'sensor_refresh_Hz') && ~isnan(stats.sensor_refresh_Hz)
        fprintf('  Sensor refresh : %.0f Hz (during motion)\n', stats.sensor_refresh_Hz);
    end
    if isfield(stats, 'cmd_to_motion_ms') && isstruct(stats.cmd_to_motion_ms)
        fprintf('  Cmd -> motion  : mean %.1f ms,  max %.1f ms,  min %.1f ms\n', stats.cmd_to_motion_ms.mean, stats.cmd_to_motion_ms.max, stats.cmd_to_motion_ms.min);
    end
    fprintf('═════════════════════════════════════════════\n\n');
end