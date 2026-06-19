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

% SECTION 2: GEOMETRY GENERATION
% 8 x 8 grid with double layer (top, bottom, and diagonal strands)
 
% Nodes of the upper cord (z-layer = H)
% Índices: fila i, columna j  →  nodo (i-1)*(Ng+1) + j
n_upper = (Ng+1)^2;  % 81
coords_upper = zeros(n_upper, 3);
idx = 1;
for i = 0:Ng
    for j = 0:Ng
        coords_upper(idx,:) = [j*Lg, i*Lg, H];
        idx = idx + 1;
    end
end
 
% Nodes of the lower string (z = 0 layer), shifted by Lg/2
n_lower = Ng^2;  % 64
coords_lower = zeros(n_lower, 3);
idx = 1;
for i = 0:Ng-1
    for j = 0:Ng-1
        coords_lower(idx,:) = [(j+0.5)*Lg, (i+0.5)*Lg, 0];
        idx = idx + 1;
    end
end
 
% Global coordinates: Identify nodes on the upper perimeter (fixed) and interior nodes (free)
perim_mask = false(n_upper,1);
for k = 1:n_upper
    row = floor((k-1)/(Ng+1));
    col = mod(k-1, Ng+1);
    if row==0 || row==Ng || col==0 || col==Ng
        perim_mask(k) = true;
    end
end
 
idx_fixed_up = find(perim_mask);  % of upper boundary nodes (fixed)
idx_free_up  = find(~perim_mask);  % of upper (free) interior nodes
 
% Node numbering:
% 1 .. n_lower                             -> free nodes on the lower chord
% n_lower+1 .. n_lower+length(idx_free_up) -> free interior nodes on the upper chord
% remaining nodes                          -> fixed nodes on the upper boundary
coords_free  = [coords_lower; coords_upper(idx_free_up,:)];
coords_fixed = coords_upper(idx_fixed_up,:);
 
n_free  = size(coords_free, 1);
n_fixed = size(coords_fixed,1);
n_total = n_free + n_fixed;
 
% Complete coordinates for connectivity
coords_all = [coords_free; coords_fixed];
