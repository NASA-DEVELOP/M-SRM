% quick and dirty script to load up error values
clc; clear all;

% path='C:\Users\jwely\NASA_DEVELOP_TESTBED\Salida';
path='C:\Users\jwely\NASA_DEVELOP_TESTBED\Salida\Limari Zero Lag';

cd(path);
d=dir(strcat('*.xls'));

for m=1:size(d)
    legends(m)=str2num((d(m).name((end-7):(end-4))));
%     Error(:,m)= xlsread(d(m).name,'AD21:AD3307');
%     Diff(:,m)= xlsread(d(m).name,'AC21:AC3307');
%     
%     Qact(:,m)=xlsread(d(m).name,'B21:B3307');
%     Qsim(:,m)=xlsread(d(m).name,'AB21:AB3307');

    Error(:,m)= xlsread(d(m).name,'AD21:AD385');
    Diff(:,m)= xlsread(d(m).name,'AC21:AC385');
    
    Qact(:,m)=xlsread(d(m).name,'B21:B385');
    Qsim(:,m)=xlsread(d(m).name,'AB21:AB385');
    Ratio(:,m)=Qact(:,m)./Qsim(:,m);
    
    Error(Error>=20)=0;
    
    Qact(:,m)=smooth(Qact(:,m),31);
    Qsim(:,m)=smooth(Qsim(:,m),31);
    Error(:,m)=smooth(Error(:,m),31);
    Ratio(:,m)=smooth(Ratio(:,m),31);
    
end

%take the average errors between all output files.
for j=1:length(Error)
AvgError(j)=mean(Error(j,:));
AvgDiff(j)=mean(Diff(j,:));
AvgRatio(j)=mean(Ratio(j,:));
end

%plot a few figures.
r=(1:length(Diff))./365; leg={'1','2','3'};
figure (1);plot(r,Error,r,AvgError,'k-');legend(leg);grid on;
figure(2);plot(r,Diff,r,AvgDiff,'k-');legend(leg);grid on;
figure(3);plot(r,Ratio,r,AvgRatio,'k-');legend(leg);grid on;

cd('C:\Users\jwely\NASA_DEVELOP_TESTBED\Ejecutables\Matlab');
xlswrite('AvgError.xls',AvgRatio');



% for x=1:3
%     
%     leg(x)
% %zero pad the signals according to the appropriate simulationt ime
%     pad=zeros(round(size(Qact,1)/2),1);
%     CorrQact(:,x)=[pad;Qact(:,x);pad];
%     CorrQsim(:,x) = [pad;Qsim(:,x);pad];
%     
%     CorrLength(x)=length(CorrQact(:,x))*2-1;
%     
% % take the correlation and fid the offset
%     Corr(:,x)=fftshift(ifft(fft(CorrQact(:,x),CorrLength(x)).*conj(fft(CorrQsim(:,x),CorrLength(x)))));
%     offset(x) = find(Corr(:,x)==max(Corr(:,x)))- length(CorrQact(:,x));
%     offset(x);
%     fprintf('offset found to be about %2.0f days \n',offset(x));
%     
%     if offset(x) <0
%         offset(x)=abs(offset(x));
%         Qa=[pad;Qact(:,x);zeros(offset(x),1);pad];
%         Qs=[pad;zeros(offset(x),1);Qsim(:,x);pad];
%     elseif offset(x)>=0
%         Qa=[pad;zeros(offset(x),1);Qact(:,x);pad];
%         Qs=[pad;Qsim(:,x);zeros(offset(x),1);pad];
%     end
% 
% %find the transfer function assuming the estimated correlation offset
% %is correct. 
%     np=5;       %poles
%     nz=np-1;    %zeros
%     
% %find the transfer function
%     tfdata=iddata(Qs,Qa,1/(60*60*24));
%     sys=tfest(tfdata,np,nz,0);
%     [zers(:,x),poles(:,x),gain(:,x)]=zpkdata(sys,'v')
%     sys
% 
% % apply the transfer function to the simulated data to see how closely it
% % matches the output data.
    

%     % Make some plots
%     figure(x+10)
%     r=(1:length(Qact))./365;
%     plot(r,Qact(:,x),r,Qsim(:,x));
%     title(leg(x));
%     legend('Qactual','Qsimulated');
%     grid on;


