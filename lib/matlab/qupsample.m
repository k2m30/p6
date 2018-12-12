function [t, q] = qupsample(pt, dt)
    t = 0:dt:max(pt.t);
    q = zeros(1, length(t));

    for k = 1:(length(pt.t)-1)
        a = trj_coeff(pt.p(k+1), pt.v(k+1), pt.a(k+1), ...
            pt.p(k), pt.v(k), pt.a(k), ...
            pt.t(k+1) - pt.t(k));

        ind = (t >= pt.t(k)) & (t < pt.t(k+1));

        q(ind) = trj(a, t(ind) - pt.t(k));
    end
end