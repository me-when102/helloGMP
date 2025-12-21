# HelloGMP: `hello_mpq`
The `hello_mpq` module is one of the main libraries of the **helloGMP** library which provides big and exact rational number arithmetic. How `hello_mpq` works depends on the foundations of the `hello_mpz` module's arithmetic foundations, therefore its performance is significantly slower in asymptotic complexity.

## ✨ Features of `hello_mpq`
- **Arithmetic operators**: Overloaded `+`, `-`, `*`, `/`, and unary `-`
- **Comparison operators**: Overloaded `>`, `>=`, `==`, `<=`, `<`
  (`>` and `>=` are inherited from `__lt` and `__le`)
- `.compare(a, b)` function to return `1`, `0`, or `-1` results.

- **Core Constructors & Conversions**
  - `hello_mpz.new(nom, den)` → nom = nominator and den = denominator, can be `hello_mpz` number, native Luau number, or string.
  - `hello_mpz.fromString(nom, den)` → must be string number
  - `hello_mpz.fromNumber(nom, den)` → must be native Luau number
  - `:toString()` → Convert to rational string
  - `__tostring` → Metamethod of `:toString()`

- **Utilities**
  - `:abs()` - Returns the absolute value of the integer.
  - `:neg()` - Returns the negated value (unary minus, `__unm`)

## Uses and Demonstrations of `hello_mpz`

wip.

## 🔨 Performance Benchmarks

wip