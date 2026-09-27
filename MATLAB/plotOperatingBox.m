function plotOperatingBox(stlFile, plc, varargin)
%PLOTOPERATINGBOX  Draw operating box + robot mesh + live TCP (no motion)
%
% USAGE:
%   plotOperatingBox('igus_asm.stp.stl', plc);
%   plotOperatingBox('igus_asm.stp.stl', plc, 'box', [280 550; -300 300; 100 700]);
%
% NAME-VALUE PAIRS:
%   'box'       — [Xmin Xmax; Ymin Ymax; Zmin Zmax] (default [280 550; -300 300; 100 700])
%   'translate' — mesh shift (default [-340 -130 0])
%   'rotate'    — mesh rotation [rx ry rz] deg (default [0 0 0])
%   'scale'     — STL scale factor (default 1.0)
%   'meshColor' — RGB triplet (default light grey)
%   'meshAlpha' — transparency 0-1 (default 0.55)
%   'boxColor'  — RGB for the box edges (default orange)
%   'boxFill'   — fill faces of the box transparently (default true)

    p = inputParser;
    addParameter(p, 'box',       [280 550; -300 300; 100 700]);
    addParameter(p, 'translate', [-340 -130 0]);
    addParameter(p, 'rotate',    [0 0 0]);
    addParameter(p, 'scale',     1.0);
    addParameter(p, 'meshColor', [0.55 0.55 0.6]);
    addParameter(p, 'meshAlpha', 0.55);
    addParameter(p, 'boxColor',  [0.95 0.55 0.10]);
    addParameter(p, 'boxFill',   true);
    parse(p, varargin{:});
    opts = p.Results;

    % ── Read live TCP ────────────────────────────────────────────────────────
    tcp = [];
    if nargin >= 2 && ~isempty(plc)
        try
            tcp = plc.getActualTCP();
            fprintf('  Live TCP: X=%.2f Y=%.2f Z=%.2f B=%.2f C=%.2f\n', tcp);
        catch ME
            warning('Could not read TCP: %s', ME.message);
        end
    end

    % ── Pre-load STL ─────────────────────────────────────────────────────────
    haveMesh = false;
    F = []; V = [];
    if exist(stlFile, 'file')
        TR = stlread(stlFile);
        F = TR.ConnectivityList;
        V = TR.Points * opts.scale;
        rot = opts.rotate * pi/180;
        Rx = [1 0 0; 0 cos(rot(1)) -sin(rot(1)); 0 sin(rot(1)) cos(rot(1))];
        Ry = [cos(rot(2)) 0 sin(rot(2)); 0 1 0; -sin(rot(2)) 0 cos(rot(2))];
        Rz = [cos(rot(3)) -sin(rot(3)) 0; sin(rot(3)) cos(rot(3)) 0; 0 0 1];
        V = (Rz * Ry * Rx * V')';
        V = V + opts.translate;
        haveMesh = true;
        fprintf('  Mesh bounds: X[%.0f, %.0f] Y[%.0f, %.0f] Z[%.0f, %.0f] mm\n', min(V(:,1)), max(V(:,1)), min(V(:,2)), max(V(:,2)), min(V(:,3)), max(V(:,3)));
    end

    fprintf('  Operating box: X[%.0f, %.0f] Y[%.0f, %.0f] Z[%.0f, %.0f] mm\n', opts.box(1,:), opts.box(2,:), opts.box(3,:));

    % ── Figure with two panels ───────────────────────────────────────────────
    fig = figure('Name', 'IGUS RL-DP-5 Operating Envelope + Robot', 'Color', 'w', 'Position', [100 100 800 700]);

    ax1 = axes('Parent', fig);
    drawScene(ax1, opts.box, [], haveMesh, F, V, opts);   % pass [] to skip TCP star
    view(ax1, 45, 25);
    title(ax1, sprintf('IGUS RL-DP-5 Operating Envelope  (%d \\times %d \\times %d mm)', diff(opts.box(1,:)), diff(opts.box(2,:)), diff(opts.box(3,:))), 'FontWeight', 'bold');
    
        dcm = datacursormode(fig);
        set(dcm, 'Enable', 'on', 'UpdateFcn', @customDataTip);
        fprintf('\n  Click any point to see (X, Y, Z).\n\n');
    end


function drawScene(ax, box, tcp, haveMesh, F, V, opts)
    hold(ax, 'on');
    legendEntries = gobjects(0);
    legendNames   = {};

    % ── Translucent filled box (six faces) ───────────────────────────────────
    if opts.boxFill
        xL = box(1,:); yL = box(2,:); zL = box(3,:);
        % 8 vertices
        Vbox = [xL(1) yL(1) zL(1);
                xL(2) yL(1) zL(1);
                xL(2) yL(2) zL(1);
                xL(1) yL(2) zL(1);
                xL(1) yL(1) zL(2);
                xL(2) yL(1) zL(2);
                xL(2) yL(2) zL(2);
                xL(1) yL(2) zL(2)];
        % 6 faces using vertex indices
        Fbox = [1 2 3 4;     % bottom
                5 6 7 8;     % top
                1 2 6 5;     % front (Y=Ymin)
                2 3 7 6;     % right (X=Xmax)
                3 4 8 7;     % back  (Y=Ymax)
                4 1 5 8];    % left  (X=Xmin)
        h = patch(ax, 'Faces', Fbox, 'Vertices', Vbox, 'FaceColor', opts.boxColor, 'EdgeColor', 'none', 'FaceAlpha', 0.10, 'PickableParts', 'none');
        legendEntries(end+1) = h; %#ok<NASGU>
        % don't add to legend — the wireframe entry below covers it
    end

    % ── Wireframe edges of the box ───────────────────────────────────────────
    h = drawBoxWireframe(ax, box, opts.boxColor);
    legendEntries(end+1) = h;
    legendNames{end+1}   = 'Operating envelope';

    % ── Live TCP — magenta star ──────────────────────────────────────────────
    if ~isempty(tcp)
        h = plot3(ax, tcp(1), tcp(2), tcp(3), 'p', 'MarkerSize', 14, 'MarkerFaceColor', [0.85 0.20 0.85], 'MarkerEdgeColor', 'k', 'LineWidth', 1.4, 'Tag', 'tcpPoint');
        legendEntries(end+1) = h;
        legendNames{end+1}   = 'Live TCP';
    end

    % ── Base origin ──────────────────────────────────────────────────────────
    h = plot3(ax, 0, 0, 0, 'k+', 'MarkerSize', 16, 'LineWidth', 2, 'Tag', 'baseOrigin');
    legendEntries(end+1) = h;
    legendNames{end+1}   = 'Base origin';

    % ── Robot mesh ───────────────────────────────────────────────────────────
    if haveMesh
        h = patch(ax, 'Faces', F, 'Vertices', V, 'FaceColor', opts.meshColor, 'EdgeColor', 'none', 'FaceAlpha', opts.meshAlpha, 'FaceLighting', 'gouraud', 'AmbientStrength', 0.3, 'Tag', 'robotMesh', 'PickableParts', 'none');
        camlight(ax, 'headlight'); material(ax, 'dull');
        legendEntries(end+1) = h;
        legendNames{end+1}   = 'Robot + stand';
    end

    grid(ax, 'on'); axis(ax, 'equal');
    xlabel(ax, 'X [mm]'); ylabel(ax, 'Y [mm]'); zlabel(ax, 'Z [mm]');
    legend(ax, legendEntries, legendNames, 'Location', 'best');
end


function h = drawBoxWireframe(ax, box, color)
    xL = box(1, :);  yL = box(2, :);  zL = box(3, :);
    h = plot3(ax, [xL(1) xL(2) xL(2) xL(1) xL(1)], [yL(1) yL(1) yL(2) yL(2) yL(1)], [zL(1) zL(1) zL(1) zL(1) zL(1)], '-', 'Color', color, 'LineWidth', 1.5);
    plot3(ax, [xL(1) xL(2) xL(2) xL(1) xL(1)], [yL(1) yL(1) yL(2) yL(2) yL(1)], [zL(2) zL(2) zL(2) zL(2) zL(2)], '-', 'Color', color, 'LineWidth', 1.5);
    for ix = 1:2
        for iy = 1:2
            plot3(ax, [xL(ix) xL(ix)], [yL(iy) yL(iy)], [zL(1) zL(2)], '-', 'Color', color, 'LineWidth', 1.5);
        end
    end
end


function txt = customDataTip(~, info)
    pos = info.Position;
    target = info.Target;
    tag = '';
    if isprop(target, 'Tag'), tag = get(target, 'Tag'); end
    label = '';
    switch tag
        case 'tcpPoint',   label = 'Live TCP';
        case 'baseOrigin', label = 'Base origin';
    end
    if isempty(label)
        txt = {sprintf('X = %.2f mm', pos(1)), sprintf('Y = %.2f mm', pos(2)), sprintf('Z = %.2f mm', pos(3))};
    else
        txt = {label, sprintf('X = %.2f mm', pos(1)), sprintf('Y = %.2f mm', pos(2)), sprintf('Z = %.2f mm', pos(3))};
    end
end