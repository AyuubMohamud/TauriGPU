# Kevin's Verilator testbench

/home/kvl01/tools/oss-cad-suite/bin/verilator -Wall --trace -cc fp_mul.sv --exe tb_mul.cpp
cd obj_dir
make -f Vfp_mul.mk Vfp_mul
./Vfp_mul