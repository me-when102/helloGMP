<p align="center">
  <img src="./assets/logo/helloGMP-logo.png" alt="helloGMP Logo" width="250" />
</p>

# 🌟 The helloGMP Library 🌟
Welcome to **helloGMP**, your modular, high-performance library designed for use in Roblox Studio or Luau environments. **HelloGMP** is heavily inspired by the GNU Multiple Precision library (GMP), this library brings precision computation optimized for developers. 🔥🔥

 - **INSTALLATION**: To get started, [install **helloGMP** here.](./INSTALL.md)

## Three Main Libraries
The library is planned to have three main modules that specializes on different types of numbers:
- `hello_mpz`: Specializes on high-performance arbitrary precision integer arithmetic. **This is the core of the helloGMP library.**
- `hello_mpq`: Specializes on rational number arithmetic that represents values as normalized fractions to avoid rounding error. 
- `hello_mpf`: Specializes on float-point arithmetic with configurable precision and rounding modes for numerics that need controlled approximation.

### Current Status 
- ✅ `hello_mpz` (integer arithmetic) is stable and benchmarked
- ⚠️ `hello_mpq` (rational arithmetic) is planned but not yet implemented
- ⚠️ `hello_mpf` (floating-point arithmetic) is experimental and subject to change

## Why **helloGMP**?
**HelloGMP** is engineered to both have a lot of features and being optimized for raw-performance, both on lower overhead and asymptotic complexity. All functions are tested for the balance of speed and correctness multiple times during its development.

### ✨ Features of `hello_mpz`
**HelloGMP's** `hello_mpz` module includes:

- **Arithmetic operators**: Overloaded `+`, `-`, `*`, `/`, `//`, `%`, `^`, and unary `-`
- **Comparison operators**: Overloaded `>`, `>=`, `==`, `<=`, `<`  
  (`>` and `>=` are inherited from `__lt` and `__le`)
- **Utilities**:
  - `:clone()` → `O(n)`  
  - `:isEven()` → `O(1)`  
  - `:isOdd()` → `O(1)`
  - `:abs()` → `O(n)`
  - `:neg()` → `O(n)` (`__unm`)
  - `:isZero()` → `O(1)`
  - `:isPositive()` → `O(1)`
  - `:isNegative()` → `O(1)`
- **Multiplication algorithms**:
  - Schoolbook → `O(n^2)`  
  - Comba (optimized schoolbook) → `O(n^2)` with tighter constants  
  - Karatsuba → `O(n^~1.585)`
- **Division & modulo**:
  - Knuth D division → optimized `O(n^2)`
- **Roots**:
  - Integer square root (`isqrt`) → Binary search + Newton iteration  
  - General n‑th root (`iroot`) → Binary search + Newton iteration
- **Base conversions**:
  - Built‑in defaults: Unary, Binary, Octal, Hexadecimal, Base36, Base62, Ascii95, Ascii256
  - Custom alphabets supported for arbitrary bases
  - Can be converted back to hello_mpz integers.
- **For loop support**:
  - Native iteration over ranges using `for … in` syntax
  - Inclusive and exclusive variants:
    - `:to(b, step)` → iterate upwards, inclusive
    - `:toExclusive(b, step)` → iterate upwards, exclusive
    - `:downTo(b, step)` → iterate downwards, inclusive
    - `:downToExclusive(b, step)` → iterate downwards, exclusive
  - Standalone iterator: `hello_mpz.range(a, b, step, exclusive)`
  - Step can be numeric, string, or `hello_mpz` object
  - Complexity: `O(n)` per step (big integer addition + comparison)
- **Other Mathematical Functions**:
  - `GCD(a, b)` → Binary GCD (Stein's algorithm), `O(m log n)`
  - `LCM(a, b)` → via GCD + division + multiplication, dominated by `O(m^2)`
- **Factorials**:
  - `factorial()` → Computes n! using binary splitting, `O(n · m^1.585)` (Karatsuba path)
  - `doubleFactorial()` → Computes n!! with step 2, `O(n · m^1.585)`
  - `multiFactorial(step)` → Computes n!ₖ with arbitrary step k, `O((n/k) · m^1.585)`
- **Mathematical Probability Functions**:
  - `comb(n, r)` → Combinations, computed iteratively with multiplication + division, `O(r · m^2)`
  - `perm(n, r)` → Permutations, computed iteratively with multiplication, `O(r · m^2)`
- **Random number generation**:
  - `random(min, max)` → Produces a uniformly distributed random integer within the specified range, `O(n)` per candidate