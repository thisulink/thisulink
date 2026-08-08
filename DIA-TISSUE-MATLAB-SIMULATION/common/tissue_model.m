function dxdt = tissue_model(t,x,m,c,k,F0,f_exc)
% DIA-TISSUE MASS-SPRING-DAMPER MODEL
% x(1) = displacement
% x(2) = velocity
displacement = x(1);
velocity = x(2);
force = F0*sin(2*pi*f_exc*t);
acceleration = (force-c*velocity-k*displacement)/m;
dxdt = [velocity;acceleration];
end