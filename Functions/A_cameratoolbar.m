function [h_toolbar] = A_cameratoolbar(figurehandle)
%A_CAMERATOOLBAR Summary of this function goes here
%   Detailed explanation goes here

h_toolbar.main =uitoolbar(figurehandle);


% add custom rotator:
h_toolbar.rotate3dtog=uitoggletool(h_toolbar.main, 'CData', A_loadicon('camera'),...
    'TooltipString', 'Rotate 3D', 'OnCallback', {@A_toolbar_rotate,'on'},...
    'OffCallback', {@A_toolbar_rotate,'off'}, 'State', 'on');
h_toolbar.slide3dtog=uitoggletool(h_toolbar.main, 'CData', A_loadicon('move'),...
    'TooltipString', 'Slide Slices', 'OnCallback', {@A_toolbar_slideslices,'on'},...
    'OffCallback', {@A_toolbar_slideslices,'off'}, 'State', 'off');
h_toolbar.magnifyplus=uitoggletool(h_toolbar.main,'CData',A_loadicon('zoomin'),...
    'TooltipString', 'Zoom In', 'OnCallback', {@A_toolbar_zoomin,'on'},...
    'OffCallback', {@A_toolbar_zoomin,'off'}, 'State', 'off');
h_toolbar.magnifyminus=uitoggletool(h_toolbar.main, 'CData', A_loadicon('zoomout'),...
    'TooltipString', 'Zoom Out', 'OnCallback', {@A_toolbar_zoomout,'on'},...
    'OffCallback', {@A_toolbar_zoomout,'off'}, 'State', 'off');
h_toolbar.handtog=uitoggletool(h_toolbar.main, 'CData', A_loadicon('pan'),...
    'TooltipString', 'Pan Scene', 'OnCallback', {@A_toolbar_pan,'on'},...
    'OffCallback', {@A_toolbar_pan,'off'}, 'State', 'off');


end


function A_toolbar_rotate(hObject,~,cmd)
scene = ArenaScene.getscenedata(hObject);
toolbar = scene.handles.cameratoolbar;
figure = scene.handles.figure;

toolbar.rotate3dtog.State = 'on';
toolbar.slide3dtog.State = 'off';

%get axes
ax = scene.handles.axes;

if strcmp(cmd,'off')
    set(figure,'Pointer','arrow')
    return
end

set(figure,'Pointer','circle')


% disable click actions on surfaces (image slices)
set(findobj(ax.Children,'Type','surface'),'HitTest','off');

A_mouse_camera(figure);

end

function A_toolbar_slideslices(hObject,~,cmd)

scene = ArenaScene.getscenedata(hObject);
toolbar = scene.handles.cameratoolbar;
figure = scene.handles.figure;
% 
% toolbar.rotate3dtog.State = 'off';
% toolbar.slide3dtog.State = 'on';

if strcmp(cmd,'off')
    return
end
% reset button down function
set(figure,'WindowButtonDownFcn', []);

%get axes
ax = scene.handles.axes;
set(findobj(ax.Children,'Type','surface'),'HitTest','on'); 


end

function A_toolbar_zoomin(varargin)
disp('zoom in!')
%steal from ea_zoomin (ea_imageclassifier)
end

function A_toolbar_zoomout(varargin)
disp('zoom out!')
%steal from ea_zoomout
end

function A_toolbar_pan(varargin)
disp('pan!')
%steal from ea_pan
end

function icon = A_loadicon(type)
switch type
    case 'camera'
        icon = imread('camera.jpg');
    case 'move'
         icon = imread('plane.jpg');
    case 'zoomin'
         icon = imread('zoom.jpg');
    case 'zoomout'
         icon = imread('zoom.jpg');
    case 'pan'
         icon = imread('pan.jpg');
end
end


