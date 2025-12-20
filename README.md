<p align="center">
  <img src="./assets/logo/helloGMP-logo.png" alt="helloGMP Logo" width="250" />
</p>

# 🌟 The helloGMP Library 🌟
Welcome to **helloGMP**, a modular, high-performance library designed for Roblox Studio and Luau environments. Heavily inspired by the GNU Multiple Precision library (GMP), helloGMP adapts multiple-precision arithmetic techniques to the constraints of Luau. 🔥🔥

_Note: The library name is `helloGMP`. In documentation, you may see "HelloGMP" at the start of sentences, this is just grammatical capitalization._

 - **INSTALLATION**: To get started, [install **helloGMP** here](./INSTALL.md).

## Why **helloGMP**?
**HelloGMP** exists to bring the power of arbitrary‑precision mathematics into Roblox Studio and Luau. It is designed to balance performance, correctness, and usability, providing exact arithmetic where native numeric types are insufficient. Whether you’re building games, simulations, or experimenting with number theory, helloGMP provides a reliable foundation.

To ensure reliability, core arithmetic and number-theoretic functions have been validated against Wolfram|Alpha across a wide range of test cases.

### ✨ Features of the Library
- **Inline documentation**
  - Functions are annotated with descriptions that appear in Roblox Studio’s autocomplete and tooltips.
- **Extensions and Features**
  - Offers extensions containing modules such as `hello_datetime` and `hello_complex` focuses on their own domains.
  - Provides a broad set of features intended to function as a general-purposenumerical toolkit for Roblox Studio.
- **Performance**
  - Engineered with optimized algorithms and code, resulting in very low overhead and asymptotic complexity.
  - Note: The constructor has a slight overhead but it is asymptotically efficient.
- **Customizable Settings**
  - Configuration lives in the `base_settings` module, where you can adjust defaults before execution.
  - Settings are validated and frozen; they are not intended to be changed at runtime.
- **Readable Code** 
  - The source is heavily commented, making the implementation approachable and easy to understand.

## Three Main Libraries
The **helloGMP** library is planned to have three main modules that specializes on different numeric domains similar to GMP's foundational design, for more information, click on their `name`:
- [`hello_mpz`](./docs/API-hello_mpz.md): Specializes on high-performance arbitrary precision integer arithmetic. **This is the core of the helloGMP library.**
- `hello_mpq`: Specializes on rational number arithmetic that represents values as normalized fractions to avoid rounding error. 
- `hello_mpf`: Specializes on float-point arithmetic with configurable precision and rounding modes for numerics that need controlled approximation.

### Current Status 
- ✅ `hello_mpz` (integer arithmetic) is stable and benchmarked
- ⚠️ `hello_mpq` (rational arithmetic) is planned but not yet implemented
- ⚠️ `hello_mpf` (floating-point arithmetic) is experimental and subject to change

## The **HelloGMP** Base System
**HelloGMP** actually chooses the default limb base of **10^7** which may be the sweet spot for arbitrary precision arithmetic.
- Luau numbers are double-precision floats. By using base 10^7, we ensure that even when multiplying two "limbs" (10^7 × 10^7 = 10^14), the result stays safely under the 2^53 (approx. 9 × 10^15) limit where precision loss begins.
- Using a decimal base makes `toString()` operation in `hello_mpz` asymptotically faster (`O(n)`). This is critical for Roblox UI elements like `TextLabels` that need to update frequently.
- This specific base is large enough to keep the number of limbs (and thus loop iterations) low, but small enough to avoid the overhead of Luau's large-integer handling.