# [WIP] HakuTPU

An AI accelerator implemenation for Xilinx FPGA

This project based on Xilinx Ultrascale+ FPGA's, utilize their DSP48E2 tile to do efficient FP8 matmul. Than implement vectorized ALU for activation(or related operation).

This project is more for fun, not for real usage. But if anyone have interests to make it work, feel free to open PR.

## Introduction

All the resource utilization estimation in this section is based on XCVU13P.
Which have 1728k LUTs, 3456K FFs and 12288 DSPs.

### Fundamental Components

* [ ] Global Controller
* [ ] Unit Controller
* [ ] 128x16bit buffer
* [ ] Tensor Core: 4x8x4 FP8 mul FP12 accu

  * [X] 32 x 1x4 FP8VectorMul
  * [X] 32 x 4+4 FPaddition
* [ ] FP16 ALU

  * [ ] efficient FP16 FMA
  * [X] FP12 inversion
  * [ ] FP12 exp/log
* [ ] General Processor

  * [ ] FP32

### Compute Unit

Each compute unit have following components

* Unit Controller
* Tensor Core
* FP16 ALU * 8

#### Tensor Core

Follow the idea of tensor core in Nvidia Volta arch. We use 4x4x4 gemm as the smallest unit in Tensor Core.
There for, to achieve 4x4x4 matmul you need 16 FP8VectorMul(design1) and 16 FPVectorAdd(adder tree) to achieve 1cycle pipelined 4x4x4 Tensor Core.

And you will find the LUT cost is very high and you will run out of it easily. Therefore, we consider to use FP12, 128~192core in our setup.

#### Vectorized ALU

Basically just a bunch of ALU which can do one cycle FMA and maybe more one cycle things.
Since we only use 4k\~6k DSPs in our Tensor Core. We plan to use 2\~4 DSPs per ALU to achieve totally 1024\~2048 ALU here.
(Based on Nvidia's marketing form, you can say our project will eventually have 1024\~2048 CUDA cores and 128~192 Tensor cores).
