function PickAndPlace(plc, pickX, pickY, pickZ, pickB, pickC, placeX, placeY, placeZ, placeB, placeC, homePos)
% PICKANDPLACE  Full pick and place sequence using existing tcp_move()
%
% USAGE (called from RobotControlPanel or Robot_session):
%   pickAndPlace(plc, pickX, pickY, pickZ, pickB, pickC, placeX, placeY, placeZ, placeB, placeC, homePos)
%
% GRIPPER: Schunk EGP 40-N-N-B — electric servo gripper, 24V digital I/O
%   gripperOpen()  — White wire HIGH → fingers open  (0.2s)
%   gripperClose() — Black wire HIGH → fingers close (0.2s)
%   Both off       → gripper holds position internally via servo
%
% All motion handled by PLC — MATLAB just sequences the steps.
% B and C are gripper orientation angles captured from the real robot.
% homePos is a 1x5 vector [X Y Z B C] captured before sequence starts.

    OFFSET = 80.0;  % mm above bottle for safe approach and depart

    opt.confirm = false;
    opt.timeout = 60;
    opt.verbose = true;

    fprintf('\n=== PICK AND PLACE START ===\n');
    fprintf('  Pick  : X=%.2f  Y=%.2f  Z=%.2f  B=%.2f  C=%.2f\n', pickX,  pickY,  pickZ,  pickB,  pickC);
    fprintf('  Place : X=%.2f  Y=%.2f  Z=%.2f  B=%.2f  C=%.2f\n', placeX, placeY, placeZ, placeB, placeC);
    fprintf('  Home  : X=%.2f  Y=%.2f  Z=%.2f  B=%.2f  C=%.2f\n', homePos(1), homePos(2), homePos(3), homePos(4), homePos(5));

    % ── 1. Open gripper — fingers open, ready to approach ────────────────────
    plc.gripperOpen();
    pause(0.3);   % EGP opens in 0.2s — 0.3s gives small safety margin
    fprintf('[1] Gripper open\n');

    % ── 2. Move above pick position (safe height) ─────────────────────────────
    tcp_move(plc, 'abs', pickX, pickY, pickZ + OFFSET, pickB, pickC, opt);
    fprintf('[2] Above pick position\n');

    % ── 3. Lower straight down to bottle ─────────────────────────────────────
    tcp_move(plc, 'abs', pickX, pickY, pickZ, pickB, pickC, opt);
    fprintf('[3] At pick position\n');

    % ── 4. Close gripper — fingers grip bottle ────────────────────────────────
    plc.gripperClose();
    pause(0.3);   % EGP closes in 0.2s — 0.3s gives small safety margin
    fprintf('[4] Gripper closed\n');

    % ── 5. Lift straight up with bottle ──────────────────────────────────────
    tcp_move(plc, 'abs', pickX, pickY, pickZ + OFFSET, pickB, pickC, opt);
    fprintf('[5] Lifted\n');

    % ── 6. Move across to above place position ────────────────────────────────
    tcp_move(plc, 'abs', placeX, placeY, placeZ + OFFSET, placeB, placeC, opt);
    fprintf('[6] Above place position\n');

    % ── 7. Lower straight down to place position ──────────────────────────────
    tcp_move(plc, 'abs', placeX, placeY, placeZ, placeB, placeC, opt);
    fprintf('[7] At place position\n');

    % ── 8. Open gripper — release bottle ─────────────────────────────────────
    plc.gripperOpen();
    pause(0.3);
    fprintf('[8] Gripper open — bottle released\n');

    % ── 9. Move across to above place position ────────────────────────────────
    tcp_move(plc, 'abs', placeX, placeY, placeZ + OFFSET, placeB, placeC, opt);
    fprintf('[6] Above place position\n');

    % ── 10. Return to home position ────────────────────────────────────────────
    tcp_move(plc, 'abs', homePos(1), homePos(2), homePos(3), homePos(4), homePos(5), opt);
    fprintf('[10] Back at home\n');

    % Note: No gripperNeutral() needed for EGP 40-N-N-B
    % The integrated servo controller holds finger position when both signals off

    fprintf('=== PICK AND PLACE DONE ===\n\n');
end