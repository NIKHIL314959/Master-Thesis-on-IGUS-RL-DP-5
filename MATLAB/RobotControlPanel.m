classdef RobotControlPanel < matlab.apps.AppBase
% ROBOTCONTROLPANEL  Live monitoring and control GUI for the IGUS RL-DP-5
%
% PURPOSE:
%   App Designer GUI that connects to the PLC via PLCController and
%   provides a single window for monitoring and commanding the robot.
%
% FEATURES:
%   - Connection panel    : IP / port, connect / disconnect, status lamp
%   - Status panel        : Ready, Homed, Power, Moving, Error lamps
%   - Live position       : TCP (X,Y,Z,B,C) and joint angles (Q1..Q5)
%   - Motion parameters   : velocity, acceleration, override
%   - Move commands       : absolute TCP move with confirmation
%   - Pick & place panel  : teach Pick / Place / Home, run sequence
%   - Gripper controls    : open / close (Schunk EGP 40-N-N-B)
%   - Emergency stop      : sends Stop and clears commands
%
% USAGE:
%   app = RobotControlPanel;   % opens the GUI
%
% INTERNALS:
%   - Live data is polled at 100 ms via pollTimer.
%   - All motion is delegated to tcp_move() and PickAndPlace().
%   - No IK runs in MATLAB — the PLC handles all kinematics.

    % IGUS RL-DP-5 — Robot Control Panel (Absolute mode + Pick & Place + Gripper)

    properties (Access = public)
        plc
        pollTimer
        isConnected = false
    end

    properties (Access = public)
        UIFigure                matlab.ui.Figure
        % Connection
        ConnPanel               matlab.ui.container.Panel
        IPField                 matlab.ui.control.EditField
        IPLabel                 matlab.ui.control.Label
        PortField               matlab.ui.control.NumericEditField
        PortLabel               matlab.ui.control.Label
        ConnectButton           matlab.ui.control.Button
        DisconnectButton        matlab.ui.control.Button
        ConnStatusLamp          matlab.ui.control.Lamp
        ConnStatusLabel         matlab.ui.control.Label
        % Status
        StatusPanel             matlab.ui.container.Panel
        ReadyLamp               matlab.ui.control.Lamp
        ReadyLabel              matlab.ui.control.Label
        HomedLamp               matlab.ui.control.Lamp
        HomedLabel              matlab.ui.control.Label
        PowerLamp               matlab.ui.control.Lamp
        PowerLabel              matlab.ui.control.Label
        MovingLamp              matlab.ui.control.Lamp
        MovingLabel             matlab.ui.control.Label
        ErrorLamp               matlab.ui.control.Lamp
        ErrorLabel              matlab.ui.control.Label
        ErrorIDLabel            matlab.ui.control.Label
        ErrorIDValue            matlab.ui.control.Label
        HomeButton              matlab.ui.control.Button
        % Actual TCP
        ActualTCPPanel          matlab.ui.container.Panel
        ActXLabel               matlab.ui.control.Label
        ActXValue               matlab.ui.control.Label
        ActYLabel               matlab.ui.control.Label
        ActYValue               matlab.ui.control.Label
        ActZLabel               matlab.ui.control.Label
        ActZValue               matlab.ui.control.Label
        ActBLabel               matlab.ui.control.Label
        ActBValue               matlab.ui.control.Label
        ActCLabel               matlab.ui.control.Label
        ActCValue               matlab.ui.control.Label
        % Actual Joints
        ActualJointsPanel       matlab.ui.container.Panel
        ActQ1Label              matlab.ui.control.Label
        ActQ1Value              matlab.ui.control.Label
        ActQ2Label              matlab.ui.control.Label
        ActQ2Value              matlab.ui.control.Label
        ActQ3Label              matlab.ui.control.Label
        ActQ3Value              matlab.ui.control.Label
        ActQ4Label              matlab.ui.control.Label
        ActQ4Value              matlab.ui.control.Label
        ActQ5Label              matlab.ui.control.Label
        ActQ5Value              matlab.ui.control.Label
        % Move command
        MovePanel               matlab.ui.container.Panel
        TgtXLabel               matlab.ui.control.Label
        TgtXField               matlab.ui.control.NumericEditField
        TgtYLabel               matlab.ui.control.Label
        TgtYField               matlab.ui.control.NumericEditField
        TgtZLabel               matlab.ui.control.Label
        TgtZField               matlab.ui.control.NumericEditField
        TgtBLabel               matlab.ui.control.Label
        TgtBField               matlab.ui.control.NumericEditField
        TgtCLabel               matlab.ui.control.Label
        TgtCField               matlab.ui.control.NumericEditField
        VelLabel                matlab.ui.control.Label
        VelField                matlab.ui.control.NumericEditField
        MoveButton              matlab.ui.control.Button
        StopButton              matlab.ui.control.Button
        ErrorResetButton        matlab.ui.control.Button
        GripperOpenButton       matlab.ui.control.Button
        GripperCloseButton      matlab.ui.control.Button
        % Pick and Place
        PickPlacePanel          matlab.ui.container.Panel
        PickXField              matlab.ui.control.NumericEditField
        PickYField              matlab.ui.control.NumericEditField
        PickZField              matlab.ui.control.NumericEditField
        PickBField              matlab.ui.control.NumericEditField
        PickCField              matlab.ui.control.NumericEditField
        PlaceXField             matlab.ui.control.NumericEditField
        PlaceYField             matlab.ui.control.NumericEditField
        PlaceZField             matlab.ui.control.NumericEditField
        PlaceBField             matlab.ui.control.NumericEditField
        PlaceCField             matlab.ui.control.NumericEditField
        CapturePickButton       matlab.ui.control.Button
        CapturePlaceButton      matlab.ui.control.Button
        StartPickPlaceButton    matlab.ui.control.Button
        SeqStatusLabel          matlab.ui.control.Label
        % Log
        LogPanel                matlab.ui.container.Panel
        LogArea                 matlab.ui.control.TextArea
        ClearLogButton          matlab.ui.control.Button
    end

    methods (Access = private)

        function buildUI(app)
            app.UIFigure = uifigure('Name', 'IGUS RL-DP-5 — Robot Control Panel', ...
                'Position', [100 50 840 900], ...
                'Color', [0.15 0.15 0.18], 'Resize', 'off');

            % ── CONNECTION ───────────────────────────────────────────────────
            app.ConnPanel = uipanel(app.UIFigure, 'Title', 'Connection', ...
                'Position', [10 830 820 60], ...
                'BackgroundColor', [0.2 0.2 0.25], 'ForegroundColor', [1 1 1], ...
                'FontWeight', 'bold');
            app.IPLabel = uilabel(app.ConnPanel, 'Text', 'PLC IP:', ...
                'Position', [10 8 50 22], 'FontColor', [0.8 0.8 0.8]);
            app.IPField = uieditfield(app.ConnPanel, 'text', ...
                'Value', '169.254.137.11', 'Position', [65 8 130 22]);
            app.PortLabel = uilabel(app.ConnPanel, 'Text', 'Port:', ...
                'Position', [210 8 35 22], 'FontColor', [0.8 0.8 0.8]);
            app.PortField = uieditfield(app.ConnPanel, 'numeric', ...
                'Value', 48400, 'Position', [248 8 70 22], ...
                'Limits', [1 65535], 'ValueDisplayFormat', '%.0f');
            app.ConnectButton = uibutton(app.ConnPanel, 'push', 'Text', 'Connect', ...
                'Position', [340 8 80 24], 'BackgroundColor', [0.2 0.6 0.3], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) app.onConnect());
            app.DisconnectButton = uibutton(app.ConnPanel, 'push', 'Text', 'Disconnect', ...
                'Position', [440 8 90 24], 'BackgroundColor', [0.6 0.2 0.2], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.onDisconnect());
            app.ConnStatusLamp = uilamp(app.ConnPanel, ...
                'Position', [550 13 16 16], 'Color', [0.5 0.5 0.5]);
            app.ConnStatusLabel = uilabel(app.ConnPanel, 'Text', 'Disconnected', ...
                'Position', [572 10 120 22], 'FontColor', [0.8 0.8 0.8]);

            % ── STATUS ───────────────────────────────────────────────────────
            app.StatusPanel = uipanel(app.UIFigure, 'Title', 'Robot Status', ...
                'Position', [10 750 820 70], ...
                'BackgroundColor', [0.2 0.2 0.25], 'ForegroundColor', [1 1 1], ...
                'FontWeight', 'bold');
            statusItems = {'Ready','Homed','Power','Moving','Error'};
            lamps = {'ReadyLamp','HomedLamp','PowerLamp','MovingLamp','ErrorLamp'};
            lbls  = {'ReadyLabel','HomedLabel','PowerLabel','MovingLabel','ErrorLabel'};
            xpos  = [10 110 210 310 410];
            for k = 1:5
                app.(lamps{k}) = uilamp(app.StatusPanel, ...
                    'Position', [xpos(k) 17 20 20], 'Color', [0.4 0.4 0.4]);
                app.(lbls{k}) = uilabel(app.StatusPanel, 'Text', statusItems{k}, ...
                    'Position', [xpos(k)+24 17 70 22], ...
                    'FontColor', [0.8 0.8 0.8], 'FontWeight', 'bold');
            end
            app.ErrorIDLabel = uilabel(app.StatusPanel, 'Text', 'ErrorID:', ...
                'Position', [510 17 52 22], 'FontColor', [0.8 0.8 0.8]);
            app.ErrorIDValue = uilabel(app.StatusPanel, 'Text', '0', ...
                'Position', [562 17 55 22], 'FontColor', [1 0.6 0.2], ...
                'FontWeight', 'bold');
            app.HomeButton = uibutton(app.StatusPanel, 'push', ...
                'Text', 'HOME', ...
                'Position', [685 16 120 24], ...
                'BackgroundColor', [0.3 0.3 0.5], 'FontColor', [0.9 0.9 0.9], ...
                'FontWeight', 'bold', 'FontSize', 11, 'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.onHome());

            % ── ACTUAL TCP ───────────────────────────────────────────────────
            app.ActualTCPPanel = uipanel(app.UIFigure, 'Title', 'Actual TCP Position', ...
                'Position', [10 630 395 110], ...
                'BackgroundColor', [0.2 0.2 0.25], 'ForegroundColor', [1 1 1], ...
                'FontWeight', 'bold');
            tcpLabels = {'X [mm]','Y [mm]','Z [mm]','B [deg]','C [deg]'};
            tcpLblN = {'ActXLabel','ActYLabel','ActZLabel','ActBLabel','ActCLabel'};
            tcpValN = {'ActXValue','ActYValue','ActZValue','ActBValue','ActCValue'};
            tcpX = [10 88 166 244 322];
            for k = 1:5
                app.(tcpLblN{k}) = uilabel(app.ActualTCPPanel, 'Text', tcpLabels{k}, ...
                    'Position', [tcpX(k) 62 72 18], 'FontColor', [0.6 0.8 1], 'FontSize', 10);
                app.(tcpValN{k}) = uilabel(app.ActualTCPPanel, 'Text', '---', ...
                    'Position', [tcpX(k) 34 72 24], 'FontColor', [0.2 1 0.5], ...
                    'FontWeight', 'bold', 'FontSize', 13, 'HorizontalAlignment', 'center');
            end

            % ── ACTUAL JOINTS ────────────────────────────────────────────────
            app.ActualJointsPanel = uipanel(app.UIFigure, 'Title', 'Actual Joint Angles', ...
                'Position', [415 630 415 110], ...
                'BackgroundColor', [0.2 0.2 0.25], 'ForegroundColor', [1 1 1], ...
                'FontWeight', 'bold');
            jntLabels = {'Q1 [deg]','Q2 [deg]','Q3 [deg]','Q4 [deg]','Q5 [deg]'};
            jntLblN = {'ActQ1Label','ActQ2Label','ActQ3Label','ActQ4Label','ActQ5Label'};
            jntValN = {'ActQ1Value','ActQ2Value','ActQ3Value','ActQ4Value','ActQ5Value'};
            jntX = [10 88 166 244 322];
            for k = 1:5
                app.(jntLblN{k}) = uilabel(app.ActualJointsPanel, 'Text', jntLabels{k}, ...
                    'Position', [jntX(k) 62 72 18], 'FontColor', [0.6 0.8 1], 'FontSize', 10);
                app.(jntValN{k}) = uilabel(app.ActualJointsPanel, 'Text', '---', ...
                    'Position', [jntX(k) 34 72 24], 'FontColor', [1 0.85 0.3], ...
                    'FontWeight', 'bold', 'FontSize', 13, 'HorizontalAlignment', 'center');
            end

            % ── MOVE COMMAND ─────────────────────────────────────────────────
            % Panel height 190 to fit two button rows
            app.MovePanel = uipanel(app.UIFigure, 'Title', 'Move Command  [Absolute]', ...
                'Position', [10 460 820 160], ...
                'BackgroundColor', [0.2 0.2 0.25], 'ForegroundColor', [1 1 1], ...
                'FontWeight', 'bold');
            app.VelLabel = uilabel(app.MovePanel, 'Text', 'Vel [mm/s]:', ...
                'Position', [657 139 80 22], 'FontColor', [0.8 0.8 0.8]);
            app.VelField = uieditfield(app.MovePanel, 'numeric', ...
                'Value', 10, 'Position', [727 139 55 22], 'Limits', [1 200]);
            coords  = {'X','Y','Z','B','C'};
            units   = {'mm','mm','mm','deg','deg'};
            tgtLblN = {'TgtXLabel','TgtYLabel','TgtZLabel','TgtBLabel','TgtCLabel'};
            tgtFldN = {'TgtXField','TgtYField','TgtZField','TgtBField','TgtCField'};
            fldX    = [10 168 326 484 642];
            for k = 1:5
                app.(tgtLblN{k}) = uilabel(app.MovePanel, ...
                    'Text', sprintf('%s [%s]', coords{k}, units{k}), ...
                    'Position', [fldX(k) 110 100 20], 'FontColor', [0.8 0.8 0.8]);
                app.(tgtFldN{k}) = uieditfield(app.MovePanel, 'numeric', ...
                    'Value', 0, 'Position', [fldX(k) 80 140 26], 'FontSize', 13);
            end
            % Button row 1 — Move / Stop / Reset Error
            app.MoveButton = uibutton(app.MovePanel, 'push', 'Text', '▶  MOVE', ...
                'Position', [10 30 130 28], 'BackgroundColor', [0.1 0.5 0.9], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 12, ...
                'Enable', 'off', 'ButtonPushedFcn', @(~,~) app.onMove());
            app.StopButton = uibutton(app.MovePanel, 'push', 'Text', '■  STOP', ...
                'Position', [160 30 130 28], 'BackgroundColor', [0.85 0.2 0.2], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', 'FontSize', 12, ...
                'Enable', 'off', 'ButtonPushedFcn', @(~,~) app.onStop());
            app.ErrorResetButton = uibutton(app.MovePanel, 'push', 'Text', '↺  Reset Error', ...
                'Position', [310 30 130 28], 'BackgroundColor', [0.6 0.4 0.1], ...
                'FontColor', [1 1 1], 'FontWeight', 'bold', ...
                'Enable', 'off', 'ButtonPushedFcn', @(~,~) app.onErrorReset());
            % Button row 1 — Gripper Open / Gripper Close
            app.GripperOpenButton = uibutton(app.MovePanel, 'push', ...
                'Text', '✋  Gripper Open', ...
                'Position', [460 30 130 28], ...
                'BackgroundColor', [0.15 0.5 0.2], 'FontColor', [1 1 1], ...
                'FontWeight', 'bold', 'FontSize', 12, 'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.onGripperOpen());
            app.GripperCloseButton = uibutton(app.MovePanel, 'push', ...
                'Text', '✊  Gripper Close', ...
                'Position', [610 30 130 28], ...
                'BackgroundColor', [0.5 0.15 0.15], 'FontColor', [1 1 1], ...
                'FontWeight', 'bold', 'FontSize', 12, 'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.onGripperClose());

            % ── PICK AND PLACE ────────────────────────────────────────────────
            app.PickPlacePanel = uipanel(app.UIFigure, 'Title', 'Pick and Place', ...
                'Position', [10 270 820 180], ...
                'BackgroundColor', [0.2 0.2 0.25], 'ForegroundColor', [1 1 1], ...
                'FontWeight', 'bold');

            uilabel(app.PickPlacePanel, 'Text', 'PICK POSITION', ...
                'Position', [10 135 160 20], ...
                'FontColor', [0.4 0.9 1], 'FontWeight', 'bold', 'FontSize', 12);
            uilabel(app.PickPlacePanel, 'Text', 'PLACE POSITION', ...
                'Position', [420 135 170 20], ...
                'FontColor', [1 0.8 0.3], 'FontWeight', 'bold', 'FontSize', 12);

            coords  = {'X','Y','Z','B','C'};
            units   = {'mm','mm','mm','deg','deg'};
            pickFN  = {'PickXField','PickYField','PickZField','PickBField','PickCField'};
            placeFN = {'PlaceXField','PlaceYField','PlaceZField','PlaceBField','PlaceCField'};
            fxpos   = [10 90 170 250 330];
            for k = 1:5
                uilabel(app.PickPlacePanel, ...
                    'Text', sprintf('%s [%s]', coords{k}, units{k}), ...
                    'Position', [fxpos(k) 115 72 18], ...
                    'FontColor', [0.6 0.85 1], 'FontSize', 10);
                app.(pickFN{k}) = uieditfield(app.PickPlacePanel, 'numeric', ...
                    'Value', 0, 'Position', [fxpos(k) 90 72 24], 'FontSize', 11);
                uilabel(app.PickPlacePanel, ...
                    'Text', sprintf('%s [%s]', coords{k}, units{k}), ...
                    'Position', [fxpos(k)+410 115 72 18], ...
                    'FontColor', [1 0.85 0.5], 'FontSize', 10);
                app.(placeFN{k}) = uieditfield(app.PickPlacePanel, 'numeric', ...
                    'Value', 0, 'Position', [fxpos(k)+410 90 72 24], 'FontSize', 11);
            end

            app.CapturePickButton = uibutton(app.PickPlacePanel, 'push', ...
                'Text', '⊕  Capture Pick', ...
                'Position', [10 48 160 30], ...
                'BackgroundColor', [0.1 0.45 0.65], 'FontColor', [1 1 1], ...
                'FontWeight', 'bold', 'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.onCapturePick());
            app.CapturePlaceButton = uibutton(app.PickPlacePanel, 'push', ...
                'Text', '⊕  Capture Place', ...
                'Position', [185 48 160 30], ...
                'BackgroundColor', [0.5 0.35 0.05], 'FontColor', [1 1 1], ...
                'FontWeight', 'bold', 'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.onCapturePlace());
            app.StartPickPlaceButton = uibutton(app.PickPlacePanel, 'push', ...
                'Text', '▶  START PICK & PLACE', ...
                'Position', [420 48 200 30], ...
                'BackgroundColor', [0.15 0.6 0.25], 'FontColor', [1 1 1], ...
                'FontWeight', 'bold', 'FontSize', 12, 'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) app.onStartPickPlace());
            app.SeqStatusLabel = uilabel(app.PickPlacePanel, ...
                'Text', 'Sequence: idle', ...
                'Position', [635 48 175 30], ...
                'FontColor', [0.5 0.5 0.5], 'FontSize', 12, 'FontWeight', 'bold');
            uilabel(app.PickPlacePanel, ...
                'Text', '① Jog to bottle → Capture Pick     ② Jog to place → Capture Place     ③ Start Pick & Place', ...
                'Position', [10 14 780 22], ...
                'FontColor', [0.5 0.5 0.5], 'FontSize', 10);

            % ── LOG ───────────────────────────────────────────────────────────
            app.LogPanel = uipanel(app.UIFigure, 'Title', 'Log', ...
                'Position', [10 20 820 240], ...
                'BackgroundColor', [0.2 0.2 0.25], 'ForegroundColor', [1 1 1], ...
                'FontWeight', 'bold');
            app.ClearLogButton = uibutton(app.LogPanel, 'push', 'Text', 'Clear Log', ...
                'Position', [722 212 90 22], 'BackgroundColor', [0.35 0.35 0.4], ...
                'FontColor', [0.9 0.9 0.9], ...
                'ButtonPushedFcn', @(~,~) app.onClearLog());
            app.LogArea = uitextarea(app.LogPanel, ...
                'Position', [8 8 804 200], 'Editable', 'off', ...
                'BackgroundColor', [0.1 0.1 0.12], 'FontColor', [0.7 1 0.7], ...
                'FontName', 'Courier New', 'FontSize', 11, ...
                'Value', {'[Panel] Robot Control Panel ready.', ...
                          '[Panel] Enter PLC IP and click Connect.'});
        end

        % ── CONNECTION ────────────────────────────────────────────────────────
        function onConnect(app)
            ip   = app.IPField.Value;
            port = app.PortField.Value;
            app.log(sprintf('Connecting to %s:%d...', ip, port));
            try
                addpath('Z:\Nikhil\Project_5_Axes\5AxesRoboArm(A)_MATLAB');
                app.plc = PLCController(ip, port);
                if app.plc.connect()
                    app.isConnected = true;
                    assignin('base', 'plc', app.plc);
                    app.ConnStatusLamp.Color    = [0.2 0.9 0.3];
                    app.ConnStatusLabel.Text    = 'Connected';
                    app.ConnectButton.Enable    = 'off';
                    app.DisconnectButton.Enable = 'on';
                    app.MoveButton.Enable           = 'on';
                    app.StopButton.Enable           = 'on';
                    app.ErrorResetButton.Enable     = 'on';
                    app.GripperOpenButton.Enable    = 'on';
                    app.GripperCloseButton.Enable   = 'on';
                    app.CapturePickButton.Enable    = 'on';
                    app.CapturePlaceButton.Enable   = 'on';
                    app.StartPickPlaceButton.Enable = 'on';
                    app.HomeButton.Enable           = 'on';
                    app.log('Connected successfully.');
                    app.startPolling();
                else
                    app.log('Connection failed. Check IP and PLC state.');
                end
            catch ME
                app.log(sprintf('Error: %s', ME.message));
            end
        end

        function onDisconnect(app)
            app.stopPolling();
            if ~isempty(app.plc)
                try, app.plc.disconnect(); catch, end
            end
            app.isConnected = false;
            evalin('base', 'clear plc');
            app.ConnStatusLamp.Color    = [0.5 0.5 0.5];
            app.ConnStatusLabel.Text    = 'Disconnected';
            app.ConnectButton.Enable    = 'on';
            app.DisconnectButton.Enable = 'off';
            app.MoveButton.Enable           = 'off';
            app.StopButton.Enable           = 'off';
            app.ErrorResetButton.Enable     = 'off';
            app.GripperOpenButton.Enable    = 'off';
            app.GripperCloseButton.Enable   = 'off';
            app.CapturePickButton.Enable    = 'off';
            app.CapturePlaceButton.Enable   = 'off';
            app.StartPickPlaceButton.Enable = 'off';
            app.HomeButton.Enable           = 'off';
            app.SeqStatusLabel.Text      = 'Sequence: idle';
            app.SeqStatusLabel.FontColor = [0.5 0.5 0.5];
            app.clearDisplays();
            app.log('Disconnected.');
        end

        % ── POLLING ───────────────────────────────────────────────────────────
        function startPolling(app)
            app.pollTimer = timer('ExecutionMode', 'fixedRate', 'Period', 1.0, ...
                'TimerFcn', @(~,~) app.pollPLC(), ...
                'ErrorFcn', @(~,~) app.onTimerError());
            start(app.pollTimer);
            app.log('Live polling started (1s).');
        end

        function stopPolling(app)
            if ~isempty(app.pollTimer) && isvalid(app.pollTimer)
                try, stop(app.pollTimer); delete(app.pollTimer); catch, end
            end
            app.pollTimer = [];
        end

        function pollPLC(app)
            if ~app.isConnected || isempty(app.plc), return, end
            try
                s = app.plc.getStatus();
                app.updateStatusLamps(s);
                tcp = app.plc.getActualTCP();
                app.ActXValue.Text = sprintf('%.2f', tcp(1));
                app.ActYValue.Text = sprintf('%.2f', tcp(2));
                app.ActZValue.Text = sprintf('%.2f', tcp(3));
                app.ActBValue.Text = sprintf('%.2f', tcp(4));
                app.ActCValue.Text = sprintf('%.2f', tcp(5));
                q = app.plc.getActualJoints();
                app.ActQ1Value.Text = sprintf('%.2f', q(1));
                app.ActQ2Value.Text = sprintf('%.2f', q(2));
                app.ActQ3Value.Text = sprintf('%.2f', q(3));
                app.ActQ4Value.Text = sprintf('%.2f', q(4));
                app.ActQ5Value.Text = sprintf('%.2f', q(5));
            catch
            end
        end

        function updateStatusLamps(app, s)
            app.ReadyLamp.Color   = app.lampColor(s.ready);
            app.HomedLamp.Color   = app.lampColor(s.homed);
            app.PowerLamp.Color   = app.lampColor(s.powerOn);
            app.MovingLamp.Color  = app.movingColor(s.moving);
            app.ErrorLamp.Color   = app.errorColor(s.error);
            app.ErrorIDValue.Text = num2str(s.errorID);
        end

        % ── MOVE COMMAND ──────────────────────────────────────────────────────
        function onMove(app)
            if ~app.isConnected, return, end
            addpath('Z:\Nikhil\Project_5_Axes\5AxesRoboArm(A)_MATLAB');
            x   = app.TgtXField.Value;
            y   = app.TgtYField.Value;
            z   = app.TgtZField.Value;
            b   = app.TgtBField.Value;
            c   = app.TgtCField.Value;
            vel = app.VelField.Value;
            app.log(sprintf('[Move] X=%.2f Y=%.2f Z=%.2f B=%.2f C=%.2f Vel=%.1f mm/s', ...
                    x, y, z, b, c, vel));
            try
                app.plc.setMotionParams(vel, vel*5, 100);
                opt.confirm = false;
                opt.verbose = false;
                opt.timeout = 60;
                success = tcp_move(app.plc, 'abs', x, y, z, b, c, opt);
                if success
                    app.log('[Move] Complete — in position.');
                else
                    app.log('[Move] Did not complete or TCP error exceeded tolerance.');
                end
            catch ME
                app.log(sprintf('[Move] Error: %s', ME.message));
            end
        end

        function onStop(app)
            if ~app.isConnected, return, end
            try
                app.plc.stop();
                app.log('[Stop] Stop command sent.');
            catch ME
                app.log(sprintf('[Stop] Error: %s', ME.message));
            end
        end

        function onErrorReset(app)
            if ~app.isConnected, return, end
            try
                app.plc.resetError();
                app.log('[Reset] Error reset sent.');
            catch ME
                app.log(sprintf('[Reset] Error: %s', ME.message));
            end
        end

        % ── HOME ──────────────────────────────────────────────────────────────
        function onHome(app)
            if ~app.isConnected, return, end
            try
                app.log('[Home] Homing started...');
                app.HomeButton.Enable           = 'off';
                app.MoveButton.Enable           = 'off';
                app.StartPickPlaceButton.Enable = 'off';
                drawnow;
                app.plc.home();
                success = app.plc.waitUntilHomed(60);
                if success
                    app.log('[Home] Homing complete — robot ready.');
                else
                    app.log('[Home] Homing failed or timed out.');
                end
            catch ME
                app.log(sprintf('[Home] Error: %s', ME.message));
            end
            app.HomeButton.Enable           = 'on';
            app.MoveButton.Enable           = 'on';
            app.StartPickPlaceButton.Enable = 'on';
        end

        % ── GRIPPER ───────────────────────────────────────────────────────────
        function onGripperOpen(app)
            if ~app.isConnected, return, end
            try
                app.plc.gripperOpen();
                app.log('[Gripper] Open command sent.');
            catch ME
                app.log(sprintf('[Gripper] Error: %s', ME.message));
            end
        end

        function onGripperClose(app)
            if ~app.isConnected, return, end
            try
                app.plc.gripperClose();
                app.log('[Gripper] Close command sent.');
            catch ME
                app.log(sprintf('[Gripper] Error: %s', ME.message));
            end
        end

        % ── PICK AND PLACE ────────────────────────────────────────────────────
        function onCapturePick(app)
            if ~app.isConnected, return, end
            try
                tcp = app.plc.getActualTCP();
                app.PickXField.Value = tcp(1);
                app.PickYField.Value = tcp(2);
                app.PickZField.Value = tcp(3);
                app.PickBField.Value = tcp(4);
                app.PickCField.Value = tcp(5);
                app.log(sprintf('[Pick] Captured: X=%.2f  Y=%.2f  Z=%.2f  B=%.2f  C=%.2f', ...
                        tcp(1), tcp(2), tcp(3), tcp(4), tcp(5)));
            catch ME
                app.log(sprintf('[Pick] Capture failed: %s', ME.message));
            end
        end

        function onCapturePlace(app)
            if ~app.isConnected, return, end
            try
                tcp = app.plc.getActualTCP();
                app.PlaceXField.Value = tcp(1);
                app.PlaceYField.Value = tcp(2);
                app.PlaceZField.Value = tcp(3);
                app.PlaceBField.Value = tcp(4);
                app.PlaceCField.Value = tcp(5);
                app.log(sprintf('[Place] Captured: X=%.2f  Y=%.2f  Z=%.2f  B=%.2f  C=%.2f', ...
                        tcp(1), tcp(2), tcp(3), tcp(4), tcp(5)));
            catch ME
                app.log(sprintf('[Place] Capture failed: %s', ME.message));
            end
        end

        function onStartPickPlace(app)
            if ~app.isConnected, return, end

            pickX  = app.PickXField.Value;
            pickY  = app.PickYField.Value;
            pickZ  = app.PickZField.Value;
            pickB  = app.PickBField.Value;
            pickC  = app.PickCField.Value;
            placeX = app.PlaceXField.Value;
            placeY = app.PlaceYField.Value;
            placeZ = app.PlaceZField.Value;
            placeB = app.PlaceBField.Value;
            placeC = app.PlaceCField.Value;

            % Capture home — wherever robot is right now before sequence starts
            homePos = app.plc.getActualTCP();

            app.log(sprintf('[Seq] Pick:  X=%.1f  Y=%.1f  Z=%.1f  B=%.1f  C=%.1f', ...
                    pickX, pickY, pickZ, pickB, pickC));
            app.log(sprintf('[Seq] Place: X=%.1f  Y=%.1f  Z=%.1f  B=%.1f  C=%.1f', ...
                    placeX, placeY, placeZ, placeB, placeC));
            app.log(sprintf('[Seq] Home:  X=%.1f  Y=%.1f  Z=%.1f  B=%.1f  C=%.1f', ...
                    homePos(1), homePos(2), homePos(3), homePos(4), homePos(5)));

            % Lock buttons during sequence
            app.SeqStatusLabel.Text         = 'Sequence: running...';
            app.SeqStatusLabel.FontColor    = [0.2 0.8 1];
            app.StartPickPlaceButton.Enable = 'off';
            app.CapturePickButton.Enable    = 'off';
            app.CapturePlaceButton.Enable   = 'off';
            app.MoveButton.Enable           = 'off';
            app.GripperOpenButton.Enable    = 'off';
            app.GripperCloseButton.Enable   = 'off';
            drawnow;

            try
                PickAndPlace(app.plc, ...
                    pickX,  pickY,  pickZ,  pickB,  pickC, ...
                    placeX, placeY, placeZ, placeB, placeC, ...
                    homePos);
                app.SeqStatusLabel.Text      = 'Sequence: DONE ✓';
                app.SeqStatusLabel.FontColor = [0.2 0.9 0.3];
                app.log('[Seq] Pick and place complete.');
            catch ME
                app.SeqStatusLabel.Text      = 'Sequence: FAILED ✗';
                app.SeqStatusLabel.FontColor = [1 0.2 0.2];
                app.log(sprintf('[Seq] Failed: %s', ME.message));
            end

            % Re-enable all buttons
            app.StartPickPlaceButton.Enable = 'on';
            app.CapturePickButton.Enable    = 'on';
            app.CapturePlaceButton.Enable   = 'on';
            app.MoveButton.Enable           = 'on';
            app.GripperOpenButton.Enable    = 'on';
            app.GripperCloseButton.Enable   = 'on';
        end

        % ── LOG ───────────────────────────────────────────────────────────────
        function onClearLog(app)
            app.LogArea.Value = {'[Panel] Log cleared.'};
        end

        function onTimerError(app)
            app.log('[Poll] Timer error — polling stopped.');
            app.stopPolling();
        end

        function log(app, msg)
            timestamp = datestr(now, 'HH:MM:SS.FFF');
            newLine   = sprintf('[%s] %s', timestamp, msg);
            current   = app.LogArea.Value;
            if ischar(current), current = {current}; end
            app.LogArea.Value = [current; {newLine}];
            scroll(app.LogArea, 'bottom');
        end

        function clearDisplays(app)
            vals = {'ActXValue','ActYValue','ActZValue','ActBValue','ActCValue', ...
                    'ActQ1Value','ActQ2Value','ActQ3Value','ActQ4Value','ActQ5Value'};
            for k = 1:numel(vals), app.(vals{k}).Text = '---'; end
            lamps = {'ReadyLamp','HomedLamp','PowerLamp','MovingLamp','ErrorLamp'};
            for k = 1:numel(lamps), app.(lamps{k}).Color = [0.4 0.4 0.4]; end
            app.ErrorIDValue.Text = '0';
        end

        function c = lampColor(~, s)
            if s, c = [0.2 0.9 0.3]; else, c = [0.4 0.4 0.4]; end
        end
        function c = movingColor(~, s)
            if s, c = [0.2 0.6 1.0]; else, c = [0.4 0.4 0.4]; end
        end
        function c = errorColor(~, s)
            if s, c = [1.0 0.2 0.2]; else, c = [0.4 0.4 0.4]; end
        end

    end

    methods (Access = public)
        function app = RobotControlPanel()
            app.buildUI();
            app.UIFigure.CloseRequestFcn = @(~,~) app.onClose();
            if nargout == 0, clear app, end
        end

        function onClose(app)
            app.stopPolling();
            if ~isempty(app.plc) && app.isConnected
                try, app.plc.disconnect(); catch, end
            end
            delete(app.UIFigure);
        end
    end
end