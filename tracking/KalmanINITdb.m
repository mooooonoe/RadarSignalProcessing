clc; clear; close all;

load("HistoryMap.mat");
load("rangeBin.mat");

Nsamples =  length(HistoryMap(:,1));


NChirp=128;
c = 3e8;                            
pri=76.51e-6;                    
prf=1/pri;
start_frequency = 77e9;              
wavelength = c / start_frequency;

velocity_resolution =wavelength/(2*pri*NChirp);
max_vel = wavelength/(4*pri); 

dt = 1;
t = 0:1:Nsamples-1;

for k=1:Nsamples
    if HistoryMap(k,2) ~= 0
        sensorVel = HistoryMap(k, 2);
        z = GetVel(sensorVel);
        initpos = [HistoryMap(k, 1) HistoryMap(k, 2)]';
        [pos, vel] = IntKalman(initpos, z);
        Xsaved(k, :) = [pos vel];
        Zsaved(k) = z;
    
    else
        Nbacktab = 1;

        while HistoryMap(k-Nbacktab, 2) == 0
            Nbacktab = Nbacktab - 1;
        end
        sensorVel = HistoryMap(k-Nbacktab, 2);
        initpos = [HistoryMap(k, 1) HistoryMap(k, 2)]';
        [pos, vel] = IntKalman(initpos, z);
        Xsaved(k,:) = [HistoryMap(k-Nbacktab, 1) HistoryMap(k-Nbacktab, 2)];
        Zsaved(k) = z;
    end
end
velocityAxis = -max_vel:velocity_resolution:max_vel;

figure('Position', [300,100, 1200, 800]);
tiledlayout(1,2);
nexttile;
plot(Xsaved(:,2), Xsaved(:,1))
xlim([min(velocityAxis), max(velocityAxis)]);
ylim([min(rangeBin), max(rangeBin)]);
nexttile;
hold on
plot(t, Zsaved(:), 'r.');
plot(t, Xsaved(:,2));
yticks(0:2:max(rangeBin));

function [pos, vel] = IntKalman(x, z)

persistent A H Q R
persistent P
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

    %x = [0 20]';
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