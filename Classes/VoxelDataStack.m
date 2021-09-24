classdef VoxelDataStack < handle
    %VOXELDATASTACK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Voxels %4D
        R
        Weights
        
    end
    
    properties(Hidden)
        Recipe
        RecipePath
        LayerLabels
        ScoreLabel
    end
    
    methods
        function obj = VoxelDataStack(Voxels,R,Weights)
            if nargin>0
                obj.Voxels = Voxels;
            end
            if nargin>1
                obj.R = R;
            end
            if nargin>2
                obj.Weights = Weights;
            end

        end
        
        function obj = newEmpty(obj,reference,n_files)
            if nargin==1
                n_files = 1;
            end
            
            obj.R = reference.R;
            obj.Voxels = zeros([size(reference.Voxels),n_files],'int8');
            obj.Weights = ones(1,n_files);
        end
        
        
        
        function obj = loadStudyDataFromRecipe(obj,recipe,templatefile)
            if nargin==1
                waitfor(msgbox('Find the recipe'))
                [filename,foldername] = uigetfile('*.xlsx','Locate the recipe');
                recipe = fullfile(foldername,filename);
                waitfor(msgbox('Find a nii that serves as template space'))
                [filename,foldername] = uigetfile('*.nii','Get template file');
                templatefile = fullfile(foldername,filename);
                
            end
            
            %load excel sheet with scores. Names should match the folders.
            obj.RecipePath=recipe;
            recipe = readtable(recipe);
            obj.Recipe = recipe;
            scoreTag = getScoreTag(recipe);
            scores = obj.Recipe.(scoreTag);
            
            %load template. This will define the voxelsize etc.
            ref = VoxelData(templatefile);
            
            %set up Stack
            obj.newEmpty(ref,length(obj.Recipe.fullpath));
            obj.ScoreLabel = scoreTag;
            
            %subfolder or one folder?
            data_is_in_subfolders = any(ismember(recipe.Properties.VariableNames,'folderID'));
            
            
            
            %Loop over the folders. All files in a folder will be merged.
            subfolders.name = 1;
            for i = 1:height(obj.Recipe)
                
                if data_is_in_subfolders
                    files = A_getfiles(obj.Recipe.fullpath{i});
                    for iFile = 1:numel(files)
                    thisFile = fullfile(obj.Recipe.fullpath{i},files(iFile).name);
                    vd = VoxelData(thisFile);
                    if any(isnan(vd.Voxels(:)))
                        vd.Voxels(isnan(vd.Voxels)) = 0;
                    end
                    
                    %Mirror to the left.
                    cog = vd.getcog;
                    if cog.x>1 && obj.Recipe.Move_or_keep_left(i)
                        vd.mirror;
                    end
                    
                    %Add subfolders together
                    if iFile==1
                        together = vd.warpto(ref).makeBinary(0.5);
                    else
                        together = together+vd.warpto(ref).makeBinary(0.5);
                    end
                    
                    end
                    obj.InsertVoxelDataAt(together,i);
                    id = obj.Recipe.folderID(i);
                else
                    vd = VoxelData(obj.Recipe.fullpath{i});
                    if any(isnan(vd.Voxels(:)))
                        vd.Voxels(isnan(vd.Voxels)) = 0;
                    end
                    
                    %Mirror to the left.
                    cog = vd.getcog;
                    if cog.x>1 && obj.Recipe.Move_or_keep_left(i)
                        vd.mirror;
                    end
                    obj.InsertVoxelDataAt(vd,i);
                    id = obj.Recipe.fileID(i);
                end

                %get the weight
                
                obj.Weights(i) = scores(i);
                obj.LayerLabels{i} = id;
            end


            function score_tag = getScoreTag(recipe)
            if length(recipe.Properties.VariableNames)==4
                score_tag = recipe.Properties.VariableNames{4};
            else
                indx = listdlg('Liststring',recipe.Properties.VariableNames(4:end));
                score_tag = recipe.Properties.VariableNames{1+indx};
            end
            end
        end
            
          
            
        
        
        function obj = InsertVoxelDataAt(obj,vd,index)
            sizeStack = size(obj.Voxels);
            if any(not(size(vd.Voxels)==sizeStack(1:3)))
                vd = vd.warpto.obj;
            end
            
            obj.Voxels(:,:,:,index) = vd.Voxels;
        end
        
        function vd = sum(obj)
            vd = VoxelData(sum(obj.Voxels,4),obj.R);
        end
        
        function binaryObj = makeBinary(obj,T)
            if nargin==1

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
            
            if nargout==1
                binaryObj = VoxelDataStack;
                binaryObj(obj.Voxels>T,obj.R,obj.Weights);
            else
                obj.Voxels = obj.Voxels>T;
            end
            
        end
        
        function vd = getVoxelDataAtPosition(obj,index)
            Voxels = obj.Voxels(:,:,:,index);
            vd = VoxelData(Voxels,obj.R);
        end
        
        function convertToLOOHeatmaps(obj,filename,description,startingFrom)
            if nargin==3
                startingFrom = 1;
            end
            
            for iLOO = startingFrom:numel(obj.Weights)
                Vloo = obj.Voxels;
                Vloo(:,:,:,iLOO) = [];
                Wloo = obj.Weights;
                Wloo(iLOO) = [];
                Rloo = obj.R;
                LOOstack = VoxelDataStack(Vloo,Rloo,Wloo);
                
                [parent,sub,fn] = fileparts(obj.LayerLabels{iLOO});
                LOOstack.convertToHeatmap(sub,description,false,filename)
                clear LOOstack
            end
            
        end
        
        function heatmap = convertToHeatmap(obj,filename,description,savememory,LOOdir)
            global arena
            if not(isfield(arena.Settings,'rootdir'))
                error('Your settings file is outdated. Please remove config.mat and restart MATLAB for a new setup')
            end
            
            if nargin<3
                error('Include the heatmapname and a short description!')
            end
            
            if nargin<4
                savememory = false;
            end
            
            if nargin==5
                LOOmode = true;
            else
                LOOmode = false;
            end

            raw.recipe = obj.Recipe;
            raw.files = obj.LayerLabels;
            [tmap,pmap,signedpmap] = obj.ttest();
            heatmap = Heatmap();
            heatmap.tmap = tmap;
            heatmap.pmap = pmap;
            heatmap.signedpmap = signedpmap;
            heatmap.raw = raw;
            heatmap.description = description;
            
            %save
            
            
        
            
            if LOOmode
                outputdir = fullfile(arena.Settings.rootdir,'HeatmapOutput',LOOdir);
                [~, ~] = mkdir(outputdir);
            else
                outputdir = fullfile(arena.Settings.rootdir,'HeatmapOutput');
            end
            save(fullfile(outputdir,[filename,'.heatmap']),'-struct','heatmap')
            
            if savememory
                %save memory file
                memory = obj;
                save(fullfile(outputdir,['memory_',filename,'.heatmap']),'memory','-v7.3')
            end
            
        end
        
        
        function [tmap,pmap,signedpmap] = ttest(obj)
            
          serialized = reshape(obj.Voxels,[],size(obj.Voxels,4));
          t_voxels = zeros([length(serialized),1]);
            p_voxels = zeros([length(serialized),1]);
            
            for i =  1:length(serialized)
                
                if any([all(serialized(i,:)),all(not(serialized(i,:)))])
                    p = 1;
                    t = 0;
                else
                [~,p,~,stat] = ttest2(obj.Weights(serialized(i,:)>0.5),obj.Weights(not(serialized(i,:)>0.5)));
                  t = stat.tstat;
                end
                t_voxels(i) = t;
                p_voxels(i) = p;
            end
          
            stacksize = size(obj.Voxels);
            outputsize = stacksize(1:3);
            signed_p_voxels = (1-p_voxels).*sign(t_voxels);
            tmap = VoxelData(reshape(t_voxels,outputsize),obj.R);
            pmap = VoxelData(reshape(p_voxels,outputsize),obj.R);
            signedpmap = VoxelData(reshape(signed_p_voxels,outputsize),obj.R);
            Done;
        end
        
        function [tmap,pmap,signedpmap] = ttest_fuckedup(obj)
            %Explanation
            %-----
            %1. Serialization
            % First the 4D array is converted to 2D. So that every voxel is
            % on a row, and the columns are filled with 1 or 0 depending if
            % it belongs to this instance or not.
            
            %2. Pointer
            % Instead of repeating the same calculations over and over, I
            % give an ID to similar voxels. This I call a pointer in this
            % context. The pointer is a decimal number based on the binary
            % combination of the voxel values. If voxel 1 contains: 
            % [0 0 1 1] then this translates to value 3. Hence all voxels
            % with this pattern will now be referred to as 3.
            
            %3. T-test
            %te test is not done for every voxel. Instead it's done for
            %every unique ID. For each existing voxelcombination the ttest
            %is performed. (testing data inside voxel against data not in
            %voxel in a two sample ttest). Then these values are applied to
            %similar voxels
            
            if length(obj.Weights)<=5
                error('Insufficient data for stats')
            end
            disp('serialize')
            serialized = reshape(obj.Voxels,[],size(obj.Voxels,4));
            serialized_pointer = convertBinaryToDecimal(serialized);
            t_voxels = zeros([length(serialized),1]);
            p_voxels = zeros([length(serialized),1]);
            
            uniquePointers = unique(serialized_pointer);
            for iPointer = 1:length(uniquePointers)
                
                thisPointer = uniquePointers(iPointer);
                disp(['Pointer: ',num2str(thisPointer)])
                original = convertDecimalToBinary(thisPointer,length(obj.Weights));
  
                if any([all(original),all(not(original))])
                    p = 1;
                    t = 0;
                else
                    [~,p,~,stat] = ttest2(obj.Weights(original),obj.Weights(not(original)));
                    t = stat.tstat;
                end
                t_voxels(serialized_pointer==thisPointer) = t;
                p_voxels(serialized_pointer==thisPointer) = p;
                
            end
            
            stacksize = size(obj.Voxels);
            outputsize = stacksize(1:3);
            signed_p_voxels = 1-p_voxels.*sign(t_voxels);
            tmap = VoxelData(reshape(t_voxels,outputsize),obj.R);
            pmap = VoxelData(reshape(p_voxels,outputsize),obj.R);
            signedpmap = VoxelData(reshape(signed_p_voxels,outputsize),obj.R);
            
            
            function out = convertDecimalToBinary(in,L)
                out = dec2bin(in)=='1';
                while length(out)<L
                    out(end+1) = 0; %extend so the length matches the number of weights
                end
            end
            function out = convertBinaryToDecimal(a)
                home;
                disp('Converting to Decimal Pointers')
                 binarylist = 2.^(0:size(a,2)-1);
                 
                 out = zeros([length(a),1],'int8');
                 index = 1;
                 stepsize = 10000000;
                 allOK = true;
                 while allOK
                     disp('*snip in pieces of 10 million voxels*')
                     endindex = min([stepsize,length(a)-index]);
                     out(index:index+endindex) = int8(single(a(index:index+endindex,:))*binarylist');
                     
                     index = index+stepsize;
                     if index > length(a)
                         allOK = false;
                     end
                     
                     
                 end
                 
            end

            end
        end
    end


