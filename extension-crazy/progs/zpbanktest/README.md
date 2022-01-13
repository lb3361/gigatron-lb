# ZPBANKTEST

This program test that Zero Page Banking works as expected. Zero page banking is tricky because it depends on the state of address bit A7 which is only available when the 74LVC244 is on, quite late before the Gigatron memory read cycle. This is to make sure there is enough time to compute the correct bank.

The program first tests the presence of zero page banking, then sets zero page banking, then performs some computation using GLCC which happens to exercise registers located in the banked part of the page zero. If zero page banking was broken, this would just crash.
