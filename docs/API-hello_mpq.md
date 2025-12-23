# HelloGMP: `hello_mpq`
The `hello_mpq` module is one of the main libraries of the **helloGMP** library which provides big and exact rational number arithmetic. How `hello_mpq` works depends on the foundations of the `hello_mpz` module's arithmetic foundations, therefore its performance is significantly slower in asymptotic complexity.

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
  - `:toString()` → Convert rational to string
  - `__tostring` → Metamethod of `:toString()`
  - `:toNumber()` → Convert rational to approximate native lua number. Can lose precision.

- **Utilities**
  - `:abs()` - Returns the absolute value of the rational.
  - `:neg()` - Returns the negated value of the rational (unary minus, `__unm`)
  - `:inv()` - Returns the inversed (reciprocal) value of the rational

## ✨ Potentially upcoming features for `hello_mpq`
- Approximated float-number representation.
- Mixed fraction representation.
- Native `floor` and `ceil` functions.
- Exponent arithmetic `^`.
- Square root and n-root arithmetic (may be extremely difficult).

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

-- to number
print("a (to number):", a:toNumber())
print("b (to number):", b:toNumber())
print("c (to number):", c:toNumber())
print("d (to number):", d:toNumber())
print("e (to number):", e:toNumber())
print("f (to number):", f:toNumber())

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

All benchmarks were conducted in Roblox Studio with fixed seed (`123456`) and 2000 iterations.  
Test sizes correspond to digit lengths of numerator and denominator:

- **Small:** 10‑digit numbers  
- **Medium:** 50‑digit numbers  
- **Large:** 100‑digit numbers  

### Constructors

| Operation        | Time (s) | µs/op |
|------------------|----------|-------|
| fromString       | 0.087607 | 43.803 |
| fromNumber       | 0.040605 | 20.302 |
| new / fromAny    | 0.038033 | 19.017 |

### Core Arithmetic (Small)

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| Addition  | 0.278119 | 139.059 |
| Subtract  | 0.294282 | 147.141 |
| Multiply  | 0.150999 | 75.499 |
| Divide    | 0.242742 | 121.371 |

### Core Arithmetic (Medium)

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| Addition  | 1.594309 | 797.154 |
| Subtract  | 1.576426 | 788.213 |
| Multiply  | 0.917311 | 458.656 |
| Divide    | 0.946007 | 473.003 |

### Core Arithmetic (Large)

| Operation | Time (s) | µs/op |
|-----------|----------|-------|
| Addition  | 4.110393 | 2055.196 |
| Subtract  | 4.260924 | 2130.462 |
| Multiply  | 2.371908 | 1185.954 |
| Divide    | 2.270338 | 1135.169 |

### Mixed-Size Arithmetic

| Mix        | Add (s)  | Sub (s)  | Mul (s)  | Div (s)  |
|------------|----------|----------|----------|----------|
| Small+Medium | 1.860884 | 1.906176 | 1.387132 | 1.399157 |
| Small+Large  | 4.336058 | 4.383858 | 3.236797 | 3.071640 |
| Medium+Large | 6.266062 | 6.216346 | 4.239121 | 4.567661 |

### Utility Operations

| Size   | abs (s) | neg (s) | inv (s) | toString (s) | toNumber (s) |
|--------|---------|---------|---------|--------------|--------------|
| Small  | 0.002299 | 0.002365 | 0.073428 | 0.002980 | 0.003051 |
| Medium | 0.002814 | 0.002849 | 0.504785 | 0.018566 | 0.019279 |
| Large  | 0.003830 | 0.003905 | 1.082658 | 0.014894 | 0.016878 |

### Comparison Operations

| Size   | __eq (s) | __lt (s) | __le (s) | compare (s) |
|--------|----------|----------|----------|-------------|
| Small  | 0.000517 | 0.009273 | 0.007580 | 0.006550 |
| Medium | 0.000866 | 0.027164 | 0.021925 | 0.024239 |
| Large  | 0.000487 | 0.035024 | 0.033829 | 0.035937 |
| Small+Medium | 0.000537 | 0.010636 | 0.011114 | 0.012394 |
| Small+Large  | 0.000402 | 0.018084 | 0.013973 | 0.014997 |
| Medium+Large | 0.000421 | 0.024371 | 0.026808 | 0.024463 |

## 🔨 Time Complexity Benchmark

The following benchmark measures three core operations on extremely large rational numbers:

- **Cosntruction & LCD normalization**
- **LCD-based addition**
- **Cross-simplified multiplication**

Two test sizes are used:

- **500-digit numerator/denominator**
- **5000-digit numerator/denominator**

| Digits | Construction & GCD | LCD Addition | Cross‑Simplify Multiply | Total Time |
|--------|------------------|--------------|------------------------|------------|
| **500**  | 0.0066s          | 0.0095s      | 0.0074s                | 0.0234s    |
| **5000** | 0.4161s          | 0.5771s      | 0.4275s                | 1.4208s    |