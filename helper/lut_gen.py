import numpy as np
from dataclasses import dataclass
from typing import Tuple


@dataclass
class FPNumber:
    """Custom floating point number representation"""

    sign: int
    exponent: int
    mantissa: int
    exp_bits: int  # Number of exponent bits
    man_bits: int  # Number of mantissa bits

    @classmethod
    def from_float(cls, value: float, exp_bits: int, man_bits: int) -> "FPNumber":
        """Convert float to custom floating point format"""
        if value == 0:
            return cls(0, 0, 0, exp_bits, man_bits)

        # Extract sign
        sign = 0 if value >= 0 else 1

        # Extract exponent and mantissa
        abs_val = abs(value)
        exp = int(np.floor(np.log2(abs_val)))
        man = abs_val / (2**exp) - 1  # Subtract 1 to get fractional part

        # Scale mantissa to have extra bits for rounding
        extra_bits = 3  # Guard, round, and sticky bits
        man_scaled = int(man * (1 << (man_bits + extra_bits)))

        # Extract rounding bits
        guard_bit = (man_scaled >> (extra_bits - 1)) & 1
        round_bit = (man_scaled >> (extra_bits - 2)) & 1
        sticky_bit = (man_scaled & ((1 << (extra_bits - 2)) - 1)) != 0

        # Perform round to nearest even
        man_int = man_scaled >> extra_bits
        round_up = False

        if guard_bit == 1:
            if round_bit == 1 or sticky_bit == 1:
                round_up = True
            elif man_int & 1 == 1:  # If mantissa is odd, round up
                round_up = True

        if round_up:
            man_int += 1
            # Handle mantissa overflow
            if man_int >= (1 << man_bits):
                man_int >>= 1
                exp += 1

        # Normalize to our custom format
        bias = (1 << (exp_bits - 1)) - 1
        exp_biased = exp + bias

        # Handle overflow/underflow
        if exp_biased >= (1 << exp_bits):
            exp_biased = (1 << exp_bits) - 1
            man_int = (1 << man_bits) - 1
        elif exp_biased < 0:
            exp_biased = 0
            man_int = 0

        return cls(sign, exp_biased, man_int, exp_bits, man_bits)

    def to_float(self) -> float:
        """Convert back to float"""
        if self.exponent == 0 and self.mantissa == 0:
            return 0.0

        bias = (1 << (self.exp_bits - 1)) - 1
        exp = self.exponent - bias
        man = 1.0 + (self.mantissa / (1 << self.man_bits))

        return man * (2.0**exp) * ((-1) ** self.sign)

    def to_bits(self) -> int:
        """Convert to bit representation"""
        return (
            (self.sign << (self.exp_bits + self.man_bits))
            | (self.exponent << self.man_bits)
            | self.mantissa
        )

    @classmethod
    def from_bits(cls, bits: int, exp_bits: int, man_bits: int) -> "FPNumber":
        """Create from bit representation"""
        man_mask = (1 << man_bits) - 1
        mantissa = bits & man_mask
        exponent = (bits >> man_bits) & ((1 << exp_bits) - 1)
        return cls(
            bits >> (exp_bits + man_bits), exponent, mantissa, exp_bits, man_bits
        )


def generate_inverse_lut(
    input_exp_bits: int, input_man_bits: int, output_exp_bits: int, output_man_bits: int
) -> dict:
    """Generate LUT for inverse function (1/x)"""
    lut = {}
    input_bits = input_man_bits  # We only need mantissa bits since 1.mmm format

    for i in range(1 << input_bits):
        # Convert i to FP12 number (1.mmm format)
        input_val = 1.0 + (i / (1 << input_bits))
        inv_val = 1.0 / input_val

        # Convert result to output format
        fp_result = FPNumber.from_float(inv_val, output_exp_bits, output_man_bits)
        lut[i] = fp_result.to_bits()

    return lut


def generate_inverse_lut_subnormal(
    input_exp_bits: int, input_man_bits: int, output_exp_bits: int, output_man_bits: int
) -> dict:
    """Generate LUT for inverse function (1/x), where x have exp=0 and man!=0"""
    lut = {}
    input_bits = input_man_bits  # We only need mantissa bits since 0.mmm format

    for i in range(1 << input_bits):
        # Convert i to FP12 number (0.mmm format)
        input_val = 2**(0 - 2**(input_exp_bits-1) + 1) * (i / (1 << input_bits))
        print(i, input_val, 2**(0 - 2**(input_exp_bits-1) + 1), i / (1 << input_bits))
        if input_val == 0:
            inv_val = 0
        else:
            inv_val = 1.0 / input_val

        # Convert result to output format
        fp_result = FPNumber.from_float(inv_val, output_exp_bits, output_man_bits)
        lut[i] = fp_result.to_bits()

    return lut


def generate_log_lut(
    input_man_bits: int, output_exp_bits: int, output_man_bits: int
) -> dict:
    """Generate LUT for log(1.mmm)"""
    lut = {}

    for i in range(1 << input_man_bits):
        # Convert i to 1.mmm format
        input_val = 1.0 + (i / (1 << input_man_bits))
        log_val = np.log(input_val)

        # Convert result to output format
        fp_result = FPNumber.from_float(log_val, output_exp_bits, output_man_bits)
        lut[i] = fp_result.to_bits()

    return lut


def generate_log_exp_lut(
    input_exp_bits: int, output_exp_bits: int, output_man_bits: int
) -> dict:
    """Generate LUT for e*log(2)"""
    lut = {}
    # convert i to exponent, when we have n exp bits, the offset is 2^(n-1)-1.
    exp_offset = (1 << (input_exp_bits - 1)) - 1

    for i in range(1 << input_exp_bits):
        e = i - exp_offset
        log_val = np.log(2) * e
        fp_result = FPNumber.from_float(log_val, output_exp_bits, output_man_bits)
        lut[i] = fp_result.to_bits()

    return lut


def generate_exp_lut(
    input_bits: int, output_exp_bits: int, output_man_bits: int
) -> dict:
    """Generate LUT for exp(x) where x is in [0, ln(2))"""
    lut = {}

    for i in range(1 << input_bits):
        # Convert i to value in [0, ln(2))
        input_val = (i / (1 << input_bits)) * np.log(2)
        exp_val = np.exp(input_val)

        # Convert result to output format
        fp_result = FPNumber.from_float(exp_val, output_exp_bits, output_man_bits)
        lut[i] = fp_result.to_bits()

    return lut


# Example usage and test
if __name__ == "__main__":
    # Generate inverse LUT (FP12 to FP16)
    inv_lut = generate_inverse_lut(5, 6, 5, 10)  # FP12(E5M6) to FP16
    results = []
    for i in range(1 << 6):
        results.append(f"{inv_lut[i]:016b}")
        print(f"{inv_lut[i]:016b}: {FPNumber.from_bits(inv_lut[i], 5, 10).to_float()}")
    for i in zip(*results):
        print("".join(reversed(list(i))))

    invlut_subnorm = generate_inverse_lut_subnormal(5, 6, 5, 10)
    results = []
    for i in range(1 << 6):
        results.append(f"{invlut_subnorm[i]:016b}")
        print(f"{invlut_subnorm[i]:016b}: {FPNumber.from_bits(invlut_subnorm[i], 5, 10).to_float()}")
    for i in zip(*results):
        print("".join(reversed(list(i))))

    # Generate log LUT and log-exp LUT
    # log(x) = log(1.mmmmmm) + e*log(2)
    log_lut = generate_log_lut(6, 5, 10)  # 6-bit mantissa input to FP16
    log_exp_lut = generate_log_exp_lut(5, 5, 10)  # 5-bit exp input to FP16

    # Generate exp LUT
    exp_lut = generate_exp_lut(6, 5, 10)  # 6-bit input to FP16

    # Test inverse function
    print("\nTesting inverse LUT:")
    test_values = [1.0, 1.25, 1.5, 1.75, 3.14]
    for val in test_values:
        fp12 = FPNumber.from_float(val, 5, 6)
        lut_result = FPNumber.from_bits(inv_lut[fp12.mantissa], 5, 10)
        print(f"1/{val:.3f} = {lut_result.to_float():.6f}")

    # Test log function
    print("\nTesting log LUT:")
    for val in test_values:
        fp_in = FPNumber.from_float(val, 5, 6)
        lut_result_man = FPNumber.from_bits(log_lut[fp_in.mantissa], 5, 10)
        lut_result_exp = FPNumber.from_bits(log_exp_lut[fp_in.exponent], 5, 10)
        final_result = lut_result_man.to_float() + lut_result_exp.to_float()
        diff = np.log(val) - final_result
        APE = abs(diff) / np.log(val) * 100 if diff else 0
        print(
            f"log({val:.3f}) = {final_result:.6f}"
            f" (actual = {np.log(val):.6f}, APE = {APE:.2f}%)"
        )

    # Test exp function
    print("\nTesting exp LUT:")
    test_values = [0.0, 0.2, 0.4, 0.6]
    for val in test_values:
        idx = int((val / np.log(2)) * (1 << 6))
        lut_result = FPNumber.from_bits(exp_lut[idx], 5, 10)
        diff = np.exp(val) - lut_result.to_float()
        APE = abs(diff) / np.exp(val) * 100 if diff else 0
        print(
            f"exp({val:.3f}) = {lut_result.to_float():.6f}"
            f" (actual = {np.exp(val):.6f}, APE = {APE:.2f}%)"
        )
