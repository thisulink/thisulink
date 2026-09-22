function dxdt = tissue_model(t, x, m, c, k, F0, f_exc)
% THISULINK PLANTAR TISSUE DYNAMICS - 1-DOF KELVIN-VOIGT CONTACT MODEL
%
% State vector:
%   x(1) = Plantar tissue surface vertical displacement [m]
%   x(2) = Plantar tissue surface velocity [m/s]
%
% Parameters:
%   m     = Moving actuator mass (VCA coil + contactor tip) [kg] (0.045 kg)
%   c     = Dynamic viscoelastic damping [N*s/m]
%   k     = Lumped contact tissue stiffness [N/m]
%   F0    = Dynamic excitation force amplitude [N] (0.100 N)
%   f_exc = Excitation frequency [Hz]
%
% Governing equation:
%   m*x'' + c*x' + k*x = F0 * sin(2*pi*f_exc*t)

displacement = x(1);
velocity = x(2);

% Harmonic skin excitation force
force = F0 * sin(2 * pi * f_exc * t);

% Instantaneous acceleration
acceleration = (force - c * velocity - k * displacement) / m;

% State derivative
dxdt = [velocity; acceleration];
end
