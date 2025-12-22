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
local hello_mpq = require(game.ReplicatedStorage.helloGMP.hello_mpq)

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
-- wip
```

## 🔨 Performance Benchmarks

wip