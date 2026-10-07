% =========================================================================
% TAREA 1: Carga de datos y visualización inicial
% =========================================================================

% readtable('datos_motor.csv'): Importa el contenido completo del archivo CSV y lo almacena 
% en la variable 'data' como una estructura de tabla, facilitando la manipulación por columnas.
data = readtable('datos_motor.csv');

% Extracción de variables: Se extraen los vectores de datos de la tabla. 
% Se omite la primera columna debido a un error de formato al convertir a CSV.
t = data{:,2};  % Asigna la columna 2 al vector de tiempo (t)
u = data{:,3};  % Asigna la columna 3 a la señal de excitación o escalón (u)
y = data{:,4};  % Asigna la columna 4 a la respuesta medida del motor (y)

% figure(...): Inicializa una nueva ventana gráfica en blanco para no sobrescribir gráficos anteriores.
figure('Name', 'Tarea 1 - Señales del Sistema', 'NumberTitle', 'off');

% plot(...): Traza ambas señales en una sola figura superpuesta. Grafica la excitación frente 
% al tiempo en color azul ('b') y la respuesta frente al tiempo en rojo ('r'), con grosor 1.5.
plot(t, u, 'b', t, y, 'r', 'LineWidth', 1.5);

% xlabel(...) y ylabel(...): Asignan las etiquetas a los ejes horizontal y vertical.
xlabel('Tiempo [s]');
ylabel('Amplitud');

% title(...): Establece el título principal en la parte superior de la gráfica.
title('Señal de excitación y respuesta del sistema');

% legend(...): Crea un cuadro explicativo que asocia los colores (azul y rojo) con 
% sus respectivas variables (u(t) y y(t)), ubicándolo automáticamente en la mejor posición ('best').
legend('Excitación u(t)', 'Respuesta y(t)', 'Location', 'best');

% grid on: Activa una cuadrícula de fondo para facilitar la lectura visual de coordenadas.
grid on;

% =========================================================================
% TAREA 2: Cálculo de Líneas de Referencia y Recta Tangente (Varianza Móvil)
% =========================================================================

% --- 1. Líneas de Referencia ---
% find(...): Busca el primer índice donde la excitación 'u' es mayor a 0 y se le resta 1 
% para obtener el índice exacto justo antes de que inicie el escalón.
idx_escalon = find(u > 0, 1) - 1; 

% mean(...): Promedia los valores de 'y' antes del escalón para definir la línea base inmune al ruido inicial.
linea_base = mean(y(1:idx_escalon));

% Se seleccionan los índices donde el sistema ya se estabilizó (ej. valores mayores a 0.9) 
% y se promedian para trazar una línea del 100% precisa.
indices_estables = (y > 0.9); 
linea_100 = mean(y(indices_estables));

% --- 2. Detección del Punto de Inflexión (Varianza Móvil) ---
% Se define una ventana de 5 muestras para analizar estadísticamente pequeños tramos de la señal.
tamano_ventana = 5; 

% movvar(...): Calcula la varianza móvil. El sector de la curva con el cambio más brusco 
% (máxima pendiente) tendrá la varianza más alta, ignorando el ruido de alta frecuencia.
varianza_movil = movvar(y, tamano_ventana);

% max(...): Encuentra el valor máximo de la varianza móvil y guarda su índice (idx_inflexion).
[~, idx_inflexion] = max(varianza_movil);

% Se extraen las coordenadas de tiempo y amplitud exactas del punto de inflexión.
t_inflexion = t(idx_inflexion);
y_inflexion = y(idx_inflexion);

% --- 3. Cálculo de la Recta Tangente ---
% Se toma una pequeña ventana simétrica alrededor del punto de inflexión (5 puntos en total).
rango_pendiente = (idx_inflexion - 2) : (idx_inflexion + 2);

% polyfit(...): Realiza un ajuste lineal (polinomio de grado 1) sobre esa pequeña ventana 
% para obtener la ecuación de la recta de forma robusta.
coeficientes = polyfit(t(rango_pendiente), y(rango_pendiente), 1);
m = coeficientes(1); % El primer coeficiente es la pendiente (m)

% Se despeja la coordenada 't' de la ecuación de la recta (y - y1 = m*(t - t1)) 
% para hallar las intersecciones con las líneas de referencia.
t_base = (linea_base - y_inflexion) / m + t_inflexion;
t_100 = (linea_100 - y_inflexion) / m + t_inflexion;

% --- 4. Salida de Resultados y Visualización ---
% disp(...): Imprime en la consola los valores de los cortes para mostrarlos al docente.
disp('--- TAREA 2: Valores de Corte ---');
disp(['Corte con Línea Base (t_base): ', num2str(t_base), ' s']);
disp(['Corte con Línea 100% (t_100): ', num2str(t_100), ' s']);

% Se crea una nueva figura para presentar el análisis geométrico solicitado.
figure('Name', 'Tarea 2 - Análisis Geométrico', 'NumberTitle', 'off');
plot(t, u, 'b', t, y, 'r', 'LineWidth', 1.5); 
hold on; grid on; % hold on permite superponer las nuevas líneas en la misma gráfica.

% yline(...): Traza líneas horizontales infinitas para denotar el 0% y el 100% del sistema.
yline(linea_base, '--k', 'Línea Base', 'LabelHorizontalAlignment', 'left');
yline(linea_100, '--k', 'Línea 100%', 'LabelHorizontalAlignment', 'left');

% plot(...): Se traza un segmento de línea magenta ('m-') que une los puntos de corte, 
% graficando así la recta tangente calculada.
plot([t_base, t_100], [linea_base, linea_100], 'm-', 'LineWidth', 1.5, 'DisplayName', 'Tangente');

% Se grafica un punto verde ('go') para marcar visualmente dónde detectó el algoritmo el punto de inflexión.
plot(t_inflexion, y_inflexion, 'go', 'MarkerFaceColor', 'g');

title('Tarea 2: Agregado de Líneas de Referencia y Recta Tangente');
xlabel('Tiempo [s]'); ylabel('Amplitud');
legend('Excitación', 'Respuesta', 'Línea Base', 'Línea 100%', 'Recta Tangente', 'Punto Inflexión', 'Location', 'best');

% =========================================================================
% TAREA 3: Métodos FOTD, Funciones de Transferencia, RMSE y Gráfica Única
% =========================================================================

% Calcular los cambios (deltas) y la Ganancia Estática (K)
delta_u = max(u) - min(u); % Magnitud del escalón (es 1.5 en la tabla datos)
cambio_y = linea_100 - linea_base;
K = cambio_y / delta_u;


% Definimos el tiempo absoluto en que arranca el escalón para referenciar el tiempo muerto
t_escalon = t(idx_escalon + 1);

% --- 1. Método de Ziegler & Nichols ---
% El retardo (theta) es la diferencia entre el inicio del escalón y el cruce con la línea base.
theta_zn = t_base - t_escalon;
% La constante de tiempo (tau) es la diferencia entre los dos cruces geométricos calculados en la Tarea 2.
tau_zn = t_100 - t_base;

% --- 2. Método de Miller ---
% Se calcula la amplitud correspondiente al 63.21% de la respuesta total.
valor_63 = linea_base + 0.6321 * (linea_100 - linea_base);
% find(...): Busca el primer índice donde la respuesta real supera ese 63.21%
idx_63 = find(y >= valor_63, 1);
% Se interpola linealmente entre ese punto y el anterior para hallar el tiempo exacto.
t_63_abs = t(idx_63-1) + (t(idx_63)-t(idx_63-1))/(y(idx_63)-y(idx_63-1))*(valor_63-y(idx_63-1));
% Se transforma a tiempo relativo restando el inicio del escalón.
t_63_relativo = t_63_abs - t_escalon;
% Miller hereda el retardo geométrico de la tangente. Tau es la diferencia hasta el 63.2%.
theta_miller = theta_zn; 
tau_miller = t_63_relativo - theta_miller;

% --- 3. Método Analítico ---
% Se repite el proceso de interpolación, pero ahora para el 28.3% de la curva.
valor_28 = linea_base + 0.283 * (linea_100 - linea_base);
idx_28 = find(y >= valor_28, 1);
t_28_abs = t(idx_28-1) + (t(idx_28)-t(idx_28-1))/(y(idx_28)-y(idx_28-1))*(valor_28-y(idx_28-1));
t_28_relativo = t_28_abs - t_escalon;
% Fórmulas algebraicas propias del Método Analítico:
tau_analitico = 1.5 * (t_63_relativo - t_28_relativo);
theta_analitico = t_63_relativo - tau_analitico;
disp('--- TAREA 3: Resultados para la Tabla ---');
% --- 4. Construcción de Modelos G(s) y Simulación ---
% tf(...): Construye la función de transferencia definiendo numerador [K], denominador [tau 1] y el retardo.
G_zn = tf(K, [tau_zn 1], 'InputDelay', theta_zn)
G_miller = tf(K, [tau_miller 1], 'InputDelay', theta_miller)
G_ana = tf(K, [tau_analitico 1], 'InputDelay', theta_analitico)

% lsim(...): Simula la respuesta dinámica de cada G(s) sometiéndola al vector de entrada real 'u'.
y_zn = lsim(G_zn, u, t);
y_miller = lsim(G_miller, u, t);
y_ana = lsim(G_ana, u, t);

% --- 5. Cálculo del RMSE ---
% mean(...): Calcula el promedio de los errores cuadrados (ECM).
% sqrt(...): Obtiene la raíz cuadrada del ECM para entregar el RMSE solicitado en la rúbrica.
rmse_zn = sqrt(mean((y - y_zn).^2));
rmse_miller = sqrt(mean((y - y_miller).^2));
rmse_ana = sqrt(mean((y - y_ana).^2));

% --- 6. Gráfica Única (Datos Reales + 3 Modelos) ---
figure('Name', 'Tarea 3 - Comparación de Modelos', 'NumberTitle', 'off');
hold on; grid on;

% Gráfica de los datos reales base.
plot(t, u, 'b', 'LineWidth', 1.5, 'DisplayName', 'Escalón Entrada');
plot(t, y, 'r', 'LineWidth', 1.5, 'DisplayName', 'Salida Real (Motor)');

% Gráfica de las 3 simulaciones matemáticas con distintos estilos de trazo.
plot(t, y_zn, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Modelo Z-N');
plot(t, y_miller, 'c-.', 'LineWidth', 1.5, 'DisplayName', 'Modelo Miller');
plot(t, y_ana, 'g:', 'LineWidth', 2.5, 'DisplayName', 'Modelo Analítico');

title('Comparación: Sistema Real vs. Modelos Identificados');
xlabel('Tiempo [s]'); ylabel('Amplitud');
legend('Location', 'best');

% --- 7. Impresión de Resultados en Consola (Para llenar la tabla del informe) ---

fprintf('Z-N       -> K: %.3f | Theta: %.3fs | Tau: %.3fs | RMSE: %.5f\n', K, theta_zn, tau_zn, rmse_zn);
fprintf('Miller    -> K: %.3f | Theta: %.3fs | Tau: %.3fs | RMSE: %.5f\n', K, theta_miller, tau_miller, rmse_miller);
fprintf('Analítico -> K: %.3f | Theta: %.3fs | Tau: %.3fs | RMSE: %.5f\n', K, theta_analitico, tau_analitico, rmse_ana);
