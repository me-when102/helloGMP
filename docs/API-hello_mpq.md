# HelloGMP: `hello_mpq`
The `hello_mpq` module is one of the main libraries of the **helloGMP** library which provides big and exact rational number arithmetic. How `hello_mpq` works depends on the foundations of the `hello_mpz` module's arithmetic foundations, therefore its performance is significantly slower in asymptotic complexity.

> NOTE: This document is working in progress, you can use the source code and learn it yourself.

## ✨ Features of `hello_mpq`
- **Arithmetic operators**: Overloaded `+`, `-`, `*`, `/`, and unary `-`
- **Comparison operators**: Overloaded `>`, `>=`, `==`, `<=`, `<`
  (`>` and `>=` are inherited from `__lt` and `__le`)
- `.compare(a, b)` function to return `1`, `0`, or `-1` results.

- **Core Constructors & Conversions**
  - `hello_mpz.new(nom, den)` → nom = nominator and den = denominator, can be `hello_mpz` number, native Luau number, or string.
  - `hello_mpz(nom, den)` → Same as `.new()` but serves as a shortcut.
  - `hello_mpz.fromString(nom, den)` → must be string number
  - `hello_mpz.fromNumber(nom, den)` → must be native Luau number
  - `:toString()` → Convert to rational string
  - `__tostring` → Metamethod of `:toString()`

- **Utilities**
  - `:abs()` - Returns the absolute value of the rational.
  - `:neg()` - Returns the negated value of the rational (unary minus, `__unm`)
  - `:inv()` - Returns the inversed (reciprocal) value of the rational

## ✨ Potentially upcoming features for `hello_mpq`
- Approximated float-number representation.
- Mixed fraction representation.
- Native `floor` and `ceil` functions.
- Exponent arithmetic `^`.
- Square root and n-root arithmetic.

## Uses and Demonstrations of `hello_mpz`

### Construction and Representation

```lua
local hello_mpq = require(path.to.hello_mpq)

-- this is going to be timed, construction and normalization is slower here
local t = os.clock()

local a = hello_mpq.fromString("1", "3") -- takes only string numbers only
local b = hello_mpq.fromNumber(8, 5) -- takes native lua numbers only
local c = hello_mpq.new("48", 123) -- takes both, can be mixed

-- simplification
local d = hello_mpq.fromString("12345", "58743")
local e = hello_mpq("4444", "8888") -- same as .new, callable shortcut
local f = hello_mpq("4444", "8889") -- can't be simplified

print("a:", a)
print("b:", b)
print("c:", c)
print("d:", d) -- 4115/19581
print("e:", e) -- 1/2
print("f:", f)

-- big int
local big_a = hello_mpq.new("4321894321890432184343818904328904324321", "543254325435243543254322")
local big_b = hello_mpq.new("4721890437218932189489042178472894120004242", "77747327432757894785493025784932")

print("big_a:", big_a)
print("big_b:", big_b)

-- denominator always positive
local g = hello_mpq.new("21341234", "-43214321")
local h = hello_mpq.new("6776547654", "-3214322")
local i = hello_mpq.new("-1234213432132134", "-21342143214124321432")

print("g:", g)
print("h:", h)
print("i:", i)

print("took ".. tostring(os.clock() - t) .. " seconds") -- should take less than 0.01 seconds on modern hardware
```

### Arithmetic

```lua
local hello_mpq = require(path.to.hello_mpq)

-- Basic operations
local a = hello_mpq.new(1, 3)   -- 1/3
local b = hello_mpq.new(1, 6)   -- 1/6

print("Addition:", a + b)        -- 1/2
print("Subtraction:", a - b)     -- 1/6
print("Multiplication:", a * b)  -- 1/18
print("Division:", a / b)        -- 2/1
print("Negation:", -a)           -- -1/3

-- Complex operations
local c = hello_mpq.new(2, 5)   -- 2/5
local d = hello_mpq.new(3, 7)   -- 3/7

print("Mixed:", (a + b) * (c - d))  -- Result auto-simplifies (-1/70)

-- Large number arithmetic
local big_1 = hello_mpq.new("123456789012345", "987654321098765")
local big_2 = hello_mpq.new("111111111111111", "222222222222222")

print("Big addition:", big_1 + big_2) -- 246913579824691/395061728439506
print("Big multiplication:", big_1 * big_2) -- 24691357802469/395061728439506
```

## Comparison Operations

```lua
local hello_mpq = require(path.to.hello_mpq)

local a = hello_mpq.new(1, 3)   -- 1/3
local b = hello_mpq.new(1, 2)   -- 1/2
local c = hello_mpq.new(2, 6)   -- 2/6 (equals 1/3)

print("a < b:", a < b)           -- true
print("a <= b:", a <= b)         -- true
print("a == c:", a == c)         -- true (auto-simplified)
print("a > b:", a > b)           -- false
print("a >= b:", a >= b)         -- false

-- Compare function (returns -1, 0, or 1)
print(hello_mpq.compare(a, b))   -- -1 (a < b)
print(hello_mpq.compare(a, c))   -- 0 (a == c)
print(hello_mpq.compare(b, a))   -- 1 (b > a)
```

## Utilities

```lua
local hello_mpq = require(path.to.hello_mpq)

local a = hello_mpq.new(-3, 4)  -- -3/4
local b = hello_mpq.new(2, 5)   -- 2/5

-- Absolute value
print("abs(a):", a:abs())        -- 3/4
print("abs(b):", b:abs())        -- 2/5

-- Negation
print("neg(a):", a:neg())        -- 3/4
print("neg(b):", b:neg())        -- -2/5

-- Inversion (reciprocal)
print("inv(a):", a:inv())        -- -4/3
print("inv(b):", b:inv())        -- 5/2

-- Chaining operations
local c = hello_mpq.new(5, 8)
print("Chained:", c:abs():inv():neg())  -- -8/5
```


## 🔨 Performance Benchmarks (tested on helloGMP 1.1.0)

All benchmarks were conducted in Roblox Studio with fixed seed (`123456`) and averaged over 3 iterations.  
Test sizes correspond to digit lengths of numerator and denominator:

- **Small:** 10‑digit numbers  
- **Medium:** 50‑digit numbers  
- **Large:** 100‑digit numbers  

### Constructors

| Operation        | Time (s) | µs/op |
|------------------|----------|-------|
| fromString       | 0.118386 | 59.193 |
| fromNumber       | 0.064119 | 32.060 |
| new / fromAny    | 0.060962 | 30.481 |

### Core Arithmetic Operations

#### **Small (10‑digit)**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| Addition  | 0.466694 | 233.347 |
| Subtract  | 0.446772 | 223.386 |
| Multiply  | 0.268668 | 134.334 |
| Divide    | 0.400683 | 200.341 |

#### **Medium (50‑digit)**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| Addition  | 3.330383 | 1665.192 |
| Subtract  | 3.266719 | 1633.359 |
| Multiply  | 1.878927 | 939.463 |
| Divide    | 1.905796 | 952.898 |

#### **Large (100‑digit)**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| Addition  | 8.780678 | 4390.339 |
| Subtract  | 9.588679 | 4794.340 |
| Multiply  | 5.020431 | 2510.216 |
| Divide    | 5.129610 | 2564.805 |

### Mixed‑Size Arithmetic

#### **Small + Medium**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| Addition  | 1.860884 | 930.442 |
| Subtract  | 1.906176 | 953.088 |
| Multiply  | 1.387132 | 693.566 |
| Divide    | 1.399157 | 699.578 |

#### **Small + Large**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| Addition  | 4.336058 | 2168.029 |
| Subtract  | 4.383858 | 2191.929 |
| Multiply  | 3.236797 | 1618.398 |
| Divide    | 3.071640 | 1535.820 |

#### **Medium + Large**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| Addition  | 6.266062 | 3133.031 |
| Subtract  | 6.216346 | 3108.173 |
| Multiply  | 4.239121 | 2119.561 |
| Divide    | 4.567661 | 2283.830 |

### Utility Operations

#### **Small**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| abs       | 0.003581 | 1.790 |
| neg       | 0.003434 | 1.717 |
| inv       | 0.149205 | 74.603 |
| toString  | 0.003493 | 1.747 |

#### **Medium**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| abs       | 0.003134 | 1.567 |
| neg       | 0.006137 | 3.068 |
| inv       | 1.068707 | 534.354 |
| toString  | 0.010050 | 5.025 |

#### **Large**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| abs       | 0.006630 | 3.315 |
| neg       | 0.006015 | 3.007 |
| inv       | 2.575326 | 1287.663 |
| toString  | 0.020145 | 10.072 |

### Comparison Operations

#### **Small**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| __eq      | 0.000517 | 0.258 |
| __lt      | 0.009273 | 4.636 |
| __le      | 0.007580 | 3.790 |
| compare   | 0.006550 | 3.275 |

#### **Medium**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| __eq      | 0.000866 | 0.433 |
| __lt      | 0.027164 | 13.582 |
| __le      | 0.021925 | 10.963 |
| compare   | 0.024239 | 12.120 |

#### **Large**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| __eq      | 0.000487 | 0.244 |
| __lt      | 0.035024 | 17.512 |
| __le      | 0.033829 | 16.915 |
| compare   | 0.035937 | 17.968 |

### Mixed‑Size Comparisons

#### **Small + Medium**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| __eq      | 0.000537 | 0.268 |
| __lt      | 0.010636 | 5.318 |
| __le      | 0.011114 | 5.557 |
| compare   | 0.012394 | 6.197 |

#### **Small + Large**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| __eq      | 0.000402 | 0.201 |
| __lt      | 0.018084 | 9.042 |
| __le      | 0.013973 | 6.987 |
| compare   | 0.014997 | 7.499 |

#### **Medium + Large**

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| __eq      | 0.000421 | 0.211 |
| __lt      | 0.024371 | 12.185 |
| __le      | 0.026808 | 13.404 |
| compare   | 0.024463 | 12.231 |

## 🔨 Time Complexity Benchmark

The following benchmark measures three core operations on extremely large rational numbers:

- **Cosntruction & LCD normalization**
- **LCD-based addition**
- **Cross-simplified multiplication**

Two test sizes are used:

- **500-digit numerator/denominator**
- **5000-digit numerator/denominator**

| Digits | Construction & GCD | LCD Addition | Cross‑Simplify Multiply | Total Time |
|--------|---------------------|--------------|--------------------------|-------------|
| **500**  | 0.0149s             | 0.0229s      | 0.0191s                  | 0.0569s     |
| **5000** | 0.9911s             | 1.6284s      | 1.2544s                  | 3.8740s     |
