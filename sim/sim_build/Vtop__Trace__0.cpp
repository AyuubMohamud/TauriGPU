// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_fst_c.h"
#include "Vtop__Syms.h"


void Vtop___024root__trace_chg_0_sub_0(Vtop___024root* vlSelf, VerilatedFst::Buffer* bufp);

void Vtop___024root__trace_chg_0(void* voidSelf, VerilatedFst::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_0\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vtop___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vtop___024root__trace_chg_0_sub_0(Vtop___024root* vlSelf, VerilatedFst::Buffer* bufp) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    bufp->chgBit(oldp+0,(vlSelf->clk));
    bufp->chgIData(oldp+1,(vlSelf->a),24);
    bufp->chgIData(oldp+2,(vlSelf->b),24);
    bufp->chgIData(oldp+3,(vlSelf->result),24);
    bufp->chgBit(oldp+4,(vlSelf->fp_mul__DOT__clk));
    bufp->chgIData(oldp+5,(vlSelf->fp_mul__DOT__a),24);
    bufp->chgIData(oldp+6,(vlSelf->fp_mul__DOT__b),24);
    bufp->chgIData(oldp+7,(vlSelf->fp_mul__DOT__result),24);
    bufp->chgIData(oldp+8,(vlSelf->fp_mul__DOT__product_o),17);
    bufp->chgBit(oldp+9,(vlSelf->fp_mul__DOT__zero_flag_o));
    bufp->chgBit(oldp+10,(vlSelf->fp_mul__DOT__sign_xor_o));
    bufp->chgSData(oldp+11,(vlSelf->fp_mul__DOT__sum_exp_o),9);
    bufp->chgBit(oldp+12,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__clk));
    bufp->chgIData(oldp+13,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__a),24);
    bufp->chgIData(oldp+14,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__b),24);
    bufp->chgIData(oldp+15,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__product_o),17);
    bufp->chgBit(oldp+16,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__zero_flag_o));
    bufp->chgBit(oldp+17,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign_xor_o));
    bufp->chgSData(oldp+18,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sum_exp_o),9);
    bufp->chgBit(oldp+19,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign1));
    bufp->chgBit(oldp+20,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__sign2));
    bufp->chgCData(oldp+21,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp1),8);
    bufp->chgCData(oldp+22,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__exp2),8);
    bufp->chgBit(oldp+23,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_1));
    bufp->chgBit(oldp+24,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mantissa_top_bit_2));
    bufp->chgSData(oldp+25,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant1),16);
    bufp->chgSData(oldp+26,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__mant2),16);
    bufp->chgIData(oldp+27,(vlSelf->fp_mul__DOT__fp_mul_0_inst__DOT__product),32);
    bufp->chgBit(oldp+28,(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__clk));
    bufp->chgIData(oldp+29,(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__product_i),17);
    bufp->chgBit(oldp+30,(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__zero_flag_i));
    bufp->chgBit(oldp+31,(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sign_xor_i));
    bufp->chgSData(oldp+32,(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sum_exp_i),9);
    bufp->chgIData(oldp+33,(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__result_o),24);
    bufp->chgBit(oldp+34,(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__sign_o));
    bufp->chgSData(oldp+35,(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__exp_o),9);
    bufp->chgSData(oldp+36,(vlSelf->fp_mul__DOT__fp_mul_1_inst__DOT__mant_o),15);
}

void Vtop___024root__trace_cleanup(void* voidSelf, VerilatedFst* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_cleanup\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VlUnpacked<CData/*0:0*/, 1> __Vm_traceActivity;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        __Vm_traceActivity[__Vi0] = 0;
    }
    // Body
    vlSymsp->__Vm_activity = false;
    __Vm_traceActivity[0U] = 0U;
}
