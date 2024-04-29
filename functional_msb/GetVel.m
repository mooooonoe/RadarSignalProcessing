
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