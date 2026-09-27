%% THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM - SIMULATION PARAMETERS
% Project: THISULINK - Integrated Dual-Modality Frontline Diabetic Triage
% Hardware Subsystem: Plantar Biomechanical Shear Wave Elastography (SWE) Platform
% Reference: Smart India Hackathon (SIH) 2026 Grand Finale
%
% Shared parameter script for all experiments (run it as a script; it defines
% variables in the caller's workspace and deliberately does NOT clear anything).
%
% IMPORTANT: these are MODEL ASSUMPTIONS for a simulation study. Tissue values
% are literature-inspired placeholders, not clinically validated measurements,
% and the hardware values are design targets, not bench-measured data.

%% =========================================================================
%% 1. ACTUATOR SUBSYSTEM (Voice Coil Actuator - VCA)
%% =========================================================================
m = 0.0450;             % Effective moving mass (VCA coil + contactor tip) [kg]
f_exc = 50.0;           % Nominal diagnostic excitation frequency [Hz]
F0 = 0.100;             % Dynamic harmonic excitation force amplitude [N] (100 mN safe contact)
f_start = 10.0;         % Chirp sweep start frequency [Hz]
f_end = 300.0;          % Chirp sweep end frequency [Hz]
frequency_step = 1.0;   % Sweep step size [Hz]

% VCA Electrical Parameters
vca_R = 8.20;           % Voice coil DC resistance [Ohm]
vca_L = 0.00120;        % Voice coil inductance [H] (1.2 mH)
vca_Kf = 2.40;          % Force sensitivity constant [N/A]
vca_Ke = 2.40;          % Back-EMF constant [V/(m/s)]
vca_Vdrive = 1.20;      % Peak driving voltage [V]

%% =========================================================================
%% 2. CONTACT INTERLOCK & LOAD CELL CONSTRAINTS
%% =========================================================================
F_preload_target = 1.50;    % Calibrated target static preload [N]
F_preload_min    = 1.40;    % Minimum acceptable preload threshold [N]
F_preload_max    = 1.60;    % Maximum acceptable preload threshold [N]
load_cell_noise  = 0.015;   % Load cell measurement RMS noise (HX711 24-bit ADC) [N]
contact_alpha    = 180.0;   % Contact stiffening coefficient [(N/m)/N]

%% =========================================================================
%% 3. SENSOR SUBSYSTEM (Dual Analog Devices ADXL355 Accelerometers)
%% =========================================================================
% The production probe uses 2 x ADXL355 (hardware/README.md). The ADXL355
% output data rate (ODR) is programmable up to 4000 Hz and its digital
% low-pass filter corner is ~ODR/4, i.e. 1000 Hz at ODR = 4000 Hz. This
% covers the full 10-300 Hz excitation sweep.
% (The earlier value of 150 Hz was below the sweep band and has been fixed.)
% NOTE: the ESP32-S3 + ADXL345 proof-of-concept firmware samples at 200 Hz
% ODR (Nyquist 100 Hz), so that POC board can only cover ~10-90 Hz.
sensor_range_g     = 2.048;     % Full-scale range [+/- g]
sensor_bits        = 20;        % ADC resolution [bits]
sensor_odr         = 4000.0;    % Output data rate [Hz] (ADXL355 maximum)
sensor_bandwidth   = sensor_odr / 4;  % Digital LPF corner = noise bandwidth [Hz] (1000 Hz)
sensor_noise_dens  = 0.000245;  % Noise density: 25 ug/sqrt(Hz) converted to m/s^2/sqrt(Hz)
sensor_bias        = 0.0050;    % DC offset bias [m/s^2]
x_sensor1          = 0.105;     % Distance from VCA tip to Proximal Pickup 1 [m] (105 mm)
x_sensor2          = 0.145;     % Distance from VCA tip to Distal Pickup 2 [m] (145 mm)
delta_x            = x_sensor2 - x_sensor1; % Inter-sensor gauge separation [m] (40 mm)
% Phase-wrapping limit of the 40 mm baseline: the inter-sensor phase lag is
% dphi = 2*pi*f*delta_x/cs. It exceeds pi (ambiguous for a wrapped estimate)
% above f = cs/(2*delta_x) and a full cycle above f = cs/delta_x. For
% cs = 3.7-8 m/s that is ~46-100 Hz (pi) and ~93-200 Hz (2*pi), so a
% 10-300 Hz sweep MUST be phase-unwrapped across frequency (Experiment 10).

%% =========================================================================
%% 4. PLANTAR SOFT-TISSUE BIOMECHANICAL MODELS
%% =========================================================================
% cs_X below is the purely ELASTIC speed sqrt(mu/rho). With viscosity eta the
% Kelvin-Voigt phase velocity is dispersive and slightly higher (see
% common/shear_wave_propagation_model.m), e.g. ~3.81 m/s vs 3.72 m/s for
% Class 1 at 50 Hz.
rho_tissue = 1050.0;    % Plantar soft tissue mass density [kg/m^3]

% --- Class 1: Healthy Plantar Tissue (Compliant Control) ---
k_A    = 800.0;         % Lumped dynamic contact stiffness [N/m]
c_A    = 2.50;          % Dynamic damping coefficient [N*s/m]
mu_A   = 14500.0;       % Baseline shear modulus [Pa] (14.5 kPa)
eta_A  = 12.0;          % Plantar tissue shear viscosity [Pa*s]
cs_A   = sqrt(mu_A / rho_tissue);   % Theoretical shear wave speed [m/s] (~3.72 m/s)
E_A    = 3 * mu_A;      % Young's elasticity modulus [Pa] (43.5 kPa)
fn_A   = (1/(2*pi)) * sqrt(k_A / m); % Natural frequency [Hz] (~21.22 Hz)
zeta_A = c_A / (2 * sqrt(k_A * m));  % Damping ratio (~0.208)

% --- Class 2: Early Glycation / Pre-Neuropathic (Moderate Stiffening) ---
k_B    = 1500.0;        % Lumped dynamic contact stiffness [N/m]
c_B    = 3.20;          % Dynamic damping coefficient [N*s/m]
mu_B   = 32000.0;       % Baseline shear modulus [Pa] (32.0 kPa)
eta_B  = 18.5;          % Plantar tissue shear viscosity [Pa*s]
cs_B   = sqrt(mu_B / rho_tissue);   % Theoretical shear wave speed [m/s] (~5.52 m/s)
E_B    = 3 * mu_B;      % Young's elasticity modulus [Pa] (96.0 kPa)
fn_B   = (1/(2*pi)) * sqrt(k_B / m); % Natural frequency [Hz] (~29.06 Hz)
zeta_B = c_B / (2 * sqrt(k_B * m));  % Damping ratio (~0.195)

% --- Class 3: Diabetic Neuropathy / Severe Stiffening (High Ulceration Risk) ---
k_C    = 2600.0;        % Lumped dynamic contact stiffness [N/m]
c_C    = 4.50;          % Dynamic damping coefficient [N*s/m]
mu_C   = 68000.0;       % Baseline shear modulus [Pa] (68.0 kPa)
eta_C  = 28.0;          % Plantar tissue shear viscosity [Pa*s]
cs_C   = sqrt(mu_C / rho_tissue);   % Theoretical shear wave speed [m/s] (~8.05 m/s)
E_C    = 3 * mu_C;      % Young's elasticity modulus [Pa] (204.0 kPa)
fn_C   = (1/(2*pi)) * sqrt(k_C / m); % Natural frequency [Hz] (~38.25 Hz)
zeta_C = c_C / (2 * sqrt(k_C * m));  % Damping ratio (~0.208)

%% =========================================================================
%% 5. MECHANICAL STABILIZATION & FLEXURE SUBSYSTEM
%% =========================================================================
k_flexure_lat = 7500.0;     % Planar spring flexure lateral restoring stiffness [N/m]
k_velcro_strap = 12000.0;   % Medical Velcro foot stabilization strap stiffness [N/m]
c_velcro_strap = 35.0;      % Foot strap damping coefficient [N*s/m]
m_brass_base = 0.580;       % Inertial brass reaction mass [kg]
fn_isolation = 4.2;         % Elastomer base isolation resonance [Hz]

%% =========================================================================
%% 6. TIME & SAMPLING GRID
%% =========================================================================
fs = 4000;              % Platform ADC sampling frequency [Hz]
T  = 1.0;               % Standard simulation time window [s]
t  = (0:1/fs:T-1/fs)';   % Time vector [s]

%% =========================================================================
%% 7. CONSOLE DISPLAY
%% =========================================================================
fprintf('\n========================================================================\n');
fprintf('  THISULINK PLANTAR BIOMECHANICAL SWE PLATFORM - SIMULATION PARAMETERS  \n');
fprintf('  Dual-Modality Frontline Diabetic Triage Engineering Verification      \n');
fprintf('========================================================================\n');
fprintf('VCA Moving Mass (m)       : %.4f kg (45.0 g)\n', m);
fprintf('Excitation Frequency      : %.1f Hz (Bandwidth: %.0f - %.0f Hz)\n', f_exc, f_start, f_end);
fprintf('Dynamic Force Amplitude   : %.3f N (100 mN safe skin contact)\n', F0);
fprintf('Calibrated Static Preload : %.2f N (Allowable Interlock: %.2f - %.2f N)\n', ...
    F_preload_target, F_preload_min, F_preload_max);
fprintf('Dual ADXL355 Pickup Grid  : Proximal = %.0f mm, Distal = %.0f mm (dx = %.0f mm)\n', ...
    x_sensor1*1000, x_sensor2*1000, delta_x*1000);
fprintf('------------------------------------------------------------------------\n');
fprintf('CLASS 1: HEALTHY COMPLIANT CONTROL\n');
fprintf('  k = %.1f N/m | fn = %.2f Hz | cs = %.2f m/s | E = %.1f kPa\n', k_A, fn_A, cs_A, E_A/1000);
fprintf('CLASS 2: EARLY GLYCATION / MILD NEUROPATHY\n');
fprintf('  k = %.1f N/m | fn = %.2f Hz | cs = %.2f m/s | E = %.1f kPa\n', k_B, fn_B, cs_B, E_B/1000);
fprintf('CLASS 3: DIABETIC NEUROPATHY / HIGH ULCER RISK\n');
fprintf('  k = %.1f N/m | fn = %.2f Hz | cs = %.2f m/s | E = %.1f kPa\n', k_C, fn_C, cs_C, E_C/1000);
fprintf('ADXL355 ODR / Bandwidth   : %.0f Hz / %.0f Hz (sweep %.0f - %.0f Hz)\n', ...
    sensor_odr, sensor_bandwidth, f_start, f_end);
fprintf('Phase-wrap limit (40 mm)  : dphi = pi at %.0f / %.0f / %.0f Hz (Class 1/2/3, elastic cs)\n', ...
    cs_A/(2*delta_x), cs_B/(2*delta_x), cs_C/(2*delta_x));
fprintf('========================================================================\n\n');
