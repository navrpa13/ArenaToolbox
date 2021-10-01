classdef ArenaActor < handle & matlab.mixin.Copyable
    %ARENAACTOR Connects visualisation settings to Data. Links to Scene.
    
    properties
        Data
        Visualisation
        Scene
        Tag
        Visible = true;
    end
    
    methods
        function obj = ArenaActor()
            %ACTOR Construct an instance of this class
            %   Detailed explanation goes here
            obj.Data = [];
            obj.Visualisation = [];
            obj.Scene = ArenaScene.empty;
            
        end
        
        function obj = create(obj,data,scene,OPTIONALvisualisation)
            obj.Data = data;
            try
                obj.Scene(end+1) = scene;
            catch
                %wont work if it's not a scene; but a cropmenu
            end
            
            if nargin==4
                settings = OPTIONALvisualisation;
            else
                settings = NaN;
            end
            
            visualize(obj,settings,data,scene)
            obj.Tag = class(data);
            
        end
        
        function settings = visualizeContour(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.colorFace = scene.getNewColor(scene);
                settings.colorEdge = scene.getNewColor(scene);%
                settings.faceOpacity = 80;
                settings.edgeOpacity = 0;

            end
            
            axes(scene.handles.axes)
            
            
            %create the handle
            handle = data.patch;
            
            %apply settings
            handle.FaceColor = settings.colorFace;
            handle.EdgeColor = settings.colorEdge;
            handle.FaceAlpha = settings.faceOpacity/100;
            handle.EdgeAlpha = settings.edgeOpacity/100;
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            %update
            updateCC(obj,scene)
        end
        
        function settings = visualizeObjFile(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.colorFace = scene.getNewColor(scene);
                settings.colorEdge = scene.getNewColor(scene);
                settings.complexity = 100;
                settings.faceOpacity = 100;
                settings.edgeOpacity = 0;
                settings.smooth = 0;
            end
            
            axes(scene.handles.axes)
            
            
            %create the handle
            handle = patch('Faces',data.Faces,'Vertices',data.Vertices);
            
            %apply settings
            reducepatch(handle,settings.complexity/100);
            handle.FaceColor = settings.colorFace;
            handle.EdgeColor = settings.colorEdge;
            handle.FaceAlpha = settings.faceOpacity/100;
            handle.EdgeAlpha = settings.edgeOpacity/100;
            if settings.smooth
                handle.FaceLighting = 'gouraud';
            else
                handle.FaceLighting = 'flat';
            end
            material(handle,[0.8 1 0.2]) 
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            %update
            updateCC(obj,scene)
        end
        
        function settings = visualizeSlice(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                creation = 1;
                settings = struct;
                settings.colorDark = [0 0 0];
                settings.colorLight = [1 1 1];
                settings.valueDark = min(obj.Data.vol(:));
                settings.valueLight = max(obj.Data.vol(:));
                settings.slice = 0;
                settings.plane = 'axial';
                settings.faceOpacity = 90;
                %settings.clipDark = 0;
            else
                creation = 0;
            end
           
        %Slicei already lives
        cmap = A_colorgradient(settings.colorDark,settings.colorLight,255);
        obj.Data.cmap = cmap;
        obj.Data.dark = settings.valueDark;
        obj.Data.light = settings.valueLight;
        obj.Data.opacity = settings.faceOpacity/100;
        
       % obj.Data.clipDark = settings.clipDark;
       
       switch settings.plane
           case 'axial'
               obj.Data.slicedim = 3;
           case 'sagittal'
               obj.Data.slicedim = 1;
           case 'coronal'
               obj.Data.slicedim = 2;
       end
       
       vector = [0 0 0];
        vector(obj.Data.slicedim) = settings.slice;
         T = obj.Data.I2X;
        T(4,4) = 1;
        imagespace = SDK_transform3d(vector,inv(T'));
        obj.Data.sliceidx = imagespace(obj.Data.slicedim);
        
        %refresh only when it already exists
        if not(creation)
            obj.Data.update_slice(scene);
        end
        
            
             
            obj.Visualisation.handle = obj.Data.handle;
        obj.Visualisation.settings = settings;

            
        end
        function settings = visualizeSlice_old(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.colorDark = [0 0 0];
                settings.colorLight = [1 1 1];
                settings.valueDark = 0;
                settings.valueLight = 255;
                settings.baseVector = [0,0,0];
                settings.normalVector = [0, 0, 1];
                settings.faceOpacity = 90;
                settings.edgeOpacity = 0;
                settings.clipDark = 0;
            end
            
            axes(scene.handles.axes)
            
            %create the handle
            data = data.getslicefromvoxeldata(Vector3D(settings.baseVector),Vector3D(settings.normalVector));
            [gridx,gridy,gridz] = A_imref2meshgrid(data.Source.R);
            
            
            handle = slice(gridx,gridy,gridz,data.Source.Voxels,data.Plane.X,data.Plane.Y,data.Plane.Z);
            handle.FaceAlpha = settings.faceOpacity/100;
            handle.EdgeAlpha = settings.edgeOpacity/100;
            handle.FaceColor = 'interp';
            
            
            cmap = A_colorgradient(settings.colorDark,settings.colorLight,255);
            sliceVoxelValues = handle.CData;
            RGBvector = A_vals2colormap(handle.CData(:),cmap,[settings.valueDark,settings.valueLight]);
            RGB = reshape(RGBvector,[size(handle.CData),3]);
            handle.CData = RGB;
            
            if settings.clipDark
                handle.FaceColor = 'interp';
                handle.FaceAlpha = 'interp';
                handle.AlphaDataMapping = 'none';
                handle.AlphaData = double(sliceVoxelValues > settings.valueDark) * (settings.faceOpacity/100);
                material(handle,[0.8 1 0]) %mostly ambient, some diffuse, NO specular
          
            end
            
            
            
            
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            %update
            updateCC(obj,scene)
            
            
            
        end
        
        function settings = visualizeMesh(obj,settings,data,scene)
            %---- default settings
            dynamicComplexity = 0;
            if and(isempty(data.Source),not(isstruct(settings))) % mesh has no voxel image as source
                settings = struct;
                settings.colorFace = scene.getNewColor(scene);%[0 188 216]/255;
                settings.colorEdge = scene.getNewColor(scene);%[0 188 216]/255;
                settings.complexity = 20;
                settings.threshold = NaN;
                settings.faceOpacity = 50;
                settings.edgeOpacity = 0;
                settings.smooth = 1;
                
            else
                if not(isstruct(settings)) %mesh has been generated from voxels
                    settings = struct;
                    settings.colorFace = scene.getNewColor(scene);%[0 188 216]/255;
                    settings.colorEdge = scene.getNewColor(scene);%[0 188 216]/255;
                    settings.complexity = 20;
                    settings.threshold = data.Settings.T;
                    settings.faceOpacity = 50;
                    settings.edgeOpacity = 0;
                    settings.smooth = 1;
                    dynamicComplexity = 1;
                end
            end
            try
            axes(scene.handles.axes)
            catch;
            end
               
            
            isBasedOnVoxelData = not(isempty(data.Source));
            
            % changing threshold triggers new triangulation from voxeldata
            if isBasedOnVoxelData
                if or(not(round(settings.threshold,7)==round(data.Settings.T,7)),isa(scene,'ArenaCropMenu'))
                    if isnan(settings.threshold)
                        data.getmeshfromvoxeldata({data.Source});
                        settings.threshold = data.Settings.T;
                    else
                        data.getmeshfromvoxeldata({data.Source,settings.threshold});
                    end
                end
            end
            
            %create the handle
            try
            out2=lpflow_trismooth(data.Vertices,data.Faces);
            handle = patch('Faces',data.Faces,'Vertices',out2);
            catch
                handle = patch('Faces',data.Faces,'Vertices',data.Vertices);
            end
                
            
            %Dynamic Complexity
            if dynamicComplexity
                complexity = 100/length(handle.Vertices);
                if complexity>1
                    complexity = 1;
                elseif complexity < 0.2
                    complexity = 0.2;
                end
                settings.complexity = complexity *100;
                reducepatch(handle,complexity);
            else
                reducepatch(handle,settings.complexity/100);
            end
            %apply settings
            
            
            handle.FaceColor = settings.colorFace;
            handle.EdgeColor = settings.colorEdge;
            handle.FaceAlpha = settings.faceOpacity/100;
            handle.EdgeAlpha = settings.edgeOpacity/100;
            if settings.smooth
                handle.FaceLighting = 'gouraud';
            else
                handle.FaceLighting = 'flat';
            end
            
            material(handle,[0.8 1 0.2]) 
            
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            %update
            updateCC(obj,scene)
        end
        
        
        function settings = visualizeVectorCloud(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.color1 = [0.85 0.85 0.85];
                settings.color2 = [0.5 0.5 0.5];
                settings.color3 = [0 0 1];
                settings.scale = 5;
                settings.leadoverlay = 0;
                settings.opacity = 100;
            end
            
            axes(scene.handles.axes)
            
            
            if settings.leadoverlay ==0
                handle = [];
                for i = 1:numel(data.Base)
                    
                    primaryend = data.Base(i).getArray() + settings.scale*data.Direction(i).getArray();
                    h.primary = mArrow3(data.Base(i).getArray(),primaryend, 'facealpha', settings.opacity, 'color', settings.color1, 'stemWidth', settings.scale*0.02,'Visible','on','Clipping','off');
                    alpha(h.primary,settings.opacity/100)
                    handle(end+1) = h.primary;
                end
                
                
            else
                
                load('Arena_mdt3389.mat');
                
                handle = [];
                for i = 1:numel(data.Base)
                    T = A_transformationmatriforleadmesh(data.Base(i),data.Direction(i));
                    body = mdt3389.body.transform(T);
                    c0 = mdt3389.c0.transform(T);
                    c1 = mdt3389.c1.transform(T);
                    c2 = mdt3389.c2.transform(T);
                    c3 = mdt3389.c3.transform(T);
                    
                    
                    handle(end+1) = patch('Faces',body.Faces,'Vertices',body.Vertices,'FaceColor',settings.color1 ,'EdgeColor','none','Clipping',0,'SpecularStrength',0,'FaceAlpha',settings.opacity/100);
                    %handle(end).FaceLighting = 'gouraud';
                    handle(end+1) = patch('Faces',c0.Faces,'Vertices',c0.Vertices,'FaceColor',settings.color2,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    %handle(end).FaceLighting = 'gouraud';
                    handle(end+1) = patch('Faces',c1.Faces,'Vertices',c1.Vertices,'FaceColor',settings.color2,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    %handle(end).FaceLighting = 'gouraud';
                    handle(end+1) = patch('Faces',c2.Faces,'Vertices',c2.Vertices,'FaceColor',settings.color2,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    %handle(end).FaceLighting = 'gouraud';
                    handle(end+1) = patch('Faces',c3.Faces,'Vertices',c3.Vertices,'FaceColor',settings.color2,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    %handle(end).FaceLighting = 'gouraud';
                    
                end
                
            end

            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            updateCC(obj,scene)
        end
        
                function settings = visualizeElectrode(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.colorBase = [1 1 1];
                settings.colorInactive = [0.5 0.5 0.5];
                settings.colorCathode = [1 0.5 0];
                settings.colorAnode = [0 0.5 1];
                settings.cathode = [0 0 0 0];
                settings.anode = [0 0 0 0];
                settings.opacity = 100;
                settings.type = data.Type;
            end
            
            axes(scene.handles.axes)
            
            if strcmp(settings.type,'Medtronic3389')
                leadmodel = load('Arena_mdt3389.mat');
                strucname = 'mdt3389';
            elseif strcmp(settings.type,'Medtronic3387')
                leadmodel = load('Arena_mdt3387.mat');
                strucname = 'mdt3387';
            elseif strcmp(settings.type,'Medtronic3391')
                leadmodel = load('Arena_mdt3391.mat');
                strucname = 'mdt3391';
            elseif strcmp(settings.type,'BostonScientific')
                 leadmodel = load('Arena_BostonScientific.mat');
                 strucname = 'BostonScientific';
              else
                error('leadtype is currently not yet supported!')   
              end
                
                handle = gobjects(0);

                    T = A_transformationmatriforleadmesh(data.C0,data.Direction);
                    body = leadmodel.(strucname).body.transform(T);
                    handle(end+1) = patch('Faces',body.Faces,'Vertices',body.Vertices,'FaceColor',settings.colorBase ,'EdgeColor','none','Clipping',0,'SpecularStrength',0,'FaceAlpha',settings.opacity/100);
                   material(handle(end),'shiny') 
                    handle(end).FaceLighting = 'gouraud';
                    
                    for i = 0:numel(fieldnames(leadmodel.(strucname)))-2
                    ci = leadmodel.(strucname).(['c',num2str(i)]).transform(T);
                    handle(end+1) = patch('Faces',ci.Faces,'Vertices',ci.Vertices,'FaceColor',settings.colorInactive,'EdgeColor','none','Clipping',0,'SpecularStrength',1,'FaceAlpha',settings.opacity/100);
                    material(handle(end),'dull') 
                    handle(end).FaceLighting = 'gouraud';
     
                    end
                    
                    for i = 1:numel(settings.cathode)
                        if settings.cathode(i)
                            handle(1+i).FaceColor = settings.colorCathode;
                        end
                    end
                    for i = 1:numel(settings.anode)
                        if settings.anode(i)
                            handle(1+i).FaceColor = settings.colorAnode;
                        end
                    end
              
                
            
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            updateCC(obj,scene)
                end
        
        
        function settings = visualizePointCloud(obj,settings,data,scene)
            %---- default settings
            if not(isstruct(settings))
                settings = struct;
                settings.colorLow = scene.getNewColor(scene);
                settings.colorHigh = 1-scene.getNewColor(scene);
                settings.thickness = 100;
                settings.opacity = 100;
            end
            
            axes(scene.handles.axes)
            
            v = data.Vectors.getArray();
            w = data.Weights;
            
            if numel(v) ==3
                v = v';
            end
            cmap = A_colorgradient(settings.colorLow,settings.colorHigh,256);
            w_color = A_vals2colormap(w,cmap);
            
            handle = scatter3(v(:,1),v(:,2),v(:,3),settings.thickness,w_color,'filled');
            
            alpha(handle,settings.opacity/100)
            
            obj.Visualisation.handle = handle;
            obj.Visualisation.settings = settings;
            
            updateCC(obj,scene)
            
            
        end
        
        
        function settings = visualizeFibers(obj,settings,data,scene)
            axes(scene.handles.axes)
            
               if isempty(data.Connectome) %in case of VTK fibers
                   switch class(settings)
                       case 'double'
                           %default VTK 
                           faceOpacity = 3;
                           colorByDirection = true;
                           colorByWeight = false;
                           colorSolid = false;
                           colorFace = scene.getNewColor(scene);
                           colorFace2 = [1 1 1];
                           
                           if ~isnan(settings)
                               nFibers = settings;
                           else
                               nFibers = length(data.Vertices);
                               
                           end
                           
                       case 'struct'
%                            obj.Visualisation.settings = settings;
                           nFibers = settings.numberOfFibers;
                           faceOpacity = settings.faceOpacity;
                           colorByDirection = settings.colorByDirection;
                           colorByWeight = settings.colorByWeight;
                           colorSolid = settings.colorSolid;
                           colorFace = settings.colorFace;
                           colorFace2 = settings.colorFace2;
                   end
                   
                   
                    
                    obj.Visualisation.settings.colorFace = colorFace;
                    obj.Visualisation.settings.colorFace2 = colorFace2;
                    obj.Visualisation.settings.colorByDirection = colorByDirection;
                    obj.Visualisation.settings.colorByWeight= colorByWeight;
                    obj.Visualisation.settings.colorSolid = colorSolid;
                    obj.Visualisation.settings.faceOpacity = faceOpacity;
                    obj.Visualisation.settings.numberOfFibers = nFibers;
                    data.drawVTKfibers(obj,scene)
                    
                    settings = obj.Visualisation.settings; %required for output
                    %update
                    updateCC(obj,scene)
                    return
               end
                
            %---- default settings for connectome
            if not(isstruct(settings)) % mesh has no voxel image as source
  
                settings = struct;
                settings.colorFace = scene.getNewColor(scene);%[0 188 216]/255;
                settings.colorFace2 = [1 1 1];
                settings.numberOfFibers = 100;
                settings.faceOpacity = 50;
                settings.colorByDirection = true;
                settings.colorByWeight = false;
                settings.colorSolid = false;

                obj.Visualisation.settings = settings;
                
             

            else 
            
            
           % check if numberOfFibers matches --> otherwise trigger
           
           if settings.numberOfFibers ~= numel(obj.Visualisation.handle)
               if settings.numberOfFibers < numel(obj.Visualisation.handle)
                   
                   if ~isempty(data.Connectome)
                       obj.Data.Vertices(settings.numberOfFibers+1:end) = [];
                       obj.Data.Indices(settings.numberOfFibers+1:end) = [];
                   end
                   delete(obj.Visualisation.handle(settings.numberOfFibers+1:end))
                   obj.Visualisation.handle(settings.numberOfFibers+1:end) = [];
                   
               else
                   if isempty(data.Connectome) %in case of VTK fibers
                       obj.Visualisation.settings.numberOfFibers = settings.numberOfFibers;
                       data.drawVTKfibers(obj,scene)
                   else
                       getFibersPassingThroughMesh(obj.Data.Connectome,...
                           obj.Data.IncludeSeed,...
                           settings.numberOfFibers,...
                           scene,...
                           obj.Data)
                   end
               end
           end
           
           % Connectome
           if settings.faceOpacity ~=obj.Visualisation.settings.faceOpacity
               for iH = 1:numel(obj.Visualisation.handle)
                    obj.Visualisation.handle(iH).FaceAlpha = settings.faceOpacity/100;
               end
           end
           
           % update styling settings if changed:
           always_update_color = 1;
             if any([settings.colorFace ~= obj.Visualisation.settings.colorFace,...
                     settings.colorFace2 ~=obj.Visualisation.settings.colorFace2,...
                     settings.colorByDirection ~=obj.Visualisation.settings.colorByDirection,...
                     settings.colorByWeight ~=obj.Visualisation.settings.colorByWeight,...
                     settings.colorSolid ~=obj.Visualisation.settings.colorSolid,...
                     always_update_color])
%                 %apply settings
                for iH = 1:numel(obj.Visualisation.handle)
                    if settings.colorByDirection
                        color = PointCloud(abs(diff(obj.Data.Vertices(iH).Vectors.getArray))).Vectors.unit;
                        color = [color;color(end,:)];


                                colorArray = color.getArray;

                                CData = [];
                                CData(:,:,1) = repmat(colorArray(:,1),1, size(obj.Visualisation.handle(iH).CData,2));
                                CData(:,:,2) = repmat(colorArray(:,2),1, size(obj.Visualisation.handle(iH).CData,2));
                                CData(:,:,3) = repmat(colorArray(:,3),1, size(obj.Visualisation.handle(iH).CData,2));
                    elseif settings.colorByWeight
                        
                  colorvalue = (obj.Data.Weight(iH) - min(obj.Data.Weight))/(max(obj.Data.Weight)-min(obj.Data.Weight));
                   low = colorvalue;
                   high = 1-low;
                   
                   lowRGB = settings.colorFace;
                   highRGB = settings.colorFace2;
                  
                        
                    CData = ones(size(obj.Visualisation.handle(iH).CData));
                    CData(:,:,1) = CData(:,:,1)*lowRGB(1)*low + CData(:,:,1)*highRGB(1)*high ;
                    CData(:,:,2) = CData(:,:,2)*lowRGB(2)*low + CData(:,:,2)*highRGB(2)*high ;
                    CData(:,:,3) = CData(:,:,3)*lowRGB(3)*low + CData(:,:,3)*highRGB(3)*high ;
                        
                    else
                    CData = ones(size(obj.Visualisation.handle(iH).CData));
                    CData(:,:,1) = CData(:,:,1)*settings.colorFace(1);
                    CData(:,:,2) = CData(:,:,2)*settings.colorFace(2);
                    CData(:,:,3) = CData(:,:,3)*settings.colorFace(3);
                    end
                    obj.Visualisation.handle(iH).CData = CData;

                end
            end
            
            
            %mirrored
            %regenerate the first fiber and see if the vertices are the
            %same
            if not(isempty(obj.Data.Connectome)) %doesn't work on vtk
                idcs_cumsum = cumsum(obj.Data.Connectome.Data.idx);
                iFib = data.Indices(1);
                try
                start = idcs_cumsum(iFib-1)+1;
                catch
                    start = 1;
                end

                FirstVertex = obj.Data.Connectome.Data.fibers(start,1);



                if not(FirstVertex==obj.Data.Vertices(1).Vectors(1).x)
                    obj.Data.redraw(scene,obj);
                end
            end
                
            
            
            %material(handle,[0.8 1 0.2]) 
            
            obj.Visualisation.settings = settings;
            end
            
            %update
            updateCC(obj,scene)
        end
        
        
        function getSettings(obj)
            disp(obj.Visualisation.settings)
        end
        
        function cog = getCOG(obj)
            cog = obj.Data.getCOG;
        end
        
        function changeSetting(obj,varargin)
            if rem(numel(varargin),2) %isodd
                error('input arguments should be pairs')
            end
            for iPair = 1:2:numel(varargin)
                if not(isfield(obj.Visualisation.settings,varargin{iPair}))
                    error([varargin{iPair},' is not a valid property'])
                end
                obj.Visualisation.settings.(varargin{iPair}) = varargin{iPair+1};
            end
            
            if not(or(or(isa(obj.Data,'Slicei'),...
                    isa(obj.Data,'Fibers')),...
                    isa(obj.Data,'Contour')))
                    delete(obj.Visualisation.handle);
            end
            
            visualize(obj,obj.Visualisation.settings,obj.Data,obj.Scene)
            obj.Scene.refreshLayers();
        end
        
        function updateCC(obj,scene)
            settings = obj.Visualisation.settings;
            scene.clearconfigcontrols()
            
            switch class(obj.Data)
                case 'PointCloud'
                    scene.newconfigcontrol(obj,'color',{settings.colorLow, settings.colorHigh},{'colorLow','colorHigh'});
                    scene.newconfigcontrol(obj,'edit',settings.thickness,'thickness');
                    scene.newconfigcontrol(obj,'edit',settings.opacity,'opacity');
                case {'Mesh','CroppedVoxelData'}
                    scene.newconfigcontrol(obj,'color',{settings.colorFace,settings.colorEdge},{'colorFace','colorEdge'});
                    scene.newconfigcontrol(obj,'edit',{settings.complexity,settings.threshold},{'complexity','threshold'});
                    scene.newconfigcontrol(obj,'edit',{settings.faceOpacity,settings.edgeOpacity},{'faceOpacity','edgeOpacity'})
                    
                    scene.newconfigcontrol(obj,'button',{'crop','slice'},{'crop','slice'})
                    scene.newconfigcontrol(obj,'checkbox',settings.smooth,'smooth')
                case 'ObjFile'
                    scene.newconfigcontrol(obj,'color',{settings.colorFace,settings.colorEdge},{'colorFace','colorEdge'});
                    scene.newconfigcontrol(obj,'edit',{settings.complexity},{'complexity'});
                    scene.newconfigcontrol(obj,'edit',settings.faceOpacity,'faceOpacity')
                    scene.newconfigcontrol(obj,'edit',settings.edgeOpacity,'edgeOpacity')
                    scene.newconfigcontrol(obj,'checkbox',settings.smooth,'smooth')
                case 'VectorCloud'
                    scene.newconfigcontrol(obj,'color',{settings.color1,settings.color2,settings.color3},{'color1','color2','color3'});
                    scene.newconfigcontrol(obj,'edit',settings.scale,'scale');
                    scene.newconfigcontrol(obj,'edit',settings.opacity,'opacity');
                    scene.newconfigcontrol(obj,'checkbox',settings.leadoverlay,'leadoverlay');
                case 'Slice'
                    scene.newconfigcontrol(obj,'color',{settings.colorDark,settings.colorLight},{'colorDark','colorLight'});
                    scene.newconfigcontrol(obj,'edit',{settings.valueDark,settings.valueLight},{'valueDark','valueLight'});
                    scene.newconfigcontrol(obj,'vector',settings.crossing,'crossing');
                    scene.newconfigcontrol(obj,'edit',{settings.faceOpacity,settings.edgeOpacity},{'faceOpacity','edgeOpacity'});
                    scene.newconfigcontrol(obj,'checkbox',settings.clipDark,'clipDark');
                case 'Electrode'
                    scene.newconfigcontrol(obj,'color',{settings.colorBase,settings.colorInactive},{'colorBase','colorInactive'});
                    scene.newconfigcontrol(obj,'color',{settings.colorCathode,settings.colorAnode},{'colorCathode','colorAnode'});
                    scene.newconfigcontrol(obj,'vector',{settings.cathode,settings.anode},{'cathode','anode'});
                    scene.newconfigcontrol(obj,'edit',{settings.opacity},{'opacity'});
                    scene.newconfigcontrol(obj,'list',{settings.type},{'type'},{'Medtronic3389','Medtronic3387','Medtronic3391','BostonScientific'})
                case 'Slicei'
                    scene.newconfigcontrol(obj,'color',{settings.colorDark,settings.colorLight},{'colorDark','colorLight'});
                    scene.newconfigcontrol(obj,'edit',{settings.valueDark,settings.valueLight},{'valueDark','valueLight'});
                    scene.newconfigcontrol(obj,'vector',{settings.slice,settings.faceOpacity},{'slice','faceOpacity'});
                    scene.newconfigcontrol(obj,'list',{settings.plane},{'plane'},{'axial','coronal','sagittal'})
                    scene.newconfigcontrol(obj,'button','mesh','mesh')
                    %scene.newconfigcontrol(obj,'checkbox',settings.clipDark,'clipDark');
                case 'Fibers'
                    scene.newconfigcontrol(obj,'color',{settings.colorFace,settings.colorFace2},{'colorFace','colorFace2'});
                    scene.newconfigcontrol(obj,'edit',settings.numberOfFibers,'numberOfFibers');
                    scene.newconfigcontrol(obj,'edit',settings.faceOpacity,'faceOpacity');
                    %scene.newconfigcontrol(obj,'checkbox',settings.colorByDirection,'colorByDirection');
                    scene.newconfigcontrol(obj,'radio',{settings.colorByDirection,settings.colorByWeight,settings.colorSolid},{'colorByDirection','colorByWeight','colorSolid'});
                    
                case 'Contour'
                    scene.newconfigcontrol(obj,'color',{settings.colorFace,settings.colorEdge},{'colorFace','colorEdge'})
                    scene.newconfigcontrol(obj,'edit',settings.faceOpacity,'faceOpacity')
                    scene.newconfigcontrol(obj,'edit',settings.edgeOpacity,'edgeOpacity')
                    
                   
                    
                otherwise
                    keyboard
            end
           
        end
        
        function updateActor(obj,scene,settings)
            
            if not(or(or(isa(obj.Data,'Slicei'),...
                    isa(obj.Data,'Fibers')),...
                    isa(obj.Data,'Contour')))
                
                delete(obj.Visualisation.handle);
            end
            
            %replace nans with current values
            currentsettings = obj.Visualisation.settings;
            props = fieldnames(currentsettings);
            for i = 1:numel(props)
                if isnan(settings.(props{i}))
                    settings.(props{i}) = currentsettings.(props{i});
                end
            end
            
            %
            
            visualize(obj,settings,obj.Data,scene);
            
        end
        
        
        %TO DO: THIS SWITCH SHOULD BE AVOIDED.
        %INSTEAD: DO OBJ.DATA.VISUALIZE() AND PUT THE METHOD IN THE DATACLASS
        
        %Important: The first property you add to Settings must be COLOR!
        %Because this will be used for the layer indication
      
        function settings = visualize(obj,settings,data,scene)
            visualize(data,obj,settings,scene) %refers to the visualize method in the class. (Google: Function Precedence Order MATLAB)
            return
            
            
            switch class(data)
                case 'PointCloud'
                    settings = visualizePointCloud(obj,settings,data,scene);
                case 'Mesh'
                    settings = visualizeMesh(obj,settings,data,scene);
                case 'ObjFile'
                    settings = visualizeObjFile(obj,settings,data,scene);
                case 'VectorCloud'
                    settings = visualizeVectorCloud(obj,settings,data,scene);
                case 'Slice'
                    settings = visualizeSlice(obj,settings,data,scene);
                case 'Electrode'
                    settings = visualizeElectrode(obj,settings,data,scene);
                case 'Slicei'
                    settings = visualizeSlice(obj,settings,data,scene);
                case 'Fibers'
                    settings = visualizeFibers(obj,settings,data,scene);
                case 'Contour'
                    settings = visualizeContour(obj,settings,data,scene);
                otherwise
                    keyboard
            end
        end
        
        function changeName(obj,name)
            obj.Tag = name;
            obj.Scene.refreshLayers();
        end
        
        function export3d(obj,directoryname)
            
           
            A_writeObjFile(obj,directoryname)

        end
        
        function saveToFolder(obj,outdir)
            data = obj.Data;
%             try
            data.saveToFolder(outdir,obj.Tag);
%             catch
                %warning(['Data of type ',class(data),' cannot be saved yet. Ask Jonas'])
%             end
            Done;
            
            
        end
        
        function transform(obj,scene,varargin)
            if numel(varargin)>0
                switch varargin{1}
                    case 'lps2ras'
                        T = diag([-1 -1 1 1]);
                        obj = applyT(obj,T)
                    case 'mirror'
                        T = diag([-1 1 1 1]);
                        obj = applyT(obj,T)
                    case 'Fake2MNI'
                        T = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
                        obj = applyT(obj,T);
                    case 'T'
                        T = varargin{2};
                        obj = applyT(obj,T)
                end
            end
            
            %TO DO: THIS SWITCH SHOULD BE AVOIDED.
            %INSTEAD: DO OBJ.DATA.APPLYT() AND PUT THE METHOD IN THE DATACLASS
            function obj = applyT(obj,T)
                switch class(obj.Data)
                    case 'PointCloud'
                        v = obj.Data.Vectors.getArray;
                        if size(v,2)==1
                            v = v';
                        end
                        v_transformed = SDK_transform3d(v,T);
                        obj.Data.Vectors = v_transformed;
                        obj.updateActor(scene,obj.Visualisation.settings);
                        
                    case 'Mesh'
                        Source = obj.Data.Source;
                        [imOut,rOut] = imwarp(Source.Voxels,Source.R,affine3d(T));
                        v = obj.Data.Vertices;
                        v_transformed = SDK_transform3d(v,T);
                        obj.Data.Vertices = v_transformed;
                        newSource = VoxelData(imOut,rOut);
                        obj.Data.Source = newSource;
                        delete(obj.Visualisation.handle)
                        obj.Visualisation.handle = []; %remove old handle
                        obj.updateActor(scene,obj.Visualisation.settings);
                    case 'ObjFile'
                        v = obj.Data.Vertices;
                        v_transformed = SDK_transform3d(v,T);
                        obj.Data.Vertices = v_transformed;
                        obj.updateActor(scene,obj.Visualisation.settings);
                    case 'Electrode'
                        obj.Data.C0 = obj.Data.C0.transform(T);
                        delete(obj.Visualisation.handle)
                        obj.visualizeElectrode(obj.Visualisation.settings,obj.Data,scene)
                        
                        warning('Electrode can not be transformed like this')
                
                        
                        %obj.updateActor(scene,obj.Visualisation.settings);
                    case 'Fibers'
                        for iFiber = 1:numel(obj.Data.Vertices)
                            obj.Data.Vertices(iFiber) = obj.Data.Vertices(iFiber).transform(T);

                        end
                        obj.updateActor(scene,obj.Visualisation.settings);
                        
                    otherwise
                        
                        keyboard
                end
                
            end
            
        end
        
        function edit(obj,scene)
            question = ['Edit ',obj.Tag];
            switch class(obj.Data)
                otherwise
                    answer = questdlg(question,'Arena','change name','delete actor','cancel','cancel');
            end
            switch answer
                case 'change name'
                    newname = inputdlg('Change name','Arena',[1 40],{obj.Tag});
                    obj.Tag = newname{1};
                    scene.refreshLayers();
                case 'delete actor'
                    rusure = questdlg(['You are about to delete ',obj.Tag],'Arena','delete','cancel','cancel');
                    switch rusure
                        case 'delete'
                            delete(obj,scene)
                        case 'cancel'
                            return
                    end
                case 'change threshold'
                    keyboard
                case 'cancel'
                    return
            end
            
        end
        
        function copyobj = duplicate(obj,scene)
            copyobj = copy(obj);
            switch class(copyobj.Data)
                case 'Mesh'
                    copyobj.Data = copyobj.Data.duplicate;
                    copyobj.Visualisation.handle = copy(obj.Visualisation.handle);
                case 'Electrode'
                    for iSubPatch = 1:numel(copyobj.Visualisation.handle)
                        copyobj.Visualisation.handle(iSubPatch) = copy(copyobj.Visualisation.handle(iSubPatch));
                    end
                case 'Fibers'
                    copyobj.Data = obj.Data.duplicate;
                    copyobj.Data.ActorHandle = copyobj;
                case 'PointCloud'
                    copyobj.Visualisation.handle = copy(obj.Visualisation.handle);
                otherwise
                    copyobj.Visualisation.handle = copy(obj.Visualisation.handle);
                    %if it crashes here: make a new case for this class.
                
            end
            scene.Actors(end+1) = copyobj;
            scene.refreshLayers();
        end
        
        function delete(obj,scene)
            if nargin==1
                scene = obj.Scene;
            end
                    
            currentIndex = find(scene.Actors==obj);
            scene.Actors(currentIndex) = [];
            try
            delete(obj.Visualisation.handle)
            catch
                disp('deleted empty actor')
            end
            scene.refreshLayers();
        end
        
        function newActor = reviveInScene(obj,scene)
            newActor = scene.newActor(obj.Data,obj.Visualisation.settings);
            newActor.changeName(['* ',obj.Tag]);
            
        end
        
        function Visibility(obj,command)
            switch command
                case 'toggle'
                    obj.Visible = not(obj.Visible);
                case 'hide'
                    obj.Visible = false;
                case 'unhide'
                    obj.Visible = true;
            end
                            
        end
            
        function set.Visible(obj,value)
            obj.Visible = value;
            if value
                for iHandle = 1:numel(obj.Visualisation.handle)
                    if isstruct(obj.Visualisation.handle(iHandle))
                        obj.Visualisation.handle(iHandle).Visible = 'on';
                    elseif ishandle(obj.Visualisation.handle(iHandle))
                        set( obj.Visualisation.handle(iHandle),'Visible','on');
                    end
                end
            else
                for iHandle = 1:numel(obj.Visualisation.handle)
                    if isstruct(obj.Visualisation.handle(iHandle))
                    obj.Visualisation.handle(iHandle).Visible = 'off';
                    elseif ishandle(obj.Visualisation.handle(iHandle))
                        set( obj.Visualisation.handle(iHandle),'Visible','off');
                    end
                end
            end
        
        end
        
        function callback(obj,value)
            switch value
                case 'crop'
                    cropMesh(obj)
                case 'slice'
                    switch class(obj.Data)
                        case 'Mesh'
                            actor = obj.Data.Source.getslice.see(obj.Scene);
                            actor.changeName(obj.Tag)
                        otherwise
                            keyboard
                    end
                case 'mesh'
                    actor = obj.Data.parent.getmesh.see(obj.Scene);
                    actor.changeName(obj.Tag)
                otherwise
                    num = str2num(value);
                    if not(isempty(num))
                        feval(obj.Scene.handles.btn_updateActor.Callback,obj.Scene.handles.btn_updateActor,[])
                    end
            end
                    
        end
        
        %--- mesh callbacks
        function cropMesh(obj)
            cropwindow = ArenaCropMenu;
            
            cropwindow.load(obj);
        end
    end
end

