# HelloGMP: `hello_mpf`
The `hello_mpf` module is one of the main libraries of the **helloGMP** library which provides big approximate floating-point arithmetic. Unlike the two libraries, `hello_mpf` is based on the Multiple-Precision Floating-Point Reliable (MPFR) library.

> NOTE: `hello_mpf` is still affected by floating-point drifts in representation, if you want exact values please use `hello_mpq` instead.

## `hello_mpf` System Overview

`hello_mpf` is implements arbitrary precision floating-point numbers using a system modeled after the **MPFR** library. Unlike `hello_mpz`, which stores integers in decimal base chunks, `hello_mpf` stores number in a **binary scientific-notation format**:

$$ \text{value} = \text{sign} \times \text{mantissa} \times 2^{\text{exponent}} $$

Where:
- `sign` is a boolean (`false = positive`, `true = negative`)
- `mantissa` is a `hello_mpz` integer which stores the significant bits of the number.
- `exponent` is a Lua number (integer) which represents the power of two.
- `precision` is the number of bits to keep in the mantissa. The default is the `DEFAULT_PRECISION` setting parameter in the `base_settings` module.

The `hello_mpf` normalizer adjusts the mantissa and exponent to enforce this invariant:

$$ 2^{p - 1} \le \text{mantissa} < 2^{p} $$

Where `p = precision`. This ensures stable rounding and predictable arithmetic behaviour.

## ✨ Features of `hello_mpf`

- **Arithmetic operators**: Overloaded `+`, `=`, `*`, `/`, and unary `-`
- **Comparison operators**: Overloaded `>`, `>=`, `==`, `<=`, `<`
  (`>` and `>=` are inherited from `__lt` and `__le`)
- **Customizable and Optional Precision for Constructors**: `hello_mpf` constructors have an optional precision parameter determining how many bits the value would have. Higher precision = more accuracy but slower operations.

- **Core Constructors & Conversions**
  - `hello_mpf.new(value, precision)` → Creates the floating-point number with its value and precision (in bits, and optional).
  - `hello_mpf(value, precision)` → Same as `.new()` but serves as a callable shortcut.
  - `hello_mpf.fromString(value, precision)` → value must be a string number
  - `hello_mpf.fromNumber(value, precision)` → value must be a native Luau number
  - `:toString()` → Converts the floating-point number into a binary scientific or fixed value representation depending on `base_settings` default.
  - `__tostring` → Metamethod of `:toString()`
  - `:toScientificString()` → Converts the floating-point number into a binary scientific representation.
  - `:toDecimalString()` → Converts the floating-point number into a fixed value representation.

- **Utilities**
  - `:neg()` - Returns the negated value of the floating-point number (unary minus, `__unm`)
  - `:abs()` - Returns the absolute value of the floating-point number
  - `:clone()` - Clones the floating-point number.

## Uses and Demonstrations of `hello_mpf`

### Construction and Representation

```lua
local hello_mpf = require(path.to.hello_mpf)

local a = hello_mpf.fromString("1.21344321") -- value must be a string
local b = hello_mpf.fromNumber(5432.2134) -- value must be a native Lua number
local c = hello_mpf.new("4327184372189437218904321.432174321943214321") -- can accept both types (string or number)
local d = hello_mpf.new("47382174839274821.4321467329143721894312", 125) -- 125 bits of precision
local e = hello_mpf.new("9999999999999999.4", 999) -- 999 bits of precision

-- toString (base_settings.FLOAT_DISPLAY_MODE = "fixed")
-- Note that floating-point drifts apply here.
print("a:", a)
print("b:", b)
print("c:", c)
print("d:", d)
print("e:", e)

-- toDecimalString
print("a (decimal string digits: 5):", a:toDecimalString(5))
print("b (decimal string digits: 6):", b:toDecimalString(6))
print("c (decimal string digits: 7):", c:toDecimalString(7))
print("d (decimal string digits: 8):", d:toDecimalString(8))
print("e (decimal string digits: 9):", e:toDecimalString(9))

-- toScientificString 
-- NOTE: scientific string is most likely used for debugging purposes rather than normal display.
print("a (scientific string):", a:toScientificString())
print("b (scientific string):", b:toScientificString())
print("c (scientific string):", c:toScientificString())
print("d (scientific string):", d:toScientificString())
print("e (scientific string):", e:toScientificString())
```

### Arithmetic

```lua
local hello_mpf = require(path.to.hello_mpf)

-- Example prices
local price1 = hello_mpf.new("12.99")
local price2 = hello_mpf.new("3.99")
local price3 = hello_mpf.new("54.49")

-- Tax rate
local tax = hello_mpf.new("0.3")

-- Multiplication 
print("price1 * tax =", (price1 * tax):toDecimalString(4))  -- 3.897
print("price2 * tax =", (price2 * tax):toDecimalString(4))  -- 1.197
print("price3 * tax =", (price3 * tax):toDecimalString(4))  -- 16.347

-- Division
print("price1 / tax =", (price1 / tax):toDecimalString())  -- 43.3
print("price2 / tax =", (price2 / tax):toDecimalString())  -- 13.3
print("price3 / tax =", (price3 / tax):toDecimalString(4))  -- 181.6333

-- Addition
local total = price1 + price2 + price3
print("Total price =", total:toDecimalString(4))  -- 71.4700

-- Subtraction
local discount = hello_mpf.new("5.50")
local discounted_total = total - discount
print("Discounted total =", discounted_total:toDecimalString(4))  -- 65.9700

-- Combined example
local final_price = (price1 + price2 + price3) * (hello_mpf.new("1") + tax) - hello_mpf.new("2.0")
print("Final price with tax and discount =", final_price:toDecimalString(4))  -- 90.9110
```

### Comparison Operations

```lua
local hello_mpf = require(path.to.hello_mpf)

-- Example numbers
local a = hello_mpf.new("12.99")
local b = hello_mpf.new("3.99")
local c = hello_mpf.new("12.9900000001") -- slightly bigger than a

-- Less than
print("a < b:", a < b)   -- false
print("b < a:", b < a)   -- true

-- Less than or equal
print("a <= b:", a <= b) -- false
print("a <= c:", a <= c) -- true

-- Greater than
print("a > b:", a > b)   -- true
print("b > a:", b > a)   -- false

-- Greater than or equal
print("a >= b:", a >= b) -- true
print("a >= c:", a >= c) -- false

-- Equal and not equal
print("a == b:", a == b) -- false
print("a == hello_mpf.new('12.99'):", a == hello_mpf.new("12.99")) -- true
print("a ~= c:", a ~= c) -- true
```

### Utilities

```lua
local hello_mpf = require(path.to.hello_mpf)

-- Example numbers
local a = hello_mpf.new("12.34")
local b = hello_mpf.new("-56.78")

-- === clone ===
local a_clone = a:clone()
print("Original a:", a:toDecimalString(4))
print("Cloned a:", a_clone:toDecimalString(4))

-- Modifying the clone should NOT affect the original
a_clone = a_clone * hello_mpf.new("2")
print("Modified clone:", a_clone:toDecimalString(4))
print("Original a after clone modification:", a:toDecimalString(4))  -- should stay 12.34

-- === abs ===
print("Absolute value of a:", a:abs():toDecimalString(4))  -- 12.34
print("Absolute value of b:", b:abs():toDecimalString(4))  -- 56.78

-- === neg ===
local neg_a = a:neg()
print("Negated a:", neg_a:toDecimalString(4))  -- -12.34
local neg_b = b:neg()
print("Negated b:", neg_b:toDecimalString(4))  -- 56.78

-- === unary minus (__unm) ===
print("Unary minus a:", (-a):toDecimalString(4))  -- -12.34
print("Unary minus b:", (-b):toDecimalString(4))  -- 56.78
```

## 🔨 Performance Benchmarks (helloGMP 1.3.0)

Benchmarks were performed on `hello_mpf` to evaluate the relative cost of core floating-point operations across different operand sizes, ran for 3 iterations on 50 samples.

### Test Categories
- **Small**: ~10 decimal digits (64 bits of precision)
- **Medium**: ~20 decimal digits (128 bits of precision)
- **Large**: ~40 decimal digits (256 bits of precision)

### Arithmetic Operations

| Operation        | Small (s) | Medium (s) | Large (s) |
|------------------|-----------|------------|-----------|
| Addition         | 0.003858  | 0.008399   | 0.020719  |
| Subtraction      | 0.003949  | 0.008730   | 0.019898  |
| Multiplication   | 0.003050  | 0.008612   | 0.020775  |
| Division         | 0.002292  | 0.005513   | 0.012263  |

### Comparison Operations

| Operation              | Small (s) | Medium (s) | Large (s) |
|------------------------|-----------|------------|-----------|
| Equality & Ordering    | 0.000120  | 0.000075   | 0.000093  |

### Utility Operations

| Operation        | Small (s) | Medium (s) | Large (s) |
|------------------|-----------|------------|-----------|
| clone()          | 0.000098  | 0.000078   | 0.000037  |
| abs()            | 0.000092  | 0.000030   | 0.000047  |
| neg / __unm     | 0.000051  | 0.000034   | 0.000057  |

### Conversion Operations

| Operation              | Small (s) | Medium (s) | Large (s) |
|------------------------|-----------|------------|-----------|
| toDecimalString        | 0.002053  | 0.002852   | 0.003652  |
| toScientificString    | 0.000026  | 0.000071   | 0.000090  |