#!/usr/local/bin/octave
graphics_toolkit fltk
% pt.v = [0:1:100, ones(1,100)*100, 100:-1:0]
pt.v = [0:1:100, 99:-1:0]
pt.t = (0:1:200)/1000
pt.p = cumtrapz(pt.t,pt.v);
pt.a = pt.t * 0;
dt = 1e-3;

[t, q] = qupsample(pt, dt);

subplot(2, 1, 1); plot(t, rad2deg(q)); grid;
hold on;
plot(pt.t, rad2deg(pt.p), '-');
hold off
vq = [0 diff(rad2deg(q)/dt)];

subplot(2, 1, 2);
plot(t, vq);
grid;
hold on;
plot(pt.t, rad2deg(pt.v), '-');
hold off;

s_real = sum(vq)*dt
pause
