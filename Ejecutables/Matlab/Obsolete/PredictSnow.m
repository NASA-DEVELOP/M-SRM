function []=PredictSnow(root,Basin,year,FZS,FZW,plots)

% print status report
    fprintf('Status: Predicting SCA from day %3.0f to end of year (%4.0f)\n'...
        ,FZS,year);
    
    ProfilePath= strcat(root,'\Datos\Cuencas\',Basin,'\Parametros');
    MasterPath= strcat(root,'\Datos\Cuencas\',Basin,'\Datos_Intermedia');
    Ys=num2str(year); % the year in easy string format

% gather all the required inputs.
    input=zeros(366,15);
    temp=xlsread(strcat(MasterPath,'\Master',Ys,'.xls'),1,strcat('F2:T',num2str(FZS+1)));
    input(1:length(temp),:)=temp;
    e=length(temp);
    
    Profile=xlsread(strcat(ProfilePath,'\SCA_Profile.xls'),1,'B2:P367');
    Tproff=xlsread(strcat(ProfilePath,'\Temperature_Profile.xls'),1,'B2:B367');
    T=xlsread(strcat(MasterPath,'\Master',Ys,'.xls'),1,strcat('E2:E',num2str(FZS+1)));
    Tprojected=normrnd(Tproff,sqrt(3.1637));
    Tprojected(1:FZS)=T(1:FZS);
    
    Actual=xlsread(strcat(MasterPath,'\Master',Ys,'.xls'),1,'E2:P367');

% Fit the theoretical profile to the actual data before day_forecast    
for i=1:15
    input(:,i)=smooth(input(:,i),7);
    %find the scaling factor to match the actual profile
    for j=0:3
        Scale(j+1,i)=input(e-j,i)./Profile(e-j,i);
    end
    
    % Extrapolate the snow cover curve to find SCAprojected
        extrapolated(:,i)=mean(Scale(:,i))*Profile((e+1):end,i);
        SCAprojected(1:(e-1),i)=input(1:(e-1),i);
        SCAprojected((e+1):(e+length(extrapolated)),i)=extrapolated(:,i);
end

%==========================================================================
%                  Write ProjectedMaster file
%==========================================================================   

%saving new master file data
    Master=xlsread(strcat(MasterPath,'\Master',Ys,'.xls'),'A2:AA367');
    Master(1:365,5)=Tprojected(1:365);
    Master(1:365,6:20)=SCAprojected(1:365,:);
     
    Headers={'Day','Measured Discharge' ,'Station Precip','NASA Precip',...
        'Avg Temp' ,'Zone1', 'Zone2' ,'Zone3' ,'Zone4','Zone5',...
        'Zone6' ,'Zone7', 'Zone8' ,'Zone9','Zone10' ,'Zone11',...
        'Zone12', 'Zone13', 'Zone14', 'Zone15','DegDay' ,'RCsnow',...
        'RC_Pstations', 'RC_Pnasa','Tlapse', 'Recess_X','Recess_Y'};

    xlswrite(strcat(MasterPath,'\ProjectedMaster',Ys,'.xls'),Headers,'Sheet1','A1');
    xlswrite(strcat(MasterPath,'\ProjectedMaster',Ys,'.xls'),Master,'Sheet1','A2');
    
    disp('Status: Finished Predicting Snow Covered Area Curves!');

%==========================================================================
%                       Plots
%========================================================================== 

if plots =='y'
     SCAprojected(isnan(SCAprojected))=0;

     figure((year-2000)*10 +5);
     subplot(2,1,1);
        plot(SCAprojected(273:end,3:15));
        legend('1','2','3','4','5','6','7','8','9','10','11','12','13','14');
        title('Projected SCA Profiles');    
        axis([0 365-273 0 1]); grid on

     subplot(2,1,2);
        plot(Actual(273:end,3:11));
        legend('1','2','3','4','5','6','7','8','9','10','11','12','13','14');
        title('Actual SCA Profiles');    
        axis([0 365-273 0 1]); grid on

     figure((year-2000)*10 +2);
        subplot(2,1,1);
        plot(SCAprojected(:,3:11))
        legend('1','2','3','4','5','6','7','8','9','10','11','12','13','14');
        title('Full Projected SCA Profiles');    
        axis([0 365 0 1]); grid on

        subplot(2,1,2);
        plot(Actual(:,3:11));
        legend('1','2','3','4','5','6','7','8','9','10','11','12','13','14');
        title('Whole Actual SCA Profiles');    
        axis([0 365 0 1]); grid on
end

end



