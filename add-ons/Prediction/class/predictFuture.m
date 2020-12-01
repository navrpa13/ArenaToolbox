classdef predictFuture<handle
    %This class is the replacement of the old Predict.m file
    %   It is in construction...
    
    % If you want to jump to specific part in the hirarchy of the functions
    % please use:
    % MAC: Cmd + f
    % Windows: Windows key + f
    % Search possebilities:
    % primary functions
    %   newPrediction
    %   closePrediction
    %   kSnapshotPrediction
    %   buttonStartSubprogramm
    % secondary functions
    %   menuImportfile 
    %   buttonStartPrediction
    %   menuSavePrediction
    
    properties
        Title
        Patient_Information
        handles
        SavePath
        VTAPoolPath
        Heatmap
        Tag
        config
        Data_In
    end
    
    properties (Hidden)
        Data_Out
        saveLoadedVTA=1
        unilateralOn=0
        bilateralOn=0
    end
    
    methods
        %------
        % all primary functions are inside here
        
        function obj = predictFuture()
            %First linking of class to variable
        end
        
        function  newPrediction(obj,pathDirectory)
            %It builds the enviroment to work on predictions
            
            % Everything which runs before the window is opened, comes
            % here...
            
            answer=questdlg('Are you sure to start a prediction?','Beginn?','Yes','No','Yes');
            if strcmp(answer,'Yes')
            else
                return;
            end
            
            obj.handles=[];
            
            if pathDirectory>0
                obj.handles.importButton.Visible='off';
            end
            obj.Data_In=pathDirectory;
            
            % All components for the window creation are inside here.
            xpos=0.15;
            ypos=0.1;
            xwidth=0.7;
            yheight=0.7;
            
            obj.handles.figure=figure('units','normalized',...
                'outerposition',[xpos ypos xwidth yheight],...
                'menubar','none',...
                'name','Prediction Enviroment',...
                'numbertitle','off',...
                'resize','off',...
                'UserData',obj,...
                'CloseRequestFcn',@closePrediction,...
                'WindowKeyPressFcn',@kSnapshotPrediction,...
                'Color',[1 1 1]);
            
            obj.handles.importButton=uicontrol('parent',obj.handles.figure,...
                'units','normalized',...
                'outerposition',[0.02 0.15 0.5 0.6],...
                'String','Import File',...
                'BackgroundColor',[0.5 0.5 0.5],...
                'FontName','Arial',...
                'FontSize',14,...
                'Visible','off',...
                'Callback',@Import);
            
            obj.handles.heatmapText=uicontrol('parent',obj.handles.figure,...
                'units','normalized',...
                'outerposition',[0.57 0.6 0.4 0.05],...
                'String','Please select a heatmap!',...
                'style','text');
            
            obj.handles.heatmapListbox=uicontrol('parent',obj.handles.figure,...
                'units','normalized',...
                'style','listbox',...
                'outerposition',[0.57 0.45 0.4 0.1],...
                'String',{'DystoniaWürzburg(gpi)','BostonBerlin(stn)','BostonAlone(stn)'},...
                'BackgroundColor',[0.5 0.5 0.5],...
                'FontName','Arial',...
                'FontSize',14,...
                'Callback',@heatmapListbox);
            
            [pic,map]=imread('glass_sphere.png');
            pic=imresize(pic,0.4);
            
            obj.handles.runButton=uicontrol('parent',obj.handles.figure,...
                'units','normalized',...
                'outerposition',[0.05 0.05 0.9 0.9],...
                'String','Press me to your Start Prediction',...
                'BackgroundColor',[0.5 0.5 0.5],...
                'FontName','Arial',...
                'FontSize',14,...
                'cdata',pic,...
                'Visible','off',...
                'Callback',@runButton);
            
            obj.handles.menu.file.main=uimenu('parent',obj.handles.figure,...
                'Text','File',...
                'ForegroundColor','black',...
                'Visible','off');
          
            obj.handles.menu.file.Sound.main=uimenu('parent',obj.handles.menu.file.main,...
                'Accelerator','A',...
                'Text','Finish Sound  (Com+A)','callback',@SoundOn); 
          
            obj.handles.menu.file.heatmap.main=uimenu('parent',obj.handles.menu.file.main,...
                'Text','Heatmap');
            %submenu for the heatmap setting
            obj.handles.menu.file.heatmapDystoniaWuerzburgMartin.main=uimenu('parent',obj.handles.menu.file.heatmap.main,...
                'Text','Dystonia Würzburg','callback',@dystoniaWuerzburgMartin);
            obj.handles.menu.file.heatmapBostonBerlin.main=uimenu('parent',obj.handles.menu.file.heatmap.main,...
                'Text','BostonBerlin','callback',@heatmapBostonBerlin);
            obj.handles.menu.file.heatmapBostonAlone.main=uimenu('parent',obj.handles.menu.file.heatmap.main,...
                'Text','BostonAlone','callback',@heatmapBostonAlone);
            
            obj.handles.menu.file.changeVTAPoolPath.main=uimenu('parent',obj.handles.menu.file.main,...
                'Text','Change VTA Pool','callback',@changeVTAPoolPath);           
            obj.handles.menu.file.SaveDirectory.main=uimenu('parent',obj.handles.menu.file.main,...
                    'Accelerator','S',...
                    'Text','Change Save Directory (Com+S)','callback',@saveFolder); 
                
            obj.handles.menu.file.BilateralOn.main=uimenu('parent',obj.handles.menu.file.main,...
                    'Text','Bilateral Prediction ','callback',@bilateralOn);

                
            if pathDirectory==0
                obj.handles.menu.file.import.main=uimenu('parent',obj.handles.menu.file.main,...
                    'Accelerator','I',....
                    'Text','Import File(Com+I)','callback',@Import);
                obj.handles.menu.file.UnilateralOn.main=uimenu('parent',obj.handles.menu.file.main,...
                    'Text','Unilateral Prediction ','callback',@unilateralOn);
                bilateralOn();
            end
            %%------
            %everything which is executed after the enviroment is built
            
                obj.handles.SoundOn=struct('value',0,'gong',0);
                obj.handles.SoundOn.value=0;
                obj.handles.menu.file.main.Visible='on';
                if obj.Data_In==0
                obj.handles.importButton.Visible='on';
                else  
                obj.handles.menu.file.import.main.ForegroundColor=[0 0.4470 0.7410];
                obj.Data_Out.Creation_Date=now;
                obj.handles.heatmapText.OuterPosition=[0.3 0.6 0.4 0.05];
                obj.handles.heatmapListbox.OuterPosition=[0.3 0.45 0.4 0.1];
                end
            
            %% -----
            %Essential function for rudiment working
            function closePrediction(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                request=questdlg('Are you sure you want to close the Prediction?','Confirmation',...
                    'Cancel','Yes','Yes');
                switch request
                    case 'Cancel'
                        return
                    case 'Yes'
                        delete(gcf);
                end
            end
            
            function kSnapshotPrediction (hObject,eventdata)
                spaceBarPressed=eventdata.Key;
                if strcmpi(spaceBarPressed,'space')
                    h=getframe(gcf);
                    text=inputdlg('Type your number of the screenshot: ');
                    name='.png';
                    text=char(text);
                    imwrite(h.cdata,['screenshot',text,name]);
                end
            end
            
            function saveFolder(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                %definition of the save path
                thisprediction.SavePath=uigetdir('/Users','Save to');
                if not(any(thisprediction.SavePath))
                    return
                end
            end
            
            function Import(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                questdlg('You can only import .dcm files!','Import',...
                    'Import','Import');
                [filename,pathname]=uigetfile('*.dcm');
                if not(any(filename))
                    warning('You did not select a file!');
                    return
                end
                thisprediction.handles.menu.file.import.main.ForegroundColor=[0 0.4470 0.7410];
                thisprediction.Data_In=fullfile(pathname,filename);
                thisprediction.Data_Out.Creation_Date=now;
                thisprediction.handles.target='gpi';
                thisprediction.handles.importButton.Visible='off';
            end
            
            function heatmapListbox(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                switch thisprediction.handles.heatmapListbox.Value
                    case 1
                        check=questdlg('Your about to run your prediction with the "Dystonia Heatmap"!','Confirm','Yes','No','Yes');
                        if strcmp(check,'Yes')
                        thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.MenuSelectedFcn(hObject,eventdata);
                        else
                            return
                        end
                    case 2
                        check=questdlg('Your about to run your prediction with the "Boston Heatmap"!','Confirm','Yes','No','Yes');
                        if strcmp(check,'Yes')
                        thisprediction.handles.menu.file.heatmapBostonBerlin.main.MenuSelectedFcn(hObject,eventdata);
                         else
                            return
                        end
                    case 3
                        check=questdlg('Your about to run your prediction with the "Boston Alone Heatmap"!','Confirm','Yes','No','Yes');
                        if strcmp(check,'Yes')
                        thisprediction.handles.menu.file.heatmapBostonAlone.main.MenuSelectedFcn(hObject,eventdata);
                         else
                            return
                        end
                end
                if strcmp(lower(thisprediction.handles.importButton.Visible),'off')  
                    thisprediction.handles.runButton.Visible='on';
                    delete(thisprediction.handles.heatmapListbox);
                    delete(thisprediction.handles.heatmapText);
                end
            end
            %% -----
            %all secondary functions are inside here
            function runButton(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                thisprediction.handles.runButton.Enable='inactive';
                
                if isempty(thisprediction.Data_In)
                    error('You did not provide the programm with the right data!');
                end
                
                if ~(strcmp(thisprediction.Data_In(end-3:end),'.dcm'))
                    warning('You selected the wrong filetype as input!!!');
                    return
                end
                
                if isempty(thisprediction.Heatmap)
                    error('No Heatmap was given! Please select one in the menu!');
                    return
                end
                
                f=uifigure;
                progress=uiprogressdlg(f,'Message','VTAs are processed!','Value',0.1);
                pause(1);
                b=buttonConnected();
                [thisprediction.handles.VTA_Information,thisprediction.Patient_Information,result] =b.VTA_Transformation(thisprediction);
                if result==0
                progress.Message='Prediction is in progress!';
                progress.Value=0.3;
                pause(1);
                [thisprediction.handles.prediction_Information.bilateral,thisprediction.handles.prediction_Information.unilateral]=b.predictionProcess(thisprediction);
                progress.Message='Prediction is finished!';
                progress.Value=0.6;
                b.saveTheData(thisprediction);
                progress.Message='Data is stored';
                progress.Value=0.8;
                b.showTheData(thisprediction);
                progress.Value=1;
                progress.Message='Finished';
                pause(1);
                if thisprediction.handles.SoundOn.value
                    % if you are not around looking on the monitor, then you
                    % can just hear it is finished
                    thisprediction.handles.SoundOn.gong=load('gong.mat');
                    gong = audioplayer(thisprediction.handles.SoundOn.gong.y, thisprediction.handles.SoundOn.gong.Fs);
                    play(gong);
                    pause(3);
                end
                delete(f);
                else
                    thisprediction.Heatmap.Name=0;
                    delete(f);
                end
                waitfor(msgbox('Your Prediction is done!'));
                delete(obj.handles.figure);
            end
            
            function SoundOn(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                if thisprediction.handles.SoundOn.value==1
                    thisprediction.handles.SoundOn.value=0;
                    thisprediction.handles.menu.file.Sound.main.ForegroundColor='black';
                else
                    thisprediction.handles.SoundOn.value=1;
                    thisprediction.handles.menu.file.Sound.main.ForegroundColor=[0 0.4470 0.7410];
                end
            end
            
            function unilateralOn(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                if thisprediction.unilateralOn==1
                    thisprediction.unilateralOn=0;
                    thisprediction.handles.menu.file.UnilateralOn.main.ForegroundColor='black';
                else
                    thisprediction.unilateralOn=1;
                    thisprediction.handles.menu.file.UnilateralOn.main.ForegroundColor=[0 0.4470 0.7410];
                end
            end
            function bilateralOn(hObject,eventdata)
                 thisprediction=predictFuture.getpredictdata(hObject);
                if thisprediction.bilateralOn==1
                    thisprediction.bilateralOn=0;
                    thisprediction.handles.menu.file.BilateralOn.main.ForegroundColor='black';
                else
                    thisprediction.bilateralOn=1;
                    thisprediction.handles.menu.file.BilateralOn.main.ForegroundColor=[0 0.4470 0.7410];
                end
            end
            function dystoniaWuerzburgMartin(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                thisprediction.Heatmap.Name='DystoniaWuerzburg';
                if thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor(1,3)==0
                    thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor=[0 0.4470 0.7410];
                    thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor='black';
                    thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor='black';
                    thisprediction.handles.target='gpi';
                else
                    thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor='black';
                    thisprediction.handles.target='';
                    thisprediction.Heatmap.Name='';
                end
                
            end
            
            function heatmapBostonBerlin(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                thisprediction.Heatmap.Name='heatmapBostonBerlin';
                if thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor(1,3)==0
                    thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor=[0 0.4470 0.7410];
                    thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor='black';
                    thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor='black';
                    thisprediction.handles.target='stn';
                else
                    thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor='black';
                    thisprediction.Heatmap.Name='';
                    thisprediction.handles.target='';
                end
            end
            
            function heatmapBostonAlone(hObject,eventdata)
                thisprediction=predictFuture.getpredictdata(hObject);
                thisprediction.Heatmap.Name='heatmapBostonAlone';
                if thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor(1,3)==0
                    thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor=[0 0.4470 0.7410];
                    thisprediction.handles.menu.file.heatmapBostonBerlin.main.ForegroundColor='black';
                    thisprediction.handles.menu.file.heatmapDystoniaWuerzburgMartin.main.ForegroundColor='black';
                    thisprediction.handles.target='stn';
                else
                    thisprediction.handles.menu.file.heatmapBostonAlone.main.ForegroundColor='black';
                    thisprediction.Heatmap.Name='';
                    thisprediction.handles.target='';
                end
            end
            function changeVTAPoolPath(hObject,eventdata)
                 waitfor(msgbox('You want to change searching path of your VTA Pool? Please choose...'));
                                thisprediction.VTAPoolPath=uigetdir;
                                VTAPoolPath=thisprediction.VTAPoolPath;
                                folder=what('Prediction');
                                save(fullfile(currentfolder.path,'/predictionConfig'),'VTAPoolPath');
            end
        end
    end


    %% This methode is used to get back at the first position in the hirarchy
    %of subclasses(parent, child):
    methods(Static)
        function thisprediction = getpredictdata(h)
            while not(isa(h.UserData,'predictFuture'))
                h = h.Parent;
            end
            thisprediction = h.UserData;
        end
    end
end

