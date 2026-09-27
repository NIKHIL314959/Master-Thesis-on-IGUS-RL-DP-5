classdef PLCController < handle
% PLCCONTROLLER  OPC UA interface between MATLAB and the B&R PLC
%
% PURPOSE:
%   Manages the OPC UA connection to the X20CP0484-1 PLC running the
%   5AxesRoboarmA project. Caches all OPC UA node handles at connect
%   time so that runtime reads/writes are fast.
%
% RESPONSIBILITIES:
%   - Connect / disconnect to opc.tcp://<ip>:<port>
%   - Read  : actual TCP (X,Y,Z,B,C), actual joints (Q1..Q5), status flags
%   - Write : target TCP, motion parameters, command flags, gripper signals
%   - Trigger: MoveLinear, MoveDirect, Stop, ErrorReset, Pick&Place, Teach
%   - Wait helpers: waitUntilReady, waitForInPosition
%
% USAGE:
%   plc = PLCController('169.254.137.11', 48400);
%   plc.connect();
%   plc.printStatus();
%   tcp = plc.getActualTCP();          % [X Y Z B C]
%   plc.setMotionParams(10, 50, 100);  % vel, acc, override
%   plc.disconnect();
%
% NOTES:
%   Security mode is None / Anonymous (lab use only).
%   Namespace prefix 'ns=6;s=' is NOT used — names are resolved by the
%   client's namespace browser via findNodeByName.

    properties (Access = public)
        client
        nodes = struct()
    end

    properties (SetAccess = private)
        plcIP   = '169.254.137.11'
        plcPort = 48400
    end

    properties (Access = private)
        connected = false
    end

    methods

        function obj = PLCController(ip, port)
            if nargin >= 1 && ~isempty(ip),  obj.plcIP   = ip;   end
            if nargin >= 2 && ~isempty(port), obj.plcPort = port; end
            fprintf('[PLCController] Initialized for %s:%d\n', obj.plcIP, obj.plcPort);
        end

        function success = connect(obj)
            try
                fprintf('[PLCController] Connecting to opc.tcp://%s:%d...\n', obj.plcIP, obj.plcPort);
                obj.client = opcua(obj.plcIP, obj.plcPort);
                setSecurityModel(obj.client, "None", "None");
                connect(obj.client);
                fprintf('[PLCController] Connected\n');
                obj.connected = true;
                obj.cacheNodes();
                success = true;
            catch ME
                fprintf('[PLCController] Connection failed: %s\n', ME.message);
                obj.connected = false;
                success = false;
            end
        end

        function disconnect(obj)
            if obj.connected && ~isempty(obj.client)
                try, disconnect(obj.client);
                    fprintf('[PLCController] Disconnected\n');
                catch, end
            end
            obj.connected = false;
        end

        function cacheNodes(obj)
            fprintf('[PLCController] Caching OPC UA nodes...\n');
            try
                % TCP targets
                obj.nodes.targetX       = findNodeByName(obj.client.Namespace, 'gTargetX',            '-once');
                obj.nodes.targetY       = findNodeByName(obj.client.Namespace, 'gTargetY',            '-once');
                obj.nodes.targetZ       = findNodeByName(obj.client.Namespace, 'gTargetZ',            '-once');
                obj.nodes.targetB       = findNodeByName(obj.client.Namespace, 'gTargetB',            '-once');
                obj.nodes.targetC       = findNodeByName(obj.client.Namespace, 'gTargetC',            '-once');
                % Commands
                obj.nodes.cmdMoveLinear = findNodeByName(obj.client.Namespace, 'gCmd_MoveLinear',     '-once');
                obj.nodes.cmdMoveDirect = findNodeByName(obj.client.Namespace, 'gCmd_MoveDirect',     '-once');
                obj.nodes.cmdStop       = findNodeByName(obj.client.Namespace, 'gCmd_Stop',           '-once');
                obj.nodes.cmdErrorReset = findNodeByName(obj.client.Namespace, 'gCmd_ErrorReset',     '-once');
                % Status
                obj.nodes.statusReady   = findNodeByName(obj.client.Namespace, 'gStatus_Ready',       '-once');
                obj.nodes.statusMoving  = findNodeByName(obj.client.Namespace, 'gStatus_Moving',      '-once');
                obj.nodes.statusInPos   = findNodeByName(obj.client.Namespace, 'gStatus_InPosition',  '-once');
                obj.nodes.statusError   = findNodeByName(obj.client.Namespace, 'gStatus_Error',       '-once');
                obj.nodes.statusErrorID = findNodeByName(obj.client.Namespace, 'gStatus_ErrorID',     '-once');
                obj.nodes.statusHomed   = findNodeByName(obj.client.Namespace, 'gStatus_Homed',       '-once');
                obj.nodes.statusPowerOn = findNodeByName(obj.client.Namespace, 'gStatus_PowerOn',     '-once');
                % Actual TCP
                obj.nodes.actualX       = findNodeByName(obj.client.Namespace, 'gActual_X',           '-once');
                obj.nodes.actualY       = findNodeByName(obj.client.Namespace, 'gActual_Y',           '-once');
                obj.nodes.actualZ       = findNodeByName(obj.client.Namespace, 'gActual_Z',           '-once');
                obj.nodes.actualB       = findNodeByName(obj.client.Namespace, 'gActual_B',           '-once');
                obj.nodes.actualC       = findNodeByName(obj.client.Namespace, 'gActual_C',           '-once');
                % Actual joints
                obj.nodes.actualQ1      = findNodeByName(obj.client.Namespace, 'gActual_Q1',          '-once');
                obj.nodes.actualQ2      = findNodeByName(obj.client.Namespace, 'gActual_Q2',          '-once');
                obj.nodes.actualQ3      = findNodeByName(obj.client.Namespace, 'gActual_Q3',          '-once');
                obj.nodes.actualQ4      = findNodeByName(obj.client.Namespace, 'gActual_Q4',          '-once');
                obj.nodes.actualQ5      = findNodeByName(obj.client.Namespace, 'gActual_Q5',          '-once');
                % Motion params
                obj.nodes.paramVel      = findNodeByName(obj.client.Namespace, 'gParam_Velocity',     '-once');
                obj.nodes.paramAcc      = findNodeByName(obj.client.Namespace, 'gParam_Acceleration', '-once');
                obj.nodes.paramOverride = findNodeByName(obj.client.Namespace, 'gParam_Override',     '-once');
                % Gripper — Schunk EGP 40 NNB electric gripper
                obj.nodes.gripperOpen   = findNodeByName(obj.client.Namespace, 'gGripperOpen',        '-once');
                obj.nodes.gripperClose  = findNodeByName(obj.client.Namespace, 'gGripperClose',       '-once');
                % Homing
                obj.nodes.cmdHome       = findNodeByName(obj.client.Namespace, 'gCmd_Home',           '-once');
                obj.nodes.statusHoming  = findNodeByName(obj.client.Namespace, 'gStatus_Homing',      '-once');

                fprintf('[PLCController] All nodes cached successfully\n');
            catch ME
                warning('[PLCController] Node caching failed: %s', ME.message);
            end
        end

        function status = getStatus(obj)
            obj.checkConnected();
            status = struct();
            try
                status.ready      = logical(readValue(obj.client, obj.nodes.statusReady));
                status.moving     = logical(readValue(obj.client, obj.nodes.statusMoving));
                status.inPosition = logical(readValue(obj.client, obj.nodes.statusInPos));
                status.error      = logical(readValue(obj.client, obj.nodes.statusError));
                status.errorID    = double( readValue(obj.client, obj.nodes.statusErrorID));
                status.homed      = logical(readValue(obj.client, obj.nodes.statusHomed));
                status.powerOn    = logical(readValue(obj.client, obj.nodes.statusPowerOn));
            catch ME
                warning('[PLCController] getStatus failed: %s', ME.message);
                status = obj.safeStatusDefaults();
            end
        end

        function ready = isReady(obj)
            s = obj.getStatus();
            ready = s.ready;
        end

        function tcp = getActualTCP(obj)
            obj.checkConnected();
            try
                x = double(readValue(obj.client, obj.nodes.actualX));
                y = double(readValue(obj.client, obj.nodes.actualY));
                z = double(readValue(obj.client, obj.nodes.actualZ));
                b = double(readValue(obj.client, obj.nodes.actualB));
                c = double(readValue(obj.client, obj.nodes.actualC));
                tcp = [x, y, z, b, c];
            catch ME
                warning('[PLCController] getActualTCP failed: %s', ME.message);
                tcp = [0 0 0 0 0];
            end
        end

        function tcp = getTargetTCP(obj)
            % Returns the TCP target currently written in the PLC [X Y Z B C]
            % Used by logMonitor to capture targets that change during sequences
            obj.checkConnected();
            try
                x = double(readValue(obj.client, obj.nodes.targetX));
                y = double(readValue(obj.client, obj.nodes.targetY));
                z = double(readValue(obj.client, obj.nodes.targetZ));
                b = double(readValue(obj.client, obj.nodes.targetB));
                c = double(readValue(obj.client, obj.nodes.targetC));
                tcp = [x, y, z, b, c];
            catch ME
                warning('[PLCController] getTargetTCP failed: %s', ME.message);
                tcp = [0 0 0 0 0];
            end
        end

        function q = getActualJoints(obj)
            obj.checkConnected();
            try
                q1 = double(readValue(obj.client, obj.nodes.actualQ1));
                q2 = double(readValue(obj.client, obj.nodes.actualQ2));
                q3 = double(readValue(obj.client, obj.nodes.actualQ3));
                q4 = double(readValue(obj.client, obj.nodes.actualQ4));
                q5 = double(readValue(obj.client, obj.nodes.actualQ5));
                q = [q1, q2, q3, q4, q5];
            catch ME
                warning('[PLCController] getActualJoints failed: %s', ME.message);
                q = [0 0 0 0 0];
            end
        end

        function success = setTargetTCP(obj, x, y, z, b, c)
            obj.checkConnected();
            if nargin < 5, b = 0.0; end
            if nargin < 6, c = 0.0; end
            try
                writeValue(obj.client, obj.nodes.targetX, {double(x)});
                writeValue(obj.client, obj.nodes.targetY, {double(y)});
                writeValue(obj.client, obj.nodes.targetZ, {double(z)});
                writeValue(obj.client, obj.nodes.targetB, {double(b)});
                writeValue(obj.client, obj.nodes.targetC, {double(c)});
                fprintf('[PLCController] Target TCP: X=%.2f Y=%.2f Z=%.2f B=%.2f C=%.2f\n', x,y,z,b,c);
                success = true;
            catch ME
                warning('[PLCController] setTargetTCP failed: %s', ME.message);
                success = false;
            end
        end

        function success = triggerMoveLinear(obj)
            obj.checkConnected();
            try
                writeValue(obj.client, obj.nodes.cmdMoveLinear, {true});
                fprintf('[PLCController] MoveLinear triggered\n');
                success = true;
            catch ME
                warning('[PLCController] triggerMoveLinear failed: %s', ME.message);
                success = false;
            end
        end

        function success = triggerMoveDirect(obj)
            obj.checkConnected();
            try
                writeValue(obj.client, obj.nodes.cmdMoveDirect, {true});
                fprintf('[PLCController] MoveDirect triggered\n');
                success = true;
            catch ME
                warning('[PLCController] triggerMoveDirect failed: %s', ME.message);
                success = false;
            end
        end

        function success = triggerJogJoint(obj, jointIndex, stepDeg)
            % Triggers single joint jog step in ACS coordinate system.
            % Requires gCmd_JogJoint, gJogJointIndex, gJogJointStep in OPC UA map.
            obj.checkConnected();
            try
                obj.nodes.cmdJogJoint   = findNodeByName(obj.client.Namespace, 'gCmd_JogJoint',  '-once');
                obj.nodes.jogJointIndex = findNodeByName(obj.client.Namespace, 'gJogJointIndex', '-once');
                obj.nodes.jogJointStep  = findNodeByName(obj.client.Namespace, 'gJogJointStep',  '-once');
                writeValue(obj.client, obj.nodes.jogJointIndex, {int16(jointIndex)});
                writeValue(obj.client, obj.nodes.jogJointStep, {double(stepDeg)});
                writeValue(obj.client, obj.nodes.cmdJogJoint,   {true});
                success = true;
            catch ME
                warning('[PLCController] triggerJogJoint failed: %s', ME.message);
                success = false;
            end
        end

        function gripperOpen(obj)
            obj.checkConnected();
            try
                writeValue(obj.client, obj.nodes.gripperOpen,  {true});
                writeValue(obj.client, obj.nodes.gripperClose, {false});
                fprintf('[PLCController] Gripper open\n');
            catch ME
                warning('[PLCController] gripperOpen failed: %s', ME.message);
            end
        end

        function gripperClose(obj)
            obj.checkConnected();
            try
                writeValue(obj.client, obj.nodes.gripperClose, {true});
                writeValue(obj.client, obj.nodes.gripperOpen,  {false});
                fprintf('[PLCController] Gripper close\n');
            catch ME
                warning('[PLCController] gripperClose failed: %s', ME.message);
            end
        end

        function gripperNeutral(obj)
            obj.checkConnected();
            try
                writeValue(obj.client, obj.nodes.gripperOpen,  {false});
                writeValue(obj.client, obj.nodes.gripperClose, {false});
                fprintf('[PLCController] Gripper neutral\n');
            catch ME
                warning('[PLCController] gripperNeutral failed: %s', ME.message);
            end
        end

                function success = startPickAndPlace(obj)
            % Triggers the PLC pick-and-place state machine.
            % Pick / Place / Home positions must already be taught.
            % The robot moves: Home -> Pick -> Place -> Home using the taught poses.
            %
            % USAGE:
            %   plc.startPickAndPlace()
            %
            % This is non-blocking — the function returns immediately.
            % Use waitForPickAndPlace() to wait for completion.
            obj.checkConnected();
            try
                if ~isfield(obj.nodes, 'cmdPickPlace')
                    obj.nodes.cmdPickPlace = findNodeByName(obj.client.Namespace, 'gCmd_PickPlace', '-once');
                end
                writeValue(obj.client, obj.nodes.cmdPickPlace, {true});
                fprintf('[PLCController] Pick-and-place sequence started\n');
                success = true;
            catch ME
                warning('[PLCController] startPickAndPlace failed: %s', ME.message);
                success = false;
            end
        end

        function success = waitForPickAndPlace(obj, timeout_s)
            % Waits until the pick-and-place sequence finishes.
            % Detects completion by watching gCmd_PickPlace go FALSE
            % (the PLC clears it at the end of step 17).
            %
            % USAGE:
            %   plc.waitForPickAndPlace()           % default 120s timeout
            %   plc.waitForPickAndPlace(60)
            if nargin < 2, timeout_s = 120; end
            obj.checkConnected();
            if ~isfield(obj.nodes, 'cmdPickPlace')
                obj.nodes.cmdPickPlace = findNodeByName(obj.client.Namespace,'gCmd_PickPlace', '-once');
            end
            fprintf('[PLCController] Waiting for pick-and-place to complete...\n');
            pause(0.5);   % give the PLC time to start
            tic;
            while toc < timeout_s
                try
                    cmdActive = logical(readValue(obj.client, obj.nodes.cmdPickPlace));
                    if ~cmdActive
                        fprintf('[PLCController] Pick-and-place complete\n');
                        success = true; return
                    end
                catch
                end
                pause(0.2);
            end
            warning('[PLCController] Timeout waiting for pick-and-place');
            success = false;
        end

        function home(obj)
            % Triggers homing on all 5 axes — same as mapp Cockpit Home button
            obj.checkConnected();
            try
                writeValue(obj.client, obj.nodes.cmdHome, {true});
                fprintf('[PLCController] Homing triggered\n');
            catch ME
                warning('[PLCController] home failed: %s', ME.message);
            end
        end

        function success = waitUntilHomed(obj, timeout_s)
    if nargin < 2, timeout_s = 60; end
    fprintf('[PLCController] Homing triggered — waiting for axes to start...\n');

    % Fixed 2 second wait — gives PLC time to start homing
    % and axes time to lose their homed state
    pause(2.0);

    fprintf('[PLCController] Waiting for homing to complete...\n');
    tic;
    while toc < timeout_s
        try
            s = obj.getStatus();
            if s.homed
                fprintf('[PLCController] Homing complete\n');
                success = true; return
            end
            if s.error
                fprintf('[PLCController] Error during homing (ErrorID=%d)\n', s.errorID);
                success = false; return
            end
        catch, end
        pause(0.5);
    end
    warning('[PLCController] Timeout waiting for homing');
    success = false;
end

        function resetError(obj)
            obj.checkConnected();
            try
                writeValue(obj.client, obj.nodes.cmdErrorReset, {true});
                fprintf('[PLCController] Error reset sent\n');
                pause(0.3);
            catch ME
                warning('[PLCController] resetError failed: %s', ME.message);
            end
        end

        function setMotionParams(obj, velocity_mm_s, acceleration_mm_s2, override_pct)
            if nargin < 2 || isempty(velocity_mm_s), velocity_mm_s      = 10.0;  end
            if nargin < 3 || isempty(acceleration_mm_s2), acceleration_mm_s2 = 50.0;  end
            if nargin < 4 || isempty(override_pct), override_pct       = 100.0; end
            obj.checkConnected();
            try
                writeValue(obj.client, obj.nodes.paramVel, {single(velocity_mm_s)});
                writeValue(obj.client, obj.nodes.paramAcc, {single(acceleration_mm_s2)});
                writeValue(obj.client, obj.nodes.paramOverride, {single(override_pct)});
                fprintf('[PLCController] Motion params: vel=%.1f mm/s, acc=%.1f mm/s2, override=%.0f%%\n', velocity_mm_s, acceleration_mm_s2, override_pct);
            catch ME
                warning('[PLCController] setMotionParams failed: %s', ME.message);
            end
        end

        function success = waitUntilReady(obj, timeout_s)
            if nargin < 2, timeout_s = 60; end
            fprintf('[PLCController] Waiting for robot ready...\n');
            tic;
            while toc < timeout_s
                try
                    if obj.isReady()
                        fprintf('[PLCController] Robot ready\n');
                        success = true; return
                    end
                catch, end
                pause(0.5);
            end
            warning('[PLCController] Timeout waiting for ready state');
            success = false;
        end

        function success = waitForInPosition(obj, timeout_s)
            if nargin < 2, timeout_s = 60; end
            fprintf('[PLCController] Waiting for move completion...\n');
            pause(0.3);
            tic;
            while toc < timeout_s
                try
                    s = obj.getStatus();
                    if s.inPosition
                        fprintf('[PLCController] In position\n');
                        success = true; return
                    end
                    if s.error
                        fprintf('[PLCController] Error during move (ErrorID=%d)\n', s.errorID);
                        success = false; return
                    end
                    if ~s.moving && toc > 2.0
                        fprintf('[PLCController] Move stopped\n');
                        success = false; return
                    end
                catch, end
                pause(0.1);
            end
            warning('[PLCController] Timeout waiting for in-position');
            success = false;
        end

        function moving = getMovingFlag(obj)
            % Reads only gStatus_Moving — used for low-overhead polling
            % during latency tests. Much faster than getStatus().
            obj.checkConnected();
            try
                moving = logical(readValue(obj.client, obj.nodes.statusMoving));
            catch
                moving = false;
            end
        end

        function printStatus(obj)
            s   = obj.getStatus();
            tcp = obj.getActualTCP();
            q   = obj.getActualJoints();
            fprintf('\n[PLCController] ══ Status Snapshot ══\n');
            fprintf('  Ready      : %d\n', s.ready);
            fprintf('  Homed      : %d\n', s.homed);
            fprintf('  PowerOn    : %d\n', s.powerOn);
            fprintf('  Moving     : %d\n', s.moving);
            fprintf('  InPosition : %d\n', s.inPosition);
            fprintf('  Error      : %d  (ID=%d)\n', s.error, s.errorID);
            fprintf('  Actual TCP : X=%.2f  Y=%.2f  Z=%.2f  B=%.2f C=%.2f\n', tcp);
            fprintf('  Actual Q   : [%.3f  %.3f  %.3f  %.3f  %.3f]\n', q);
            fprintf('[PLCController] ══════════════════════\n\n');
        end

        function delete(obj)
            obj.disconnect();
        end

    end

    methods (Access = private)

        function checkConnected(obj)
            if ~obj.connected
                error('[PLCController] Not connected. Call connect() first.');
            end
        end

        function status = safeStatusDefaults(~)
            status = struct('ready',false,'moving',false,'inPosition',false,'error',false,'errorID',0,'homed',false,'powerOn',false);
        end

    end
end