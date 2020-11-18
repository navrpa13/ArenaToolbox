classdef VoxelData <handle
    %VOXELDATA contains Voxels [3D array], R [imref], can load nii.
    %   Detailed explanation goes here
    
    properties
        Voxels
        R
    end
    
    
    methods
        function obj = VoxelData(varargin)
            %VOXELDATA Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==1
                if isfile(varargin{1})
                    obj = obj.loadnii(varargin{1});
                else
                    warning(['input (',varargin{1},') is not a valid filename.. (it has to include .nii)'])
                    
                end
            elseif nargin==2
                obj.Voxels = varargin{1};
                obj.R = varargin{2};
            end
        end
        
        function savenii(obj,filename)
            
            [x,y,z] = obj.R.worldToIntrinsic(0,0,0);
            spacing = [obj.R.PixelExtentInWorldX,obj.R.PixelExtentInWorldY,obj.R.PixelExtentInWorldZ];
            origin = [x y z];
            datatype = 16;%64;
            nii = make_nii(double(permute(obj.Voxels,[2 1 3])), spacing, origin, datatype);
            save_nii(nii,filename);
        end
        
        function obj = importSuretuneDataset(obj,dataset)
            if isa(dataset,'Dataset')
                volume = dataset.volume;
            elseif isa(dataset,'Volume')
                volume = dataset;
            end
            
            a = 1;
            b = 2;
            c = 3;
            info = volume.volumeInfo;
            voxels = permute(volume.voxelArray,[2 1 3]);
            R = imref3d(info.dimensions([2 1 3]),info.spacing(a),info.spacing(b),info.spacing(c));
            R.XWorldLimits = R.XWorldLimits+info.origin(a)-info.spacing(a);%-Rfrom.ImageExtentInWorldX;
            R.YWorldLimits = R.YWorldLimits+info.origin(b)-info.spacing(b);%-Rfrom.ImageExtentInWorldY;
            R.ZWorldLimits = R.ZWorldLimits+info.origin(c)-info.spacing(c);
            obj.Voxels = voxels;
            obj.R = R;
        end
        
        function obj = crop(obj,leftdown,rightup)
            if not(isa(leftdown,'Vector3D'))
                leftdown = Vector3D(leftdown);
                rightup = Vecgtor3D(rightup);
            end
            
        %get the voxelindices at boundingbox edges
        [ldy,ldx,ldz] = obj.R.worldToSubscript(min([leftdown.x,rightup.x]),min([leftdown.y,rightup.y]),min([leftdown.z,rightup.z]));  
        [ruy,rux,ruz] = obj.R.worldToSubscript(max([leftdown.x,rightup.x]),max([leftdown.y,rightup.y]),max([leftdown.z,rightup.z]));
        
        %crop voxels
        v  = obj.Voxels(ldy:ruy,ldx:rux,ldz:ruz);
        
        %make new imref
        new_x_span = [obj.R.XWorldLimits(1)+obj.R.PixelExtentInWorldX*ldx,...
            obj.R.XWorldLimits(1)+obj.R.PixelExtentInWorldX*(rux+1)];
        
        new_y_span = [obj.R.YWorldLimits(1)+obj.R.PixelExtentInWorldY*ldy,...
            obj.R.YWorldLimits(1)+obj.R.PixelExtentInWorldY*(ruy+1)];
        
        new_z_span = [obj.R.ZWorldLimits(1)+obj.R.PixelExtentInWorldZ*ldz,...
            obj.R.ZWorldLimits(1)+obj.R.PixelExtentInWorldZ*(ruz+1)];

        sz = size(v);
        newR = imref3d(sz,new_x_span,new_y_span,new_z_span);
        
        
        %save
            
            if nargout==1 %make a copy (default is overwrite)
                obj = CroppedVoxelData(obj.Voxels,obj.R,leftdown,rightup,obj);
            end
              obj.Voxels = v;
              obj.R = newR;
             

        end
        
        function cropped = convertToCropped(obj)
            leftdown = Vector3D([obj.R.XWorldLimits(1),...
                obj.R.YWorldLimits(1),...
                obj.R.ZWorldLimits(1)]);
             rightup = Vector3D([obj.R.XWorldLimits(2),...
                obj.R.YWorldLimits(2),...
                obj.R.ZWorldLimits(2)]);
            cropped = CroppedVoxelData(obj.Voxels,obj.R,leftdown,rightup,obj);
        end
        
        
        function [obj,filename] = loadnii(obj,niifile,noreslice)

            if nargin==1
                [filename,pathname] = uigetfile('*.nii','Find nii image');
                if filename==0
                    return
                end
                niifile = fullfile(pathname,filename);
            elseif nargin==2
                noreslice = 0;
            elseif nargin==3
                if ischar(noreslice)
                    switch lower(noreslice)
                        case 'true'
                            noreslice = 1;
                        case 'false'
                            noreslice = 0;
                        otherwise
                            error('cannnot interpret if I should reslice or not, please use 0 or 1')
                    end
                end
            else
                [~,filename] = fileparts(niifile);
            end
            
            if not(contains(niifile,'.nii'));error('input has to be a nifti file');end
            
            tempname = [datestr(datetime('now'),'yyyymmddhhMMss'),'.nii'];
            
            if noreslice %for heatmaps: reslicing might alter voxelvalues slightly. 
                warning('Reslicing is turned off.')
                loadednifti = load_nii(niifile);
            else %reslicing might change your data slightly, but rotates the data when a rotation is saved in the header. 
                    % reslicing is recommended for normal use.
                reslice_nii(niifile,fullfile(tempdir,tempname));
                loadednifti = load_nii(fullfile(tempdir,tempname));
                delete(fullfile(tempdir,tempname));
            end
            
            obj.Voxels = permute(loadednifti.img,[2 1 3]);
            
            dimensions = loadednifti.hdr.dime.dim(2:4);
            voxelsize = loadednifti.hdr.dime.pixdim(2:4);
            transform = [loadednifti.hdr.hist.srow_x;...
                loadednifti.hdr.hist.srow_y;...
                loadednifti.hdr.hist.srow_z;...
                0 0 0 1];
            
            
            
            % make imref
            Ref = imref3d(dimensions([2 1 3]),voxelsize(1),voxelsize(2),voxelsize(3));
            Ref.XWorldLimits = Ref.XWorldLimits+transform(1,4)-voxelsize(1);
            Ref.YWorldLimits = Ref.YWorldLimits+transform(2,4)-voxelsize(2);
            Ref.ZWorldLimits = Ref.ZWorldLimits+transform(3,4)-voxelsize(3);
            
            obj.R = Ref;
            
        end
        
        function [bool, percentage_nonbinary] = isBinary(obj,slack)
            if nargin==1
                %default slack is 0%
                slack = 0;
            end
            v = obj.Voxels;
            high = v==max(v(:));
            low = v==min(v(:));
            
            inbetween = not(or(high,low));
            percentage_nonbinary = sum(inbetween(:))/numel(v(:))*100;
            
            if percentage_nonbinary <= slack
                bool = true;
            else
                bool = false;
            end
            
            
        end
        
        function showprojection(o1,view)
            
            [i,j,k] = o1.R.worldToIntrinsic(0,0,0);
            Origin_vxl = round([i,j,k]);
            if nargin == 1;view = 'a';end
            switch lower(view)
                case {'sagittal','s','sag'}
                    slice = squeeze(sum(o1.Voxels,2))';
                    origin_index = [2,3];
                case {'coronal','c','cor'}
                    slice = squeeze(sum(o1.Voxels,1))';
                    origin_index = [1,3];
                case {'axial','a','ax','axi'}
                    slice = sum(o1.Voxels,3);
                    origin_index = [1,2];
            end
            figure;imshow(slice/max(slice(:)));
            hold on
            scatter(Origin_vxl(origin_index(1)),Origin_vxl(origin_index(2)),'r','filled')
            ax = gca;
            ax.YDir = 'normal';
            
        end
        
        function showorigin(obj,view)
            [i,j,k] = obj.R.worldToIntrinsic(0,0,0);
            Origin_vxl = round([i,j,k]);
            if nargin == 1;view = 'a';end
            switch lower(view)
                case {'sagittal','s','sag'}
                    slice = squeeze(obj.Voxels(:,Origin_vxl(1),:))';
                    origin_index = [2,3];
                case {'coronal','c','cor'}
                    slice = squeeze(obj.Voxels(Origin_vxl(2),:,:))';
                    origin_index = [1,3];
                case {'axial','a','ax','axi'}
                    slice = obj.Voxels(:,:,Origin_vxl(3));
                    origin_index = [1,2];
            end
            figure;imshow(slice/max(slice(:)));
            hold on
            scatter(Origin_vxl(origin_index(1)),Origin_vxl(origin_index(2)),'r','filled')
            ax = gca;
            ax.YDir = 'normal';
        end
        
        function meshobj = getmesh(obj,T)
            if nargin==2
                meshobj = Mesh(obj,T);
            else
                meshobj = Mesh(obj);
            end
        end
        
        function sliceobj = getslice(obj)
            sliceobj = Slicei;
            sliceobj.getFromVoxelData(obj);

%             if nargin>1
%                 sliceobj = Slice(obj,x,y,z);
%             else
%                 sliceobj = Slice(obj);
%             end
        end
        
        function o3 = and(o1,o2)
            
            img1 = o1.Voxels;
            img2 = o2.Voxels;
            
            if not(islogical(img1))
                error('input 1 should be binary')
            end
            if not(islogical(img2))
                error('input 2 should be binary')
            end
            
            o3 = VoxelData(and(img1,img2),o1.R);
        end
        
        function o3 = times(o1,o2)
            img1 = o1.Voxels;
            if isa(o2,'VoxelData')
                img2 = o2.Voxels;
                o3 = VoxelData(img1.*img2,o1.R);
            else %assuming o2 is a number
                o3 = VoxelData(img1*o2,o1.R);
            end
            
            
            
        end
        
        function o3 = minus(o1,o2)
            img1 = o1.Voxels;
            img2 = o2.Voxels;
            
            o3 = VoxelData(img1-img2,o1.R);
        end
        
        function o3 = plus(o1,o2)
            img1 = o1.Voxels;
            img2 = o2.Voxels;
            
            o3 = VoxelData(img1+img2,o1.R);
        end
        
        function vd_out = abs(vd)
            if nargout==1
                vd_out = VoxelData(abs(vd.Voxels),vd.R);
            else
                vd.Voxels = abs(vd.Voxels);
                vd_out =  vd;
            end
        end
        
        function vd_out = changeToNan(vd,value)
            if nargout==1
                vd_out = VoxelData(vd.Voxels,vd.R);
                vd_out.Voxels(vd_out.Voxels==value) = nan;
            else
                vd.Voxels(vd.Voxels==value) = nan;
                vd_out = vd;
            end
            
                
        end
        
        function value = dice(o1,o2)
            value = dice(o1.Voxels>0,o2.Voxels>0);
        end
        
        
        function center_of_gravity = getcog(obj)
            [yq,xq,zq] = meshgrid(1:size(obj.Voxels,2),...
                1:size(obj.Voxels,1),...
                1:size(obj.Voxels,3));
            
            xm = xq(:)'*double(obj.Voxels(:)) / sum(obj.Voxels(:));
            ym = yq(:)'*double(obj.Voxels(:)) / sum(obj.Voxels(:));
            zm = zq(:)'*double(obj.Voxels(:)) / sum(obj.Voxels(:));
            
            center_of_gravity_internal = [ym,xm,zm];
            [x,y,z] = obj.R.intrinsicToWorld(center_of_gravity_internal(1),center_of_gravity_internal(2),center_of_gravity_internal(3));
            center_of_gravity = Vector3D([x,y,z]);
        end
        
        function [x_coords,y_coords,z_coords] = getlinspace(obj)
            v = obj.Voxels;
                    %squeeze the data into one dimension
            v_x = sum(sum(v,3),1);
            v_y = sum(sum(v,3),2);
            v_z = squeeze(sum(sum(v,2),1));
            
            %convert the voxel locations to worldlocations
             [firstX,firstY,firstZ] = obj.R.intrinsicToWorld(1,1,1);
             [lastX,lastY,lastZ] = obj.R.intrinsicToWorld(length(v_x),length(v_y),length(v_z));
             
             %define the x-axis values
             x_coords = linspace(firstX,lastX,length(v_x));
             y_coords = linspace(firstY,lastY,length(v_y));
             z_coords = linspace(firstZ,lastZ,length(v_z));
        end
        
        function [fwhm,f] = getDensityDistribution(obj)
            v = obj.Voxels;
            
            %squeeze the data into one dimension
            v_x = sum(sum(v,3),1);
            v_y = sum(sum(v,3),2);
            v_z = squeeze(sum(sum(v,2),1));
            
            %convert the voxel locations to worldlocations
             [firstX,firstY,firstZ] = obj.R.intrinsicToWorld(1,1,1);
             [lastX,lastY,lastZ] = obj.R.intrinsicToWorld(length(v_x),length(v_y),length(v_z));
             
             %define the x-axis values
             x_coords = linspace(firstX,lastX,length(v_x));
             y_coords = linspace(firstY,lastY,length(v_y));
             z_coords = linspace(firstZ,lastZ,length(v_z));
             
             %interpolate
             xCi = linspace(firstX,lastX,length(v_x)*10);
             yCi = linspace(firstY,lastY,length(v_y)*10);
             zCi = linspace(firstZ,lastZ,length(v_z)*10);
             
             xVi = interp1(x_coords,v_x,xCi,'pchip');
             yVi = interp1(y_coords,v_y,yCi,'pchip');
             zVi = interp1(z_coords,v_z,zCi,'pchip');
            
             %plot
            f = figure; hold on
            set(f,'DefaultLineLineWidth',2)
            p = plot(xCi,xVi,'r',yCi,yVi,'g',zCi,zVi,'b');
            
            
            
            %find the xlim (to only include data >0)
            minCoord = min([xCi(find(xVi>0,1,'first')),...
                yCi(find(yVi>0,1,'first')),...
               zCi(find(zVi>0,1,'first'))]);
           
           maxCoord = max([xCi(find(xVi>0,1,'last')),...
                yCi(find(yVi>0,1,'last')),...
               zCi(find(zVi>0,1,'last'))]);
           
           xlim([minCoord,maxCoord])
           legend({'x','y','z'})
           
           %FWHM
           x_1 = xCi(find(xVi>max(xVi)/2,1,'first'));
           x_2 = xCi(find(xVi>max(xVi)/2,1,'last'));
           
           y_1 = yCi(find(yVi>max(yVi)/2,1,'first'));
           y_2 = yCi(find(yVi>max(yVi)/2,1,'last'));
           
           z_1 = zCi(find(zVi>max(zVi)/2,1,'first'));
           z_2 = zCi(find(zVi>max(zVi)/2,1,'last'));
           
           patch([x_1 x_1 x_2 x_2],[0 max(xVi)/2 max(xVi)/2 0],'red','FaceAlpha',0.4);
           patch([y_1 y_1 y_2 y_2],[0 max(yVi)/2 max(yVi)/2 0],'green','FaceAlpha',0.4);
           patch([z_1 z_1 z_2 z_2],[0 max(zVi)/2 max(zVi)/2 0],'blue','FaceAlpha',0.4);
           
           legend({'x','y','z','FWHM x','FWHM y','FWHM z'})
           
           %output
           fwhm.x = x_2-x_1;
           fwhm.y = y_2-y_1;
           fwhm.z = z_2-z_1;
           fwhm.xrange = [x_1 x_2];
           fwhm.yrange = [y_1 y_2];
           fwhm.zrange = [z_1 z_2];  
           fwhm.xCi = xCi;
           fwhm.yCi = yCi;
           fwhm.zCi = zCi;
           fwhm.xVi = xVi;
           fwhm.yVi = yVi;
           fwhm.zVi = zVi;
           
           
        end
            
            
            
        
        function see(obj)
            disp('This funnction does not exist. Use [].getmesh.see instead')
        end
        
        function Points = detectPoints(obj)
            bw = obj.Voxels>25;
            [labels,n] = bwlabeln(bw);
            Points = Vector3D.empty;
            for iL = 1:n
                [x,y,z] = ind2sub(size(obj.Voxels),find(labels==iL));
                [xw,yw,zw] = obj.R.intrinsicToWorld(y,x,z);
                Points(iL) = Vector3D(mean(xw),mean(yw),mean(zw));
            end
            
            
        end
        
        function newobj = warpto(obj,target,T)
            if nargin==2
                T = affine3d(eye(4));
            end
            
            if isa(target,'VoxelData')
                R = target.R;
            elseif isa(target,'imref3d')
                R = target;
            else
                error('input requirments: obj, target, T')
            end
            
            newVoxels = imwarp(double(obj.Voxels),obj.R,T,'OutputView',R);
            
            %restore binary data if it was binary
            if islogical(obj.Voxels)
                newVoxels = newVoxels>0.5;
            end
            
            if nargout==1
               newobj = VoxelData(newVoxels,R);
            else
                obj.Voxels = newVoxels;
                obj.R = R;
            end
        end
        
        function newObj = imwarp(obj,T)
            if nargin ==1
                T = affine3d(eye(4));
            end
            if and(not(isa(T,'affine3d')),numel(T==16))
                T = round(T,6);
                try
                    T = affine3d(T);
                catch
                    T = affine3d(T');
                end
            end
            
            obj.Voxels(isnan(obj.Voxels))= 0;
            
            if nargout==0
                disp('Transformation is applied on original object')
                [obj.Voxels,obj.R] = imwarp(obj.Voxels,obj.R,T);
            else
                 disp('Transformation is applied on new object')
                [Voxels,R] = imwarp(obj.Voxels,obj.R,T);
                newObj = VoxelData(Voxels,R);
            end
        end
        
        function newObj = mirror(obj)
            
            [imOut,rOut] = imwarp(obj.Voxels,obj.R,affine3d(diag([-1 1 1 1])));
            
            if nargout==1
                newObj = VoxelData(imOut,rOut);
            else
                newObj = obj;
                newObj.Voxels = imOut;
                newObj.R = rOut;
            end
            
        end
        
        function binaryObj = makeBinary(obj,T)
            if nargin==1
                
                if obj.isBinary
                    T = 0.5;
                else
                        %ask for user input
                    histf = figure;histogram(obj.Voxels(:),50);
                    set(gca, 'YScale', 'log')
                    try
                        [T,~] = ginput(1);
                    catch
                        error('user canceled')
                    end
                    close(histf)
                end
            end
            
            if nargout==1
                binaryObj = VoxelData(obj.Voxels>T,obj.R);
            else
                obj.Voxels = obj.Voxels>T;
            end
        end
        
        function [CubicMM,voxelcount] = getCubicMM(obj,T)
            if not(all(islogical(obj.Voxels)))
                if nargin==1
                    obj = makeBinary(obj);
                elseif nargin==2
                    obj = makeBinary(obj,T);
                end
            end
            
            voxelsBW = obj.Voxels;
            voxelcount = sum(double(voxelsBW(:)));
            voxelsize = obj.R.PixelExtentInWorldX * obj.R.PixelExtentInWorldY * obj.R.PixelExtentInWorldZ;
            CubicMM = voxelcount * voxelsize;
            
        end
        
        
        function [cellarray, scalaroutput,sizelist] = seperateROI(obj)
            cellarray = {};
            v = obj.Voxels;
            
            if not(islogical(v))
                v_bw = v > 0;
            else
                v_bw = v;
            end
            
            [L,n] = bwlabeln(v_bw);
            
            sizelist = [];
            for i = 0:n
                region = (L==i);
                sizelist(i+1) = sum(region(:));
                region = int16(region);
                region_voxeldata = VoxelData(region,obj.R);
                cellarray{i+1} = region_voxeldata;
            end
            
            scalaroutput = VoxelData(L,obj.R);
            
            
        end
        
        function saveToFolder(obj,outdir,tag)
            savenii(obj,fullfile(outdir,[tag,'.nii']))
        end
        
        function obj_out=smooth(obj,size,sd)
             if nargin==1
                    v = smooth3(obj.Voxels);
             elseif nargin==2
                 v = smooth3(obj.Voxels,size);
             elseif nargin==3
                 v = smooth3(obj.Voxels,size,sd);
             end
             
             if nargout==1
                 obj_out = VoxelData(v,obj.R);
             else
                 obj.Voxels = v;
                 obj_out = obj;
             end
            
        end
        
        function whatis(obj)
            disp('VOXELDATA')
            disp('---------')
            whatis(obj.Voxels)
        end
        
    end
end

