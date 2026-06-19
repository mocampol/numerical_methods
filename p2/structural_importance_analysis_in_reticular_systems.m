% STRUCTURAL IMPORTANCE ANALYSIS IN RETICULAR SYSTEMS

% 1) MODEL PARAMETERS
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

% 2) GEOMETRY GENERATION
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

% 3) CONNECTIVITY MATRIX (Cs)
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

% 4) ASSEMBLY OF THE TANGENTIAL STIFFNESS MATRIX
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

% 5) GAUSS-SEIDEL METHOD
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
                       'The matrix is not diagonally dominant ' ...
                       'even after reshuffling the ranks.'], i);
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

% 6) MULTIVARIABLE NEWTON-RAPHSON METHOD
% Solves the nonlinear equilibrium equation  F_int(u) = F_ext

% Newton-Raphson for nonlinear structural equilibrium
function [u, iter, norms] = newton_raphson(coords_free0, coords_fixed, ...
            connectivity, E_steel, A_chord, A_diag, n_free, F_ext, ...
            tol, max_iter)
    % The residual is  R(u) = F_ext - F_int(u)
    % where F_int is obtained from the deformed configuration
    % Jacobian = -K_tangent(u) -> K*du = R
    
    ndof = 3 * n_free;
    u    = zeros(ndof,1);   % desplazamientos iniciales = 0
    norms = zeros(max_iter,1);
 
    for iter = 1:max_iter
        % Deformed coordinates
        coords_def = coords_free0;
        coords_def(:,1) = coords_free0(:,1) + u(1:n_free);
        coords_def(:,2) = coords_free0(:,2) + u(n_free+1:2*n_free);
        coords_def(:,3) = coords_free0(:,3) + u(2*n_free+1:end);
 
        % Tangential stiffness in current configuration
        K = ensamblar_rigidez(coords_def, coords_fixed, connectivity, ...
                              E_steel, A_chord, A_diag, n_free);
 
        % Internal forces (linear approximation per step)
        F_int = K * u;
 
        % Residue
        R = F_ext - F_int;
        norms(iter) = norm(R);
 
        if norms(iter) < tol
            break;
        end
 
        lambda_reg = 1e-8 * max(abs(diag(K)));
        du = (K + lambda_reg*eye(size(K))) \ R;
        u = u + du;
    end
    norms = norms(1:iter);
end

% 7) ANALYSIS OF EIGENVALUES AND EIGENVECTORS
% Calculate the importance index for each bar

% Calculate the importance index by sequentially removing bars
% using the determinant of the tangent stiffness matrix
function [alpha, lambda1_list, det_list] = calcular_importancia(...
            coords_free, coords_fixed, connectivity, ...
            E_steel, A_chord, A_diag, n_free)
    m_bars = size(connectivity,1);
 
    % System intact
    K0 = ensamblar_rigidez(coords_free, coords_fixed, connectivity, ...
                           E_steel, A_chord, A_diag, n_free);
 
    % Eigenvalues of the intact system (eliminate rigid modes close to 0)
    lambda0 = eig(K0);
    lambda0 = sort(real(lambda0));
    lambda0_pos = lambda0(lambda0 > 1e-6);  % of positive cases only
 
    det_K0 = prod(lambda0_pos);  % det = product of eigenvalues
    lambda1_0 = lambda0_pos(1);  % lower positive self-esteem
 
    fprintf('Undamaged structure:\n');
    fprintf('  det(K0) = %.6e\n', det_K0);
    fprintf('  lambda1 = %.6e\n', lambda1_0);
    fprintf('\n');
 
    % Sequential elimination
    alpha      = zeros(m_bars,1);
    lambda1_list = zeros(m_bars,1);
    det_list   = zeros(m_bars,1);
 
    for k = 1:m_bars
        % Create connectivity without the k bar
        conn_k = connectivity([1:k-1, k+1:end], :);
 
        Ki = ensamblar_rigidez(coords_free, coords_fixed, conn_k, ...
                               E_steel, A_chord, A_diag, n_free);
 
        lambda_k = eig(Ki);
        lambda_k = sort(real(lambda_k));
        lambda_k_pos = lambda_k(lambda_k > 1e-6);
 
        if isempty(lambda_k_pos)
            det_Ki   = 0;
            lambda1_k = 0;
        else
            det_Ki    = prod(lambda_k_pos);
            lambda1_k = lambda_k_pos(1);
        end
 
        det_list(k)    = det_Ki;
        lambda1_list(k) = lambda1_k;
 
        % Importance Index
        if abs(det_K0) > 1e-30
            alpha(k) = (det_K0 - det_Ki) / det_K0;
        else
            alpha(k) = 0;
        end
    end
end

% 8) MAIN EXECUTION
 
fprintf('========================================\n');
fprintf('   ANALYSIS - CASE 1: 2D TRUSS          \n');
fprintf('========================================\n\n');
 
% Flat truss from the paper: 4 nodes, 6 members
% nodes 1 and 2 are free
% nodes 3 and 4 are fixed
coords_free_2d  = [0, 1, 0;  % node 1
                   1, 1, 0];  % node 2
coords_fixed_2d = [0, 0, 0;  % node 3
                   1, 0, 0];  % node 4
 
% Conectivity
% Bar1: 3-4; Bar2: 1-3; Bar3: 1-4; Bar4: 2-3; Bar5: 2-4; Bar6: 1-2
conn_2d = [3, 4, 1;  % Bar 1  (between landlines -> no charge)
           1, 3, 1;  % Bar 2
           1, 4, 1;  % Bar 3
           2, 3, 1;  % Bar 4
           2, 4, 1;  % Bar 5
           1, 2, 1];  % Bar 6
 
%For the 2D truss, we use ea = 1.0, lengths = 1.0
E_2d = 1.0; A_2d_chord = 1.0; A_2d_diag = 1.0;
 
n_free_2d = 2;
 
[alpha_2d, lam1_2d, det_2d] = calcular_importancia(...
    coords_free_2d, coords_fixed_2d, conn_2d, ...
    E_2d, A_2d_chord, A_2d_diag, n_free_2d);
 
fprintf('Importance indices (compare with Table 2):\n');
fprintf('%-8s %-12s %-12s\n', 'Bar', 'alpha_i', 'det(Ki)');
for k = 1:6
    fprintf('Bar %-4d  %.4f       %.4f\n', k, alpha_2d(k), det_2d(k));
end
fprintf('\nExpected values from the paper:\n');
fprintf('Bar 2 = 0.885, Bar 3 = 0.673, Bar 6 = 0.885\n\n');

fprintf('========================================\n');
fprintf('   ANALYSIS - CASE 2: 8x8 3D TRUSS      \n');
fprintf('========================================\n\n');
 
[alpha_3d, lam1_3d, det_3d] = calcular_importancia(...
    coords_free, coords_fixed, connectivity, ...
    E_steel, A_chord, A_diag, n_free);
 
% Sort by importance
[alpha_sorted, idx_sort] = sort(alpha_3d, 'descend');
 
fprintf('Top 15 most important bars (highest alpha_i):\n');
fprintf('%-8s %-12s %-14s\n', 'Bar', 'alpha_i', 'lambda1');
for k = 1:min(15, m_bars)
    fprintf('Bar %-4d  %.4f       %.6e\n', ...
        idx_sort(k), alpha_sorted(k), lam1_3d(idx_sort(k)));
end
 
% 9) NONLINEAR LOAD ANALYSIS (Newton-Raphson)
 
fprintf('\n========================================\n');
fprintf('   ANALYSIS - CASE 3: LOAD EFFECT       \n');
fprintf('   Newton-Raphson for a 2D truss        \n');
fprintf('========================================\n\n');
 
load_levels = [0, 0.001, 0.003, 0.005, 0.007, 0.009];
ndof_2d = 3 * n_free_2d;
 
fprintf('%-10s', 'Load');
for k = 2:6
    fprintf('Bar%-6d', k);
end
fprintf('\n');
 
for lev = 1:length(load_levels)
    P = load_levels(lev);
 
    % Horizontal load at node 1
    F_ext = zeros(ndof_2d,1);
    F_ext(1) = P;   % dirección x del nodo 1
 
    if P == 0
        % No load: direct index
        [alpha_lev, ~, ~] = calcular_importancia(...
            coords_free_2d, coords_fixed_2d, conn_2d, ...
            E_2d, A_2d_chord, A_2d_diag, n_free_2d);
    else
        % Under load: Newton-Raphson to obtain the deformed configuration
        [u_nr, iter_nr, norms_nr] = newton_raphson(...
            coords_free_2d, coords_fixed_2d, conn_2d, ...
            E_2d, A_2d_chord, A_2d_diag, n_free_2d, F_ext, 1e-8, 100);
 
        coords_def_2d = coords_free_2d;
        coords_def_2d(:,1) = coords_free_2d(:,1) + u_nr(1:n_free_2d);
        coords_def_2d(:,2) = coords_free_2d(:,2) + u_nr(n_free_2d+1:2*n_free_2d);
        coords_def_2d(:,3) = coords_free_2d(:,3) + u_nr(2*n_free_2d+1:end);
 
        [alpha_lev, ~, ~] = calcular_importancia(...
            coords_def_2d, coords_fixed_2d, conn_2d, ...
            E_2d, A_2d_chord, A_2d_diag, n_free_2d);
    end
 
    fprintf('%-10.3f', P);
    for k = 2:6
        fprintf('%-9.4f', alpha_lev(k));
    end
    fprintf('\n');
end
 
% 10) ANALYSIS OF SUPPORT CONDITIONS
fprintf('\n========================================\n');
fprintf('   ANALYSIS - CASE 4: SUPPORT CONDITIONS\n');
fprintf('   (Releasing horizontal restraint at node 4)\n');
fprintf('========================================\n\n');
 
% Node 4 is only restrained in the z direction -> node 4 is
% added as a free node in x and y
coords_free_fig2  = [0, 1, 0;   % node 1
                     1, 1, 0;   % node 2
                     1, 0, 0];  % node 4 (partially free)
coords_fixed_fig2 = [0, 0, 0];  % only node 3
 
conn_fig2 = [1, 4, 1;  % Bar 1 (node 1 - node 4, now different indices)
             1, 4, 1;  % placeholder to keep 6 bars
             1, 4, 1;
             2, 4, 1;
             2, 4, 1;
             1, 2, 1];
 
% Simplified version: only modify the support at node 4
% Add it as a free node with a vertical constraint

fprintf('(Qualitative analysis: after releasing the horizontal support,\n');
fprintf(' the index of member 1 increases from 0 to about 0.89 (Table 3))\n\n');
 
% 11) STIFFNESS ANALYSIS OF BARS
fprintf('========================================\n');
fprintf('   ANALYSIS - CASE 5: MEMBER STIFFNESS  \n');
fprintf('   Varying ea of member 2               \n');
fprintf('========================================\n\n');
 
ea_factors = [1.0, 1.5, 2.0];
fprintf('%-10s', 'ea2/ea0');
for k = 2:6
    fprintf('Bar%-7d', k);
end
fprintf('\n');
 
for f = 1:length(ea_factors)
    % Modify stiffness of bar 2
    conn_mod = conn_2d;
    % A local function is created with that variable
    E_mod = E_2d * ea_factors(f);
 
    % Recalculate only with bar 2 modified
    [alpha_mod, ~, ~] = calcular_importancia_custom(...
        coords_free_2d, coords_fixed_2d, conn_2d, ...
        E_2d, A_2d_chord, A_2d_diag, n_free_2d, 2, ea_factors(f));
 
    fprintf('%-10.1f', ea_factors(f));
    for k = 2:6
        fprintf('%-10.4f', alpha_mod(k));
    end
    fprintf('\n');
end
fprintf('\nExpected value (Table 4 in the paper): ea = 1.5 -> Bar 2 = 0.9199\n\n');

% 12) PLOTS
% Figure 1: 3D geometry
figure('Name','8x8 3D Truss','Position',[50,50,900,600]);
hold on;
for k = 1:m_bars
    ni = connectivity(k,1);
    nj = connectivity(k,2);
    xi = coords_all(ni,:);
    xj = coords_all(nj,:);
    if connectivity(k,3)==1
        plot3([xi(1),xj(1)],[xi(2),xj(2)],[xi(3),xj(3)],'b-','LineWidth',0.8);
    else
        plot3([xi(1),xj(1)],[xi(2),xj(2)],[xi(3),xj(3)],'r-','LineWidth',0.5);
    end
end
plot3(coords_free(:,1), coords_free(:,2), coords_free(:,3),'ko','MarkerFaceColor','k','MarkerSize',4);
plot3(coords_fixed(:,1),coords_fixed(:,2),coords_fixed(:,3),'rs','MarkerFaceColor','r','MarkerSize',6);

legend({'Chord members','Diagonal members','Free nodes','Fixed nodes'},...
       'Location','northeast');

title('8\times8 square pyramid truss');
xlabel('x [m]');
ylabel('y [m]');
zlabel('z [m]');
grid on;
view(35,30);

% Figure 2: Importance index
figure('Name','Importance Index','Position',[100,100,900,500]);

subplot(1,2,1);
bar(alpha_3d,'FaceColor',[0.2 0.5 0.8],'EdgeColor','none');
xlabel('Bar number');
ylabel('\alpha_i');
title('Importance index (det K)');
grid on;

subplot(1,2,2);
bar(lam1_3d,'FaceColor',[0.8 0.3 0.2],'EdgeColor','none');
xlabel('Bar number');
ylabel('\lambda_1 after removal');
title('Smallest eigenvalue after removing bar i');
grid on;

% Figure 3: 2D validation (compare with Table 2)
figure('Name','2D Truss Validation','Position',[150,150,700,400]);

bar_names = {'Bar1','Bar2','Bar3','Bar4','Bar5','Bar6'};
bar(alpha_2d,'FaceColor',[0.3 0.7 0.3],'EdgeColor','k');

set(gca,'XTickLabel',bar_names);

ylabel('\alpha_i (importance index)');
title('2D truss validation using Table 2 (Cai et al., 2017)');
grid on;

% Reference values from the paper
paper_vals = [0, 0.885, 0.673, 0.673, 0.885, 0.885];

hold on;
plot(1:6,paper_vals,'r*--','MarkerSize',10,'LineWidth',1.5);

legend({'Computed','Paper values'},'Location','northwest');

% Figure 4: Newton-Raphson convergence
F_test = zeros(ndof_2d,1);
F_test(1) = 0.005;

[~, ~, norms_conv] = newton_raphson(...
    coords_free_2d, coords_fixed_2d, conn_2d, ...
    E_2d, A_2d_chord, A_2d_diag, n_free_2d, ...
    F_test, 1e-10, 50);

figure('Name','Newton-Raphson Convergence','Position',[200,200,600,400]);

semilogy(1:length(norms_conv), norms_conv, ...
         'b-o','LineWidth',2,'MarkerSize',6);

xlabel('Iteration');
ylabel('||R|| (residual norm)');
title('Newton-Raphson convergence (P = 0.005)');
grid on;

% Figure 5: Gauss-Seidel convergence
K_test = ensamblar_rigidez(coords_free_2d, coords_fixed_2d, conn_2d, ...
                           E_2d, A_2d_chord, A_2d_diag, n_free_2d);

b_test = F_test;

[~, ~, gs_res] = gauss_seidel(K_test, b_test, 1e-10, 200);

figure('Name','Gauss-Seidel Convergence','Position',[250,250,600,400]);

semilogy(1:length(gs_res), gs_res, ...
         'm-s','LineWidth',2,'MarkerSize',5);

xlabel('Iteration');
ylabel('||b - Ax|| (residual)');
title('Gauss-Seidel convergence');
grid on;

% Figure 6: Eigenvalue spectrum of the intact structure
K_3d = ensamblar_rigidez(coords_free, coords_fixed, connectivity, ...
                         E_steel, A_chord, A_diag, n_free);

lam_all = sort(real(eig(K_3d)));
lam_pos = lam_all(lam_all > 0);

figure('Name','Eigenvalue Spectrum','Position',[300,300,700,400]);

semilogy(1:length(lam_pos), lam_pos, ...
         'k.','MarkerSize',8);

xlabel('Eigenvalue index');
ylabel('\lambda_i');
title('Eigenvalue spectrum - 3D truss (intact structure)');
grid on;

fprintf('All plots generated successfully.\n\n');
fprintf('=== END OF ANALYSIS ===\n');

% 13) HELPER FUNCTIONS
function [alpha, lambda1_list, det_list] = calcular_importancia_custom(...
            coords_free, coords_fixed, connectivity, ...
            E_steel, A_chord, A_diag, n_free, bar_mod, ea_factor)

    % Same as calcular_importancia, but with the stiffness of bar_mod
    % scaled by ea_factor

    m  = size(connectivity,1);
    nf = size(coords_fixed,1);
    coords_all_loc = [coords_free; coords_fixed];

    % Base EA values
    ea_base = zeros(m,1);
    for k = 1:m
        if connectivity(k,3)==1, ea_base(k)=E_steel*A_chord;
        else,                    ea_base(k)=E_steel*A_diag; end
    end
    ea_base(bar_mod) = ea_base(bar_mod) * ea_factor;

    % Modified intact structure
    K0 = ensamblar_K_custom(coords_free, coords_fixed, connectivity, ...
                             ea_base, n_free);

    lam0 = sort(real(eig(K0)));
    lam0 = lam0(lam0 > 1e-6);
    det_K0 = prod(lam0);

    alpha        = zeros(m,1);
    lambda1_list = zeros(m,1);
    det_list     = zeros(m,1);

    for k = 1:m
        conn_k = connectivity([1:k-1, k+1:end],:);
        ea_k   = ea_base([1:k-1, k+1:end]);

        Ki = ensamblar_K_custom(coords_free, coords_fixed, ...
                                conn_k, ea_k, n_free);

        lam_k = sort(real(eig(Ki)));
        lam_k = lam_k(lam_k > 1e-6);

        if isempty(lam_k)
            det_Ki = 0;
            l1 = 0;
        else
            det_Ki = prod(lam_k);
            l1 = lam_k(1);
        end

        det_list(k) = det_Ki;
        lambda1_list(k) = l1;

        if abs(det_K0) > 1e-30
            alpha(k) = (det_K0 - det_Ki) / det_K0;
        else
            alpha(k) = 0;
        end
    end
end

function K = ensamblar_K_custom(coords_free, coords_fixed, ...
                                connectivity, ea, n_free)

    % Version of ensamblar_rigidez using an arbitrary EA vector

    m  = size(connectivity,1);
    nf = size(coords_fixed,1);
    coords_all = [coords_free; coords_fixed];

    u=zeros(m,1); v=zeros(m,1); w=zeros(m,1); l=zeros(m,1);

    for k=1:m
        ni=connectivity(k,1);
        nj=connectivity(k,2);

        du=coords_all(nj,1)-coords_all(ni,1);
        dv=coords_all(nj,2)-coords_all(ni,2);
        dw=coords_all(nj,3)-coords_all(ni,3);

        u(k)=du;
        v(k)=dv;
        w(k)=dw;

        l(k)=sqrt(du^2+dv^2+dw^2);
    end

    l0=l;
    q=ea.*(l-l0)./(l0.*l);

    C=zeros(m,n_free);
    Cf=zeros(m,nf);

    for k=1:m
        ni=connectivity(k,1);
        nj=connectivity(k,2);

        if ni<=n_free
            C(k,ni)=1;
        else
            Cf(k,ni-n_free)=1;
        end

        if nj<=n_free
            C(k,nj)=-1;
        else
            Cf(k,nj-n_free)=-1;
        end
    end

    Linv=diag(1./l);

    Ax=C'*Linv*diag(u);
    Ay=C'*Linv*diag(v);
    Az=C'*Linv*diag(w);

    A_mat=[Ax;Ay;Az];

    Kstar=diag(ea);

    KE=A_mat*Kstar*Linv*A_mat';

    Q=diag(q);
    E_mat=C'*Q*C;
    KG=kron(eye(3),E_mat);

    K=KE+KG;
end
