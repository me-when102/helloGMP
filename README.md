<p align="center">
  <img src="./assets/logo/helloGMP-logo.png" alt="helloGMP Logo" width="250" />
</p>

# 🌟 The helloGMP Library 🌟
Welcome to **helloGMP**, your modular, high-performance library designed for use in Roblox Studio or Luau environments. **HelloGMP** is heavily inspired by the GNU Multiple Precision library (GMP), this library brings precision computation optimized for developers. 🔥🔥

 - **INSTALLATION**: To get started, [install **helloGMP** here.](./INSTALL.md)

## Why **helloGMP**?
**HelloGMP** is engineered to both have a lot of features and being optimized for raw-performance, both on lower overhead and asymptotic complexity. All functions are tested for the balance of speed and correctness multiple times during its development.

### ✨ Features of the Library
- **Inline documentation**
  - Functions are annotated with descriptions that appear in Roblox Studio’s autocomplete and tooltips.
- **Extensions**
  - helloGMP offers extensions containing modules such as `hello_datetime` and `hello_complex` focuses on their own domains.

### Three Main Libraries
The library is planned to have three main modules that specializes on different types of numbers:
- [`hello_mpz`](./docs/API-hello_mpz.md): Specializes on high-performance arbitrary precision integer arithmetic. **This is the core of the helloGMP library.**
- `hello_mpq`: Specializes on rational number arithmetic that represents values as normalized fractions to avoid rounding error. 
- `hello_mpf`: Specializes on float-point arithmetic with configurable precision and rounding modes for numerics that need controlled approximation.

#### Current Status 
- ✅ `hello_mpz` (integer arithmetic) is stable and benchmarked
- ⚠️ `hello_mpq` (rational arithmetic) is planned but not yet implemented
- ⚠️ `hello_mpf` (floating-point arithmetic) is experimental and subject to change