function drawCity(city, cityAxes, graphAxes, portraitPhaseAxes)
% Pinta todas las gráficas

cla(cityAxes);
cla(graphAxes);
cla(portraitPhaseAxes);

hold(cityAxes, 'on');
hold(graphAxes, 'on');
hold(portraitPhaseAxes, 'on');

%% Gráfica de la ciudad

% Dibuja las casas
xx = zeros(4,city.Homes.length());
yy = zeros(4, city.Homes.length());

for i = 1 : city.Homes.length()
    b = city.Homes.getAt(i);

    xx(:, i) = [b.X, b.X + b.Width, b.X + b.Width, b.X];
    yy(:, i) = [b.Y, b.Y, b.Y + b.Height, b.Y + b.Height];
end

patch(cityAxes, 'XData', xx, 'YData',  yy, 'FaceColor', 'none', 'EdgeColor', [0 0 1]);

% Dibuja los edificios
xx = zeros(4,city.NoHomes.length());
yy = zeros(4, city.NoHomes.length());

for i = 1 : city.NoHomes.length()
    b = city.NoHomes.getAt(i);

    xx(:, i) = [b.X, b.X + b.Width, b.X + b.Width, b.X];
    yy(:, i) = [b.Y, b.Y, b.Y + b.Height, b.Y + b.Height];
end

patch(cityAxes, 'XData', xx, 'YData',  yy, 'FaceColor', 'none', 'EdgeColor', [0.4 0.4 0.4]);

% Dibuja a las personas
sx = zeros(1, city.getSusceptibleCount());
sy = zeros(1, city.getSusceptibleCount());
ix = zeros(1, city.getInfectiousCount());
iy = zeros(1, city.getInfectiousCount());
rx = zeros(1, city.getRecoveredCount());
ry = zeros(1, city.getRecoveredCount());
sc = 1;
ic = 1;
rc = 1;
for i = 1 : city.Population.length()
    p = city.Population.getAt(i);
   
    % Casos para diferentes estados
    if p.isSusceptible()
        sx(1, sc) = p.X;
        sy(1, sc) = p.Y;
        sc = sc + 1;
    elseif p.isInfectious()
        ix(1, ic) = p.X;
        iy(1, ic) = p.Y;
        ic = ic + 1;
    elseif p.isRecovered()
        rx(1, rc) = p.X;
        ry(1, rc) = p.Y;
        rc = rc + 1;
    end
end

scatter(cityAxes, sx, sy, 25, [0 0 1], 'filled');
scatter(cityAxes, ix, iy, 25, [1 0 0], 'filled');
scatter(cityAxes, rx, ry, 25, [0.4 0.4 0.4], 'filled');


%% Gráfica ISR
i = city.InfectiousByHour;
r = city.RecoveredByHour;

% Pinta un cuadro en el fondo
rh = city.getRealHour();

% Fixes for the first iteration
if rh == 0
    rh = 1;
end
xaxis = linspace(0, rh / 24, rh + 1);
area(graphAxes, xaxis, city.PopulationByHour(2, :));
area(graphAxes, xaxis, city.RecoveredByHour(2, :), 'FaceColor', [0.4 0.4 0.4]);
area(graphAxes, xaxis, city.InfectiousByHour(2, :), 'FaceColor', [1 0 0]);

axis(graphAxes, [0, rh / 24, 0, city.getOriginalPopulationSize()]);


%% Gráfica del retrato fase

% El tiempo
t0 = 0;
tf = 100;

% Valores de la epidemia
beta = city.getInfectionRate();
gamma = city.getRecoveryRate();

% Función
f = @(t, Y) [
            -beta * Y(1) * Y(2) ; % Tasa de infección
             beta * Y(1) * Y(2) - gamma * Y(2); % Tasa de susceptibles
             gamma * Y(2) % Tasa de retirados
             ];
 
         
% Valores iniciales
hours = city.getRealHour();

if hours < 1
    hours = 1;
end

hoursInterval = 12;
fixedHours = floor(hours / hoursInterval);
Y0s = zeros(3, fixedHours);

% Solo hace cuando hay suficientes datos
for i = 1 : fixedHours
    ss = city.SusceptiblesByHour(2, i * hoursInterval);
    ii = city.InfectiousByHour(2, i * hoursInterval);
    rr = city.RecoveredByHour(2, i * hoursInterval);
    Y0s(:, i) = [ss, ii, rr];
end

         
% Plotear retrato fase

% Plotea algunas soluciones
[~, n] = size(Y0s);

max_x = -inf;
max_y = -inf;
for i = 1 : n
    % Obtiene solucion
    [~,ys] = ode45(f, [t0 tf], Y0s(:, i));
    % Guarda el valor máximo y mínimo de cada eje
    new_max_x = max(ys(:, 1));
    new_max_y = max(ys(:, 2));
    if new_max_x > max_x
        max_x = new_max_x;
    end
    if new_max_y > max_y
        max_y = new_max_y;
    end
    
    % Plotea la solución
    plot3(portraitPhaseAxes, ys(:,1), ys(:,2), ys(:, 3), 'LineWidth', 2)
    plot3(portraitPhaseAxes, ys(1,1), ys(1,2), ys(1, 3),'bo') % starting point
    plot3(portraitPhaseAxes, ys(end,1), ys(end,2), ys(end, 3),'ks') % ending point
end

% Luego plotea los vectores direccionales

% El mayor eje para que todo sea proporcional
max_val = max(max_x, max_y);
arrow_quantity = 15;
% Y plotea
y1 = linspace(0, max_val, arrow_quantity);
y2 = linspace(0, max_val, arrow_quantity);
y3 = linspace(0, max_val, arrow_quantity);
[x, y, z] = meshgrid(y1, y2, y3);

u = zeros(size(x));
v = zeros(size(y));
w = zeros(size(z));

for i = 1 : numel(x)
    % Se asume que el tiempo inicial es cero
    ydot = f(0, [x(i) ; y(i) ; z(i)]);
    u(i) = ydot(1);
    v(i) = ydot(2);
    w(i) = ydot(3);
end

% Dibuja las flechas
quiver3(portraitPhaseAxes, x, y, z, u, v, w, 'r');

axis(portraitPhaseAxes, [0, city.getOriginalPopulationSize(), 0, city.getOriginalPopulationSize()]);
end

