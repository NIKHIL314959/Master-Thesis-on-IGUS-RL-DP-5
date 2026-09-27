%% ROBOT_SESSION.m — IGUS RL-DP-5 Session Startup Script
%
% PURPOSE:
%   Main entry point for every MATLAB session with the robot.
%   Run this script to connect, verify status, and start sending moves.
%
% WORKFLOW:
%   1. Connect to PLC via OPC-UA
%   2. Home the robot manually in mapp Cockpit (if not already homed)
%   3. Wait for ready state
%   4. Send moves using tcp_move()
%
% REQUIREMENTS:
%   - PLC running with 5AxesRoboarmA project downloaded
%   - Ethernet connected to 169.254.137.11
%   - Robot homed in mapp Cockpit before sending moves

%% ── 1. CONNECT ───────────────────────────────────────────────────────────────
plc = PLCController('169.254.137.11', 48400);

if ~plc.connect()
    error('Cannot connect to PLC. Check Ethernet cable and PLC IP.');
end

%% ── 2. CHECK STATUS ──────────────────────────────────────────────────────────
plc.printStatus();

%% ── 3. SET MOTION PARAMETERS (optional) ─────────────────────────────────────
% velocity [mm/s], acceleration [mm/s²], override [%]
plc.setMotionParams(10, 50, 100);

%% ── 4. WAIT FOR ROBOT READY ──────────────────────────────────────────────────
% If not yet homed: go to mapp Cockpit → Home the robot → come back here
fprintf('\nIf robot is not homed, do it now in mapp Cockpit, then press any key...\n');
pause;

if ~plc.waitUntilReady(30)
    error('Robot not ready. Check power and homing state in mapp Cockpit.');
end

%% ── 5. PRINT CURRENT POSITION ────────────────────────────────────────────────
fprintf('\nCurrent TCP position:\n');
tcp = plc.getActualTCP();
fprintf('  X=%.2f  Y=%.2f  Z=%.2f  B=%.2f  C=%.2f\n\n', tcp);

%% ── 6. EXAMPLE MOVES ─────────────────────────────────────────────────────────
% Uncomment and run sections individually

% % Absolute move — go to a known safe position
% tcp_move(plc, 'abs', 0, 0, 600, 0, 0);

% % Relative step — move 50mm in X
% tcp_move(plc, 'step', 50, 0, 0);

% % Move without confirmation prompt (for scripted sequences)
% opt.confirm = false;
% tcp_move(plc, 'abs', 300, 0, 450, 0, 0, opt);
% tcp_move(plc, 'abs', 300, 100, 450, 0, 0, opt);
% tcp_move(plc, 'abs', 300, 0, 450, 0, 0, opt);

%% ── 7. DISCONNECT (run when done) ────────────────────────────────────────────
% plc.disconnect();