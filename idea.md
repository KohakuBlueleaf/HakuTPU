# Idea

This documentation will have all the design idea in this project.

## DSP48E2

For DSP48E1, we can't do M + C + PCIN in one pass, need to move more addition outside the DSP.
But the basic idea about use multiplier and alu for 4fp8 mul in one pass is same.

We will basically only use this operation (xx) stands for bit count:
(A(27) + D(27)) * B(18) + C(48) = output

### FP8 mul
consider q * (k, v, m) where q,k,v,m are all FP8 floating point number (E5M2 or E4M3)
S1 E1 M1
S2 E2 M2

S1 xor S2 -> neg or pos
E1 + E2 -> new Exponent
1.M1 * 1.M2 -> new Mantissa

About mantissa
```
    0.111
*   0.111
--------------(DSP mul)
         111
        111
       111
--------------
    0.110001
+   0.111
+   0.111
+   1.0
--------------(LUT add)
   11.100001
```

consider E4M3, it will be
```
1.abc * 1.def = 1.000 + 0.abc + 0.def + 0.abc * 0.def

000000000000001mmm                                  B(18): mantissa from q
*
00000001mmm00001mmm00001mmm                         A(27) + D(27)
+
=
000000000000000000000000mmmmmmmmmmmmmmmmmmmmmmmm    B*(A+D)
+
0s0s0s0eeee0eeee0eeee000000000000000000000000000    C(48): sign, exponent from q (repeat)
+
0s0s0s0eeee0eeee0eeee000000000000000000000000000    PCIN(48): sign, exponent from k, v, m
=
?s?s?seeeeeeeeeeeeeee000mmmmmmmmmmmmmmmmmmmmmmmm    PCIN + C + B*(A+D)
↓
?s|?s|?s|eeeee|eeeee|eeeee|000|mmmmmmmm|mmmmmmmm|mmmmmmmm

?s: sign for qk, qv, qm
e: exponent for qk, qv, qm (if the msb is not 0, it will result in NaN or Inf)
m: mantissa for qk, qv, qm (if the msb is not 0, add 1 to result exponent)

For E5M2:
?s|?s|?s|eeeeee|eeeeee|eeeeee|000000|1mmmmm|1mmmmm|1mmmmm
```

without leading 1 (put the addition outside the DSP)
(We will use this in final design)

```
000000000000000mmm                                  B(18): mantissa from q
*
000000mmm000mmm000mmm000mmm                         A(27) + D(27)
+
=
000000000000000000000000000mmm000mmm000mmm000mmm    B*(A+D)
+
00eeee0eeee0eeee0eeee000000000000000000000000000    C(48): sign, exponent from q (repeat)
+
00eeee0eeee0eeee0eeee000000000000000000000000000    PCIN(48): sign, exponent from k, v, m
=
0eeeeeeeeeeeeeeeeeeee000mmmmmmmmmmmmmmmmmmmmmmmm    PCIN + C + B*(A+D)
↓
0|eeeee|eeeee|eeeee|eeeee|000|mmmmmm|mmmmmm|mmmmmm|mmmmmm

e: exponent for qk, qv, qm, qn (if the msb is not 0, it will result in NaN or Inf)
m: mantissa for qk, qv, qm, qn (if the msb is not 0, add 1 to result exponent)

For E5M2:
0|eeeeee|eeeeee|eeeeee|eeeeee|0000000|mmmm|mmmm|mmmm|mmmm
```

### FP16 Accumulation

The addition between floating point number is basically shift + integer addition.

Which means for FP16 it will be addition between 5bit integer (for how many bit shift) than do 10bit integer add (for mantissa).

Therefore, we can put the exponent addition in LUT than use DSP for 10bit addition.
Which means we can do [a, b, c, d] + [q, k, v, m] = [a+q, b+k, c+v, d+m] with only 1 DSP.
(DSP48 support 48bit addition within one cycle, and 10bit + 10bit = 11bit)