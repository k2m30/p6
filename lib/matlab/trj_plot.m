#!/usr/local/bin/octave
%graphics_toolkit gnuplot

data = dlmread('0.csv', ',', 2, 0);
pt.p = deg2rad(data(:, 1));
pt.v = deg2rad(data(:, 2));
pt.t = cumsum(data(:, 7)) * 1e-3;
pt.a = deg2rad(data(:, 3));;


dt = 1e-2;

[t, q] = qupsample(pt, dt);

subplot(2, 1, 1); plot(t, rad2deg(q)); grid;
hold on;
plot(pt.t, rad2deg(pt.p), '-');
hold off
vq = [0 diff(rad2deg(q)/dt)];

subplot(2, 1, 2); plot(t, vq); grid;
hold on;
plot(pt.t, rad2deg(pt.v), '-');
hold off;

pause
