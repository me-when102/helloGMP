# HelloGMP: `hello_mpf`
The `hello_mpf` module is one of the main libraries of the **helloGMP** library which provides big approximate floating-point arithmetic. Unlike the two libraries, `hello_mpf` is based on the Multiple-Precision Floating-Point Reliable (MPFR) library.

> NOTE: `hello_mpf` is still affected by floating-point drifts, if you want exact values please use `hello_mpq` instead.

## ✨ Features of `hello_mpf`

- **Arithmetic operators**: Overloaded `+`, `=`, `*`, `/`, and unary `-`
- **Comparison operators**: Overloaded `>`, `>=`, `==`, `<=`, `<`
  (`>` and `>=` are inherited from `__lt` and `__le`)

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
-- Examples coming soon.
```

### Arithmetic

```lua
-- Examples coming soon.
```

### Comparison Operations

```lua
-- Examples coming soon.
```

### Utilities

```lua
-- Examples coming soon.
```

## 🔨 Performance Benchmarks (tested on helloGMP 1.3.0)
Benchmarks for `hello_mpf` is not available at the moment. Perhaps later?