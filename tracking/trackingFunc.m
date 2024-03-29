clc; clear; close all;

load("HistoryMap.mat");

chirpsIdx=50;chanIdx=1;

numrangeBins=256;NChirp=128;NChan=4;NSample=256;Nframe = 256;c = 3e8;pri=76.51e-6;prf=1/pri;
start_frequency = 77e9;wavelength = c / start_frequency;slope = 32.7337;samples_per_chirp = 256;
chirps_per_frame = 128;sampling_rate = 5e9;bandwidth = 1.6760e9;range_resolution = c/(2*bandwidth);
velocity_resolution =wavelength/(2*pri*NChirp);sampling_time = NSample/sampling_rate;
max_vel = wavelength/(4*pri);max_range = sampling_rate*c/(2*slope);
frame_periodicity = 4e-2;
velocityAxis = -max_vel:velocity_resolution:max_vel;rangeBin = linspace(0,numrangeBins *range_resolution, numrangeBins);

Nsamples =  length(HistoryMap(:,1));

dt = 1;
t = 0:1:Nsamples-1;

for k=1:Nsamples
    if HistoryMap(k,2) ~= 0
            sensorVel = HistoryMap(k, 2);
            z = GetVel(sensorVel);
            initpos = [HistoryMap(k, 1) HistoryMap(k, 2)]';
            [pos, vel] = IntKalman(z);

            Xsaved(k, :) = [pos vel];
            Zsaved(k) = z;
        
        else
            Nbacktab = 0;
    
            while HistoryMap(k-Nbacktab, 2) == 0
                Nbacktab = Nbacktab + 1;
                if k-Nbacktab < 1
                    break;
                end
            end

            if (Nbacktab <= 2) && (k - Nbacktab ~= 0)
                sensorVel = HistoryMap(k-Nbacktab, 2);
                initpos = [HistoryMap(k, 1) HistoryMap(k, 2)]';
                [pos, vel] = IntKalman(z);                                                %% 수정
                
                Xsaved(k,:) = [HistoryMap(k-Nbacktab, 1) HistoryMap(k-Nbacktab, 2)];
                Zsaved(k) = z;
            elseif Nbacktab > 2 
                sensorVel = HistoryMap(k, 2);
                initpos = [HistoryMap(k, 1) HistoryMap(k, 2)]';
                [pos, vel] = IntKalman(z);
                Xsaved(k,:) = [HistoryMap(k-Nbacktab, 1) HistoryMap(k-Nbacktab, 2)];
                Zsaved(k) = z;
            elseif k - Nbacktab <1 
                continue;
            else
                     
            end

        end
end

figure();
nonZeroIndices = any(Xsaved(:,[1 2]) ~= 0, 2);
XsavedNonZero = Xsaved(nonZeroIndices, :);

XsavedNonZero(:,1) = XsavedNonZero(:,1) ; % 거리 축 조정: -15가 0이 되도록
XsavedNonZero(:,2) = XsavedNonZero(:,2); % 속도 축 조정: 7이 0이 되도록
HistoryMap(:,1) = HistoryMap(:,1); 
HistoryMap(:,2) = HistoryMap(:,2); 

plot(HistoryMap(:,2), HistoryMap(:,1),'MarkerSize', 4);
hold on;
plot(XsavedNonZero(:,2), XsavedNonZero(:,1));
legend('Clustering Centroids', 'Kalman Filtered')
hold off;
xlim([min(velocityAxis), max(velocityAxis)]);
ylim([min(-rangeBin), max(rangeBin)*3.5]);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
title('Kalman Filtering');

figure();
hold on
plot(t, Zsaved(:), 'r.')
plot(t, Xsaved(:,2))

function [pos, vel] = IntKalman(z)

persistent A H Q R
persistent x P
persistent firstRun


if isempty(firstRun)
    firstRun = 1;
    
    dt = 0.1;
    A = [1 dt;
         0 1 ];
    H = [0 1];
    
    Q = [1 0;
         0 3];
    R = 10;

    x = [0 20]';
    P = 5*eye(2); % eye(): identity matrix
end

xp = A*x;
Pp = A*P*A' + Q;

K = Pp*H' * inv(H*Pp*H' + R);

x = xp + K*(z - H*xp);

P = Pp - K*H*Pp;

pos = x(1);
vel = x(2);

end

function z = GetVel(sensorVel)
Velp = sensorVel;

persistent Posp

if isempty(Posp)
    Posp = 0;
end

dt = 1;
Posp = Posp + Velp*dt;      % true position

z = Velp;

end