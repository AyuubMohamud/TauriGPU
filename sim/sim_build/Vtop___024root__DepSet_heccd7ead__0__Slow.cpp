// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "Vtop__pch.h"
#include "Vtop___024root.h"

VL_ATTR_COLD void Vtop___024root___eval_static(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vtop___024root___eval_initial(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_initial\n"); );
    // Body
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = vlSelf->clk;
}

VL_ATTR_COLD void Vtop___024root___eval_final(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_final\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__stl(Vtop___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtop___024root___eval_phase__stl(Vtop___024root* vlSelf);

VL_ATTR_COLD void Vtop___024root___eval_settle(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_settle\n"); );
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelf->__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("/home/kvl01/TauriGPU/rtl/core/fp/fp_mul.sv", 1, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vtop___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelf->__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__stl(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ vlSelf->__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

void Vtop___024root___ico_sequent__TOP__0(Vtop___024root* vlSelf);

VL_ATTR_COLD void Vtop___024root___eval_stl(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        Vtop___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vtop___024root___eval_triggers__stl(Vtop___024root* vlSelf);

VL_ATTR_COLD bool Vtop___024root___eval_phase__stl(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__stl\n"); );
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtop___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelf->__VstlTriggered.any();
    if (__VstlExecute) {
        Vtop___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__ico(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ vlSelf->__VicoTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__act(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ vlSelf->__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__nba(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ vlSelf->__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtop___024root___ctor_var_reset(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->a = VL_RAND_RESET_I(24);
    vlSelf->b = VL_RAND_RESET_I(24);
    vlSelf->result = VL_RAND_RESET_I(24);
    vlSelf->fp_mul__DOT__clk = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__a = VL_RAND_RESET_I(24);
    vlSelf->fp_mul__DOT__b = VL_RAND_RESET_I(24);
    vlSelf->fp_mul__DOT__result = VL_RAND_RESET_I(24);
    vlSelf->fp_mul__DOT__product_o = VL_RAND_RESET_I(17);
    vlSelf->fp_mul__DOT__zero_flag_o = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__sign_xor_o = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__sum_exp_o = VL_RAND_RESET_I(9);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__clk = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__a = VL_RAND_RESET_I(24);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__b = VL_RAND_RESET_I(24);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__product_o = VL_RAND_RESET_I(17);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__zero_flag_o = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign_xor_o = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sum_exp_o = VL_RAND_RESET_I(9);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign1 = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign2 = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp1 = VL_RAND_RESET_I(8);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp2 = VL_RAND_RESET_I(8);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_1 = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_2 = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant1 = VL_RAND_RESET_I(16);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant2 = VL_RAND_RESET_I(16);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__product = VL_RAND_RESET_I(32);
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__clk = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__product_i = VL_RAND_RESET_I(17);
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__zero_flag_i = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sign_xor_i = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sum_exp_i = VL_RAND_RESET_I(9);
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__result_o = VL_RAND_RESET_I(24);
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sign_o = VL_RAND_RESET_I(1);
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__exp_o = VL_RAND_RESET_I(9);
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__mant_o = VL_RAND_RESET_I(15);
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
}
