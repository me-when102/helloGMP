# HelloGMP: `hello_mpz`
The `hello_mpz` module is the core of the helloGMP library, providing high‑performance arbitrary‑precision integer arithmetic. It is designed to handle numbers far beyond native Luau limits, while maintaining speed and correctness through optimized algorithms. This module serves as the foundation for advanced features such as number theory, combinatorics, and base conversions.

## ✨ Features of `hello_mpz`
The `hello_mpz` module includes a wide range of capabilities.
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
  - `hello_mpz.fromNumber(n)` → `O(1)` (Bounded by Lua number precision; conceptually `O(log n)` but capped at ~53 bits)
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
    - Integer square root (`isqrt`) → Binary search + Newton iteration (quite expensive)
    - General n‑th root (`iroot`) → Binary search + Newton iteration (very expensive)
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
    - `random(min, max)` → Produces a uniformly distributed random integer within the specified range using rejection sampling to avoid modulo bias, expected `O(m)` per accepted value

## Uses and Demonstrations of `hello_mpz`

### Construction and Representation

```lua
local hello_mpz = require(path.to.hello_mpz) -- path to hello_mpz

-- .new function accepts both strings and numbers
local a = hello_mpz.new("43673421578943798437894329890432174321")
local a2 = hello_mpz.new(887647654)

local b = hello_mpz.fromString("1273478903217489056984790469879")

local c = hello_mpz.fromNumber(43724732432)
local c2 = hello_mpz.fromNumber(43721894032174581234) -- precision loss

local d = hello_mpz("943267463217843126498321467843216981") -- shortcut

-- printing the variable automatically fires __tostring metamethod.
-- you can use v:toString() as well.
print("a:", a)
print("a2:", a2)
print("b:", b)
print("c:", c)
print("c2:", c2)
print("d:", d)

-- printing the variable in scientific notation.
-- optionally you can set how many significant digits you want it to display
print("a (scientific):", a:toScientific())
print("a2 (scientific):", a2:toScientific())
print("b (scientific):", b:toScientific())
print("c (scientific, 3 digits):", c:toScientific(3))
print("c2 (scientific, 4 digits):", c2:toScientific(4))
print("d (scientific, 20 digits):", d:toScientific(20))
```

### Arithmetic

```lua
local hello_mpz = require(path.to.hello_mpz)

-- also this is going to be timed
local t = os.clock()

local a = hello_mpz.new("44372184372189432789321489432714893217443127432189489321743213213")
local b = hello_mpz.new("99999999432167432189432194325432543254376432718496327143214324211143214321120978736543654365435543636435")

-- addition
local addition_result = a + b

print("Addition:", addition_result) -- 99999999432167432189432194325432543254420804902868516576003645700575929214338421863975843854757286849648

-- subtraction
local subtraction_result_1 = b - a
local subtraction_result_2 = a - b

print("Subtraction (b - a):", subtraction_result_1) -- 99999999432167432189432194325432543254332060534124137710425002721710499427903535609111464876113800423222
print("Subtraction (a - b):", subtraction_result_2) -- -99999999432167432189432194325432543254332060534124137710425002721710499427903535609111464876113800423222

-- negation
local neg_result_1 = -a 
local neg_result_2 = -b 

print("Negation (a):", neg_result_1) -- -44372184372189432789321489432714893217443127432189489321743213213
print("Negation (b):", neg_result_2) -- -99999999432167432189432194325432543254376432718496327143214324211143214321120978736543654365435543636435

-- multiplication
local multiplication_result = a * b

print("Multiplication:", multiplication_result) -- 4437218412022971887507875792684174646471364793180868077485972519349116349927300559475970587086239473532536631868300345982651335104556968895588740093550765541071560215655

-- division
-- Note: '/' and '//' both perform integer (floor) division.
-- Fractional results are not supported by hello_mpz.

local division_result_1 = a / b
local division_result_2 = b / a
local modulo_result_1 = b % a
local modulo_result_2 = a % b

print("Division (a / b):", division_result_1) -- 0
print("Division (b / a):", division_result_2) -- 2253664110681986379959414177405414112681
print("Modulo (b % a):", modulo_result_1) -- 5831173648903621393417456268936038988888089028684359553353582382
print("Modulo (a % b):", modulo_result_2) -- 44372184372189432789321489432714893217443127432189489321743213213

-- exponentiation
-- actually we are not powering these huge integers, large exponents will grow extremely fast and are not practical
local c = hello_mpz.new("7")
local d = hello_mpz.new("432")
local pow_result_1 = c^d
local pow_result_2 = d^c

print("Power (c^d):", pow_result_1) -- 120879675690549898392727791748526830981036368732377355032532266173044084246345846507465092077775819543241810241466669662350375123522559028526792643399169056675594910773893522773171103200843646144008367165670711538910582847096811516752920079236307077059471167758508089655040847658929503133458151737729099282390804477525959211014824729550403384229309312198797825539201
print("Power (d^c):", pow_result_2) -- 2807929681968365568

-- integer square roots
local sqrt_result_1 = a:isqrt()
local sqrt_result_2 = b:isqrt()

print("Integer Square Root (a):", sqrt_result_1) -- 210647061152510344699426127270717
print("Integer Square Root (b):", sqrt_result_2) -- 9999999971608371569167381468548474320793760390916298

-- integer n roots (performance is definitely a lot worse here)
local iroot_result_1 = a:iroot("3") -- accepts numbers or strings for convenience, you can use hello_mpz numbers as well.
local iroot_result_2 = b:iroot("4")

print("Integer Cube Root (a):", iroot_result_1) -- 3540274494663629228482
print("Integer 4-Root (b):", iroot_result_2) -- 99999999858041857745076336

-- announce compute time
print("took ".. tostring(os.clock()-t).. " seconds") -- usually take less than 0.08 seconds on modern hardware
```

### Base Representations and Conversions

```lua
local hello_mpz = require(path.to.hello_mpz)

-- Small, easy-to-read numbers for demonstration
local small   = hello_mpz.new("42")
local medium  = hello_mpz.new("12345678901234567890")
local negative = hello_mpz.new("-987654321")

print("Original numbers:")
print("small:", small)          -- 42
print("medium:", medium)        -- 12345678901234567890
print("negative:", negative)    -- -987654321
print()

-- Built-in conversions
print("Unary (base 1):", small:toUnary())                    -- 111111111111111111111111111111111111111111 (42 ones)
print("Unary with custom symbol:", small:toUnary("|"))       -- |||||||||||||||||||||||||||||||||||||||||| (42 bars)

print("Binary:", small:toBinary())                           -- 0b101010
print("Hexadecimal:", small:toHex())                         -- 0x2A
print("Octal:", small:toOctal())                             -- 0o52

print("Base36:", medium:toBase36())                          -- 36#2LSOHXAWJUI8I
print("Base62:", medium:toBase62())                          -- 62#EhzL6HwZ5ow

print("Negative in hex:", negative:toHex())                  -- -0x3ADE68B1

print()

-- Parsing back with from* functions
local from_hex = hello_mpz.fromHex("0x2A")
print("fromHex('0x2A') == 42?", from_hex == small)           -- true

local from_base62 = hello_mpz.fromBase62("62#EhzL6HwZ5ow")
print("fromBase62 matches medium?", from_base62 == medium)   -- true

-- Custom base example
local custom_decimal = medium:toBase(10, "0123456789", "DEC#")
print("Custom decimal:", custom_decimal)                     -- DEC#12345678901234567890

local parsed = hello_mpz.fromBase("DEC#12345678901234567890", 10, "0123456789", "DEC#")
print("Custom parse matches?", parsed == medium)             -- true
```

## 🔨 Performance Benchmarks

All benchmarks conducted in Roblox Studio with fixed seed (123456) and averaged over 3 iterations.

**Test data sizes:**
- **Small**: 10-digit numbers
- **Medium**: 50-digit numbers  
- **Large**: 100-digit numbers

### Core Arithmetic Operations

| Operation | Small | Medium | Large |
|-----------|-------|--------|-------|
| Addition | 0.000099s | 0.000193s | 0.000169s |
| Subtraction | 0.000145s | 0.000239s | 0.000298s |
| Multiplication | 0.000021s | 0.000082s | 0.000136s |
| Division | 0.000053s | 0.000049s | 0.000089s |
| Modulo | 0.000036s | 0.000058s | 0.000066s |
| Power (^5) | 0.000105s | 0.000449s | 0.001825s |

### Comparisons

| Operation | Small | Medium | Large |
|-----------|-------|--------|-------|
| Equality & Ordering | 0.000092s | 0.000082s | 0.000108s |

### String Conversions

| Operation | Small | Medium | Large |
|-----------|-------|--------|-------|
| toString | 0.000089s | 0.000239s | 0.000445s |
| toScientific | 0.000133s | 0.000280s | 0.000526s |
| toHex | 0.000428s | 0.001809s | 0.004434s |
| toBinary | 0.000492s | 0.003143s | 0.007600s |

### Number Theory Functions

| Operation | Small | Medium |
|-----------|-------|--------|
| GCD | 0.001350s | 0.008479s |
| LCM | 0.001289s | 0.008789s |

### Factorials

| Operation | Time |
|-----------|------|
| 50! | 0.000284s |
| 100! | 0.000351s |
| 200! | 0.000772s |
| 50!! | 0.000133s |
| 100!! | 0.000397s |
| 200!! | 0.000773s |

### Combinatorics

| Operation | Time |
|-----------|------|
| C(100, 10) | 0.000077s |
| C(1000, 50) | 0.000283s |
| C(5000, 100) | 0.000731s |
| P(100, 10) | 0.000100s |
| P(1000, 50) | 0.000196s |
| P(5000, 100) | 0.000366s |

### Root Operations

| Operation | Small | Medium | Large |
|-----------|-------|--------|-------|
| Square Root | 0.002618s | 0.022938s | 0.071727s |
| Cube Root | 0.002944s | 0.031446s | 0.102920s |

> **Note:** nth root operations (n > 2) are currently the most computationally expensive operations in helloGMP, requiring one high-precision exponentiation (`x^(k-1)`) per Newton iteration,
making nth-root performance dominated by repeated big-integer exponentiation and division.

### Random Number Generation

| Size | Time |
|------|------|
| Small range | 0.000084s |
| Medium range | 0.000094s |
| Large range | 0.000106s |

### Iterator Performance

| Range | Time |
|-------|------|
| 1 to 1,000 | 0.000758s |
| 1 to 10,000 | 0.007910s |

## ⚒️ Benchmark for Computation Capability

To test the upper limits of `hello_mpz`, we evaluate the extreme exponential sequence:

$$ 2^{2^x} \quad \text{for } x = 1 \dots 20 $$


This sequence grows extraordinarily fast, each increment of `x` doubles the exponent size, causing the number of digits to explode. This is a stress test designed to reveal the maximum operand sizes that `hello_mpz` can handle within Luau's execution constraints.

### Results

| x | Approximate Value | Decimal Digits | Time |
|---|-------------------|----------------|------|
| 10 | 1.79769313486231 × 10^308 | 308 | 0.0009s |
| 12 | 1.04438888141315 × 10^1233 | 1233 | 0.0026s |
| 13 | 1.09074813561941 × 10^2466 | 2466 | 0.0064s |
| 14 | 1.18973149535723 × 10^4932 | 4932 | 0.0148s |
| 15 | 1.41546103104495 × 10^9864 | 9864 | 0.0408s |
| 16 | 2.00352993040684 × 10^19728 | 19,728 | 0.1202s |
| 17 | 4.01413218203606 × 10^39456 | 39,456 | 0.3623s |
| 18 | 1.61132571748576 × 10^78913 | 78,913 | 1.1055s |
| 19 | 2.59637056783100 × 10^157826 | 157,826 | 3.3927s |
| 20 | — | ~315,000 | **Timeout** |

### Observations

- `hello_mpz` successfully computes **2^2^19**, a number with roughly **158k decimal digits**, in about **3.4 seconds**.
- **2^2^20** exceeds Luau’s execution time limit due to the sheer size of the operands (over 300k digits, ~1 million bits).
- Division by 2 (`2^2^x / 2`) is trivial and completes instantly, as it is effectively a right‑shift.
- The growth curve matches the expected scaling of binary exponentiation combined with Karatsuba multiplication: extremely fast for small `x`, then sharply increasing as operand sizes dominate.

This benchmark demonstrates the practical upper bound of exponentiation in Luau and highlights the robustness of `hello_mpz` when handling extremely large integers.


## ⚒️ Performance Comparison

helloGMP builds upon the excellent work of libraries like APInt and BigNum in bringing arbitrary precision arithmetic to Roblox. We're grateful for their contributions to the ecosystem.

### Head-to-Head Benchmark: helloGMP vs APInt

Performance testing conducted in Roblox Studio with fixed seed (123456), averaged over 3 iterations.

**Test configuration:**
- **Small numbers**: 5-digit integers (200 samples)
- **Large numbers**: 20-digit integers (200 samples)
- **Mixed**: Small × Large operations

#### Operation Performance

| Operation | Size | helloGMP | APInt | Speedup |
|-----------|------|----------|-------|---------|
| **Division** | Small | 0.001265s | 0.023203s | **18.3×** |
| | Large | 0.001996s | 0.046195s | **23.1×** |
| | Mixed | 0.000866s | 0.019640s | **22.7×** |
| **Modulo** | Small | 0.001535s | 0.019369s | **12.6×** |
| | Large | 0.002040s | 0.048805s | **23.9×** |
| | Mixed | 0.000989s | 0.020709s | **20.9×** |
| **toString** | Small | 0.000127s | 0.000821s | **6.5×** |
| | Large | 0.000159s | 0.001429s | **9.0×** |
| **Subtraction** | Small | 0.041489s | 0.092325s | **2.2×** |
| | Large | 0.056858s | 0.099268s | **1.7×** |
| | Mixed | 0.054044s | 0.104816s | **1.9×** |
| **Addition** | Small | 0.020432s | 0.034334s | **1.7×** |
| | Large | 0.031950s | 0.035521s | **1.1×** |
| | Mixed | 0.025520s | 0.034704s | **1.4×** |
| **Multiplication** | Small | 0.001160s | 0.003714s | **3.2×** |
| | Large | 0.001817s | 0.003783s | **2.1×** |
| | Mixed | 0.001223s | 0.003584s | **2.9×** |
| **Comparison (<)** | Small | 0.006983s | 0.020617s | **3.0×** |
| | Large | 0.007062s | 0.021311s | **3.0×** |
| | Mixed | 0.006803s | 0.020229s | **3.0×** |
| **Equality (==)** | Small | 0.005235s | 0.007953s | **1.5×** |
| | Large | 0.005027s | 0.007227s | **1.4×** |
| | Mixed | 0.005126s | 0.012380s | **2.4×** |
| **Power** | Small | 0.000082s | 0.000145s | **1.8×** |
| | Large | 0.000060s | 0.000098s | **1.6×** |

#### Constructor Performance

| Number Size | helloGMP | APInt | Notes |
|-------------|----------|-------|-------|
| Small (5 digits) | 0.000285s | 0.000146s | APInt **2.0× faster** |
| Large (20 digits) | 0.000394s | 0.000330s | APInt **1.2× faster** |

> **Constructor tradeoff:** APInt has lower overhead for small number construction, while helloGMP's asymptotically efficient algorithm becomes faster as numbers grow larger. 

### Key Takeaways

**helloGMP excels at:**
- **Division and modulo operations**: 18-24× faster across all sizes
- **String conversions**: 6-9× faster
- **All arithmetic operations**: Consistently faster, especially on larger numbers
- **Extreme number sizes**: Remains stable for 100+ digit division where APInt may timeout

**APInt advantages:**
- Smaller codebase (~553 lines vs ~2000 lines)
- Slightly faster constructor for small numbers
- Excellent choice for applications with moderate number sizes

---

*Full benchmark scripts available in the `/benchmarks` directory for independent verification.*

## Algorithm Engineering Philosophy
- **Why Schoolbook -> Comba -> Karatsuba for Multiplication?**
    - I see this as the most practical and empirically optimal algorithm ladder suiting for Luau.
    - Schoolbook is used for very small integers because its low constant factors and zero overhead make it faster than any asymptotically superior method, though it scales poorly as limb counts grow.
    - Comba refines schoolbook by tightening inner‑loop operations and improving locality, giving a clear win for mid‑sized values at the cost of more complex implementation.
    - Karatsuba activates only for large operands where its `O(n^1.585)` behaviour outweighs recursion overhead, trading simplicity for significantly better scaling.
    - I actually tried to implement Toom-3, however the implementation is difficult in correctness and the overhead completely erased the theoretical asymptotic benefits in Luau.
    - Fast Fourier Transform (FFT) multiplication has excellent asymptotic asymptotic complexity of `O(n log n)`, but the implementation is extremely complex, and Luau does not guarantee float-point precision meaning results can drift.
    - The Number Theoretic Transform (NTT) is an alternative to FFT that avoids floating-point issues, but its modulus constraints and limited coverage make it impractical for general-purpose big-integer arithmetic in Luau.
- **Why Only Use Knuth D for Division?**
    - Typical fast schoolbook long division variants in theory should achieve `O(n^2)` asymptotic complexity. In Luau, their many small, unbalanced partial divisions create a large number of temporary big integers, making them significantly slower than the theory suggests.
    - Knuth D Division performs and scales far better than "fast long division" variants despite sharing the same `O(n^2)` asymptotic complexity. The implementation was difficult but the payoff is substantial, especially because division is a core operator that must be both correct and consistently fast.
    - Burnikel-Ziegler Division has better asymptotic complexity than Knuth D Division in theory, but with implementation and tests, it is simply not possible to get it correct while fast, therefore scrapped.
    - Newton Division is an alternative to Burnikel-Ziegler that uses Newton iteration to approximate reciprocals, but it requires extremely fast multiplication to be worthwhile. In Luau, the cost of repeated large multiplications and the precision requirements of reciprocal approximation make Newton Division slower and less reliable than Knuth D for the operand sizes `hello_mpz` targets.
- **Why Use Binary Splitting for Factorials?**
    - The naive approach to computing `n!` performs `n` sequential multiplications, which is simple but scales poorly, especially because each multiplication grows in size as the result grows. In Luau, this leads to a large number of big-integer allocations and quickly becomes the dominant cost.
    - Binary splitting reduces the number of multiplications dramatically by recursively splitting the range into balanced subproducts. This produces a multiplication tree with logarithmic depth, which pairs extremely well with Karatsuba and avoids the linear chain of ever-growing intermediates.
- **Why Binary Search and Newton Iteration for Roots?**
    - Binary search is extremely reliable for small integers: it over overshoots, it requires only comparisons and multiplications, and it avoids the overhead of division. For small limb counts, this simplicity makes it faster than Newton's method despite its linear covergence.
    - Newton iteration becomes dramatically faster for large integers because it converges quadratically, each iteration roughly doubles the number of correct digits. Even though each step is expensive (requiring big-integer multiplication and division), the number of steps is small, making it the best choice for large operands.
    - This hybrid approach is used for both integer square roots and integer n-roots purely for performance reasons. Newton's method for n-roots has significantly more overhead than for square roots due to repeated big-integer exponentiation and division, but given Luau's constraints, it remains the most practical option available.