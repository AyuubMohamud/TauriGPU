#include <cstdio>
#include "VtexCoordOps.h"


int main() {
    VtexCoordOps* tx = new VtexCoordOps;

    tx->texture_s_i = 0x3fe000;
    tx->texture_t_i = 0xbf4000;
    tx->texture_wrapT_mode_i = 2;
    tx->eval();

    printf("0x%04X, 0x%04X\n", tx->s, tx->t);
    delete tx;
}