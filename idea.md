# Idea

This documentation will have all the design idea in this project.

## DSP48E2

For DSP48E1, we can't do M + C + PCIN in one pass, need to move more addition outside the DSP.
But the basic idea about use multiplier and alu for 4fp8 mul in one pass is same.

We will basically only use this operation:
(A(27) + D(27)) * B(18) + C(48)  = output
Where (xx) stands for bit count

### Pipeline

In DSP48E2, we have some pipeline register to make the DSP become staged. Whcih can increase the Fmax.
In our project, we want to achieve at least 400MHz in the Matmul unit, IN THEORY, we don't need any pipeline register for it in -2 or -3 speed grade chip. BUT if needed, we will need to implement pipelining for the unit. (But since the matmul unit itself already need multiple cycle to run the matmul,  it is easy to just add some "latency" for receiving output from fp8 vector mul unit which achieve the pipelining easily.)

pipeline inside DSP48E2 (for A and B we have A1/A2 or B1/B2, but in our project we barely use them)

```
Input| input reg |         Pipeline Reg           | Output Reg

A ----> A reg \
               (Add)=> AD reg\
D ----> D reg /               \
                              (Mult)=> M reg \
B ----> B reg ________________/              (ALU)=> P reg => 
                                             /
C ----> C reg ______________________________/
```

Since not all the input have same amount of reg in the path, we need to add some extra reg to match their cycle, also the Preg can be removed since we directly write the output into our own output reg:

```
A ----> A reg \
               (Add)=> AD reg\
D ----> D reg /               \
                              (Mult)=> M reg \
Breg1 -> B -> B reg __________/              (ALU) => Ouptut wire
                                             /
Creg1 -> Creg2 -> C -> C reg _______________/

ID   -----> reg1 -----> reg2 -----> reg3 =======> ID wire
```

In FP8 Mul we don't need AD preadder, which means we can disable AD reg and shrink the pipeline:

```
A ----> A reg \
               (Mult)=> M reg \
B ----> B reg /              (ALU)=> P reg \
                              /             => Final Output
Creg1 -> C -> C reg _________/             /
                                          /
Inputs -> InpReg1 -> InpReg2 -> InpReg3__/

ID   -----> reg1 -----> reg2 ------> reg3 ======> ID wire
```

**Note**: It is unclear that if we need Preg in the pipelining, but based on my understanding, the Preg can be seen as "write back stage", which means if we connect the Output wire to some reg directly we can ignore it. But since we have some complex operation after the dsp output. it is possible that we should better put some reg behind it as well...
**Note2**: If we use full pipeline we mentioned here, we can achieve around 800, 700, 600MHz in FP8VectorMul unit in speedgrade -3, -2, -1(-2 LE).

### FP8 mul

consider q * (k, v, m) where q,k,v,m are all FP8 floating point number (E5M2 or E4M3)
S1 E1 M1
S2 E2 M2

S1 xor S2 -> neg or pos
E1 + E2 -> new Exponent
1.M1 * 1.M2 -> new Mantissa

About mantissa, we use DSP48E2 to do the multiplication of mantissa than add the prefix 1 into it.
So it will be: `(1 + Ma) * (1 + Mb) = 1 + Ma + Mb + MaMb`

```
1.111 + 1.111 = 1 + 0.111 + 0.111 + 0.111*0.111
    0.111
*   0.111
--------------(DSP mul)
         111
        111
       111
--------------
    0.110001

    1.111
+   0.111
--------------(DSP add)
   10.110

   10.110
+   0.110001
--------------(LUT add)
   11.100001
```

#### Design1: Use 1 DSP to achieve q * [a, b, c, d]
```
000000000000001mmm                                  B(18): mantissa 1.qqq
*
000mmm00000mmm00000mmm00000mmm                      A(30): mantissa [0.aaa, 0.bbb, 0.ccc, 0.ddd]
+
000000000000000000mmm00000mmm00000mmm00000mmm000    C(48): mantissa [0.qqq, 0.qqq, 0.qqq, 0.qqq]
=
00000000000000000mmmmmmm0mmmmmmm0mmmmmmm0mmmmmmm    A*B  : 1.qqq * [0.aaa, 0.bbb, 0.ccc, 0.ddd]
+
000000000000000000mmm00000mmm00000mmm00000mmm000    C(48): mantissa [0.qqq, 0.qqq, 0.qqq, 0.qqq]
=
0000000000000000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm    B*A: 1.qqq * [1.aaa, 1.bbb, 1.ccc, 1.ddd]

Extra Arithmetic Operation in LUT:
Exponent Addition (5bit addition * 4)
exponent + 1 (if final mantissa > 2, 6bit addition * 4)
```

Consider E5M2, it will be
```
0000000000000001mm                                  B(18): mantissa 1.qqq
*
0000000000mm0000mm0000mm0000mm                      A(30): mantissa [0.aaa, 0.bbb, 0.ccc, 0.ddd]
+
00000000000000000000000000mm0000mm0000mm0000mm00    C(48): mantissa [0.qqq, 0.qqq, 0.qqq, 0.qqq]
=
0000000000000000000000000mmmmm0mmmmm0mmmmm0mmmmm    A*B  : 1.qqq * [0.aaa, 0.bbb, 0.ccc, 0.ddd]
+
00000000000000000000000000mm0000mm0000mm0000mm00    C(48): mantissa [0.qqq, 0.qqq, 0.qqq, 0.qqq]
=
000000000000000000000000mmmmmmmmmmmmmmmmmmmmmmmm    B*A: 1.qqq * [1.aaa, 1.bbb, 1.ccc, 1.ddd]

Extra Arithmetic Operation in LUT:
Exponent Addition (6bit addition * 4)
exponent + 1 (if final mantissa > 2, 6bit addition * 4)
```


#### Design 2: Use 2 DSP to achieve `[a, b, c].dot([q, k].T)`

FP8 E4M3
```
First DSP:
1mmm0001mmm0001mmm                                  B(18): mantissa from a, b, c
*
000mmm000000000000000000000mmm                      A(30): mantissa from q, k
+
000000000000000000000000000000000000000000000000    C(48)
=
000000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm    B*A: [1.aaa, 1.bbb, 1.ccc] x [0.qqq, 0.kkk]

Second DSP:
0s0s0s0s0s0s0000000eeee0eeee0eeee0eeee0eeee0eeee    A:B (30:18): exponent [a, b, c, , a, b, c]
+
0s0s0s0s0s0s0000000eeee0eeee0eeee0eeee0eeee0eeee    C(48): exponent [q, q, q, , k, k, k]
=
?s?s?s?s?s?s000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeee    C + A:B

Extra Arithmetic Operation in LUT:
Mantissa Mul Final stage (5bit addition * 6):
    qa + 1.aaa, qb + 1.bbb, qc + 1.ccc
    ka + 1.aaa, kb + 1.bbb, kc + 1.ccc
exponent + 1 (if final mantissa > 2, 6bit addition * 6)
```

FP8 E5M2
```
First DSP:
00001mm0001mm001mm                                  B(18): mantissa from a, b, c
*
0001mm0000000000000000000001mm                      A(30): mantissa from q, k
+
000000000000000000000000000000000000000000000000    C(48)
=
00000000mmmmmmmmmmmmmmmm00000000mmmmmmmmmmmmmmmm    B*A: [1.aa, 1.bb, 1.cc] x [1.qq, 1.kk]

Second DSP:
0s0s0s0s0s0s0eeeee0eeeee0eeeee0eeeee0eeeee0eeeee    A:B (30:18): exponent [a, b, c, , a, b, c]
+
0s0s0s0s0s0s0eeeee0eeeee0eeeee0eeeee0eeeee0eeeee    C(48): exponent [q, q, q, , k, k, k]
=
?s?s?s?s?s?seeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee    C + A:B

Extra Arithmetic Operation in LUT:
exponent + 1 (if final mantissa > 2, 6bit addition * 6)
```


### FP16 Accumulation

The addition between floating point number is basically shift + integer addition.

Which means for FP16 it will be addition between 5bit integer (for how many bit shift) than do 10bit integer add (for mantissa).

Therefore, we can put the exponent addition in LUT than use DSP for 10bit addition.
Which means we can do [a, b, c, d] + [q, k, v, m] = [a+q, b+k, c+v, d+m] with only 1 DSP.
(DSP48 support 48bit addition within one cycle, and 10bit + 10bit = 11bit)
