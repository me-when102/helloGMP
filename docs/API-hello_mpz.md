# HelloGMP: `hello_mpz`
The `hello_mpz` module is the core of the helloGMP library, providing high‑performance arbitrary‑precision integer arithmetic. It is designed to handle numbers far beyond native Luau limits, while maintaining speed and correctness through optimized algorithms. This module serves as the foundation for advanced features such as number theory, combinatorics, and base conversions.

## ✨ Features of `hello_mpz`
**HelloGMP's** `hello_mpz` module includes a wide range of capabilities.
For clarity, the following complexity notation is used throughout:

- `n` → size of input value (e.g., number of digits)
- `m` → number of limbs in the big integer
- `len(s)` → length of input string

### Available Features
- **Arithmetic operators**: Overloaded `+`, `-`, `*`, `/`, `//`, `%`, `^`, and unary `-`
- **Comparison operators**: Overloaded `>`, `>=`, `==`, `<=`, `<`  
  (`>` and `>=` are inherited from `__lt` and `__le`)

- **Core Constructors & Conversions**
  - `hello_mpz.new(x)` → `O(len(s))` from string, `O(log n)` from number - Unified constructor (string or number)  
  - `hello_mpz(x)` → same as `.new` - Callable shortcut with identical complexity  
  - `hello_mpz.fromString(s)` → `O(len(s))` - Parse string into big integer (signs, validation, chunking)  
  - `hello_mpz.fromNumber(n)` → `O(log n)` - Convert Lua number into big integer (precision may be lost)  
  - `:toString()` → `O(m)` - Convert to decimal string  
  - `:toScientific(precision)` → `O(m)` - Convert to scientific notation string with `precision` mantissa digits.
  - `:toNumber()` → `O(m)` - Convert to Lua number (approximate)  
  - `:toRawTable()` → `O(m)` - Debug: raw limbs + sign  
  - `__tostring` → `O(m)` - Metamethod for `tostring()`/`print()` (same as `:toString()`)

- **Utilities**
  - `:clone()` → `O(n)` - Creates a deep copy of the integer  
  - `:isEven()` → `O(1)` - Checks if the integer is divisible by 2  
  - `:isOdd()` → `O(1)` - Checks if the integer is not divisible by 2  
  - `:abs()` → `O(n)` - Returns the absolute value of the integer  
  - `:neg()` → `O(n)` - Returns the negated value (unary minus, `__unm`)  
  - `:isZero()` → `O(1)` - Tests whether the integer equals zero  
  - `:isPositive()` → `O(1)` - Tests whether the integer is strictly greater than zero  
  - `:isNegative()` → `O(1)` - Tests whether the integer is strictly less than zero  

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
    - Native iteration over ranges using `for ... in` syntax
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
    - `doubleFactorial()` → Computes n!! with step 2, `O(n * m^1.585)`
    - `multiFactorial(step)` → Computes n!ₖ with arbitrary step k, `O((n/k) · m^1.585)`
- **Mathematical Probability Functions**:
    - `comb(n, r)` → Combinations, computed iteratively with multiplication + division, `O(r · m^2)`
    - `perm(n, r)` → Permutations, computed iteratively with multiplication, `O(r * m^2)`
- **Random number generation**:
    - `random(min, max)` → Produces a uniformly distributed random integer within the specified range, `O(n)` per candidate

## Usage of `hello_mpz`
### Construction and Representation
```lua
local hello_mpz = require(path.to.hello_mpz) -- presumably helloGMP.hello_mpz

local a = hello_mpz.new("43673421578943798437894329890432174321")
local b = hello_mpz.fromString("1273478903217489056984790469879")
local c = hello_mpz.fromNumber(43724732432)

local d = hello_mpz("943267463217843126498321467843216981") -- shortcut
```