# TODO [[8,1,3]] qubit code

struct code833 <: AbstractECC end

parity_checks(c::code833) = S"XXXXXXXX
                              ZZZZZZZZ
                              _X_XYZYZ
                              _XZY_XZY
                              _YXZXZ_Y"

parity_checks_x(c::code833) = stab_to_gf2(parity_checks(code833()))[1:3,1:end÷2]
parity_checks_z(c::code833) = stab_to_gf2(parity_checks(code833()))[5:end,end÷2+1:end]

distance(c::code833) = 3