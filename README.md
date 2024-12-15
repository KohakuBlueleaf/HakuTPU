# [WIP] HakuTPU

An AI accelerator implemenation for Xilinx FPGA

This project based on Xilinx Ultrascale+ FPGA's, utilize their DSP48E2 tile to do efficient FP8 matmul. Than implement vectorized ALU for activation(or related operation).

This project is more for fun, not for real usage. But if anyone have interests to make it work, feel free to open PR.

## Introduction

### Fundamental Components

* FP8VectorMul:
  * Input:
    * Design1: q, a, b, c, d (FP8 E5M2/E4M3)
    * Design2: q, k, a, b, c (FP8 E5M2/E4M3)
  * output:
    * Design1: qa, qb, qc, qd (FP16)
    * Design2: qa, qb, qc, ka, kb, kc
  * resource cost:
    * Design 1: 105 LUT, 118 FF, 1DSP
    * Design 2: [TODO]
