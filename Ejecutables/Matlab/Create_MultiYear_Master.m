%==========================================================================
%                       Create multi-year master
%==========================================================================
%
%   Concatenates multiple years worth of existing master files for multi
%   year simulations to be performed. 
%
%   The 'Years' variable must be an array. and the output master filename 
%   will be of format Master[YYYY][YYYY].xls
%   for example, a master file from 2003 to 2011 will be named as
%   'Master20032011.xls'
%
%   NASA DEVELOP program 
%   contact: Jeff.Ely.08@gmail.com
%==========================================================================

function [] = Create_MultiYear_Master(root,Basin,Years)

%==========================================================================
    NewMaster=[];
    for i=Years
        NewYear=xlsread(strcat(root,'\Datos\Cuencas\',Basin,...
                '\Datos_Intermedia\Master',num2str(i),'.xls'),1,'A2:AA367');
        NewMaster=[NewMaster;NewYear];
    end
    
    % Rename the repeating julian days to completely sequential days.
    NewMaster(:,1)=1:size(NewMaster,1);
    
    % Name and create the new master file with name Master[YYYY][YYYY].xls
    name=strcat(num2str(Years(1)),num2str(Years(end)));
    
    Headers={'Day','Measured Discharge' ,'Station Precip','NASA Precip',...
        'Avg Temp' ,'Zone1', 'Zone2' ,'Zone3' ,'Zone4','Zone5',...
        'Zone6' ,'Zone7', 'Zone8' ,'Zone9','Zone10' ,'Zone11',...
        'Zone12', 'Zone13', 'Zone14', 'Zone15','DegDay' ,'RCsnow',...
        'RC_Pstations', 'RC_Pnasa','Tlapse', 'Recess_X','Recess_Y'};
    
    xlswrite(strcat(root,'\Datos\Cuencas\',Basin,....
        '\Datos_Intermedia\Master',name,'.xls'),Headers,'Sheet1','A1');
    
    xlswrite(strcat(root,'\Datos\Cuencas\',Basin,...
        '\Datos_Intermedia\Master',name,'.xls'),NewMaster,'Sheet1','A2');
   
    fprintf('Status: Created multi-year Master for %4.0f to %4.0f \n',...
        Years(1),Years(end));
end
