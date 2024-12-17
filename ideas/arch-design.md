## Arch Design

### hierarchical arch overview

All top level components are connected with AXI4

* XDMA (PCIE connection with host)
* DRAM (weight or result)
* URAM (weight or result)
* BRAM (instructions)
* Global Controller
  * Compute Unit
    * Compute Unit Controller (instruction decode)
    * 8 Buffer (128*16bit per buffer, which can store 8x16 F16 mat, 16x16 F8 mat or 64 F32/I32 element)
    * 1 Tensor Core (4x4x4 gemm, FP8mul FP12 acc)
    * 8 ALU (FP16 FMA, with FP12 inversion, log, exp as preprocess)
    * [Possible Feature] 1 or 2 General Core/CPU
      * Should support more complex operation
        * +-*, bit-wise operation, shift, high precision
      * possibly int8/int32/FP8/FP16/FP24/FP32 inp, int8/int32/FP16/FP32 out,
      * can use up to 16/32DSP if needed. (Can build iterative division implementation in pipeline direclty)
