clear all

dt = 0.1;
t = 0:dt:10;

Nsamples = length(t);

Xsaved = zeros(Nsamples, 2);
Zsaved = zeros(Nsamples, 1);

for k=1:Nsamples
    % 위치와 속도 추정
    z = GetVel();
    [pos, vel] = IntKalman(z);

    Xsaved(k, :) = [pos vel];
    Zsaved(k) = z;
end

figure
plot(t, Xsaved(:,1))

figure
hold on
plot(t, Zsaved(:), 'b')
plot(t, Xsaved(:,2))

function [pos, vel] = IntKalman(z)
%
%
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

P = Pp - K*H*Pp

pos = x(1);
vel = x(2);

end

function z = GetVel()
%
%
persistent Velp Posp

if isempty(Posp)
    Posp = 0;
    Velp = 80;
end

dt = 0.1;

v = 0 + 10*randn;

Posp = Posp + Velp*dt;      % true position
Velp = 80 + v;              % true speed

z = Velp;

end