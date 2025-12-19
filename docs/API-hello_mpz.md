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
  - `hello_mpz.fromNumber(n)` → `O(1)` for fixed-width Lua numbers  (conceptually `O(log n)`, but bounded by double precision)
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
    - `random(min, max)` → Produces a uniformly distributed random integer within the specified range, expected `O(m)` per accepted value

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

local a = hello_mpz.fromString("44372184372189432789321489432714893217443127432189489321743213213")
local b = hello_mpz.fromString("9999999943216743218943219432143214321120978736543654365435543636435")

-- addition
local addition_result = a + b

print("Addition:", addition_result) -- 10044372127588932651732540921575929214338421863975843854757286849648

-- subtraction
local subtraction_result_1 = b - a
local subtraction_result_2 = a - b

print("Subtraction (b - a):", subtraction_result_1) -- 9955627758844553786153897942710499427903535609111464876113800423222
print("Subtraction (a - b):", subtraction_result_2) -- -9955627758844553786153897942710499427903535609111464876113800423222

-- negation
local neg_result_1 = -a 
local neg_result_2 = -b 

print("Negation (a):", neg_result_1) -- -44372184372189432789321489432714893217443127432189489321743213213
print("Negation (b):", neg_result_2) -- -9999999943216743218943219432143214321120978736543654365435543636435

-- multiplication
local multiplication_result = a * b

print("Multiplication:", multiplication_result) -- 44372184120229...41071560215655 

-- division
-- both division and integer division return the same result for hello_mpz numbers
local division_result_1 = a / b
local division_result_2 = b // a

local modulo_result_1 = b % a
local modulo_result_2 = a % b

print("Division (div):", division_result_1) -- 0
print("Division (idiv):", division_result_2) -- 225

print("Modulo (b % a):", modulo_result_1) -- 16258459474120841345884309782363347196275064301019268043320663510
print("Modulo (a % b):", modulo_result_2) -- 44372184372189432789321489432714893217443127432189489321743213213

-- exponentation
-- actually we are not powering these huge integers, large exponents will grow extremely fast and are not practical
local c = hello_mpz.fromString("7")
local d = hello_mpz.fromString("432")

local pow_result_1 = c^d
local pow_result_2 = d^c

print("Power (c^d):", pow_result_1) -- 12087967569054989839272...309312198797825539201
print("Power (d^c):", pow_result_2) -- 2807929681968365568

-- integer square roots
local sqrt_result_1 = a:isqrt()
local sqrt_result_2 = b:isqrt()

print("Integer Square Root (a):", sqrt_result_1) -- 210647061152510344699426127270717
print("Integer Square Root (b):", sqrt_result_2) -- 3162277651190158099736552723283910

-- integer n roots (performace is definitely a lot worse here)
local iroot_result_1 = a:iroot("3")
local iroot_result_2 = b:iroot("4")

print("Integer Cube Root (a):", iroot_result_1) -- 3540274494663629228482
print("Integer 4-Root (b):", iroot_result_2) -- 56234132439205978

print("took ".. tostring(os.clock()-t).. " seconds") -- usually take less than 0.05 seconds 
```
