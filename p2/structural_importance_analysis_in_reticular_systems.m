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
fprintf('Young's Modulus       : %.3e N/m²\n', E_steel);
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

% SECTION 3: CONNECTIVITY MATRIX (Cs)
% Cs(k,p) = +1 (if member k starts at node p) or -1 (if member k ends at node p)
connectivity = [];   % [nodo_i, nodo_j, tipo]  tipo: 1=cordón, 2=diagonal

% Lower cords (between adjacent lower nodes)
for i = 0:Ng-1
    for j = 0:Ng-1
        n_ij   = i*Ng + j + 1;  % lower node (i,j)
        % Horizontal
        if j < Ng-1
            n_ij1 = i*Ng + (j+1) + 1;
            connectivity(end+1,:) = [n_ij, n_ij1, 1];
        end
        % Vertical
        if i < Ng-1
            n_i1j = (i+1)*Ng + j + 1;
            connectivity(end+1,:) = [n_ij, n_i1j, 1];
        end
    end
end

% Inner upper cables (between upper free nodes)
offset_free_up = n_lower;  % offset in global numbering
n_free_up = length(idx_free_up);
% Construir mapa: posición en grilla sup → índice global libre
map_up = zeros(Ng+1, Ng+1);   % 0 = fijo
for k = 1:n_free_up
    orig_k = idx_free_up(k);
    row = floor((orig_k-1)/(Ng+1)) + 1;
    col = mod(orig_k-1, Ng+1)  + 1;
    map_up(row,col) = offset_free_up + k;
end
% Upper perimeter nodes -> fixed global index
map_up_fixed = zeros(Ng+1,Ng+1);
for k = 1:length(idx_fixed_up)
    orig_k = idx_fixed_up(k);
    row = floor((orig_k-1)/(Ng+1)) + 1;
    col = mod(orig_k-1, Ng+1)  + 1;
    map_up_fixed(row,col) = n_free + k;
end

% Combine the two maps into one
map_up_full = map_up;
mask_fixed_2d = (map_up == 0);
map_up_full(mask_fixed_2d) = map_up_fixed(mask_fixed_2d);

for i = 1:Ng+1
    for j = 1:Ng+1
        ni = map_up_full(i,j);
        if j < Ng+1
            nj = map_up_full(i,j+1);
            connectivity(end+1,:) = [ni, nj, 1];
        end
        if i < Ng+1
            nj = map_up_full(i+1,j);
            connectivity(end+1,:) = [ni, nj, 1];
        end
    end
end

% Diagonals (each lower node connects to 4 upper nodes)
for i = 0:Ng-1
    for j = 0:Ng-1
        n_low = i*Ng + j + 1;
        % The top 4 nodes at the corners of the square
        corners = [i+1,j+1; i+1,j+2; i+2,j+1; i+2,j+2];
        for c = 1:4
            r = corners(c,1); col_c = corners(c,2);
            n_up = map_up_full(r, col_c);
            connectivity(end+1,:) = [n_low, n_up, 2];
        end
    end
end

m_bars = size(connectivity,1);

fprintf('=== GENERATED GEOMETRY ===\n');
fprintf('Free nodes    : %d\n', n_free);
fprintf('Fixed nodes   : %d\n', n_fixed);
fprintf('Total members : %d\n', m_bars);
fprintf('\n');

% SECTION 4: ASSEMBLY OF THE TANGENTIAL STIFFNESS MATRIX
% K = KE + KG
% KE = A * K* * L^{-1} * A^T (elastic stiffness)
% KG = I xor E (geometric stiffness)

% Return the 3n × 3n tangent stiffness matrix
function K = ensamblar_rigidez(coords_free, coords_fixed, connectivity, ...
                                E_steel, A_chord, A_diag, n_free)
    m  = size(connectivity,1);
    nf = size(coords_fixed,1);
    coords_all = [coords_free; coords_fixed];
 
    % Axial parameters per bar
    ea = zeros(m,1);
    for k = 1:m
        if connectivity(k,3) == 1
            ea(k) = E_steel * A_chord;
        else
            ea(k) = E_steel * A_diag;
        end
    end
 
    % Current lengths and coordinate differences
    u = zeros(m,1); v = zeros(m,1); w = zeros(m,1);
    l = zeros(m,1);
    for k = 1:m
        ni = connectivity(k,1);
        nj = connectivity(k,2);
        du = coords_all(nj,1) - coords_all(ni,1);
        dv = coords_all(nj,2) - coords_all(ni,2);
        dw = coords_all(nj,3) - coords_all(ni,3);
        u(k) = du; v(k) = dv; w(k) = dw;
        l(k) = sqrt(du^2 + dv^2 + dw^2);
    end
 
    % Unstrained lengths = initial lengths (unloaded state)
    l0 = l; % for the linear case
 
    % Force densities
    q = ea .* (l - l0) ./ (l0 .* l);
 
    % Connectivity matrices C (free nodes) and Cf (fixed nodes)
    C  = zeros(m, n_free);
    Cf = zeros(m, nf);
    for k = 1:m
        ni = connectivity(k,1);
        nj = connectivity(k,2);
        if ni <= n_free,  C(k,ni)  =  1; else Cf(k,ni-n_free) =  1; end
        if nj <= n_free,  C(k,nj)  = -1; else Cf(k,nj-n_free) = -1; end
    end
 
    % Direction matrices Ax, Ay, Az
    Linv = diag(1./l);
    Ax = C' * Linv * diag(u);
    Ay = C' * Linv * diag(v);
    Az = C' * Linv * diag(w);
    A_mat = [Ax; Ay; Az];  % 3n x m
 
    % Elastic stiffness
    Kstar = diag(ea);
    KE = A_mat * Kstar * Linv * A_mat';  % 3n x 3n
 
    % Geometric stiffness
    Q = diag(q);
    E_mat = C' * Q * C;
    KG = kron(eye(3), E_mat);  % 3n x 3n
 
    K = KE + KG;
end

% SECTION 5: GAUSS-SEIDEL METHOD
% Solve K*u = F iteratively

function [x, iter, residuals] = gauss_seidel(A, b, tol, max_iter)
    n = length(b);
    
    % Rearranging rows (partial pivoting) to avoid null or very
    % small values on the diagonal
    [~, piv] = max(abs(A), [], 2);
    order = 1:n;
    for i = 1:n
        [~, best] = max(abs(A(i:n, i)));
        best = best + i - 1;
        if best ~= i
            A([i best], :) = A([best i], :);
            b([i best])    = b([best i]);
        end
    end
 
    x = zeros(n,1);  % initial estimate
    residuals = zeros(max_iter,1);
 
    for iter = 1:max_iter
        for i = 1:n
            sigma = 0;
            for j = 1:n
                if j ~= i
                    sigma = sigma + A(i,j)*x(j);
                end
            end
            if abs(A(i,i)) < 1e-12
                error(['Gauss-Seidel: pivote nulo en fila %d. ' ...
                       'La matriz no es diagonalmente dominante ' ...
                       'incluso tras reordenar filas.'], i);
            end
            x(i) = (b(i) - sigma) / A(i,i);
        end
        res = norm(b - A*x);
        residuals(iter) = res;
        if res < tol
            break;
        end
    end
    residuals = residuals(1:iter);
end
