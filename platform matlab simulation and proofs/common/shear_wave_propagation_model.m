function [u_x, wave_info] = shear_wave_propagation_model(t, u_source, x_dist, mu, eta, rho, f_exc)
% THISULINK PLANTAR SHEAR WAVE PROPAGATION MODEL
% Biomechanical Viscoelastic Wave Propagation (Kelvin-Voigt Tissue Model)
%
% Inputs:
%   t        - Time vector [s]
%   u_source - Dynamic acceleration/displacement waveform at exciter tip (x=0)
%   x_dist   - Propagation distance to pickup sensor [m] (e.g. 0.105 m or 0.145 m)
%   mu       - Plantar tissue shear modulus [Pa]
%   eta      - Plantar tissue dynamic shear viscosity [Pa*s]
%   rho      - Plantar tissue mass density [kg/m^3] (~1050 kg/m^3)
%   f_exc    - Excitation frequency [Hz]
%
% Outputs:
%   u_x       - Simulated time-domain waveform at distance x_dist
%   wave_info - Struct containing phase velocity, attenuation, time-of-flight, and Young's modulus

omega = 2 * pi * f_exc;

% Complex shear modulus G*(omega) = mu + j*omega*eta
G_mag = sqrt(mu^2 + (omega * eta)^2);

% Phase velocity cs(omega) [m/s]
cs = sqrt((2 * G_mag^2) / (rho * (mu + G_mag)));

% Spatial attenuation coefficient alpha(omega) [Np/m]
alpha = sqrt((rho * omega^2 * (G_mag - mu)) / (2 * G_mag^2));

% Time-of-flight (ToF) delay
delta_t = x_dist / cs;

% Phase delay [rad]
k_real = omega / cs;
phase_lag = k_real * x_dist;

% Cylindrical geometric spreading factor (r0 = contact radius = 5 mm)
r0 = 0.005;
geom_attenuation = sqrt(r0 / max(x_dist, r0));

% Material viscoelastic exponential attenuation
visco_attenuation = exp(-alpha * x_dist);

% Total amplitude decay
amplitude_factor = geom_attenuation * visco_attenuation;

% Apply delay and attenuation in the time domain.
% For a harmonic signal: u(x,t) = A * amplitude_factor * sin(omega*(t - delta_t)).
% The delay is applied as a FRACTIONAL delay (linear interpolation) rather
% than being rounded to whole samples; rounding to 1/fs = 0.25 ms caused up
% to ~1-2 % error in the phase-derived wave speed over the 40 mm baseline.
% Limitation: one phase velocity/attenuation (evaluated at f_exc) is applied
% to the whole waveform, i.e. the model is only exact for narrow-band
% (single-frequency) excitation.
t = t(:);
u_source = u_source(:);
delayed_source = interp1(t, u_source, t - delta_t, 'linear', 0);

u_x = amplitude_factor * delayed_source;

% Pack diagnostic output information
wave_info.cs = cs;
wave_info.alpha = alpha;
wave_info.delta_t = delta_t;
wave_info.phase_lag_rad = phase_lag;
wave_info.phase_lag_deg = mod(phase_lag * 180 / pi, 360);
wave_info.amplitude_factor = amplitude_factor;
wave_info.Youngs_modulus_kPa = (3 * rho * cs^2) / 1000;  % apparent E from dispersive cs
wave_info.wavelength = cs / f_exc;                         % [m]
end
