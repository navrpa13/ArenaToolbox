classdef confidenceLevel<handle
    %CONFIDENCELEVEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        leftSide
        rightSide
        bilateral
        side
    end
    
    methods
        function obj = confidenceLevel()
            %Needs to be here...
        end
        
        function sampleToRealMNI(obj,heatmap,number)
            % The original map for creating the heatmap was constructed in
            % a wrong space, the so called legacy MNI space. That is why it
            % needs to be transformed.
            sampleToTransform=VoxelData;
            Tlegacy2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
            
            if strcmp(heatmap.Name,'DystoniaWuerzburg')
                sampleToTransform=sampleToTransform.loadnii('DystoniaMapWürzburg_forDecisionOfQuality.nii',1);
                R=sampleToTransform.R;
                R.XWorldLimits = [-7.5 7.5];
                R.YWorldLimits = [-7.5 7.5];
                I=sampleToTransform.Voxels;
                T=affine3d(Tlegacy2mni);
                [sampleToTransform.Voxels,sampleToTransform.R] = imwarp(I,R,T);
                sampleToTransform.Voxels(isnan(sampleToTransform.Voxels)) = 0;
                
                if obj.side.left==1
                    if isempty(obj.leftSide)
                        obj.leftSide.Map=sampleToTransform.Voxels;
                        obj.leftSide.Level=[];
                        obj.leftSide.Level.h10=zeros(number,1);
                        obj.leftSide.Level.h1=zeros(number,1);
                        obj.leftSide.Level.equal0=zeros(number,1);
                        obj.side.left=0;
                    end
                elseif obj.side.right==1
                    if isempty(obj.rightSide)
                        obj.rightSide.Map=sampleToTransform.Voxels;
                        obj.rightSide.Level=[];
                        obj.rightSide.Level.h10=zeros(number,1);
                        obj.rightSide.Level.h1=zeros(number,1);
                        obj.rightSide.Level.equal0=zeros(number,1);
                        obj.side.right=0;
                    end
                else
                    error('No hemisphere definition found!')
                end
            end
            
            
        end
        
        function calculationConfidenceLevel(obj,VTA,counter)
            %this is needed, because three different values which
            %correspond with the confidence level have to be found.
            %Also in one more discussion it was asked for a average value
            %of VTAs been there for one voxel when the heatmap was created.
            %This is seen as the second part for each side. 
            
            
            if not(isempty(obj.leftSide)) && obj.leftSide.Level.h10(counter,1)==0
                [MapHigherTen,MapHigherOneSmalerTen,MapZero]=obj.getMaps(obj.leftSide.Map); 
                score10=MapHigherTen(MapHigherTen==1 & VTA>0.5);
                score1=MapHigherOneSmalerTen(MapHigherOneSmalerTen==1 & VTA>0.5);
                score0=MapZero(MapZero==1 & VTA>0.5);
                VTANumber=numel(find(VTA>0.5));
                percentage10=100*numel(find(score10))/VTANumber;
                percentage1=100*numel(find(score1))/VTANumber;
                percentage0=100*numel(find(score0))/VTANumber;
                obj.leftSide.Level.h10(counter,1)=percentage10;
                obj.leftSide.Level.h1(counter,1)=percentage1;
                obj.leftSide.Level.equal0(counter,1)=percentage0;
                
                allVTAsAcounted=VTA>0.5;
                allUsedOriginVTAs=obj.leftSide.Map.*allVTAsAcounted;
                finalSum=sum(allUsedOriginVTAs,'all');
                sumOfValues=find(allVTAsAcounted);
                sumOfValues=numel(sumOfValues);
                obj.leftSide.average(1,counter)=finalSum/sumOfValues;
            end
            if not(isempty(obj.rightSide)) && obj.rightSide.Level.h10(counter,1)==0
                [MapHigherTen,MapHigherOneSmalerTen,MapZero]=obj.getMaps(obj.rightSide.Map);
                score10=MapHigherTen(MapHigherTen==1 & VTA>0.5);
                score1=MapHigherOneSmalerTen(MapHigherOneSmalerTen==1 & VTA>0.5);
                score0=MapZero(MapZero==1 & VTA>0.5);
                VTANumber=numel(find(VTA>0.5));
                percentage10=100*numel(find(score10))/VTANumber;
                percentage1=100*numel(find(score1))/VTANumber;
                percentage0=100*numel(find(score0))/VTANumber;
                obj.rightSide.Level.h10(counter,1)=percentage10;
                obj.rightSide.Level.h1(counter,1)=percentage1;
                obj.rightSide.Level.equal0(counter,1)=percentage0;
                
                allVTAsAcounted=VTA>0.5;
                allUsedOriginVTAs=obj.rightSide.Map.*allVTAsAcounted;
                finalSum=sum(allUsedOriginVTAs,'all');
                sumOfValues=find(allVTAsAcounted);
                sumOfValues=numel(sumOfValues);
                obj.rightSide.average(1,counter)=finalSum/sumOfValues;
            end
        end
        
        function [h10,h1,equal0]=getMaps(obj,Map)
            h10=Map>10;
            h1=(Map<10 & Map>1);
            equal0=Map==0;
        end
    end
end

