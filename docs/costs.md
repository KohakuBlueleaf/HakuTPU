## Resource cost and throughput and latency

In this documentation we list all the vivado synthesised result to check the resource cost.

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
    * performance:
        * 3-cycle latency, 1-cycle throughput

* FPVectorAdd (can customize Exponent and Mantissa)
    * Input: a1, b1, c1, d1, a2, b2, c2, d2
    * Output: a1+a2, b1+b2, c1+c2, d1+d2
    * resource cost:
        * E5M4 (FP10) : 269 LUT, 70 FF, 1 DSP
        * E5M6 (FP12) : 336 LUT, 78 FF, 1 DSP
        * E5M10 (FP16) : 535 LUT, 94 FF, 1 DSP
    * performance:
        * 1-cycle latency, 1-cycle throughput

* FP12Inversion
    * Input: a
    * Output: 1/a
    * resource cost: 38LUT
    * performance: combinational