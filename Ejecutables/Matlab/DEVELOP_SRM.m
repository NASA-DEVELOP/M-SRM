%==========================================================================
%     NASA DEVELOP- Modified Implimentation of the Snowmelt Runoff Model
%==========================================================================
%
%   This script should be called through the matlab script titled 
%   'SRM_Terminal.m', or by a GUI titled GUI_English.m or GUI_Spanish.m
%
%   This modified version of the SRM model first developed by the US
%   department of agriculture has been coded for use in the Coquimbo and
%   Atacama regions of Chile as part of a NASA DEVELOP project. This model
%   has been programed to enable simulation and short range forecasting of
%   stream flow data and was delivered with all necessary information for
%   the basins of Limari, Copiapo, and Huasco.
%
%   Function Usage:
%       [TuneError,ProjError]=DEVELOP_SRM(root,Basin,...
%       year,TimelagS,TimelagP,Eref,BaseFlow,type,DegDayF,RCsnowF,RCPsF,...
%       RCPnF,TlapseF,XF,YF,Tcrit,Threshold_TRMM_Precip_Zone,Save_Output,...
%       FZS,eseg,tseg)
%
%   Variable Definitions:
%       root      =Directory where NASA_DEVELOP package is locally saved
%       Basin     =name of folder containing basin for analysis
%       year      =year to process
%       TimelagS  =Timelag according to SRM parameter manual for Snowmelt
%       TimelagP  =Timelag according to SRM parameter manual for precip
%       Eref      =Reference elevation zone (avg elevation of Temperature
%                   stations) for extrapolating T values. 
%       BaseFlow  =minimum flow rate for the simulation period
%       type      =Either 'Validate' or 'Project'. The validate option
%                   requires a complete historical record of actual flow 
%                   rates with which to tune SRM parameters. Project option
%                   should be used in the early springtime to forecast 
%                   water availability until the end of the year.
%       Tcrit     = The critical temperature to be used
%       Threshold_TRMM_Precip_Zone = the minimum elevation zone at which to
%                   use NASA measured precipitation data
%       Save_Output = either 0 or 1 to save an output file or not.
%       FZS       = The forecast Zone Start as described in the GUI
%       eseg      = The Forecast Zone Width as described in the GUI
%       tseg      = The Tuning Zone Width as described in the GUI
%
%       Mutliplicative factors for tuning:
%           DegDayF
%           RCsnowF
%           RCPsF
%           RCPnF
%           TlapseF
%           XF
%           YF
%       The tuned versions of these parameters will be saved in the output
%       file to preserve a proper record of the caculations performed.
%
%--------------------------------------------------------------------------
%
%   This implimentation of the Snowmelt Runoff model deviates from the
%   standard USDA version outlined in the SRM manual in a few key ways to
%   permit proper characterization of these uniquely dry basins and cater
%   to the data sets available. Specific deviations are outlined below.
%
%   SRM deviations:
%       Time lag: Separate time lag coefficients have been used for flow
%                   calculated from snowmelt and that from precipitation.
%                   It is theorized that snowmelt is slow enough that the
%                   majority of this flow actually becomes groundwater
%                   first. Liquid precipitation on the other hand has been
%                   observed to runoff more immediately.
%
%       Runoff coefficient: Two sources of precipitation data were used for
%                   simulation in this study. These basins are extremely
%                   steep, and observations have indicated that
%                   precipitation is several times higher in the mountains
%                   than it is in the lowlands where monitoring stations
%                   are present. TRMM data was used in lieu of better
%                   in-situ data at elevations above 2000 meters. TRMM data
%                   is not expected to be particularly accurate for this
%                   climate, but serves as a great placeholder for GPM data
%                   when it becomes available sometime in late 2014. As a
%                   result of this change, two separate runoff coefficients
%                   for each distinct set of precipitation data were used.
%
%       Baseflow: Prevents 0 flow from causing impossible recession 
%		    coefficients. All calculated flow has the value of 
%		    Baseflow added to it, thus shifting the curve up. this
% 		    is a valuable tuning parameter.
%       
%
%   NASA DEVELOP program 
%   contact: Jeff.Ely.08@gmail.com
%   version: 4/4/2014 
%==========================================================================

function [TuneError,ProjError]=DEVELOP_SRM(root,Basin,...
    year,TimelagS,TimelagP,Eref,BaseFlow,type,DegDayF,RCsnowF,RCPsF,...
    RCPnF,TlapseF,XF,YF,Tcrit,Threshold_TRMM_Precip_Zone,Save_Output,...
    FZS,eseg,tseg)

%==========================================================================
%              Retrieve and define all required model inputs
%==========================================================================

    StartFlow=BaseFlow;
    dt=clock();
    dt(6)=round(dt(6));
    date=strcat(num2str(dt(1)),'-',num2str(dt(2)),'-',num2str(dt(3)),'_',...
        num2str(dt(4)),'-',num2str(dt(5)),'-',num2str(dt(6)));
    fprintf('Status: SRM simulating! year %4.0f, type "%s" \n',year,type);
    
    Day=1;

% Load Master file for a validation type run
    if type(1)=='V'
        In=xlsread(strcat(root,'\Datos\Cuencas\',Basin,...
        '\Datos_Intermedia\Master',num2str(year),'.xls'),'Sheet1');
    
% Load Master file for a Projected type run    
    elseif type(1)=='P'
        In=xlsread(strcat(root,'\Datos\Cuencas\',Basin,...
        '\Datos_Intermedia\ProjectedMaster',num2str(year),'.xls'),'Sheet1');
    
% Display error indicating that a suitable runtype has not been entered    
    else
        error('Invalid simulation type!, must be "Validate" or "Project"');
    end
    
% Load basin elevation characteristics file, as output by Hypso.m
    E=xlsread(strcat(root,'\Datos\Cuencas\',Basin,'\Parametros\Hypso.xls'));

% load all of the tuning parameter default values
    In(:,21)=In(:,21)*DegDayF;
    In(:,22)=In(:,22)*RCsnowF;
    In(:,23)=In(:,23)*RCPsF;
    In(:,24)=In(:,24)*RCPnF;
    In(:,25)=abs(In(:,25)*TlapseF./100);
    In(:,26)=In(:,26)*XF;
    In(:,27)=In(:,27)*YF;
    
% Define time variant inputs from the master file (currently stored as 'In')
    Days=       In(:,1);            % List of days
    Qactual=    In(:,2)*1000;       % Actual flow (to liters/day)
    Pstations=  In(:,3);            % Precip Stations(cm/day)
    Pnasa=      In(:,4);            % Precip remotely sensed(cm/day)
    T=          In(:,5);            % Temperature (degC)
    SCA(:,1:15)=In(:,6:20);         % Snow Covered Area (%)                   
    
    DegDay=     In(:,21);           % Degree day factor (cm/degday)
    RCsnow=     In(:,22);           % Snowmelt runoff coeff
    RCPs=       In(:,23);           % Rain runoff coef for stations 
    RCPn=       In(:,24);           % Rain runoff coef for nasa data  
    
    Tlapse=     In(:,25);           % Temperature Lapse rate (to deg/meter)
    X =         In(:,26);           % X for recession coefficient
    Y =         In(:,27);           % Y for recession coefficient
    
% Define time invariant inputs
    A=E(:,5).*(10000/86.400);    % Areas of each zone, with adjusted units.
    Hypso=E(:,3);                % Hypsometric elevations of each zone
    
% Preliminary smoothing and sanitizing of input data
    T=smooth(T,15);
    Pnasa=smooth(Pnasa,3);
    SCA(SCA<=.0001)=0;  
    SCA(SCA>=1)=1;
    
    for z=1:15
        SCA(:,z)=smooth(SCA(:,z),7);
    end
    
    
% experimental function by which variable time lags are used between 
% elevation zones. this is imagined to be useful in basins where time lags
% are extremely high, but has not been adequately proven. Therefore it is
% recomended to be left at 'n' for forecasting purposes.

    Variable_Time_Lags='n';
    
%==========================================================================
%                     Begin simulating daily flow rate
%==========================================================================

% compute time lag parameters for each elevation zone
    HighZone=round(max(Hypso)/500+0.5);
    LowZone=HighZone-length(Hypso(Hypso~=0))+1;
    
    for j=1:15
        if j <LowZone
            Slags(j)=0;
            Plags(j)=0;
        elseif j >HighZone
            Slags(j)=0;
            Plags(j)=0;
        else
            % compute time lags as a function of elevation zone
            % (experimental)
            if Variable_Time_Lags=='y'
                Slags(j)=round((j-LowZone+1)*(TimelagS/(length(Hypso(Hypso~=0)))));
                Plags(j)=round((j-LowZone+1)*(TimelagP/(length(Hypso(Hypso~=0)))));
              
            % compute time lags as constants equal to the maximum time lag    
            elseif Variable_Time_Lags=='n'
                Slags(j)=TimelagS;
                Plags(j)=TimelagP; 
            end
                
        end
    end   

%set initial flow rate.
    Qtot(1)=StartFlow;

% begin simulating subsequent daily flows.    
    for i=1:(length(In))
        for j=1:15
        %solve for local temperature adjusted for elevation zone
            Tlocal(i,j) = T(i)-(Hypso(j)-Eref)*Tlapse(i);
            
        %Combined Precipitation which considers Tcrit
            if Tlocal(i,j)>=Tcrit
                if j>=Threshold_TRMM_Precip_Zone
                    Pn(i,j)= Pnasa(i);      % precip from nasa data
                    Ps(i,j)=0;              % precip from stations
                elseif j<Threshold_TRMM_Precip_Zone
                    Pn(i,j)=0;              % precip from nasa data
                    Ps(i,j)= Pstations(i);  % precip from stations
                end
            else 
                Pn(i,j)=0;                  % precip from nasa data
                Ps(i,j)=0;                  % precip from stations
            end
            
        %perform this elevation zones flow calculations for snow and rain
        
            if Tlocal(i,j)>=Tcrit
                Qsnow(i+1,j)=(RCsnow(i)*DegDay(i)*Tlocal(i,j)*SCA(i,j))*A(j);
            end
            Qrain(i+1,j)=(RCPs(i)*Ps(i,j) + RCPn(i)*Pn(i,j))*A(j);
        end
    end

%Step back through and offset Qsnow and Qrain by Timelag
% this code considers Snowmelt and precipitation to have separate timelags

    for i=1:(length(In)-1)
    %calculating the recession coefficient with uper limit of 1
        if (X(i)*Qtot(i)^(-Y(i)))>=1;
                k(i+1)=.95;
        else
            k(i+1)=X(i)*Qtot(i)^(-Y(i));
        end
    %Calculate Qtotal by adding the Snow and Rain flows with timelags.
    Qtot(i+1)=BaseFlow;
        for j=LowZone:HighZone
            if i>=Slags(j)
                Qtot(i+1)= Qtot(i+1) + Qsnow(i+1-Slags(j),j);
            end
            if i>=Plags(j)
                Qtot(i+1)= Qtot(i+1) + Qrain(i+1-Plags(j),j);
            end
        end

        Qtot(i+1)=Qtot(i+1)*(1-k(i+1))+Qtot(i)*k(i+1);
    end
    

  
%==========================================================================
%                   Smoothing, Error calculation
%========================================================================== 

%smooth out the profiles and calculate error ((x) day moving average)
     x=7;
     Qactual=smooth(Qactual,x);
     Qtot=smooth(Qtot,x);
     
% define segmentation range   
    Trange=(FZS-tseg):FZS;
    Prange=FZS:(FZS+eseg);

%Error in the 120 days leading up to the forecast zone
    TuneFlowSim = sum(Qtot(Trange));
    TuneFlowAct = sum(Qactual(Trange));
    TuneError   = (TuneFlowSim-TuneFlowAct)/sum(Qactual(Trange));
    
% Error in forecast range of the simulation. For actual forecasts, this is
% impossible to calculate, and so it is set to zero.
if type(1)=='V'
    ProjFlowSim = sum(Qtot(Prange));
    ProjFlowAct = sum(Qactual(Prange));
    ProjError=(ProjFlowSim-ProjFlowAct)/sum(Qactual(Prange));
elseif type(1)=='P'
    ProjFlowSim = 0;
    ProjFlowAct = 0;
    ProjError=0;
end

disp('=============================================='); 
fprintf('%s \t %4.0f \t %s \n',Basin,year,type);   
fprintf('  Results: Error in tuning zone = \t\t %2.2f %% \n',100*TuneError);
fprintf('  Results: Error in projection zone = \t %2.2f %% \n',100*ProjError);
disp('==============================================');

    Error=((Qtot-Qactual)./Qactual);

%==========================================================================
%               Plots Plots Plots Plots Plots Plots Plots!
%==========================================================================    
% find the limits of the plots to properly scale the data
    ylimit=max([max(Qtot)*1.2, max(Qactual)*1.1]);
    Plimit=max(max(Pnasa));
    
    % clears the current figure space
    figure ((year-2000)*10+1)
    clf (((year-2000)*10+1))
    
    % defines the new figure
    figure ((year-2000)*10+1) 
    
% plot relative runoffs
    subplot(3,1,1);
    hold on
        plot(Days,Qactual,'b-','LineWidth',2);
        plot(Days,Qtot,'k--','LineWidth',2);
        title(strcat('Actual flow vs Simulated Flow: ',num2str(year)));
        xlabel('Days');ylabel('Flow in Liters per second');
        hl=legend('Actual','Simulated');
        set(hl,'location','Northwest');
        
        % plot formatting and range matching
        if length(Days)>1000
            axis([length(Days)-730 length(Days) 0 ylimit]);  grid on;
        else
            axis([0 length(Days) 0 ylimit]);  grid on;
        end
        
        yL = get(gca,'YLim');
        line([FZS FZS],yL,'LineWidth',2.5,'Color','k','LineStyle',':');
        line([FZS-tseg FZS-tseg],yL,'LineWidth',2.5,'Color','k','LineStyle',':');
        line([FZS+eseg FZS+eseg],yL,'LineWidth',2.5,'Color','k','LineStyle',':');
        
        for z=1:round(length(Qtot)/365)
            line([365*z 365*z],yL,'Color','k');
        end
% plot meteorological influencers
    subplot(3,1,2);
    hold on
        plot(Days,T,'r-','LineWidth',1);
        plot(Days,5*mean(Ps(:,:)'),'b-','LineWidth',2);
        plot(Days,mean(Pn(:,:)'),'k--','LineWidth',2);
        title(strcat('Precipitation and temperature: ',num2str(year)));
        xlabel('Days');ylabel({'Precipitation in cm/day';'Temperature in C'});
        hl=legend('Temperature','Precip (stations)','Precip (NASA)');
        set(hl,'location','Northwest');
        
        % plot formatting and range matching
        if length(Days)>1000
            axis([length(Days)-730 length(Days) 0 Plimit]);  grid on;
        else
            axis([0 length(Days) 0 Plimit]);  grid on;
        end
        
        yL = get(gca,'YLim');
        line([FZS FZS],yL,'LineWidth',2.5,'Color','k','LineStyle',':');
        line([FZS-tseg FZS-tseg],yL,'LineWidth',2.5,'Color','k','LineStyle',':');
        line([FZS+eseg FZS+eseg],yL,'LineWidth',2.5,'Color','k','LineStyle',':');
        
        for z=1:round(length(Qtot)/365)
            line([365*z 365*z],yL,'Color','k');
        end
% plot snow cover curves

% reformat the way this is expressed to make code section 508 compliant for
% software release on behalf of the US government.
    lowzone=Threshold_TRMM_Precip_Zone-1;
    hizone=Threshold_TRMM_Precip_Zone;
    for i=1:length(SCA)
        wSCAlow(i)=(SCA(i,1:lowzone)*A(1:lowzone))/sum(A(1:lowzone));
        wSCAhi(i)=(SCA(i,hizone:end)*A(hizone:end))/sum(A(hizone:end));
    end    
    
% now actually plot it.
     subplot(3,1,3);
     hold on
        plot(Days,wSCAlow,'k--','LineWidth',2);
        plot(Days,wSCAhi,'b-','LineWidth',2); grid on;
        title('Snow Covered Area');
        xlabel('Days');ylabel('Snow covered area fraction');
        legcell={'Low elevations','High elevations'};
        hl=legend(legcell);
        set(hl,'location','Northwest');
        
        % plot formatting and range matching
        if length(Days)>1000
            axis([length(Days)-730 length(Days) 0 1]); 
        else 
            axis([0 length(Days) 0 1]); 
        end
        
        yL = get(gca,'YLim');
        line([FZS FZS],yL,'LineWidth',2.5,'Color','k','LineStyle',':');
        line([FZS-tseg FZS-tseg],yL,'LineWidth',2.5,'Color','k','LineStyle',':');
        line([FZS+eseg FZS+eseg],yL,'LineWidth',2.5,'Color','k','LineStyle',':');
        
        for z=1:round(length(Qtot)/365)
            line([365*z 365*z],yL,'Color','k');
        end
%==========================================================================
%                   Save output for the simulated flow.
%==========================================================================  
if Save_Output==1
    Headers={'Day','Measured Discharge' ,'Station Precip','NASA Precip',...
        'Avg Temp' ,'Zone1', 'Zone2' ,'Zone3' ,'Zone4','Zone5',...
        'Zone6' ,'Zone7', 'Zone8' ,'Zone9','Zone10' ,'Zone11',...
        'Zone12', 'Zone13', 'Zone14', 'Zone15','DegDay' ,'RCsnow',...
        'RC_Pstations', 'RC_Pnasa','Tlapse', 'Recess_X','Recess_Y',...
        'Simulated Flow','Diff','Percent error'};
    % put simulated flow in the same units as actual flow
    In(:,28)=Qtot./1000;
    % calculate error percentage
    In(:,30)=((Qtot-Qactual)./Qactual);
    % difference
    In(:,29)=(Qtot-Qactual);
    
    ParHeaders={'Type of run','Reference Elevation','Baseflow',...
        'Max time lag (Rain)','Max time lag (Snow)','__Tune: RC snow',...
        '__Tune: RC Rain (TRMM, GPM)','____Threshold TRMM zone',...
        '__Tune: RC Rain (in-situ)','Tune: Degree day','Tune: Temp lapse rate',...
        'Tune: Critical Temperature','__Tune: Recession X','__Tune: Recession Y'};
    Pars={type,Eref,BaseFlow,TimelagP,TimelagS,RCsnowF,RCPnF,...
        Threshold_TRMM_Precip_Zone,RCPsF,DegDayF,TlapseF,Tcrit,XF,YF};

    ErrEntries={' ','Tuning Zone','Forecast Zone'};
    ErrHeaders={' ','Percent Error','Sim Flow (Liters)','Actual Flow (Liters)'};
    Errs=[TuneError*100, TuneFlowSim, TuneFlowAct; ProjError*100, ProjFlowSim, ProjFlowAct];
    
    if type(1)=='V'
        OutputName=strcat(root,'/Salida/',Basin,'_',date,...
            '_Validate_',num2str(year));
    elseif type(1)=='P'
        OutputName=strcat(root,'/Salida/',Basin,'_',date,...
            '_Project(',num2str(FZS),')_',num2str(year));
    end

    xlswrite(strcat(OutputName,'.xls'),ParHeaders','Sheet1','A1');
    xlswrite(strcat(OutputName,'.xls'),Pars','Sheet1','B1');
    xlswrite(strcat(OutputName,'.xls'),ErrEntries','Sheet1','A16');
    xlswrite(strcat(OutputName,'.xls'),ErrHeaders,'Sheet1','A16');
    xlswrite(strcat(OutputName,'.xls'),Errs,'Sheet1','B17');
    xlswrite(strcat(OutputName,'.xls'),Headers,'Sheet1','A20');
    xlswrite(strcat(OutputName,'.xls'),In,'Sheet1','A21');
    
    print(figure ((year-2000)*10+1),strcat(OutputName,'.jpg'),'-djpeg85','-r600');
end
  
% Terminate SRM Function 
fprintf('Status: SRM run complete! \n');
end