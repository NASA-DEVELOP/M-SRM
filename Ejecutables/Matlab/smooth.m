% this script was writen to replace the one in the curve fitting toolbox
% that may not be avialable to all users.

% it performs a moving averaged smoothing on a vector dataset with custom
% window width for the moving average
 %windowsizes are rouned up to the nearest odd number.

function [smoothed]=smooth(signal,windowsize)

    % rounds windowsize up to the nearest odd integer
    windowsize=int16(2*round((windowsize+1)/2)-1);
    buff=(windowsize-1)/2;
    smoothed=signal

    % performs moving average smoothing on the signal
    for i=(buff+1):(length(signal)-buff)
        smoothed(i)=mean(signal((i-buff):(i+buff)));
    end
    
    % handles the end points where the window pushes of the domain
    for i=1:buff
        smoothed(i)=mean(signal(1:(i+buff)));
    end
    
    for i=(length(signal)-buff):length(signal)
        smoothed(i)=mean(signal(i:end));
    end

    % makes some plots to confirm everything worked ok
    % hold on
    % plot(signal,'b-');
    % plot(smoothed,'k-');
end