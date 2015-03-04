%==========================================================================
%       Terminal by which the other scripts can be easily controled
%==========================================================================
clear all; clc; close all;

%==========================================================================
%                               User Inputs
%==========================================================================

% specify the Root directory in which these scripts are stored.
    Root='C:\Users\jwely\NASA_DEVELOP_TESTBED';
    Basin='Coquimbo_Limari';

% specify the desired year(s) to simulate
    years=20032011;
    
% specify which steps of the computing process need to be redone.
% a value of 'y' will execute that step.

 ExecuteHypso=              'n';
 ExecuteSnowcover=          'n';   
 ExecuteTotDischarge=       'n';   
 ExecuteAvgTemp=            'n';     
 ExecuteAvgPrecip=          'n';  

 ExecuteCreateMaster=       'n';    % Only one of these can be yes!
 ExecuteMultiYearMaster=    'y';    % Only one of these can be yes!
 ExecuteCreateProfiles =    'n';    % Must be done before Predictions! 
                                        % and must use many years!
    Years =                 2003:2011;
 
 ExecutePredictSnow =       'n';
  ForecastStartDate =       260;
  
 ExecuteMasterSRM=          'y';
 ExecuteProjectedSRM=       'n';  
    Eref =                  1240;  %1330 coquimbo, 1283 Huasco, 1240 Limari
    BaseFlow =              200;
    TimelagS =              1; 	
    TimelagP =              1;   
    DegDayF =               1;
    RCsnowF =               1;
    RCPsF =                 1;
    RCPnF =                 1;
    TlapseF =               1;
    XF =                    0.95;
    YF =                    0.1;
    Tcrit =                -2.0;
%==========================================================================
%                        Execute functions
%========================================================================== 
ScriptsPath=strcat(Root,'\Ejecutables\MatLab');
cd(ScriptsPath);   
fprintf('Set working directory to \n (%s) \n\n',Root);

i=1;
for year=years
    
    fprintf('\n ---Begin year %4.0f--- \n\n',year);

% Using Txt file from arcswat, create basin characteristic file
     if ExecuteHypso=='y'
        Hypso(Root,Basin);
        cd(ScriptsPath);
     end
    
% Create Snowcovered area inputs for SRM for given year   
    if ExecuteSnowcover=='y'
        SnowCoveredArea(Root,Basin,year);
        cd(ScriptsPath);
    end

% Convert DGA_formated Download data into 
    if ExecuteTotDischarge=='y'
        TotalDischarge(Root,Basin,year);
    end
    
    if ExecuteAvgTemp=='y'
        AvgTemp(Root,Basin,year);
    end
    
    if ExecuteAvgPrecip=='y'
        AvgPrecip(Root,Basin,year);
    end
    
    if ExecuteCreateMaster=='y'
        CreateMaster(Root,Basin,year);
    end
    
    if ExecuteMultiYearMaster=='y'
        Create_MultiYear_Master(Root,Basin,Years);
    end
    
    if ExecuteCreateProfiles =='y'
        Create_Profiles(Root,Basin,Years);
    end
    
    if ExecutePredictSnow =='y'
        PredictSnow(Root,Basin,year,ForecastStartDate,'y');
    end
   
    if ExecuteMasterSRM=='y'
        [a,Q,Qsnow,Qrain]=DEVELOP_SRM(Root,Basin,year,...
            TimelagS,TimelagP,Eref,BaseFlow,'Validate',DegDayF,RCsnowF...
            ,RCPsF,RCPnF,TlapseF,XF,YF,Tcrit)
        Error(1:365,i)=a(1:365);
    end
    
    if ExecuteProjectedSRM=='y'
        [c d]=DEVELOP_SRM(Root,Basin,year,...
            TimelagS,TimelagP,Eref,BaseFlow,'Project',DegDayF,RCsnowF...
            ,RCPsF,RCPnF,TlapseF,XF,YF,Tcrit)
        ErrorProj(1:365,i)=c(1:365); QProj(1:365,i)=d(1:365);
    end
    
    i=i+1;
end

if or(ExecuteMasterSRM=='y',ExecuteProjectedSRM=='y')
    
    if length(years)>=2
        Eavg=mean(Error');
        EPavg=mean(ErrorProj');
        Estd=std(Error');
        EPstd=std(ErrorProj');
        
        figure(1); hold off;
        plot(1:365,EPavg,'b-','LineWidth',3); grid on; hold on;
        plot(1:365,Eavg,'r-','LineWidth',3);
        legend('Measured Inputs','Forecasted Inputs');
        plot(1:365,Error,'c-',1:365,ErrorProj,'y'); 
        plot(1:365,EPavg,'b-','LineWidth',3);
        plot(1:365,Eavg,'r-','LineWidth',3);
        
        Meanstd=mean(std(Error'))
        MeanError=mean(Eavg)

        correction=1./Eavg';

        figure(2); hold off;
        plot(1:365,correction);
    else
        % figure(1); hold off;
        % plot(1:365,Error,1:365,ErrorProj); hold on; grid on
        % legend('Measured input','Partialy forecasted inputs');
        
    end

end
%correction=zeros(length(correction),1)+1;
%oldcorrection=zeros(length(correction),1)+1;
%oldcorrection=xlsread('ErrorCorrectionFactor.xls');
%xlswrite('ErrorCorrectionFactor.xls',correction.*oldcorrection);


