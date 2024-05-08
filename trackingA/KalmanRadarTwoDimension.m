clc; clear; close all;

load("h_position.mat");

Ns =  length(Position(:,1));

dt = 1;
t = 0:1:Ns-1;

for k= 1:Ns
    if Velocity(k,2) ~= 0
        sensorVel = Velocity(k, 2);
        z = GetVel(sensorVel);
        initpos = [Velocity(k, 1) Velocity(k, 2)]';
        [pos, vel] = IntKalman(initpos, z);

        Xsaved(k, :) = [pos vel];
        Zsaved(k) = z;
    
    else
    Nbacktab = 0;

        while Velocity(k-Nbacktab, 2) == 0
            Nbacktab = Nbacktab + 1;
            if k-Nbacktab < 1
                break;
            end
        end
    
        if (Nbacktab <= 2) && (k - Nbacktab ~= 0)
            sensorVel = Velocity(k-Nbacktab, 2);
            initpos = [Velocity(k, 1) Velocity(k, 2)]';
            [pos, vel] = IntKalman(initpos, z);
            
            Xsaved(k,:) = [Velocity(k-Nbacktab, 1) Velocity(k-Nbacktab, 2)];
            Zsaved(k) = z;
        elseif Nbacktab > 2 
            sensorVel = Velocity(k, 2);
            initpos = [Velocity(k, 1) Velocity(k, 2)]';
            [pos, vel] = IntKalman(initpos, z); 
            Xsaved(k,:) = [Velocity(k-Nbacktab, 1) Velocity(k-Nbacktab, 2)];
            Zsaved(k) = z;
        elseif k - Nbacktab <1 
            continue;
        else
        end      
    end
end

figure
plot(t, Xsaved(:,1))

figure
hold on
plot(t, Zsaved(:), 'r.')
plot(t, Xsaved(:,2))

function [pos, vel] = IntKalman(x, z) % 속도 추정
    
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