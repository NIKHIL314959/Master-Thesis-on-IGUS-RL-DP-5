function success = tcp_move(plc, mode, x, y, z, b, c, options)
%TCP_MOVE  Move IGUS RL-DP-5 TCP to a Cartesian target via B&R MpRoboArm5Axis
%
% DESCRIPTION:
%   Sends a TCP target (X, Y, Z, B, C) to the B&R PLC and triggers a
%   MoveLinear (straight-line Cartesian) motion. The PLC handles all
%   inverse kinematics internally via the PathGen axes group.
%
%   No IK is computed in MATLAB. No joint angles are involved.
%   B and C orientation angles are optional (default 0).
%
% USAGE:
%   tcp_move(plc, 'abs',  X,  Y,  Z)           % absolute position
%   tcp_move(plc, 'abs',  X,  Y,  Z, B, C)     % absolute with orientation
%   tcp_move(plc, 'step', dX, dY, dZ)          % relative step from current TCP
%   tcp_move(plc, 'step', dX, dY, dZ, dB, dC)  % relative step with orientation
%
% INPUTS:
%   plc     — connected PLCController object
%   mode    — 'abs' for absolute target, 'step' for relative step
%   x,y,z   — target position [mm] or step [mm]
%   b       — target B orientation [deg]  (optional, default 0)
%   c       — target C orientation [deg]  (optional, default 0)
%   options — struct with optional fields:
%               .confirm  = true/false  ask before sending (default: true)
%               .timeout  = seconds     wait timeout (default: 60)
%               .verbose  = true/false  extra output (default: true)
%
% OUTPUTS:
%   success — true if move completed and TCP is within tolerance
%
% EXAMPLES:
%   % Absolute move to a specific point
%   tcp_move(plc, 'abs', 300, 0, 450)
%
%   % Relative step 50mm in X
%   tcp_move(plc, 'step', 50, 0, 0)
%
%   % Absolute move with orientation, no confirmation prompt
%   opt.confirm = false;
%   tcp_move(plc, 'abs', 250, 100, 400, -15, 0, opt)

    % ── Input defaults ────────────────────────────────────────────────────────
    if nargin < 6 || isempty(b)
    current = plc.getActualTCP();
    b = current(4);
    end

    if nargin < 7 || isempty(c)
    current = plc.getActualTCP();
    c = current(5);
    end
    if nargin < 8, options = struct(); end
    if ~isfield(options, 'confirm'), options.confirm = true;  end
    if ~isfield(options, 'timeout'), options.timeout = 60;    end
    if ~isfield(options, 'verbose'), options.verbose = true;  end

    success = false;

    % ── Validate inputs ───────────────────────────────────────────────────────
    if ~isa(plc, 'PLCController')
        error('tcp_move: first argument must be a connected PLCController object');
    end
    mode = lower(mode);
    if ~ismember(mode, {'abs', 'step'})
        error('tcp_move: mode must be ''abs'' or ''step'', got ''%s''', mode);
    end

    % ── Check robot is ready ──────────────────────────────────────────────────
    status = plc.getStatus();
    if status.error
        fprintf('[tcp_move] Robot is in error state (ErrorID=%d)\n', status.errorID);
        fprintf('[tcp_move] Call plc.resetError() to clear, then re-home if needed.\n');
        return
    end
    if ~status.homed
        fprintf('[tcp_move] Robot is not homed.\n');
        fprintf('[tcp_move] Please home the robot in mapp Cockpit first.\n');
        return
    end
    if ~status.ready
        fprintf('[tcp_move] Robot is not ready (powered=%d, homed=%d, error=%d)\n', ...
                status.powerOn, status.homed, status.error);
        return
    end

    % ── Compute target TCP ────────────────────────────────────────────────────
    current_tcp = plc.getActualTCP();  % [X Y Z B C]

    if strcmp(mode, 'step')
        target = current_tcp + [x, y, z, b, c];
    else
        % Absolute: use given X Y Z, and given B C
        target = [x, y, z, b, c];
    end

    target_x = target(1);
    target_y = target(2);
    target_z = target(3);
    target_b = target(4);
    target_c = target(5);

    move_dist = norm(target(1:3) - current_tcp(1:3));

    % ── Print summary ─────────────────────────────────────────────────────────
    if options.verbose
        fprintf('\n════════════════════════════════════════════════\n');
        fprintf('  TCP MOVE  [%s]\n', upper(mode));
        fprintf('════════════════════════════════════════════════\n');
        fprintf('  Current  TCP : X=%7.2f  Y=%7.2f  Z=%7.2f  B=%6.2f  C=%6.2f\n', current_tcp);
        fprintf('  Target   TCP : X=%7.2f  Y=%7.2f  Z=%7.2f  B=%6.2f  C=%6.2f\n', ...
                target_x, target_y, target_z, target_b, target_c);
        fprintf('  Distance     : %.2f mm\n', move_dist);
        fprintf('════════════════════════════════════════════════\n\n');
    end

    % ── Confirmation prompt ───────────────────────────────────────────────────
    if options.confirm
        response = input('  Send move to PLC? (y/n): ', 's');
        if ~strcmpi(response, 'y')
            fprintf('  Move cancelled by user.\n\n');
            return
        end
    end

    % ── Write target and trigger move ─────────────────────────────────────────
    if ~plc.setTargetTCP(target_x, target_y, target_z, target_b, target_c)
        fprintf('[tcp_move] Failed to write TCP target to PLC.\n');
        return
    end

    if ~plc.triggerMoveLinear()
        fprintf('[tcp_move] Failed to trigger move.\n');
        return
    end

    % ── Wait for completion ───────────────────────────────────────────────────
    if options.verbose
        fprintf('[tcp_move] Move executing...\n');
    end

    move_ok = plc.waitForInPosition(options.timeout);

    if ~move_ok
        fprintf('[tcp_move] Move did not complete within %.0fs.\n', options.timeout);
        plc.printStatus();
        return
    end

    % ── Post-move verification ────────────────────────────────────────────────
    pause(0.3);
    actual_tcp  = plc.getActualTCP();
    tcp_error   = norm(actual_tcp(1:3) - [target_x, target_y, target_z]);

    if options.verbose
        fprintf('\n[tcp_move] Post-move verification:\n');
        fprintf('  Target  TCP : X=%7.2f  Y=%7.2f  Z=%7.2f\n', target_x, target_y, target_z);
        fprintf('  Actual  TCP : X=%7.2f  Y=%7.2f  Z=%7.2f\n', actual_tcp(1), actual_tcp(2), actual_tcp(3));
        fprintf('  TCP error   : %.3f mm\n', tcp_error);
    end

    TOLERANCE_MM = 2.0;  % acceptable TCP error after move

    if tcp_error <= TOLERANCE_MM
        if options.verbose
            fprintf('\n  Move complete. TCP error within tolerance (%.3f mm)\n\n', tcp_error);
        end
        success = true;
    else
        fprintf('\n[tcp_move] TCP error %.2f mm exceeds tolerance (%.1f mm)\n', ...
                tcp_error, TOLERANCE_MM);
        fprintf('[tcp_move] Check mechanical system config or re-home.\n\n');
        success = false;
    end
end