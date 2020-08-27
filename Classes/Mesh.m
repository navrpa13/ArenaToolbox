classdef Mesh < handle & matlab.mixin.Copyable
    %MESH Contains Faces and Vertices. Can be initialised with VoxelData
    
    properties
        Faces
        Vertices
        Settings
        Source
    end
    
    methods
        function obj = Mesh(varargin)
            %MESH Construct an instance of this class
            %   Detailed explanation goes here
                if nargin==0
                    return
                end
                if isa(varargin{1},'VoxelData')
                    obj.getmeshfromvoxeldata(varargin);
                    obj.Source = varargin{1};
                %if isa(varargin{1}
                elseif isa(varargin{1},'double')
                        obj.Faces = varargin{1};
                        obj.Vertices = varargin{2};
                        obj.Source = [];
                        obj.Settings = [];
                end
            end
        
        
        function obj = getmeshfromvoxeldata(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            varargin = varargin{1}; %get rid of double nesting
            VoxelData= varargin{1};
            if numel(varargin)==1
                T = obj.uithreshold(VoxelData.Voxels);
            else
                T = varargin{2};
            end
             disp('Arena Mesh: computing...')
             [X,Y,Z] = A_imref2meshgrid(VoxelData.R);
             [obj.Faces, obj.Vertices] = isosurface(X,Y,Z,VoxelData.Voxels,T);
             obj.Settings.T = T;
        end
        
        
        
        function copyobj = duplicate(obj)
            copyobj = copy(obj);
        end
            
        function T = uithreshold(obj,Voxels)
            histf = figure;histogram(Voxels(:),50);  
            set(gca, 'YScale', 'log')
            try
                figure(histf)
                [T,~] = ginput(1);
            catch
                error('user canceled')

            end
            close(histf)
            
        end
        
        
        
        function [thisActor,thisScene] = see(obj, sceneobj)
            global arena
            if nargin==1
                if isempty(arena)
                    evalin('base','startArena');
                    thisScene = arena.sceneselect(1);
                else
                    thisScene = arena.sceneselect();
                end
            else
                thisScene = sceneobj;
            end
            
            if isempty(thisScene);return;end %user cancels
            thisActor = thisScene.newActor(obj)
            
%             figure;
%             p= patch('Faces',obj.Faces,'Vertices',obj.Vertices);
%             
%             p.FaceColor = [0.3 0.6 0.8];
%             p.EdgeColor = 'none';
%             daspect([1 1 1])
%             view(3);
%             axis tight
%             camlight
%             lighting gouraud
        end
        
        function cog = getCOG(obj)
            try
            cog = PointCloud(obj.Vertices).getCOG;
            catch
            cog = Vector3D([nan nan nan]);
            end
        end
        
        function saveToFolder(obj,outdir,tag)
            %save obj, voxeldata and thresholded voxeldat
            if nargin==1
                [file,outdir] = uiputfile('*.obj');
                filepath = fullfile(outdir,file);
                tag = file(1:end-4);
            elseif nargin==2
                tag = newid;
                filepath = fullfile(outdir,[tag,'*.obj']);
            elseif nargin==3
                filepath = fullfile(outdir,[tag,'*.obj']);
            else
                return
            end
                
            %OBJ
            vertface2obj(obj.Vertices,obj.Faces,fullfile(outdir,[tag,'.obj']));
            
            %VoxelData
            obj.Source.saveToFolder(outdir,tag);
            
            %Binary
            obj.Source.makeBinary(obj.Settings.T).saveToFolder(outdir,[tag,'_binary']);
            
            
            
        end
            
     
    end
end

