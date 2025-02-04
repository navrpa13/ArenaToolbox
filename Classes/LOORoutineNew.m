classdef LOORoutineNew < handle
    
    properties
       Weights
       PredictedWeights
       PredictedWeights_mdl
       SimilarityMethod
    end
    
    properties (Hidden)
        CleanHistograms
    end
    
    
    
    methods
        function LOOroutine()
        end
        
        
        function obj=performLOO(obj, StackedData);
           if nargin<2
                StackedData=VoxelDataStack;
                StackedData.construct(); % this will prompt the question on how to load

            else
                if ~isa(StackedData,'VoxelDataStack')
                    error(['Was expecting a VoxelDataStack as input argument instead of ',class(StackedData)])
                end
                
            end
            
             if nargin<3
                    [~,nameSuggestion] = fileparts(Stack.RecipePath);
                    [out]= inputdlg({'tag','Description'},'Need info',[1 50; 3 50],{nameSuggestion,''});
                    if isempty(out)
                        tag = 'no name';
                        description = 'no description';
                    end
                    tag = out{1};
                    description = out{2};
             end
             
             
             selectionArray=zeros(1,numel(StackedData.Weights));
             selectionArray(1)=1;
             Weights_LOO=StackedData.Weights;
             leftOut=[];
             
             
             for iLOO=1:numel(StackedData.Weights)
                 if iLOO==1
                     
                     % to be completed
                 else
                    selectionArray=shift(selectionArray,1);
                    LOO_VDS=reshape(StackedData.Voxels, [], numel(StackedData.Weights)); % just sketches of code, considering using logical indexing for 
                    leftOut=LOO_VDS(iLOO);
                    LOO_VDS(iLOO)=[];
                
       
                 end
                 
                 newStack=copy(StackedData);
                 newStack.Voxels=reshape(LOO_VDS,size(StackedData.Voxels));
                 LooHeatmap=Heatmap;
                 Heatmap.fromVoxelDataStack(newStack);
             end
             %incomplete
        end
                    
             
             
             
             
             
             
             
             
             
            function setHeatmapFolder(obj)
            obj.HeatmapFolder = uigetdir();
        end
        
        function setMemoryFile(obj)
            [filename,foldername] = uigetfile('*.heatmap');
            obj.MemoryFile = fullfile(foldername,filename);
        end
        

        function clearMemory(obj)
            obj.LoadedMemory = [];
        end
        
        function saveTraining(obj,path)
            [~ ,filename] = fileparts(obj.LoadedMemory.RecipePath);
            mdl = obj.LOOmdl;
            save(fullfile(path,['training_',filename,'.mat']),'mdl');
        end
        
        function LOOmdl = LOOregression(obj, SimilarityMethod)
            obj.loadMemory() % this is slow, so will only do it once.
            
            filenames = obj.LoadedMemory.LayerLabels;
            f = figure;
            for iFilename = 1:length(filenames)
                
                thisFilename = filenames{iFilename};
                try
                [folder,file,extension] = fileparts(thisFilename);
                catch
                    file=thisFilename;
                end
                
                disp(file)
                
                
                %load LOO set.
                LOO_heatmap = obj.loadHeatmap(file,iFilename);
                
                LOO_signedP = LOO_heatmap.Signedpmap;
                LOO_tmap = LOO_heatmap.Tmap;
                LOO_VTA = obj.LoadedMemory.getVoxelDataAtPosition(iFilename);
                
                
                %take and apply bite
                
                  ba = BiteAnalysis(obj.Heatmap.Signedpmap, VD, SimilarityMethod, obj.Heatmap.Tmap); 
                  predictors = ba.SimilarityResult
                  
                % save the sampling method used to class for record
                obj.SimilarityMethod=SimilarityMethod;
                
              
               %save predictors to object
                obj.CleanPredictors(iFilename,1:length(predictors)) = predictors;
       
                
            end
            close(f)
            
            obj.LOOmdl = fitlm(obj.CleanPredictors,obj.LoadedMemory.Weights); %Here it calculates the b (by fitting a linear model = multivariatelinearregression)
            LOOmdl = obj.LOOmdl;
        end
        
        function LOOCV(obj)
            if isempty(obj.CleanPredictors)
                error('Run .LOOregression() first!')
            end
            
            
            for i = 1:numel(obj.LoadedMemory.Weights)
                %getsubsets
                subX = obj.CleanPredictors;
                subX(i,:) = [];
                subY = obj.LoadedMemory.Weights;
                subY(i) = [];
                
                %train
                X = [ones(size(subX,1),1),subX];
                [b] = regress(subY',X);
                
                
                %predict
                LOO_x = [1,obj.CleanPredictors(i,:)];
                Prediction = LOO_x*b;
                
                %save
                obj.LOOCVpredictions(i) = Prediction;
                
            end
            %evaluate prediction
            obj.LOOCVmdl = fitlm(obj.LOOCVpredictions,obj.LoadedMemory.Weights);
            obj.LOOCVmdl
            figure; obj.LOOCVmdl.plot
            
            
            
        end
        
        
    end
    
    methods(Hidden)
        function loadMemory(obj)
            if isempty(obj.LoadedMemory)
                if not(isempty(obj.Memory))
                    switch class(obj.Memory)
                        case 'char'
                            Stack = load(obj.Memory,'-mat');
                            obj.LoadedMemory = Stack.memory;
                        case 'VoxelDataStack'
                            obj.LoadedMemory = obj.Memory;
                    end
                    
                else 
                    msgbox('Please provide memory before running the routine','error','error')
                    error('Please provide memory before running the routine');
                end
            end
        end
        
        function LOO_heatmap = loadHeatmap(obj,file,i)
            if not(isempty(obj.Heatmap))
                switch class(obj.Heatmap)
                    case 'char'
                        LOO_heatmap = load(fullfile(obj.Heatmap,[file,'.heatmap']),'-mat');
                    case 'struct'
                        LOO_heatmap.Signedpmap = obj.Heatmap.Signedpmap.getVoxelDataAtPosition(i);
                        LOO_heatmap.Tmap = obj.Heatmap.Tmap.getVoxelDataAtPosition(i);
                end
            else
                msgbox('Please provide Heatmap folder or stack','error','error')
                error('Please provide Heatmap folder or stack')
            end
        end
    end
end
