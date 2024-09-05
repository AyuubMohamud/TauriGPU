// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "Vtop__pch.h"
#include "Vtop___024root.h"

void Vtop___024root___ico_sequent__TOP__0(Vtop___024root* vlSelf);

void Vtop___024root___eval_ico(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_ico\n"); );
    // Body
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        Vtop___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vtop___024root___ico_sequent__TOP__0(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___ico_sequent__TOP__0\n"); );
    // Body
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign1 
        = (1U & (vlSelf->a >> 0x17U));
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign2 
        = (1U & (vlSelf->b >> 0x17U));
    vlSelf->fp_mul__DOT__a = vlSelf->a;
    vlSelf->fp_mul__DOT__b = vlSelf->b;
    vlSelf->fp_mul__DOT__product_o = vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__product_o;
    vlSelf->fp_mul__DOT__zero_flag_o = vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__zero_flag_o;
    vlSelf->fp_mul__DOT__sign_xor_o = vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign_xor_o;
    vlSelf->fp_mul__DOT__sum_exp_o = vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sum_exp_o;
    vlSelf->fp_mul__DOT__clk = vlSelf->clk;
    vlSelf->fp_mul__DOT__result = ((0xfeU < (IData)(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__exp_o))
                                    ? 0x7f8000U : (
                                                   ((IData)(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sign_o) 
                                                    << 0x17U) 
                                                   | ((0x7f8000U 
                                                       & ((IData)(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__exp_o) 
                                                          << 0xfU)) 
                                                      | (IData)(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__mant_o))));
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp1 = 
        (0xffU & (vlSelf->a >> 0xfU));
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp2 = 
        (0xffU & (vlSelf->b >> 0xfU));
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__a = vlSelf->fp_mul__DOT__a;
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__b = vlSelf->fp_mul__DOT__b;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__product_i 
        = vlSelf->fp_mul__DOT__product_o;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__zero_flag_i 
        = vlSelf->fp_mul__DOT__zero_flag_o;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sign_xor_i 
        = vlSelf->fp_mul__DOT__sign_xor_o;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sum_exp_i 
        = vlSelf->fp_mul__DOT__sum_exp_o;
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__clk = vlSelf->fp_mul__DOT__clk;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__clk = vlSelf->fp_mul__DOT__clk;
    vlSelf->result = vlSelf->fp_mul__DOT__result;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__result_o 
        = vlSelf->fp_mul__DOT__result;
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_1 
        = (0U != (IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp1));
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_2 
        = (0U != (IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp2));
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant1 
        = (((IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_1) 
            << 0xfU) | (0x7fffU & vlSelf->a));
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant2 
        = (((IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_2) 
            << 0xfU) | (0x7fffU & vlSelf->b));
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__product 
        = ((IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant1) 
           * (IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant2));
}

void Vtop___024root___eval_triggers__ico(Vtop___024root* vlSelf);

bool Vtop___024root___eval_phase__ico(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__ico\n"); );
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vtop___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelf->__VicoTriggered.any();
    if (__VicoExecute) {
        Vtop___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vtop___024root___eval_act(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_act\n"); );
}

void Vtop___024root___nba_sequent__TOP__0(Vtop___024root* vlSelf);

void Vtop___024root___eval_nba(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_nba\n"); );
    // Body
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vtop___024root___nba_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vtop___024root___nba_sequent__TOP__0(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___nba_sequent__TOP__0\n"); );
    // Body
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__product_o 
        = (vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__product 
           >> 0xfU);
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign_xor_o 
        = ((IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign1) 
           ^ (IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign2));
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sign_o 
        = ((1U & (~ (IData)(vlSelf->fp_mul__DOT__zero_flag_o))) 
           && (IData)(vlSelf->fp_mul__DOT__sign_xor_o));
    if (vlSelf->fp_mul__DOT__zero_flag_o) {
        vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__mant_o = 0U;
        vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__exp_o = 0U;
    } else if ((0x10000U & vlSelf->fp_mul__DOT__product_o)) {
        vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__mant_o 
            = (0x7fffU & (vlSelf->fp_mul__DOT__product_o 
                          >> 1U));
        vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__exp_o 
            = (0x1ffU & ((IData)(vlSelf->fp_mul__DOT__sum_exp_o) 
                         - (IData)(0x7eU)));
    } else {
        vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__mant_o 
            = (0x7fffU & vlSelf->fp_mul__DOT__product_o);
        vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__exp_o 
            = (0x1ffU & ((IData)(vlSelf->fp_mul__DOT__sum_exp_o) 
                         - (IData)(0x7fU)));
    }
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sum_exp_o 
        = (0x1ffU & ((IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp1) 
                     + (IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp2)));
    vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__zero_flag_o 
        = ((1U & ((~ ((IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant1) 
                      >> 0xfU)) | (~ ((IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant2) 
                                      >> 0xfU)))) || 
           (0x80U > ((IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp1) 
                     + (IData)(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp2))));
    vlSelf->fp_mul__DOT__product_o = vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__product_o;
    vlSelf->fp_mul__DOT__sign_xor_o = vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign_xor_o;
    vlSelf->fp_mul__DOT__sum_exp_o = vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sum_exp_o;
    vlSelf->fp_mul__DOT__result = ((0xfeU < (IData)(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__exp_o))
                                    ? 0x7f8000U : (
                                                   ((IData)(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sign_o) 
                                                    << 0x17U) 
                                                   | ((0x7f8000U 
                                                       & ((IData)(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__exp_o) 
                                                          << 0xfU)) 
                                                      | (IData)(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__mant_o))));
    vlSelf->fp_mul__DOT__zero_flag_o = vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__zero_flag_o;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__product_i 
        = vlSelf->fp_mul__DOT__product_o;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sign_xor_i 
        = vlSelf->fp_mul__DOT__sign_xor_o;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sum_exp_i 
        = vlSelf->fp_mul__DOT__sum_exp_o;
    vlSelf->result = vlSelf->fp_mul__DOT__result;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__result_o 
        = vlSelf->fp_mul__DOT__result;
    vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__zero_flag_i 
        = vlSelf->fp_mul__DOT__zero_flag_o;
}

void Vtop___024root___eval_triggers__act(Vtop___024root* vlSelf);

bool Vtop___024root___eval_phase__act(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vtop___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        Vtop___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vtop___024root___eval_phase__nba(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vtop___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__ico(Vtop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__nba(Vtop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__act(Vtop___024root* vlSelf);
#endif  // VL_DEBUG

void Vtop___024root___eval(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelf->__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY((0x64U < __VicoIterCount))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("/home/kvl01/TauriGPU/rtl/core/fp/fp_mul.sv", 1, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vtop___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelf->__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("/home/kvl01/TauriGPU/rtl/core/fp/fp_mul.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                Vtop___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("/home/kvl01/TauriGPU/rtl/core/fp/fp_mul.sv", 1, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (Vtop___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (Vtop___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vtop___024root___eval_debug_assertions(Vtop___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->a & 0xff000000U))) {
        Verilated::overWidthError("a");}
    if (VL_UNLIKELY((vlSelf->b & 0xff000000U))) {
        Verilated::overWidthError("b");}
}
#endif  // VL_DEBUG
