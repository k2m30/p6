function a = trj_coeff(pf, vf, af, ps, vs, as, dt)
%        float32_t TTRJ = ptrNewPoint->endTime - ptrNewPoint->startTime;
%         float32_t TTRJ2 = TTRJ * TTRJ;
%         float32_t TTRJ3 = TTRJ * TTRJ2;
%         float32_t TTRJ4 = TTRJ * TTRJ3;
%         float32_t TTRJ5 = TTRJ * TTRJ4;
% 
% #define COEF_MTN (ptrNewPoint->coefVector)
% #define ACC_S (ptrNewPoint->startAcc)
% #define ACC_F (ptrNewPoint->endAcc)
% #define VEL_S (ptrNewPoint->startVel)
% #define VEL_F (ptrNewPoint->endVel)
% #define POS_S (ptrNewPoint->startPos)
% #define POS_F (ptrNewPoint->endPos)
% 
% COEF_MTN[0] = POS_S;
% COEF_MTN[1] = VEL_S;
% COEF_MTN[2] = ACC_S / 2;
% COEF_MTN[3] = -(20 * POS_S - 20 * POS_F + 8 * TTRJ * VEL_F + 12 * TTRJ * VEL_S - ACC_F * TTRJ2 + 3 * ACC_S * TTRJ2) / (2 * TTRJ3);
% COEF_MTN[4] = (30 * POS_S - 30 * POS_F + 14 * TTRJ * VEL_F + 16 * TTRJ * VEL_S - 2 * ACC_F * TTRJ2 + 3 * ACC_S * TTRJ2) / (2 * TTRJ4);
% COEF_MTN[5] = -(12 * POS_S - 12 * POS_F + 6 * TTRJ * VEL_F + 6 * TTRJ * VEL_S - ACC_F * TTRJ2 + ACC_S * TTRJ2) / (2 * TTRJ5);






    a(1) = ps;
    a(2) = vs;
    a(3) = as / 2;
    a(4) = -(20 * ps - 20 * pf + 8 * dt * vf + 12 * dt * vs - af * dt^2 + 3 * as * dt^2) / (2 * dt^3);
    a(5) = (30 * ps - 30 * pf + 14 * dt * vf + 16 * dt * vs - 2 * af * dt^2 + 3 * as * dt^2) / (2 * dt^4);
    a(6) = -(12 * ps - 12 * pf + 6 * dt * vf + 6 * dt * vs - af * dt^2 + as * dt^2) / (2 * dt^5);
end