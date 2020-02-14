classdef ArenaScene < handle
    %ARENASCENE Generates UIobjects, and stores Actors.
    %   Detailed explanation goes here
    
    properties
        Title
        Actors = ArenaActor.empty;
        handles
        SceneLocation = '';
    end
    
    properties (Hidden=true)
        configcontrolpos % stores the bounding box of the uicontrols
        gitref
    end
    
    methods
        function obj = ArenaScene()
            %ARENAWINDOW Construct an instance of this class
            %   Detailed explanation goes here
        end
        
        function obj = create(obj,OPTIONALname)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            debugmode = 0;
            
            if debugmode
                userinput = {'debug mode'};
            else
                if nargin==1
                    userinput = newid({'new scene name: '},'Arena',1,{'test'});
                elseif nargin==2
                    userinput = {OPTIONALname};
                end
            end
            obj.Title = userinput{1};
            
            obj.handles = [];
            obj.handles.figure = figure('units','normalized',...
                'outerposition',[0 0.05 1 0.9],...
                'menubar','none',...
                'name',obj.Title,...
                'numbertitle','off',...
                'resize','off',...
                'UserData',obj,...
                'CloseRequestFcn',@closeScene,...
                'WindowKeyPressFcn',@keyShortCut,...
                'WindowButtonDownFcn',@keyShortCut,...
                'Color',[1 1 1]);
            
            obj.handles.axes = axes('units','normalized',...
                'position',[0 0 1 1],...
                'fontsize',8,...
                'nextplot','add',...
                'box','off');
            axis off
            daspect([1 1 1])
            
            
            xpadding = 0.02;
            ypadding = 0.02;
            buttonheight = 0.04;
            obj.handles.panelleft = uipanel('units','normalized',...
                'position',[xpadding ypadding+buttonheight 0.4 0.3],...
                'Title','Config Controls');
            
            obj.handles.panelright = uicontrol('style','listbox',...
                'units','normalized',...
                'position',[1-xpadding-0.4 ypadding+buttonheight 0.4 0.3],...
                'callback',{@panelright_callback},...
                'max',100);
            
            obj.handles.btn_toggleleft = uicontrol('style','togglebutton',...
                'units','normalized',...
                'position', [xpadding,ypadding,0.4,buttonheight],...
                'String','close panel',...
                'Value',1,...
                'callback',{@btn_toggle_callback},...
                'Tag','left');
            
            obj.handles.btn_toggleright = uicontrol('style','togglebutton',...
                'units','normalized',...
                'position', [1-xpadding-0.4,ypadding,0.4,buttonheight],...
                'String','close panel',...
                'Value',1,...
                'callback',{@btn_toggle_callback},...
                'Tag','right');
            
            obj.handles.btn_updateActor = uicontrol('style','push',...
                'units','normalized',...
                'Parent',obj.handles.panelleft,...
                'position', [0.3,0.05,0.4,0.1],...
                'String','Update actor',...
                'Value',0,...
                'callback',{@btn_updateActor},...
                'Tag','UpdateButton');
            
            obj.handles.btn_layeroptions = uicontrol('style','push',...
                'units','normalized',...
                'position',[1-xpadding-0.05,ypadding+buttonheight+0.3,0.05,0.05],...
                'String','edit',...
                'Value',0,...
                'callback',{@btn_layeroptions});
            
            obj.handles.configcontrols = [];
            
            
            
            
            %menubar
            obj.handles.menu.file.main = uimenu(obj.handles.figure,'Text','File');
            
            obj.handles.menu.file.newscene.main = uimenu(obj.handles.menu.file.main,'Text','New empty scene','callback',{@menu_newscene});
            obj.handles.menu.file.savesceneas.main = uimenu(obj.handles.menu.file.main,'Text','Save scene as','callback',{@menu_savesceneas});
            obj.handles.menu.file.savescene.main = uimenu(obj.handles.menu.file.main,'Text','Save scene','callback',{@menu_savescene});
            obj.handles.menu.file.importscene.main = uimenu(obj.handles.menu.file.main,'Text','Import scene','callback',{@menu_importscene});
            
            obj.handles.menu.import.main = uimenu(obj.handles.figure,'Text','Import');
            obj.handles.menu.import.image.main = uimenu(obj.handles.menu.import.main,'Text','Image as');
            obj.handles.menu.import.image.imageasmesh = uimenu(obj.handles.menu.import.image.main,'Text','Mesh','callback',{@menu_importimageasmesh});
            obj.handles.menu.import.image.imageasslice = uimenu(obj.handles.menu.import.image.main,'Text','Slice','callback',{@menu_imoprtimageasslice});
            
            obj.handles.menu.import.scatter.main = uimenu(obj.handles.menu.import.main,'Text','Scatter from');
            obj.handles.menu.import.scatter.scatterfromworkspace = uimenu(obj.handles.menu.import.scatter.main,'Text','workspace','callback',{@menu_importscatterfromworkspace});
            obj.handles.menu.import.scatter.scatterfromfile = uimenu(obj.handles.menu.import.scatter.main,'Text','file','callback',{@menu_importscatterfromfile});
            obj.handles.menu.import.objfile.main = uimenu(obj.handles.menu.import.main,'Text','OBJ file','callback',{@menu_importObjfile});
            
            obj.handles.menu.import.lead.main = uimenu(obj.handles.menu.import.main,'Text','Lead from');
            obj.handles.menu.import.lead.fromnii = uimenu(obj.handles.menu.import.lead.main,'Text','from nii (2 dots)','callback',{@menu_importleadfromnii});
            
            obj.handles.menu.import.suretune.main = uimenu(obj.handles.menu.import.main,'Text','Suretune Session','callback',{@menu_importsuretune});
            
            
            obj.handles.menu.export.main = uimenu(obj.handles.figure,'Text','Export');
            obj.handles.menu.export.blender = uimenu(obj.handles.menu.export.main,'Text','Blender (obj)','callback',{@menu_exporttoblender});
            obj.handles.menu.export.handlestoworkspace = uimenu(obj.handles.menu.export.main,'Text','handles to workspace','callback',{@menu_exporthandlestoworkspace});
            
            obj.handles.menu.show.main = uimenu(obj.handles.figure,'Text','Show');
            obj.handles.menu.show.legacyatlas.main = uimenu(obj.handles.menu.show.main,'Text','Legacy atlas');
            obj.handles.menu.show.legacyatlas.stn = uimenu(obj.handles.menu.show.legacyatlas.main,'Text','STN (LPS)','callback',{@menu_legacyatlas});
            obj.handles.menu.show.legacyatlas.gpi = uimenu(obj.handles.menu.show.legacyatlas.main,'Text','GPi (LPS)','callback',{@menu_legacyatlas});
            obj.handles.menu.show.legacyatlas.other = uimenu(obj.handles.menu.show.legacyatlas.main,'Text','Other (LPS)','callback',{@menu_legacyatlas});
            obj.handles.menu.show.widgets.main = uimenu(obj.handles.menu.show.main,'Text','Widgets');
            obj.handles.menu.show.widgets.coordinatesystem = uimenu(obj.handles.menu.show.widgets.main,'Text','Coordinate system','callback',{@menu_coordinatesystem});
            obj.handles.menu.show.backgroundcolor.main = uimenu(obj.handles.menu.show.main,'Text','background');
            obj.handles.menu.show.backgroundcolor.white = uimenu(obj.handles.menu.show.backgroundcolor.main,'Text','White','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.show.backgroundcolor.white = uimenu(obj.handles.menu.show.backgroundcolor.main,'Text','Light','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.show.backgroundcolor.white = uimenu(obj.handles.menu.show.backgroundcolor.main,'Text','Dark','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.show.backgroundcolor.white = uimenu(obj.handles.menu.show.backgroundcolor.main,'Text','Black','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.show.backgroundcolor.white = uimenu(obj.handles.menu.show.backgroundcolor.main,'Text','Custom','callback',{@menu_setbackgroundcolor});
            obj.handles.menu.show.cameratoolbar.main = uimenu(obj.handles.menu.show.main,'Text','camera toolbar','callback',{@menu_cameratoolbar},'Checked','on');
            obj.handles.menu.show.MNIatlas.main = uimenu(obj.handles.menu.show.main,'Text','MNI atlas (leadDBS)','callback',{@menu_atlasleaddbs});
            
            obj.handles.menu.transform.main = uimenu(obj.handles.figure,'Text','Transform');
            obj.handles.menu.transform.selectedlayer.main = uimenu(obj.handles.menu.transform.main,'Text','Selected Layer');
            obj.handles.menu.transform.selectedlayer.lps2ras = uimenu(obj.handles.menu.transform.selectedlayer.main,'Text','LPS <> RAS','callback',{@menu_lps2ras});
            obj.handles.menu.transforn.selectedlayer.mirror = uimenu(obj.handles.menu.transform.selectedlayer.main,'Text','mirror (makes copy)','callback',{@menu_mirror});
            obj.handles.menu.transforn.selectedlayer.yeb2mni = uimenu(obj.handles.menu.transform.selectedlayer.main,'Text','Legacy --> MNI','callback',{@menu_Fake2MNI});
            
            obj.handles.menu.edit.main = uimenu(obj.handles.figure,'Text','Edit');
            obj.handles.menu.edit.count.main = uimenu(obj.handles.menu.edit.main,'Text','count overlap');
            obj.handles.menu.edit.count.toMesh = uimenu(obj.handles.menu.edit.count.main,'Text','as mesh','callback',{@menu_edit_count2mesh});
            obj.handles.menu.edit.count.toPlane = uimenu(obj.handles.menu.edit.count.main,'Text','as plane','callback',{@menu_edit_count2plane});
            obj.handles.menu.edit.add.main = uimenu(obj.handles.menu.edit.main,'Text','sum voxelvalues');
            obj.handles.menu.edit.add.toMesh = uimenu(obj.handles.menu.edit.add.main,'Text','as mesh','callback',{@menu_edit_add2mesh});
            obj.handles.menu.edit.add.toPlane = uimenu(obj.handles.menu.edit.add.main,'Text','as plane','callback',{@menu_edit_add2plane});
            
            obj.handles.cameratoolbar = cameratoolbar(obj.handles.figure,'Show');
            
            obj = createcoordinatesystem(obj);
            
            lighting gouraud
            
            function obj = createcoordinatesystem(obj)
                %Coordinate system
                h.XArrow = mArrow3([0 0 0],[3 0 0], 'facealpha', 0.5, 'color', 'red', 'stemWidth', 0.06,'Visible','off','Clipping','off');
                h.YArrow = mArrow3([0 0 0],[0 3 0], 'facealpha', 0.5, 'color', 'green', 'stemWidth', 0.06,'Visible','off','Clipping','off');
                h.ZArrow = mArrow3([0 0 0],[0 0 3], 'facealpha', 0.5, 'color', 'blue', 'stemWidth', 0.06,'Visible','off','Clipping','off');
                h.AC = text(-0.5,-0.5,-0.5,'MCP','Visible','off');
                h.R = text(4,0,0,'R','Visible','off');
                h.A = text(0,4,0,'A','Visible','off');
                h.S = text(0,0,4,'S','Visible','off');
                obj.handles.widgets.coordinatesystem = h;
            end
            
            
            %---figure functions
            function btn_toggle_callback(hObject,eventdata)
                %get link to the "ArenaScene" instance that is stored in UserData
                handles = hObject.Parent.UserData.handles;
                switch hObject.Value
                    case 0
                        set(handles.(['panel',hObject.Tag]),'Visible','off')
                        set(hObject,'String','open panel')
                    case 1
                        set(handles.(['panel',hObject.Tag]),'Visible','on')
                        set(hObject,'String', 'close panel')
                end
                handles.btn_layeroptions.Visible = handles.panelright.Visible;
                
            end
            
            function menu_newscene(hObject,eventdata)
                newScene;
            end
            
            function menu_cameratoolbar(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                switch scene.handles.cameratoolbar.Visible
                    case 'on'
                        scene.handles.cameratoolbar.Visible = 'off';
                        hObject.Checked = 'off';
                    case 'off'
                        scene.handles.cameratoolbar.Visible = 'on';
                        hObject.Checked = 'on';
                end
            end
            
            function menu_importscene(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                [filename,pathname] = uigetfile('*.scn');
                loaded = load(fullfile(pathname,filename),'-mat');
                delete(gcf);
                %isSameVersion(loaded.Scene,'show')
                
                Actors = loaded.Scene.Actors;
                
                [indx] = listdlg('ListString',{Actors.Tag});
                for thisindex = indx
                    thisActor = Actors(thisindex);
                    thisActor.reviveInScene(scene);
                end
            end
            
            function menu_savesceneas(hObject,eventdata)
                Scene = ArenaScene.getscenedata(hObject);
                try
                    Scene.gitref = getGitInfo;
                catch
                    Scene.gitref = '';
                end
                [filename,pathname] = uiputfile('*.scn');
                save(fullfile(pathname,filename),'Scene');
                Scene.SceneLocation = fullfile(pathname,filename);
                disp('Scene saved')
                
            end
            
            function menu_savescene(hObject,eventdata)
                Scene = ArenaScene.getscenedata(hObject);
                try
                    Scene.gitref = getGitInfo;
                catch
                    Scene.gitref = '';
                end
                if isempty(Scene.SceneLocation)
                    [filename,pathname] = uiputfile('*.scn');
                    save(fullfile(pathname,filename),'Scene');
                    Scene.SceneLocation = fullfile(pathname,filename);
                else
                    save(Scene.SceneLocation,'Scene')
                end
                disp('Scene saved')
            end
            
            function menu_exporttoblender(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                actorList = scene.Actors;
                thisActor = actorList(scene.handles.panelright.Value);
                name = [thisActor.Tag,'.obj'];
                thisActor.export3d(name);
                
                disp('File saved to current directory')
            end
            
            function menu_exporthandlestoworkspace(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                assignin('base','scene',scene);
                assignin('base','actors',scene.Actors);
                disp('handles saved to workspace: scene, actors')
            end
            
            function menu_lps2ras(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                actorList = scene.Actors;
                thisActor = actorList(scene.handles.panelright.Value);
                thisActor.transform(scene,'lps2ras');
                currentName = thisActor.Tag;
                label = '[LPS <> RAS]  ';
                if contains(currentName,label)
                    newname = erase(currentName,label);
                else
                    newname = [label,currentName];
                end
                thisActor.changeName(newname)
            end
            
            
            function menu_mirror(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                actorList = scene.Actors;
                thisActor = actorList(scene.handles.panelright.Value);
                copyActor = thisActor.duplicate(scene);
                copyActor.transform(scene,'mirror')
                copyActor.changeName(['[mirror]  ',copyActor.Tag])
                
                
            end
            
            function menu_Fake2MNI(hObject,eventdata)
                scene = ArenaScene.getscenedata(hObject);
                actorList = scene.Actors;
                thisActor = actorList(scene.handles.panelright.Value);
                thisActor.transform(scene,'Fake2MNI');
                currentName = thisActor.Tag;
                label = '[MNI]  ';
                if contains(currentName,label)
                    newname = erase(currentName,label);
                else
                    newname = [label,currentName];
                end
                thisActor.changeName(newname)
            end
                
            
            function menu_coordinatesystem(hObject,eventdata)
                thisScene = ArenaScene.getscenedata(hObject);
                cs_handle = thisScene.handles.widgets.coordinatesystem;
                switch hObject.Checked
                    case 'off'
                        fields=fieldnames(cs_handle);
                        for i = 1:numel(fields)
                            cs_handle.(fields{i}).Visible = 'on';
                        end
                        hObject.Checked = 'on';
                    case 'on'
                        fields=fieldnames(cs_handle);
                        for i = 1:numel(fields)
                            cs_handle.(fields{i}).Visible = 'off';
                        end
                        hObject.Checked  = 'off';
                end
            end
            function menu_setbackgroundcolor(hObject,eventdata)
                thisScene = ArenaScene.getscenedata(hObject);
                switch hObject.Text
                    case 'White'
                        color = [1 1 1];
                    case 'Light'
                        color = [0.92 0.9 0.88];
                    case 'Dark'
                        color = [0.5 0.53 0.53];
                    case 'Black'
                        color = [0 0 0];
                    case 'Custom'
                        color =uisetcolor();
                end
                set(thisScene.handles.figure,'Color',color)
                
            end
            
            function menu_atlasleaddbs(hObject,eventdata)
                %get the rootdir to load the config file
                global arena;
                root = arena.getrootdir;
                loaded = load(fullfile(root,'config.mat'))
                leadDBSatlasdir = fullfile('templates','space','MNI_ICBM_2009b_NLIN_ASYM','atlases');
                
                subfolders = A_getsubfolders(fullfile(loaded.config.leadDBS,leadDBSatlasdir));
                
                
                [indx,tf] = listdlg('ListString',{subfolders.name},'ListSize',[400,320]);
                newAtlasPath = fullfile(loaded.config.leadDBS,...
                    leadDBSatlasdir,...
                    subfolders(indx).name,'atlas_index.mat');
                in = load(newAtlasPath);
                
                allnames = in.atlases.names;
                [indx,tf] = listdlg('ListString',allnames,'SelectionMode','multiple');
                thisScene = ArenaScene.getscenedata(hObject);
                for iAtlas = indx
                    R = in.atlases.fv{iAtlas,1};
                    
                    name = in.atlases.names{iAtlas};
                    color = in.atlases.colormap(round(in.atlases.colors(iAtlas)),:);
                    
                    meshR = Mesh(R.faces,R.vertices);
                    actorR = meshR.see(thisScene);
                    actorR.changeName([name,' right'])
                    actorR.changeSetting('complexity',5,...
                        'colorFace',color,...
                        'colorEdge',color,...
                        'edgeOpacity',80);
                    
                    
                    try
                        L = in.atlases.fv{iAtlas,2};
                        meshL = Mesh(L.faces,L.vertices);
                        actorL = meshL.see(thisScene);
                        actorL.changeName([name,' left'])
                        actorL.changeSetting('complexity',5,...
                            'colorFace',color,...
                            'colorEdge',color,...
                            'edgeOpacity',80)
                    catch
                        disp('unilateral?')
                        
                        
                    end
                end
                
                
                %keyboard
            end
            
            function menu_legacyatlas(hObject,eventdata)
                %switch state
                rootdir = fileparts(fileparts(mfilename('fullpath')));
                legacypath = fullfile(rootdir,'Elements','SureTune');
                thisScene = ArenaScene.getscenedata(hObject);
                T = load('Tapproved.mat');
                switch hObject.Checked
                    case 'off'
                        
                        switch hObject.Text
                            case 'STN (LPS)'
                                obj_stn = ObjFile(fullfile(legacypath,'LH_STN-ON-pmMR.obj'));
                                obj_rn = ObjFile(fullfile(legacypath,'LH_RU-ON-pmMR.obj'));
                                obj_sn = ObjFile(fullfile(legacypath,'LH_SN-ON-pmMR.obj'));
                                
                                obj_stn_left = obj_stn.transform(T.leftstn2mni);
                                obj_stn_right = obj_stn.transform(T.rightstn2mni);
                                obj_rn_left = obj_rn.transform(T.leftstn2mni);
                                obj_rn_right = obj_rn.transform(T.rightstn2mni);
                                obj_sn_left = obj_sn.transform(T.leftstn2mni);
                                obj_sn_right = obj_sn.transform(T.rightstn2mni);
                                
                                [thisScene.handles.atlas.legacy.Actor_stnleft,scene] = obj_stn_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_snleft,scene] = obj_sn_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_rnleft,scene] = obj_rn_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_stnright,scene] = obj_stn_right.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_snright,scene] = obj_sn_right.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_rnright,scene] = obj_rn_right.see(thisScene);
                                
                                thisScene.handles.atlas.legacy.Actor_stnleft.changeName('[legacy] STNleft')
                                thisScene.handles.atlas.legacy.Actor_snleft.changeName('[legacy] SNleft')
                                thisScene.handles.atlas.legacy.Actor_rnleft.changeName('[legacy] RNleft')
                                thisScene.handles.atlas.legacy.Actor_stnright.changeName('[legacy] STNright')
                                thisScene.handles.atlas.legacy.Actor_snright.changeName('[legacy] SNright')
                                thisScene.handles.atlas.legacy.Actor_rnright.changeName('[legacy] RNright')
                                
                                thisScene.handles.atlas.legacy.Actor_stnleft.changeSetting('colorFace',[0 1 0],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                thisScene.handles.atlas.legacy.Actor_snleft.changeSetting('colorFace',[1 1 0],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                thisScene.handles.atlas.legacy.Actor_rnleft.changeSetting('colorFace',[1 0 0],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                thisScene.handles.atlas.legacy.Actor_stnright.changeSetting('colorFace',[0 1 0],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                thisScene.handles.atlas.legacy.Actor_snright.changeSetting('colorFace',[1 1 0],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                thisScene.handles.atlas.legacy.Actor_rnright.changeSetting('colorFace',[1 0 0],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                
                                
                                
                            case 'GPi (LPS)'
                                obj_gpi = ObjFile(fullfile(legacypath,'LH_IGP-ON-pmMR.obj'));
                                obj_gpe = ObjFile(fullfile(legacypath,'LH_EGP-ON-pmMR.obj'));
                                
                                obj_gpi_left = obj_gpi.transform(T.leftgpi2mni);
                                obj_gpe_left = obj_gpe.transform(T.leftgpi2mni);
                                obj_gpi_right = obj_gpi.transform(T.rightgpi2mni);
                                obj_gpe_right = obj_gpe.transform(T.rightgpi2mni);
                                
                                [thisScene.handles.atlas.legacy.Actor_gpileft,scene] = obj_gpi_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_gpeleft,scene] = obj_gpe_left.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_gpiright,scene] = obj_gpi_right.see(thisScene);
                                [thisScene.handles.atlas.legacy.Actor_gperight,scene] = obj_gpe_right.see(thisScene);
                                
                                thisScene.handles.atlas.legacy.Actor_gpileft.changeName('[legacy] GPIleft')
                                thisScene.handles.atlas.legacy.Actor_gpeleft.changeName('[legacy] GPEeft')
                                thisScene.handles.atlas.legacy.Actor_gpiright.changeName('[legacy] GPIright')
                                thisScene.handles.atlas.legacy.Actor_gperight.changeName('[legacy] GPRright')
                                
                                thisScene.handles.atlas.legacy.Actor_gpileft.changeSetting('colorFace',[0 0 1],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                thisScene.handles.atlas.legacy.Actor_gpeleft.changeSetting('colorFace',[0 1 1],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                thisScene.handles.atlas.legacy.Actor_gpiright.changeSetting('colorFace',[0 0 1],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                thisScene.handles.atlas.legacy.Actor_gperight.changeSetting('colorFace',[0 1 1],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                
                            case 'Other (LPS)'
                                %keyboard
                                atlases = uigetfile(fullfile(legacypath,'*.obj'),'MultiSelect','On');
                                if not(iscell(atlases))
                                    atlases = {atlases};
                                end
                                for iAtlas = 1:numel(atlases)
                                    obj_custom = ObjFile(fullfile(legacypath,atlases{iAtlas}));
                                    obj_custom_left = obj_custom.transform(T.leftstn2mni);
                                    obj_custom_right = obj_custom.transform(T.rightstn2mni);
                                    [scene,thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_left'])] = obj_custom_left.see(thisScene);
                                    [scene,thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_right'])] = obj_custom_right.see(thisScene);
                                    
                                    thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_left']).changeName(['[legacy] atlases{iAtlas} left'])
                                    thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_right']).changeName(['[legacy] atlases{iAtlas} right'])
                                    
                                    thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_left']).changeSetting('colorFace',[0.5 0.5 0.5],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                    thisScene.handles.atlas.legacy.(['Actor_obj_custom_',num2str(iAtlas),'_right']).changeSetting('colorFace',[0.5 0.5 0.5],'faceOpacity',20,'edgeOpacity',50,'complexity',50)
                                end
                                
                                
                                
                        end
                        hObject.Checked = 'on';
                    case 'on'
                        hObject.Checked = 'off';
                        switch hObject.Text
                            case 'STN (LPS)'
                                thisScene.handles.atlas.legacy.Actor_stnleft.delete(thisScene)
                                thisScene.handles.atlas.legacy.Actor_snleft.delete(thisScene)
                                thisScene.handles.atlas.legacy.Actor_rnleft.delete(thisScene)
                                thisScene.handles.atlas.legacy.Actor_stnright.delete(thisScene)
                                thisScene.handles.atlas.legacy.Actor_snright.delete(thisScene)
                                thisScene.handles.atlas.legacy.Actor_rnright.delete(thisScene)
                            case 'GPi (LPS)'
                                thisScene.handles.atlas.legacy.Actor_gpileft.delete(thisScene)
                                thisScene.handles.atlas.legacy.Actor_gpeleft.delete(thisScene)
                                thisScene.handles.atlas.legacy.Actor_gpiright.delete(thisScene)
                                thisScene.handles.atlas.legacy.Actor_gperight.delete(thisScene)
                        end
                end
                
                
                
            end
            
            
            function menu_importscatterfromfile(hObject,eventdata)
                thisScene =  ArenaScene.getscenedata(hObject);
                [fn,pn] = uigetfile('*.mat','MultiSelect','on');
                loaded = load(fullfile(pn,fn));
                names = {};
                data = {};
                
                vars = fieldnames(loaded);
                for iVariable = 1:numel(vars)
                    thisVariable = loaded.(vars{iVariable});
                    switch class(thisVariable)
                        case 'PointCloud'
                            names{end+1} = vars{iVariable};
                            data{end+1} = thisVariable;
                        case 'double'
                            if any(size(thisVariable)==3)
                                names{end+1} = vars{iVariable};
                                data{end+1} = thisVariable;
                            end
                    end
                end
                
                [indx] = listdlg('ListString',names);
                for thisindex = indx
                    pc = PointCloud(data{thisindex});
                    [scene,actor] = pc.see(thisScene);
                    actor.changeName(names{thisindex})
                end
            end
            
            
            
            function menu_importscatterfromworkspace(hObject,eventdata)
                thisScene =  ArenaScene.getscenedata(hObject);
                names = {};
                data = {};
                
                basevariables = evalin('base','whos');
                for iVariable = 1:numel(basevariables)
                    thisVariable = evalin('base',basevariables(iVariable).name);
                    switch class(thisVariable)
                        case 'PointCloud'
                            names{end+1} = basevariables(iVariable).name;
                            data{end+1} = thisVariable;
                        case 'double'
                            if any(size(thisVariable)==3)
                                names{end+1} = basevariables(iVariable).name;
                                data{end+1} = thisVariable;
                            end
                    end
                end
                
                [indx] = listdlg('ListString',names);
                for thisindex = indx
                    pc = PointCloud(data{thisindex});
                    [scene,actor] = pc.see(thisScene);
                    actor.changeName(names{thisindex})
                end
                
            end
            
            function menu_importObjfile(hObject,eventdata)
                o = ObjFile;
                o = o.loadfile();
                o.see(ArenaScene.getscenedata(hObject))
            end
            
            function menu_importsuretune(hObject,eventdata)
                newActors = A_loadsuretune(ArenaScene.getscenedata(hObject));
                
            end
            
            function menu_importimageasmesh(hObject,eventdata)
                
                [filename,pathname] = uigetfile('*.nii','Find nii image(s)','MultiSelect','on');
                if not(iscell(filename));filename = {filename};end
                
                for iFile = 1:numel(filename)
                    niifile = fullfile(pathname,filename{iFile});
                    v = VoxelData;
                    [~, name] = v.loadnii(niifile);
                    actor = v.getmesh.see(ArenaScene.getscenedata(hObject));
                    actor.changeName(name)
                end
                
            end
            
            function menu_imoprtimageasslice(hObject,eventdata)
                v = VoxelData;
                v.loadnii;
                v.getslice.see(ArenaScene.getscenedata(hObject));
            end
            
            
            function menu_importleadfromnii(hObject,eventdata)
                [filename,pathname] = uigetfile('*.nii','Find nii image(s)','MultiSelect','on');
                if not(iscell(filename));filename = {filename};end
                for iFile = 1:numel(filename)
                    niifile = fullfile(pathname,filename{iFile});
                    v = VoxelData;
                    [~, name] = v.loadnii(niifile);
                    Points = v.detectPoints();
                    
                    [~,order] = sort([Points.z]);% From lowest to highest
                    direction = (Points(order(2))-Points(order(1)));
                    e = Electrode(Points(order(1)),direction.unit);
                    %vc = VectorCloud(Points(order(1)),direction.unit);
                    actor = e.see(ArenaScene.getscenedata(hObject));
                    actor.changeName(name)
                end
                
            end
            
            function menu_edit_count2mesh(hObject,eventdata)
                
                vd = ArenaScene.countMesh(hObject);
                vd.getmesh.see(ArenaScene.getscenedata(hObject))
                
                
                
                
                
                
            end
            
            function menu_edit_count2plane(hObject,eventdata)
                vd = ArenaScene.countMesh(hObject);
                vd.getslice.see(ArenaScene.getscenedata(hObject))
            end
            
            function menu_edit_add2mesh(hObject,eventdata)
            end
            
            function menu_edit_add2plane(hObject,eventdata)
            end
            
            
            
            
            function btn_updateActor(hObject,eventdata)
                
                scene = hObject.Parent.Parent.UserData;
                actorList = scene.Actors;
                thisActor = actorList(scene.handles.panelright.Value);
                settings = getsettings(scene);
                
                settings = ArenaScene.ignoreUnchangedSettings(settings,thisActor(1));
                
                for i = 1:numel(thisActor)
                    thisActor(i).updateActor(scene,settings)
                end
            end
            
            function btn_layeroptions(hObject,eventdata)
                scene = hObject.Parent.UserData;
                actorList = scene.Actors;
                thisActor = actorList(scene.handles.panelright.Value);
                thisActor.edit(scene);
            end
            
            function panelright_callback(hObject,eventdata)
                scene = hObject.Parent.UserData;
                currentActor = scene.Actors(hObject.Value);
                
                %see of all selected actors are of the same class
                firstActor = class(currentActor(1).Data);
                consistentclass = true;
                for iActor = 1:numel(currentActor)
                    consistentclass = and(consistentclass,strcmp(firstActor,class(currentActor(iActor).Data)));
                end
                
                if not(consistentclass)
                    hObject.Value = hObject.Value(1);
                end
                
                currentActor(1).updateCC(scene);
                
            end
            
            function settings = getsettings(scene)
                settings = [];
                for i = 1:numel(scene.handles.configcontrols)
                    h = get(scene.handles.configcontrols(i));
                    switch h.Style
                        case 'text'
                            continue
                        case 'pushbutton'
                            if contains(h.Tag,'color')
                                settings.(h.Tag) = h.BackgroundColor;
                            end
                        case 'edit'
                            settings.(h.Tag) = str2num(h.String);
                            if isempty(settings.(h.Tag))
                                settings.(h.Tag) = NaN;
                            end
                        case 'checkbox'
                            settings.(h.Tag) = h.Value;
                        otherwise
                            keyboard
                    end
                    
                end
                
            end
            
            
            function keyShortCut(src,eventdata)
                scene = ArenaScene.getscenedata(src);
                switch eventdata.EventName
                    case 'WindowMousePress'
                        disp('click')
                    otherwise
                disp(eventdata.Key)
                f = scene.handles.figure;

                switch eventdata.Key
                    case 'o'
                        pause(0.1)
                        cameratoolbar('SetMode','orbit')
                        flash('o: orbit',f)
                    case 'r'
                        pause(0.1)
                        cameratoolbar('SetMode','roll')
                        flash('r: roll',f)
                    case 'z'
                        pause(0.1)
                        cameratoolbar('SetMode','zoom')
                        flash('z: zoom',f)
                    case 'p'
                        pause(0.1)
                        cameratoolbar('SetMode','pan')
                        flash('p: pan',f)
                    case {'return','space','escape'}
                        cameratoolbar('SetMode','none')
                        figure(f)
                end
                end
                
                function flash(text,f)
                    t = uicontrol(f,'Style','text',...
                        'String','Select a data set.',...
                        'Position',[30 50 130 30]);
                    t.String = text;
                    t.BackgroundColor = f.Color;
                    t.ForegroundColor = 1-t.BackgroundColor;
                    t.FontSize = 20;
                    t.Units = 'normalized';
                    t.Position = [0.4,0.8,0.2,0.05];
                    pause(2)
                    delete(t)
                end
            end
            
            function closeScene(src, callbackdata)
                %Close request function
                selection = questdlg('Close This Figure?',...
                    'Close Request Function',...
                    'Yes','No','Yes');
                switch selection
                    case 'Yes'
                        global arena
                        try
                            deleteIndex = find(arena.Scenes==src.UserData);
                            arena.Scenes(deleteIndex) = [];
                            delete(gcf)
                        catch
                            delete(gcf)
                            warning('Scene was an orphan..')
                        end
                        
                    case 'No'
                        return
                end
            end
            
            
        end
        function thisActor = newActor(obj,data,OPTIONALvisualisation)
            thisActor = ArenaActor;
            
            if nargin==3 %when reviving an actor in a new scene.
                thisActor.create(data,obj,OPTIONALvisualisation)
            else
                thisActor.create(data,obj)
            end
            obj.Actors(end+1) = thisActor;
            refreshLayers(obj);
            selectlayer(obj,'last')
            
        end
        
        function refreshLayers(obj)
            ActorTags = {};
            for i = 1:numel(obj.Actors)
                ActorTags{i} = obj.Actors(i).Tag;
            end
            obj.handles.panelright.String = ActorTags;
            
            if obj.handles.panelright.Value > numel(obj.handles.panelright.String)
                obj.handles.panelright.Value = 1;
            end
            
            obj.selectlayer()
            drawnow()
            
        end
        
        
        function selectlayer(obj,index)
            if nargin==1
                index = obj.handles.panelright.Value(1);
            end
            
            if ischar(index)
                switch index
                    case 'last'
                        index = numel(obj.Actors);
                    case 'first'
                        index = 1;
                    otherwise
                        keyboard
                end
            end
            
            
            
            %update the right box
            obj.handles.panelright.Value = index;
            %update the left box
            obj.Actors(index).updateCC(obj);
        end
        
        function clearconfigcontrols(obj)
            delete(obj.handles.configcontrols);
            obj.handles.configcontrols = [];
            obj.configcontrolpos = 0;
            
        end
        
        function newconfigcontrol(obj,actor,type,value,tag,other)
            xpadding = 0.05;
            ypadding = 0.05;
            
            checkboxwidth = 0.3;
            checkboxheight = 0.1;
            colorwidth = 0.1;
            colorheight = 0.1;
            editheight = 0.1;
            textwidth = 0.2;
            editwidth = 0.1;
            
            
            n = numel(obj.handles.configcontrols)+1;
            top = obj.configcontrolpos;
            left = 0;
            
            if not(iscell(value))
                value = {value};
                tag = {tag};
            end
            
            switch type
                case 'color'
                    left = textwidth+xpadding/2;
                    for i = 1:numel(value)
                        obj.handles.configcontrols(end+1) = uicontrol('style','push',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position', [left+xpadding,1-ypadding-colorheight-top,colorwidth,colorheight],...
                            'String','',...
                            'callback',{@cc_selectcolor},...
                            'Tag',tag{i},...
                            'backgroundcolor',value{i});
                        
                        left = left+xpadding+colorwidth;
                    end
                    obj.configcontrolpos = top+ypadding+colorheight;
                    
                case 'checkbox'
                    for i = 1:numel(value)
                        left = textwidth+xpadding/2;
                        obj.handles.configcontrols(end+1) = uicontrol('style','checkbox',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding,1-ypadding-checkboxheight-top,checkboxwidth,checkboxheight],...
                            'String',tag{i},...
                            'Tag',tag{i},...
                            'Value',value{i});
                        left = left+xpadding/2+checkboxwidth;
                    end
                case 'edit'
                    for i = 1:numel(value)
                        %label
                        obj.handles.configcontrols(end+1) = uicontrol('style','text',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding,1-ypadding-editheight-top,textwidth,editheight],...
                            'String',tag{i},...
                            'HorizontalAlignment','right');
                        
                        left = left+xpadding+textwidth;
                        
                        %editbox
                        obj.handles.configcontrols(end+1) = uicontrol('style','edit',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding/2,1-ypadding-editheight-top,editwidth,editheight],...
                            'String',num2str(value{i}),...
                            'Tag',tag{i});
                        
                        left = left+xpadding/2+editwidth;
                        
                    end
                    obj.configcontrolpos = top+ypadding+editheight;
                case 'vector'
                    for i = 1:numel(value)
                        %label
                        obj.handles.configcontrols(end+1) = uicontrol('style','text',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding,1-ypadding-editheight-top,textwidth,editheight],...
                            'String',tag{i},...
                            'HorizontalAlignment','right');
                        
                        left = left+xpadding+textwidth;
                        
                        %editbox
                        obj.handles.configcontrols(end+1) = uicontrol('style','edit',...
                            'Parent',obj.handles.panelleft,...
                            'units','normalized',...
                            'position',[left+xpadding/2,1-ypadding-editheight-top,editwidth,editheight],...
                            'String',num2str(value{i}),...
                            'Tag',tag{i});
                        
                        left = left+xpadding/2+editwidth;
                        
                    end
                    obj.configcontrolpos = top+ypadding+editheight;
                    
                    
                otherwise
                    keyboard
                    
            end
            
            function cc_selectcolor(hObject,eventdata)
                color = A_colorpicker;%uisetcolor;
                if length(color)==3
                    hObject.BackgroundColor = color;
                    
                    %trigger update button (nested function):
                    %UpdateButtonHandle = findobj('Tag','UpdateButton');
                    UpdateButtonHandle=hObject.Parent.Parent.UserData.handles.btn_updateActor;
                    feval(get(UpdateButtonHandle,'Callback'),UpdateButtonHandle,[]);
                end
            end
            
        end
        
        function saveas(obj,filename)
            savefig(obj.handles.figure,filename)
        end
        
        function hardclose(obj)
            global arena
            try
                deleteIndex = find(arena.Scenes==obj.handles.figure.UserData);
                arena.Scenes(deleteIndex) = [];
                delete(gcf)
            catch
                delete(gcf)
                warning('Scene was an orphan..')
            end
        end
        
    end
    
    methods(Static)
        
        function thisScene = getscenedata(h)
            while isempty(h.UserData)
                h = h.Parent;
            end
            thisScene = h.UserData;
        end
        
        function newsettings = ignoreUnchangedSettings(newsettings,actor)
            oldsettings = actor.Visualisation.settings;
            props = fieldnames(oldsettings);
            
            for iprop = 1:numel(props)
                thisprop = props{iprop};
                
                if oldsettings.(thisprop)==newsettings.(thisprop)
                    newsettings.(thisprop) = nan;
                end
            end
            
            
        end
        
        function currentActor = getSelectedActors(scene)
            ind = scene.handles.panelright.Value;
            currentActor = scene.Actors(ind);
        end
        
        function classes = getClasses(actorlist)
            classes = {};
            for i = 1:numel(actorlist)
                classes{i} = class(actorlist(i).Data);
            end
        end
        
        function vd = countMesh(hObject)
            scene = ArenaScene.getscenedata(hObject);
            currentActors = ArenaScene.getSelectedActors(scene);
            currentClasses = ArenaScene.getClasses(currentActors);
            
            corner_1 = [inf inf inf];
            corner_2 = [-inf -inf -inf];
            voxelsize = inf;
            if all(or(contains(currentClasses,'Mesh'),contains(currentClasses,'Slice')))
                %find world limits
                for i = 1:numel(currentActors)
                    R = currentActors(i).Data.Source.R;
                    corner_1 = min([corner_1;R.XWorldLimits(1),R.YWorldLimits(1),R.ZWorldLimits(1)]);
                    corner_2 = max([corner_2;R.XWorldLimits(2),R.YWorldLimits(2),R.ZWorldLimits(2)]);
                    voxelsize = min([voxelsize,R.PixelExtentInWorldX,R.PixelExtentInWorldY,R.PixelExtentInWorldZ]);
                end
                imsize = round((corner_2-corner_1)/voxelsize);
                targetR = imref3d(imsize([2 1 3]),voxelsize,voxelsize,voxelsize);
                targetR.XWorldLimits = targetR.XWorldLimits - voxelsize/2 + corner_1(1);
                targetR.YWorldLimits = targetR.YWorldLimits - voxelsize/2 + corner_1(2);
                targetR.ZWorldLimits = targetR.ZWorldLimits - voxelsize/2 + corner_1(3);
                
                
                %initialize output
                outputVoxels = double(currentActors(1).Data.Source.warpto(targetR).Voxels > currentActors(1).Data.Settings.T);
                
                %loop over remaining
                for i = 2:numel(currentActors)
                    outputVoxels = outputVoxels+double(currentActors(i).Data.Source.warpto(targetR).Voxels > currentActors(i).Data.Settings.T);
                end
                
                vd = VoxelData(outputVoxels,targetR);
            else
                disp('only supports meshes and slices as input')
                vd = VoxelData;
            end
        end
        
        
    end
end

