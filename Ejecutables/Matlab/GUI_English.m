%%=======================================================================%%
%          Graphical User Interface for Chile Water resources project
%                             Version 4/4/2014
%%=======================================================================%%

%==========================================================================
%               Begin initialization code - DO NOT EDIT
%==========================================================================
function varargout = GUI_English(varargin)
clc
disp('===========================================');
disp('Initializing Graphical User Interface (GUI)');
disp('===========================================');
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_English_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_English_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if  nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end

% Executes just before GUI_English is made visible.
    function GUI_English_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    guidata(hObject, handles);

% Outputs from this function are returned to the command line.
    function varargout = GUI_English_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

%==========================================================================
%                  Begin Defining Fields and buttons
%==========================================================================

%%=====================Root=============================%%%
function Root_Callback(hObject, eventdata, handles)
function Root_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%=================BASIN================%%
function Basin_Callback(hObject, eventdata, handles)
function Basin_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end


%%=======================Year====================%%
function Year_Callback(hObject, eventdata, handles)
function Year_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%=====================PROCESS DGA DOWNLOADS==========================%%
% --- Executes on button press that depicts "Process DGA Downloads".
function ProcessDGA_Callback(hObject, eventdata, handles) 
  Root = get(handles.Root, 'String');
  basin = get(handles.Basin, 'String'); 
  year = str2num(get(handles.Year, 'String')); 
  TotalDischarge(Root,basin,year);         
  AvgTemp(Root,basin,year);        
  AvgPrecip(Root,basin,year); 

%%=======================CREATE MASTER============================%%
%this creates master files for the Root basin and year that are inputed
function createMaster_Callback(hObject, eventdata, handles)
Root = get(handles.Root, 'String');
basin = get(handles.Basin, 'String'); 
year = str2num(get(handles.Year, 'String')); 
CreateMaster(Root,basin,year);

%%=====================EREF TEXTBOX========================%%
function Eref_Callback(hObject, eventdata, handles)
function Eref_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%========================BASE FLOW TEXTBOX=============================%%
function baseFlowTxt_Callback(hObject, eventdata, handles)
function baseFlowTxt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%======================TLAG PERCIPITATION TEXTBOX=======================%%
function TlagPercipTxt_Callback(hObject, eventdata, handles)
function TlagPercipTxt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%==========================TLAG SNOWMELT TEXTBOX========================%%
function TlagSnowmelt_Callback(hObject, eventdata, handles)
function TlagSnowmelt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%=================RUNOFF COEFFICIENT SNOW TEXTBOX=======================%%
function runoffCoefSnow_Callback(hObject, eventdata, handles)
function runoffCoefSnow_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%===============Runoff Coefficient Percip from NASA TEXTBOX=============%%
function RCPn_Callback(hObject, eventdata, handles)
function RCPn_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%========================RCPS TEXTBOX=======================%%
function RCPs_Callback(hObject, eventdata, handles)
function RCPs_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%============================HYPSO BUTTON==============================%%
%should get the Root and basin text and call the Hyso script
function Hypso_Callback(hObject, eventdata, handles) 
root = get(handles.Root, 'String');
basin = get(handles.Basin, 'String'); 
Hypso(root,basin);

%===================CREATE PROFILES===================================%%
%will get the textbox information that it needs (including the start and
%end years and then create profiles for those years
function createProfiles_Callback(hObject, eventdata, handles)
Root = get(handles.Root, 'String');
basin = get(handles.Basin, 'String'); 
Years = str2num(get(handles.ProfileYears, 'String')); 
Create_Profiles(Root,basin,Years);

%=============Create Profiles First Year Textbox========================%
function ProfileYears_Callback(hObject, eventdata, handles)
function ProfileYears_CreateFcn(hObject, eventdata, handles)   
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%=======================CREATE MULTIYEAR MASTER========================%%
%creates a multiyear master when pushed for the years inputted into the
%textbox
function multiyearMaster_Callback(hObject, eventdata, handles)
    root = get(handles.Root, 'String');
    basin = get(handles.Basin, 'String'); 
    startYear = str2num(get(handles.Year0, 'String')); 
    endYear = str2num(get(handles.Year1, 'String')); 
    Years = startYear:endYear; 
    Create_MultiYear_Master(root,basin,Years);
    
%%=======================CREATE forecasted Master========================%%    
function CreateForecastedMaster_Callback(hObject, eventdata, handles)
    Root = get(handles.Root, 'String');
    basin = get(handles.Basin, 'String'); 
    year = str2num(get(handles.MasterToForecast, 'String'));     
    FZS = str2num(get(handles.JulianForecastStart, 'String')); 
    FZW = str2num(get(handles.ForecastRange, 'String')); 
    %execute PredictSnow using the start date text box value
    ForecastSnow(Root,basin,year,FZS,FZW,'n'); 
    
%%========================Forecast Button (Predicar de dia)===============%%
function RunForecast_Callback(hObject, eventdata, handles)
%Get the input values from the text boxes
    Root = get(handles.Root, 'String');
    basin = get(handles.Basin, 'String'); 
    year = str2num(get(handles.MasterToForecast, 'String'));
    ERef = str2num(get(handles.Eref, 'String'));  
    baseFlow = str2num(get(handles.baseFlowTxt, 'String')); 
    TimelagS = str2num(get(handles.TlagSnowmelt , 'String')) ; 
    TimelagP = str2num(get(handles.TlagPercipTxt, 'String'));
    DegDayF = str2num(get(handles.DegreeDayText, 'String')); 
    RCsnowF = str2num(get(handles.runoffCoefSnow, 'String')); 
    RCPsF = str2num(get(handles.RCPs, 'String'));
    RCPnF = str2num(get(handles.RCPn, 'String'));
    TlapseF = str2num(get(handles.TempLapseText, 'String')); 
    Tcrit = str2num(get(handles.TcritText, 'String'));
    Pthresh= str2num(get(handles.Precip_Threshold,'String'));
    XF = str2num(get(handles.XCoef, 'String')); 
    YF = str2num(get(handles.YCoef, 'String')); 
    
    if (get(handles.Save_Predict,'Value') == get(handles.Save_Predict,'Max'))
        Save =1;
    else
        Save=0;
    end
    
    FZS = str2num(get(handles.JulianForecastStart, 'String')); 
    FZW = str2num(get(handles.ForecastRange, 'String')); 
    TZW = str2num(get(handles.TuneZoneWidthF, 'String'));;
  
    if length(Root)==0 | length(basin) == 0 | length(year) == 0 | ...
         length(ERef) == 0 | length(baseFlow) == 0 | ...
         length(TimelagS) == 0 | length(TimelagP) == 0
     disp('An input is missing! Check root, basin, and year inputs'); 
    else
     [TuneError,ProjError]=DEVELOP_SRM(Root,basin,year,...
            TimelagS,TimelagP,ERef,baseFlow,'Project',DegDayF,RCsnowF,RCPsF,...
    RCPnF,TlapseF,XF,YF,Tcrit,Pthresh,Save,FZS,FZW,TZW);
    end
       
%Start Date used for the forecasting button
function JulianForecastStart_Callback(hObject, eventdata, handles)
function JulianForecastStart_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%Year to forecast
function MasterToForecast_Callback(hObject, eventdata, handles)
function MasterToForecast_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%===========================SIMULATE BUTTON============================%%
function RunValidate_Callback(hObject, eventdata, handles)
    root = get(handles.Root, 'String');
    basin = get(handles.Basin, 'String'); 
    year = str2num(get(handles.MasterToSimulate, 'String')); 
    ERef = str2num(get(handles.Eref, 'String'));  
    baseFlow = str2num(get(handles.baseFlowTxt, 'String')); 
    TimelagS = str2num(get(handles.TlagSnowmelt , 'String')) ; 
    TimelagP = str2num(get(handles.TlagPercipTxt, 'String'));
    DegDayF = str2num(get(handles.DegreeDayText, 'String')); 
    RCsnowF = str2num(get(handles.runoffCoefSnow, 'String')); 
    RCPsF = str2num(get(handles.RCPs, 'String'));
    RCPnF = str2num(get(handles.RCPn, 'String'));
    TlapseF = str2num(get(handles.TempLapseText, 'String')); 
    Tcrit = str2num(get(handles.TcritText, 'String')); 
    Pthresh= str2num(get(handles.Precip_Threshold,'String'));
    XF = str2num(get(handles.XCoef, 'String')); 
    YF = str2num(get(handles.YCoef, 'String')); 
    
    FZS = str2num(get(handles.ForecastZoneStart, 'String')); 
    FZW = str2num(get(handles.ForecastZoneWidth, 'String')); 
    TZW = str2num(get(handles.TuneZoneWidthS, 'String')); 
    
    if (get(handles.Save_Simulate,'Value') == get(handles.Save_Simulate,'Max'))
        Save =1;
    else
        Save=0;
    end
  
    if length(root)==0 | length(basin) == 0 | length(year) == 0 | ...
         length(ERef) == 0 | length(baseFlow) == 0 | ...
         length(TimelagS) == 0 | length(TimelagP) == 0
     disp('An input is missing! Check root, basin, and year inputs'); 
    else
     [TuneError,ProjError]=DEVELOP_SRM(root,basin,year,...
            TimelagS,TimelagP,ERef,baseFlow,'Validate',DegDayF,RCsnowF,RCPsF,...
    RCPnF,TlapseF,XF,YF,Tcrit,Pthresh,Save,FZS,FZW,TZW);
    end
    
%%==================CALCULAR CUBIERTA DE NIEVE BUTTON====================%%
function snowCoveredArea_Callback(hObject, eventdata, handles)
    root = get(handles.Root, 'String');
    basin = get(handles.Basin, 'String'); 
    year = str2num(get(handles.Year, 'String')); 
    SnowCoveredArea(root,basin,year);

%%==================MISC fields====================%%    
function Year0_Callback(hObject, eventdata, handles)
function Year0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Year1_Callback(hObject, eventdata, handles)
function Year1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function DegreeDayText_Callback(hObject, eventdata, handles)
function DegreeDayText_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function TempLapseText_Callback(hObject, eventdata, handles)
function TempLapseText_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function XCoef_Callback(hObject, eventdata, handles)
function XCoef_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function YCoef_Callback(hObject, eventdata, handles)
function YCoef_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Precip_Threshold_Callback(hObject, eventdata, handles)
function Precip_Threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function TcritText_Callback(hObject, eventdata, handles)
function TcritText_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function MasterToSimulate_Callback(hObject, eventdata, handles)
function MasterToSimulate_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit45_Callback(hObject, eventdata, handles)
function edit45_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ForecastRange_Callback(hObject, eventdata, handles)
function ForecastRange_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ForecastZoneWidth_Callback(hObject, eventdata, handles)
function ForecastZoneWidth_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function TuneZoneWidthS_Callback(hObject, eventdata, handles)
function TuneZoneWidthS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function TuneZoneWidthF_Callback(hObject, eventdata, handles)
function TuneZoneWidthF_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ForecastZoneStart_Callback(hObject, eventdata, handles)
function ForecastZoneStart_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Save_Predict.
function Save_Predict_Callback(hObject, eventdata, handles)

% --- Executes on button press in Save_Simulate.
function Save_Simulate_Callback(hObject, eventdata, handles)
  
