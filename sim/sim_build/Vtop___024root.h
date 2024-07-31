// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop.h for the primary calling header

#ifndef VERILATED_VTOP___024ROOT_H_
#define VERILATED_VTOP___024ROOT_H_  // guard

#include "verilated.h"


class Vtop__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtop___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    CData/*0:0*/ fp_mul__DOT__clk;
    CData/*0:0*/ fp_mul__DOT__zero_flag_o;
    CData/*0:0*/ fp_mul__DOT__sign_xor_o;
    CData/*0:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__clk;
    CData/*0:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__zero_flag_o;
    CData/*0:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__sign_xor_o;
    CData/*0:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__sign1;
    CData/*0:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__sign2;
    CData/*7:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__exp1;
    CData/*7:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__exp2;
    CData/*0:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_1;
    CData/*0:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_2;
    CData/*0:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__clk;
    CData/*0:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__zero_flag_i;
    CData/*0:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__sign_xor_i;
    CData/*0:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__sign_o;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __VactContinue;
    SData/*8:0*/ fp_mul__DOT__sum_exp_o;
    SData/*8:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__sum_exp_o;
    SData/*15:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__mant1;
    SData/*15:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__mant2;
    SData/*8:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__sum_exp_i;
    SData/*8:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__exp_o;
    SData/*14:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__mant_o;
    VL_IN(a,23,0);
    VL_IN(b,23,0);
    VL_OUT(result,23,0);
    IData/*23:0*/ fp_mul__DOT__a;
    IData/*23:0*/ fp_mul__DOT__b;
    IData/*23:0*/ fp_mul__DOT__result;
    IData/*16:0*/ fp_mul__DOT__product_o;
    IData/*23:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__a;
    IData/*23:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__b;
    IData/*16:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__product_o;
    IData/*31:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__product;
    IData/*16:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__product_i;
    IData/*23:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__result_o;
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop__Syms* const vlSymsp;

    // PARAMETERS
    static constexpr IData/*31:0*/ fp_mul__DOT__WIDTH = 0x00000018U;
    static constexpr IData/*31:0*/ fp_mul__DOT__fp_mul_0_inst__DOT__WIDTH = 0x00000018U;
    static constexpr IData/*31:0*/ fp_mul__DOT__fp_mul_1_inst__DOT__WIDTH = 0x00000018U;

    // CONSTRUCTORS
    Vtop___024root(Vtop__Syms* symsp, const char* v__name);
    ~Vtop___024root();
    VL_UNCOPYABLE(Vtop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
