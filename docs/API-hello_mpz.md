# HelloGMP: `hello_mpz`
The `hello_mpz` module is the core of the helloGMP library, providing high‑performance arbitrary‑precision integer arithmetic. It is designed to handle numbers far beyond native Luau limits, while maintaining speed and correctness through optimized algorithms. This module serves as the foundation for advanced features such as number theory, combinatorics, and base conversions.

## ✨ Features of `hello_mpz`
The `hello_mpz` module includes a wide range of capabilities.
For clarity, the following complexity notation is used throughout:

- `n` → size of input value (e.g., number of digits)
- `m` → number of limbs in the big integer
- `len(s)` → length of input string
- `L` → number of limbs in the largest operand; comparisons may early-exit on differing limb counts.
- `M(?)` → algorithm complexity used in multiplication, usually denoted in `M(m)` for number of limbs. `?` is a placeholder for input length inside `M`.

### Available Features
- **Arithmetic operators**: Overloaded `+`, `-`, `*`, `/`, `//`, `%`, `^`, and unary `-`
- **Comparison operators**: Overloaded `>`, `>=`, `==`, `<=`, `<`  
  (`>` and `>=` are inherited from `__lt` and `__le`)
- `.compare(a, b)` → `O(L)` -  function to return `1`, `0`, or `-1` results. (1.1.0)

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
  - `:clone()` → `O(m)` - Creates a deep copy of the integer  
  - `:isEven()` → `O(1)` - Checks if the integer is divisible by 2  
  - `:isOdd()` → `O(1)` - Checks if the integer is not divisible by 2  
  - `:abs()` → `O(m)` - Returns the absolute value of the integer  
  - `:neg()` → `O(m)` - Returns the negated value (unary minus, `__unm`)  
  - `:isZero()` → `O(1)` - Tests whether the integer equals zero  
  - `:isPositive()` → `O(1)` - Tests whether the integer is strictly greater than zero  
  - `:isNegative()` → `O(1)` - Tests whether the integer is strictly less than zero  
  - `.max(x, ...)` → `O(n * L)` - Returns the maximum value in the given values
  - `.min(x, ...)` → `O(n * L)` - Returns the minimum value in the given values
  - `.clamp(x, min, max)` → `O(L)` - Clamps x to the inclusive range [min, max]

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
- **Primality Tests**:
    - `:isPrime()` → Baillie-PSW algorithm, `O((log n)^3)`
    - `:isProbablePrime(k)` → Miller-Rabin algorithm, `O(k * (log n)^3)`
    - `:nextPrime()` → Finds the least prime number strictly above the number, `O(M(log n) * (log n)^2)`, worst case `O(M(log n) * (log n)^3`
    - `:previousPrime()` → Finds the greatest prime number strictly under the number, `O(M(log n) * (log n)^2`, worst case `O(M(log n) * (log n)^3`
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

### Comparisons

```lua
local hello_mpz = require(path.to.hello_mpz)

-- Large positive numbers (differ by 1 at the end)
local a = hello_mpz.new("437218904321789054327189043217890432178590321743890215321")
local b = hello_mpz.new("437218904321789054327189043217890432178590321743890215322")

-- Medium positive number
local c = hello_mpz.new("77777777777777774325432")

-- Negative number
local d = hello_mpz.new("-43214231")

-- Zero for completeness
local z = hello_mpz.new("0")

print("=== Equality (==) ===")
print("a == b:", a == b)         -- false (differ by 1)
print("a == a:", a == a)         -- true
print("c == c:", c == c)         -- true
print("d == d:", d == d)         -- true
print("z == z:", z == z)         -- true
print("a == c:", a == c)         -- false

print("\n=== Greater Than (>) ===")
print("a > b:", a > b)           -- false (a is smaller)
print("b > a:", b > a)           -- true
print("c > a:", c > a)           -- false (c is much smaller)
print("a > c:", a > c)           -- true
print("d > z:", d > z)           -- false (negative < zero)
print("z > d:", z > d)           -- true

print("\n=== Less Than (<) ===")
print("a < b:", a < b)           -- true
print("b < a:", b < a)           -- false
print("c < a:", c < a)           -- true
print("a < c:", a < c)           -- false
print("d < z:", d < z)           -- true
print("z < d:", z < d)           -- false

print("\n=== Greater Than or Equal (>=) ===")
print("a >= a:", a >= a)         -- true
print("b >= a:", b >= a)         -- true
print("a >= b:", a >= b)         -- false
print("d >= z:", d >= z)         -- false
print("z >= d:", z >= d)         -- true

print("\n=== Less Than or Equal (<=) ===")
print("a <= a:", a <= a)         -- true
print("a <= b:", a <= b)         -- true
print("b <= a:", b <= a)         -- false
print("d <= z:", d <= z)         -- true
print("z <= d:", z <= d)         -- false

print("\n=== Mixed Sign Comparisons ===")
local pos = hello_mpz.new("100")
local neg = hello_mpz.new("-100")

print("pos > neg:", pos > neg)   -- true
print("neg > pos:", neg > pos)   -- false
print("pos < neg:", pos < neg)   -- false
print("neg < pos:", neg < pos)   -- true
print("pos == neg:", pos == neg) -- false
print("pos >= neg:", pos >= neg) -- true
print("neg <= pos:", neg <= pos) -- true

print("\n=== Zero Comparisons ===")
print("z > z:", z > z)           -- false
print("z < z:", z < z)           -- false
print("z >= z:", z >= z)         -- true
print("z <= z:", z <= z)         -- true
print("z == z:", z == z)         -- true

print("\n=== Compare Comparisons (1.1.0) ===")
print("a > b:", hello_mpz.compare(a, b))           -- -1
print("b > a:", hello_mpz.compare(b, a))           -- 1
print("c > a:", hello_mpz.compare(c, a))           -- -1
print("a > c:", hello_mpz.compare(a, c))           -- 1
print("d > z:", hello_mpz.compare(d, z))           -- -1
print("z > d:", hello_mpz.compare(z, d))           -- 1
print("z == z:", hello_mpz.compare(z, z))         -- 0
```

### Utilities

```lua

local hello_mpz = require(path.to.hello_mpz)

local num = hello_mpz.new("-1234567890")

-- checks if number is even (constant time)
print(":isEven()", num:isEven())       -- true

-- checks if number is odd (constant time)
print(":isOdd()", num:isOdd())        -- false

-- absolute value of self
print(":abs()", num:abs())          -- 1234567890

-- negate value of self
print(":neg()", num:neg())          -- 1234567890 (or use -num)

-- checks if number is zero (constant time)
print(":isZero()", num:isZero())       -- false

-- checks if number is positive (constant time)
print(":isPositive()", num:isPositive())   -- false

-- checks if number is negative (constant time)
print(":isNegative()", num:isNegative())   -- true

local copy = num:clone()
print(":clone()" copy == num)        -- true (different object)

-- min, max, and clamp
local a = hello_mpz.new("42")
local b = hello_mpz.new("100")
local c = hello_mpz.new("-7")

print(hello_mpz.min(a, b, c)) -- -7
print(hello_mpz.max(a, b, c)) -- 100
print(hello_mpz.clamp(a, c, b)) -- 42
```

### Number Theory Functions

```lua
local hello_mpz = require(path.to.hello_mpz)

local a = hello_mpz.fromString("12345678901234567890")
local b = hello_mpz.fromString("98765432109876543210")

local lcm_result = hello_mpz.LCM(a, b) -- Least Common Multiple
local gcd_result = hello_mpz.GCD(a, b) -- Greatest Common Divisor

print("LCM(a, b):", lcm_result) -- 1354807012498094801236261410
print("GCD(a, b):", gcd_result) -- 900000000090
```

### Probability Functions

```lua
local hello_mpz = require(game.ReplicatedStorage.helloGMP.hello_mpz)

-- making this timed
local t = os.clock()

local a = hello_mpz.fromString("100000")
local b = hello_mpz.fromString("500")

local comb_result = hello_mpz.comb(a, b)
local perm_result = hello_mpz.perm(a, b)

-- okay man these are huge integers though.
print("comb(100000, 500):", comb_result)
print("perm(100000, 500):", perm_result)

-- random integers
local min = hello_mpz.fromString("100000000000000000000")
local max = hello_mpz.fromString("999999999999999999999")

-- three random samples
local random_1 = hello_mpz.random(min, max)
local random_2 = hello_mpz.random(min, max)
local random_3 = hello_mpz.random(min, max)

print("3 random integers:", random_1, random_2, random_3)

print("took ".. tostring(os.clock() - t) .. " seconds") -- should take less than 0.05 seconds on modern hardware
```

### For loop Support

```lua
local hello_mpz = require(path.to.hello_mpz)

-- Basic upward iteration (inclusive)
local a = hello_mpz.new("1")
local b = hello_mpz.new("10")

print("=== :to (inclusive) ===")
for i in a:to(b) do
	print(i)
end
-- 1 2 3 4 5 6 7 8 9 10

-- Upward iteration with custom step (string, number, or mpz)
print("\n=== :to with step ===")
for i in a:to("20", "3") do -- steps can be strings or numbers, not only hello_mpz instances
	print(i)
end
-- 1 4 7 10 13 16 19

-- Upward exclusive iteration
print("\n=== :toExclusive (exclusive) ===")
for i in a:toExclusive("10", 2) do
	print(i)
end
-- 1 3 5 7 9

-- Downward iteration (inclusive)
local c = hello_mpz.new("15")
local d = hello_mpz.new("5")

print("\n=== :downTo (inclusive) ===")
for i in c:downTo(d) do
	print(i)
end
-- 15 14 13 12 11 10 9 8 7 6 5

-- Downward exclusive iteration
print("\n=== :downToExclusive (exclusive) ===")
for i in c:downToExclusive("5") do
	print(i)
end
-- 15 14 13 12 11 10 9 8 7 6

-- Standalone iterator (hello_mpz.range)
print("\n=== hello_mpz.range ===")
for i in hello_mpz.range("0", "12", "4") do
	print(i)
end
-- 0 4 8 12
```

### Primality Testing

```lua
local hello_mpz = require(path.to.hello_mpz)

-- Helper function to test and print primality
local function testPrime(strNum)
	local num = hello_mpz.new(strNum)
	local isPrime = num:isPrime()
	if isPrime then
		print(num:toString() .. " is prime!")
	else
		print(num:toString() .. " is not prime.")
	end
end

-- Test numbers
testPrime("32416190071")  -- prime
testPrime("32416190072")  -- not prime

-- Optional: Probabilistic test with Miller-Rabin
local num = hello_mpz.new("32416190072")

local isProbPrime = num:isProbablePrime(10) -- 10 iterations

print("Probabilistic primality test result:", isProbPrime)

-- Next prime and previous prime
local n = hello_mpz.new("1000")
print(n:nextPrime())     -- 1009
print(n:previousPrime()) -- 997
```

### Factorials 

```lua
local hello_mpz = require(path.to.hello_mpz)

-- Small examples for readability
local a = hello_mpz.new("10")
local b = hello_mpz.new("15")
local c = hello_mpz.new("25")

print("=== Factorial ===")
print("10!:", a:factorial())   -- 3628800
print("15!:", b:factorial())   -- 1307674368000
print("25!:", c:factorial())   -- 15511210043330985984000000

print("\n=== Double Factorial ===")
local d1 = hello_mpz.new("10")
local d2 = hello_mpz.new("9")

print("10!!:", d1:doubleFactorial())  -- 3840  (10 * 8 * 6 * 4 * 2)
print("9!!:",  d2:doubleFactorial())  -- 945   (9 * 7 * 5 * 3 * 1)

print("\n=== Multi-Factorial (step k) ===")
local m = hello_mpz.new("20")

print("20!_3:", m:multiFactorial(3))  -- 20 * 17 * 14 * 11 * 8 * 5 * 2
print("20!_4:", m:multiFactorial("4")) -- 20 * 16 * 12 * 8 * 4

-- Large factorials (binary splitting)
print("\n=== Large Factorials (timed) ===")
local t = os.clock()

local big1 = hello_mpz.new("100")
local big2 = hello_mpz.new("200")

local f100 = big1:factorial()
local f200 = big2:factorial()

print("100!:", f100)
print("200!:", f200)

print("took ".. tostring(os.clock() - t) .. " seconds")
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

## 🔨 Performance Benchmarks (Tested in helloGMP 1.2.0)

All benchmarks were conducted in Roblox Studio with fixed seed (`123456`) and averaged over 3 iterations.

**Test data sizes:**
- **Small**: 10‑digit numbers  
- **Medium**: 50‑digit numbers  
- **Large**: 100‑digit numbers  

### Core Arithmetic Operations

| Operation      | Small       | Medium      | Large       |
|----------------|-------------|-------------|-------------|
| Addition       | 0.000056s  | 0.000150s  | 0.000163s  |
| Subtraction    | 0.000147s  | 0.000233s  | 0.000306s  |
| Multiplication | 0.000017s  | 0.000086s  | 0.000091s  |
| Division       | 0.000025s  | 0.000045s  | 0.000039s  |
| Modulo         | 0.000037s  | 0.000032s  | 0.000044s  |
| Power (^5)     | 0.000092s  | 0.000224s  | 0.001064s  |

### Comparisons

| Operation             | Small       | Medium      | Large       |
|-----------------------|-------------|-------------|-------------|
| Equality & Ordering   | 0.000062s  | 0.000068s  | 0.000068s  |
| Raw `compare()`       | 0.000010s  | 0.000018s  | 0.000040s  |

### String Conversions

| Operation      | Small       | Medium      | Large       |
|----------------|-------------|-------------|-------------|
| toString       | 0.000111s  | 0.000236s  | 0.000476s  |
| toScientific   | 0.000121s  | 0.000330s  | 0.000413s  |
| toHex          | 0.000279s  | 0.001478s  | 0.003325s  |
| toBinary       | 0.000394s  | 0.002327s  | 0.005756s  |

### Number Theory

| Operation | Small       | Medium      |
|-----------|-------------|-------------|
| GCD       | 0.000833s  | 0.005116s  |
| LCM       | 0.000748s  | 0.004755s  |

### Factorials

| Operation       | Time        |
|-----------------|-------------|
| 50!             | 0.000288s  |
| 100!            | 0.000451s  |
| 200!            | 0.001055s  |
| 50!!            | 0.000179s  |
| 100!!           | 0.000312s  |
| 200!!           | 0.000684s  |

### Combinatorics

| Operation       | Time        |
|-----------------|-------------|
| C(100, 10)      | 0.000063s  |
| C(1000, 50)     | 0.000350s  |
| C(5000, 100)    | 0.000645s  |
| P(100, 10)      | 0.000025s  |
| P(1000, 50)     | 0.000187s  |
| P(5000, 100)    | 0.000380s  |

### Root Operations

| Operation       | Small       | Medium      | Large        |
|-----------------|-------------|-------------|--------------|
| Square Root     | 0.001977s  | 0.015561s  | 0.044447s   |
| Cube Root       | 0.002320s  | 0.018844s  | 0.059184s   |

### Primality Testing

| Operation              | Small       | Medium      | Large       |
|------------------------|-------------|-------------|-------------|
| isPrime (BPSW)         | 0.002705s  | 0.053526s  | 0.063283s  |
| isProbablePrime (MR)   | 0.002944s  | 0.109133s  | 0.000193s  |

### Random Number Generation

| Range Size      | Time        |
|-----------------|-------------|
| Small           | 0.000105s  |
| Medium          | 0.000077s  |
| Large           | 0.000102s  |

### Iterator Performance

| Range           | Time        |
|-----------------|-------------|
| 1 to 1,000      | 0.000588s  |
| 1 to 10,000     | 0.005831s  |

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

**HelloGMP's** `hello_mpz` module builds upon the excellent work of libraries like [APInt](https://github.com/CrabGuy/APInt) (by [CrabGuy](https://github.com/CrabGuy)) in bringing arbitrary precision arithmetic to Roblox. We're grateful for their contributions to the ecosystem.

### Head-to-Head Benchmark: helloGMP vs APInt (Outdated)

Performance testing conducted in Roblox Studio with fixed seed (`123456`), averaged over 3 iterations.

**Test configuration:**
- **Small numbers**: 5-digit integers (200 samples)
- **Large numbers**: 20-digit integers (200 samples)
- **Mixed**: Small × Large operations

#### Operation Performance

| Operation       | Size   | helloGMP     | APInt        | Speedup          |
|-----------------|--------|--------------|--------------|-----------------|
| **Division**    | Small  | 0.000625s    | 0.007017s    | **11.2×**       |
|                 | Large  | 0.000684s    | 0.051168s    | **74.7×** 🔥     |
|                 | Mixed  | 0.000267s    | 0.006506s    | **24.4×**       |
| **Modulo**      | Small  | 0.000485s    | 0.006802s    | **14.0×**       |
|                 | Large  | 0.000559s    | 0.048798s    | **87.3×** 🔥     |
|                 | Mixed  | 0.000383s    | 0.006554s    | **17.1×**       |
| **Multiplication** | Small | 0.000357s   | 0.001210s    | **3.4×**        |
|                 | Large  | 0.000454s    | 0.001183s    | **2.6×**        |
|                 | Mixed  | 0.000324s    | 0.001412s    | **4.4×**        |
| **toString**    | Small  | 0.000111s    | 0.000573s    | **5.2×**        |
|                 | Large  | 0.000110s    | 0.000917s    | **8.3×**        |
| **Addition**    | Small  | 0.006429s    | 0.011786s    | **1.8×**        |
|                 | Large  | 0.008455s    | 0.012502s    | **1.5×**        |
|                 | Mixed  | 0.008327s    | 0.012614s    | **1.5×**        |
| **Subtraction** | Small  | 0.012717s    | 0.033553s    | **2.6×**        |
|                 | Large  | 0.016443s    | 0.035985s    | **2.2×**        |
|                 | Mixed  | 0.015973s    | 0.037255s    | **2.3×**        |
| **Equality (==)** | Small | 0.001563s    | 0.003034s    | **1.9×**        |
|                 | Large  | 0.001462s    | 0.002353s    | **1.6×**        |
|                 | Mixed  | 0.001556s    | 0.002654s    | **1.7×**        |
| **Comparison (<)** | Small | 0.001977s    | 0.007434s    | **3.8×**        |
|                 | Large  | 0.001877s    | 0.007568s    | **4.0×**        |
|                 | Mixed  | 0.001869s    | 0.007322s    | **3.9×**        |

#### Constructor Performance

| Number Size     | helloGMP     | APInt        | Notes                        |
|-----------------|--------------|--------------|------------------------------|
| Small           | 0.000108s    | 0.000088s    | APInt slightly faster (~1.2×) |
| Large           | 0.000115s    | 0.000184s    | helloGMP slightly faster (~1.6×) |

> **Constructor tradeoff:** APInt has lower overhead for small number construction, while helloGMP's asymptotically efficient algorithm becomes faster as numbers grow larger. 

### Key Takeaways

**HelloGMP:**
- **Division and modulo operations**: Dramatically faster, especialy on large numbers (up to ~87× faster).
- **Multiplication**: 2-4× faster across most sizes.
- **String conversions (`toString`)**: 5-8× faster.
- **All arithmetic operations**: Consistently faster on both small and large numbers, with the biggest gains on large number.

**APInt:**
- **Compactness**: Smaller codebase (~553 lines vs ~2000 lines)
- **Constructor speed**: Slightly faster for small numbers (~1.2× faster)
- **Small-number equality and addition**: Competitive performance in very small arithmetic operations.

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