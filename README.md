<p align="center">
  <img src="./assets/logo/helloGMP-logo.png" alt="helloGMP Logo" width="250" />
</p>

# 🌟 The helloGMP Library 🌟
Welcome to **helloGMP**, your modular, high-performance library designed for use in Roblox Studio or Luau environments. **HelloGMP** is heavily inspired by the GNU Multiple Precision library (GMP), this library brings precision computation optimized for developers. 🔥🔥

_Note: The library name is `helloGMP`. In documentation, you may see "HelloGMP" at the start of sentences, this is just grammatical capitalization._

 - **INSTALLATION**: To get started, [install **helloGMP** here](./INSTALL.md).

## Why **helloGMP**?
**HelloGMP** exists to bring the power of arbitrary‑precision mathematics into Roblox Studio and Luau. It balances speed, correctness, and usability, giving developers exact results without sacrificing performance. Whether you’re building games, simulations, or experimenting with number theory, helloGMP provides a reliable foundation.

To ensure reliability, every function has been rigorously validated against Wolfram|Alpha, with extensive testing confirming correctness across a wide range of cases.

### ✨ Features of the Library
- **Inline documentation**
  - Functions are annotated with descriptions that appear in Roblox Studio’s autocomplete and tooltips.
- **Extensions and Features**
  - Offers extensions containing modules such as `hello_datetime` and `hello_complex` focuses on their own domains.
  - Has a lot of features to offer to serve more as a toolkit for Roblox Studio.
- **Performance**
  - Engineered with optimized algorithms and code, resulting in very low overhead and asymptotic complexity.
  - Note: The constructor has a slight overhead but it's asymptotically efficient.
- **Customizable Settings**
  - Configuration lives in the `base_settings` module, where you can adjust defaults before execution.
  - Settings are validated and frozen; they are not intended to be changed at runtime.
- **Readable Code** 
  - The source is heavily commented, making the implementation approachable and easy to understand.

## Three Main Libraries
The **helloGMP** library is planned to have three main modules that specializes on different types of numbers alike GMP's foundation, for more information, click on their `name`:
- [`hello_mpz`](./docs/API-hello_mpz.md): Specializes on high-performance arbitrary precision integer arithmetic. **This is the core of the helloGMP library.**
- `hello_mpq`: Specializes on rational number arithmetic that represents values as normalized fractions to avoid rounding error. 
- `hello_mpf`: Specializes on float-point arithmetic with configurable precision and rounding modes for numerics that need controlled approximation.

### Current Status 
- ✅ `hello_mpz` (integer arithmetic) is stable and benchmarked
- ⚠️ `hello_mpq` (rational arithmetic) is planned but not yet implemented
- ⚠️ `hello_mpf` (floating-point arithmetic) is experimental and subject to change