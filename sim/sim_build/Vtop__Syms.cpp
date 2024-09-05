// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vtop__pch.h"
#include "Vtop.h"
#include "Vtop___024root.h"

// FUNCTIONS
Vtop__Syms::~Vtop__Syms()
{

    // Tear down scope hierarchy
    __Vhier.remove(0, &__Vscope_fp_mul);
    __Vhier.remove(&__Vscope_fp_mul, &__Vscope_fp_mul__fp_mul_0_inst);
    __Vhier.remove(&__Vscope_fp_mul, &__Vscope_fp_mul__fp_mul_1_inst);

}

Vtop__Syms::Vtop__Syms(VerilatedContext* contextp, const char* namep, Vtop* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(25);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    // Setup scopes
    __Vscope_TOP.configure(this, name(), "TOP", "TOP", 0, VerilatedScope::SCOPE_OTHER);
    __Vscope_fp_mul.configure(this, name(), "fp_mul", "fp_mul", -12, VerilatedScope::SCOPE_MODULE);
    __Vscope_fp_mul__fp_mul_0_inst.configure(this, name(), "fp_mul.fp_mul_0_inst", "fp_mul_0_inst", -12, VerilatedScope::SCOPE_MODULE);
    __Vscope_fp_mul__fp_mul_1_inst.configure(this, name(), "fp_mul.fp_mul_1_inst", "fp_mul_1_inst", -12, VerilatedScope::SCOPE_MODULE);

    // Set up scope hierarchy
    __Vhier.add(0, &__Vscope_fp_mul);
    __Vhier.add(&__Vscope_fp_mul, &__Vscope_fp_mul__fp_mul_0_inst);
    __Vhier.add(&__Vscope_fp_mul, &__Vscope_fp_mul__fp_mul_1_inst);

    // Setup export functions
    for (int __Vfinal = 0; __Vfinal < 2; ++__Vfinal) {
        __Vscope_TOP.varInsert(__Vfinal,"a", &(TOP.a), false, VLVT_UINT32,VLVD_IN|VLVF_PUB_RW,1 ,23,0);
        __Vscope_TOP.varInsert(__Vfinal,"b", &(TOP.b), false, VLVT_UINT32,VLVD_IN|VLVF_PUB_RW,1 ,23,0);
        __Vscope_TOP.varInsert(__Vfinal,"clk", &(TOP.clk), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
        __Vscope_TOP.varInsert(__Vfinal,"result", &(TOP.result), false, VLVT_UINT32,VLVD_OUT|VLVF_PUB_RW,1 ,23,0);
        __Vscope_fp_mul.varInsert(__Vfinal,"WIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.fp_mul__DOT__WIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_fp_mul.varInsert(__Vfinal,"a", &(TOP.fp_mul__DOT__a), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_fp_mul.varInsert(__Vfinal,"b", &(TOP.fp_mul__DOT__b), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_fp_mul.varInsert(__Vfinal,"clk", &(TOP.fp_mul__DOT__clk), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul.varInsert(__Vfinal,"product_o", &(TOP.fp_mul__DOT__product_o), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,16,0);
        __Vscope_fp_mul.varInsert(__Vfinal,"result", &(TOP.fp_mul__DOT__result), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_fp_mul.varInsert(__Vfinal,"sign_xor_o", &(TOP.fp_mul__DOT__sign_xor_o), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul.varInsert(__Vfinal,"sum_exp_o", &(TOP.fp_mul__DOT__sum_exp_o), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,8,0);
        __Vscope_fp_mul.varInsert(__Vfinal,"zero_flag_o", &(TOP.fp_mul__DOT__zero_flag_o), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"WIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__WIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"a", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__a), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"b", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__b), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"clk", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__clk), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"exp1", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__exp1), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"exp2", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__exp2), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"mant1", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__mant1), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"mant2", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__mant2), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,15,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"mantissa_top_bit_1", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_1), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"mantissa_top_bit_2", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_2), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"product", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__product), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"product_o", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__product_o), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,16,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"sign1", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__sign1), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"sign2", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__sign2), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"sign_xor_o", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__sign_xor_o), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"sum_exp_o", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__sum_exp_o), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,8,0);
        __Vscope_fp_mul__fp_mul_0_inst.varInsert(__Vfinal,"zero_flag_o", &(TOP.fp_mul__DOT__fp_mul_0_inst__DOT__zero_flag_o), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"WIDTH", const_cast<void*>(static_cast<const void*>(&(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__WIDTH))), true, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,31,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"clk", &(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__clk), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"exp_o", &(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__exp_o), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,8,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"mant_o", &(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__mant_o), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,14,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"product_i", &(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__product_i), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,16,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"result_o", &(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__result_o), false, VLVT_UINT32,VLVD_NODIR|VLVF_PUB_RW,1 ,23,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"sign_o", &(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__sign_o), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"sign_xor_i", &(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__sign_xor_i), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"sum_exp_i", &(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__sum_exp_i), false, VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,8,0);
        __Vscope_fp_mul__fp_mul_1_inst.varInsert(__Vfinal,"zero_flag_i", &(TOP.fp_mul__DOT__fp_mul_1_inst__DOT__zero_flag_i), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
    }
}
