# [WIP] HakuTPU

An AI accelerator implemenation for Xilinx FPGA

This project based on Xilinx Ultrascale+ FPGA's, utilize their DSP48E2 tile to do efficient FP8 matmul. Than implement vectorized ALU for activation(or related operation).

This project is more for fun, not for real usage. But if anyone have interests to make it work, feel free to open PR.

## Introduction

All the resource utilization estimation in this section is based on XCVU13P.
Which have 1728k LUTs, 3456K FFs and 12288 DSPs.

### Fundamental Components

* FP8VectorMul:
  * Input:
    * Design1: q, a, b, c, d (FP8 E5M2/E4M3)
    * Design2: q, k, a, b, c (FP8 E5M2/E4M3)
  * output:
    * Design1: qa, qb, qc, qd (FP16)
    * Design2: qa, qb, qc, ka, kb, kc (FP16)
  * resource cost:
    * Design 1: 123 LUT, 118 FF, 1 DSP
    * Design 2: 163 LUT, 108 FF, 2 DSP
  * Latency:
    * 3cycles

* FPVectorAdd (can customize Exponent and Mantissa)
  * Input:
    * a1, b1, c1, d1, a2, b2, c2, d2
  * Output:
    * a1+a2, b1+b2, c1+c2, d1+d2
  * resource cost:
    * E5M4 (FP10) : 269 LUT, 70 FF, 1 DSP
    * E5M6 (FP12) : 336 LUT, 78 FF, 1 DSP
    * E5M10 (FP16) : 535 LUT, 94 FF, 1 DSP
  * Latency:
    * 1cycles

* FPALU (can customize Exponent and Mantissa)
  * WIP

### Compute Unit

#### Tensor Core
Follow the idea of tensor core in Nvidia Volta arch. We use 4x4x4 gemm as the smallest unit in Tensor Core.
There for, to achieve 4x4x4 matmul you need 16 FP8VectorMul(design1) and 16 FPVectorAdd(adder tree) to achieve 1cycle pipelined 4x4x4 Tensor Core.

And you will find the LUT cost is very high and you will run out of it easily. Therefore, we consider to use FP10accu/192core, FP12accu/160core or FP16/128core as our setup.

#### Vectorized ALU
Basically just a bunch of ALU which can do one cycle FMA and maybe more one cycle things.
Since we only use 4k~6k DSPs in our Tensor Core. We plan to use 2~4 DSPs per ALU to achieve totally 1024~2048 ALU here.
(Based on Nvidia's marketing form, you can say our project will eventually have 1024~2048 CUDA cores and 128~192 Tensor cores).