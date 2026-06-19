% STRUCTURAL IMPORTANCE ANALYSIS IN RETICULAR SYSTEMS

% SECTION 1: MODEL PARAMETERS
% 8 x 8 Square Pyramid Armor

% Geometric parameters
Ng = 8;  % Grid Modules (8 x 8)
Lg = 2.5;  % Length of each module [m]
H = 1.5;  % Truss height [m]

% Mechanical Properties (Steel)
E_steel = 2.1e11;  % Young's modulus [N/m^2]

% Cross-sections (circular tube)
% Upper/lower cords: 60 mm in diameter, 4 mm thick
d_chord = 0.060;
t_chord = 0.004;
A_chord = pi/4 * (d_chord^2 - (d_chord - 2*t_chord)^2);

% Diagonals: diameter 51 mm, thickness 4 mm
d_diag = 0.051;
t_diag = 0.004;
A_diag = pi/4 * (d_diag^2  - (d_diag  - 2*t_diag)^2);

fprintf('=== STRUCTURAL MODEL PARAMETERS ===\n');
fprintf('Young''s Modulus       : %.3e N/m²\n', E_steel);
fprintf('Chord Member Area     : %.4e m²\n', A_chord);
fprintf('Diagonal Member Area  : %.4e m²\n', A_diag);
fprintf('\n');
