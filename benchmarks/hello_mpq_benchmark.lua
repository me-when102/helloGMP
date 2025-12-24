-- bench_mpq.lua
-- Benchmark suite for hello_mpq with small/medium/large/mixed test sizes.

local hello_mpq = require(game.ReplicatedStorage.helloGMP.hello_mpq)
local hello_mpz = require(game.ReplicatedStorage.helloGMP.hello_mpz)
local base_settings = require(game.ReplicatedStorage.helloGMP.base_settings)

math.randomseed(123456)

local timeit = function(fn, iters)
	local start = os.clock()
	for _ = 1, iters do fn() end
	return (os.clock() - start)
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

-- hello_mpz already provides a random(min, max)
local function rand_mpz_digits(digits)
	local min = hello_mpz.fromString("1" .. string.rep("0", digits - 1))
	local max = hello_mpz.fromString(string.rep("9", digits))
	return hello_mpz.random(min, max)
end

local function rand_mpq_digits(digits)
	local nom = rand_mpz_digits(digits)
	local den
	repeat
		den = rand_mpz_digits(digits)
	until not den:isZero()
	return hello_mpq.new(nom, den)
end

local function bench(name, iters, fn)
	local t = timeit(fn, iters)
	print(string.format("%-30s %8d iters   %0.6f sec   (%0.3f �s/op)",
		name, iters, t, (t / iters) * 1e6))
end

------------------------------------------------------------
-- Benchmark Parameters
------------------------------------------------------------

local ITERS = 2000

local SMALL  = 10   -- 10-digit numbers
local MEDIUM = 50   -- 50-digit numbers
local LARGE  = 100  -- 100-digit numbers

print("====================================================")
print(" hello_mpq Benchmark Suite")
print(" Digits: small(10), medium(50), large(100)")
print(" Iterations:", ITERS)
print("====================================================")

------------------------------------------------------------
-- Pre-generate test operands
------------------------------------------------------------

local S1, S2 = rand_mpq_digits(SMALL),  rand_mpq_digits(SMALL)
local M1, M2 = rand_mpq_digits(MEDIUM), rand_mpq_digits(MEDIUM)
local L1, L2 = rand_mpq_digits(LARGE),  rand_mpq_digits(LARGE)

-- Mixed-size pairs
local SM = { S1, M1 }
local SL = { S1, L1 }
local ML = { M1, L1 }

------------------------------------------------------------
-- Constructors
------------------------------------------------------------

print("\n-- Constructors --")
bench("fromString()", ITERS, function()
	hello_mpq.fromString("123456789", "987654321")
end)
task.wait()
bench("fromNumber()", ITERS, function()
	hello_mpq.fromNumber(12345, 6789)
end)
task.wait()
bench("new() / fromAny()", ITERS, function()
	hello_mpq.new("12345", "6789")
end)
task.wait()
------------------------------------------------------------
-- Arithmetic
------------------------------------------------------------

local function arith_section(label, A, B)
	print("\n-- Arithmetic (" .. label .. ") --")
	bench("__add()", ITERS, function() local _ = A + B end)
	task.wait()
	bench("__sub()", ITERS, function() local _ = A - B end)
	task.wait()
	bench("__mul()", ITERS, function() local _ = A * B end)
	task.wait()
	bench("__div()", ITERS, function() local _ = A / B end)
	task.wait()
end

arith_section("Small",  S1, S2)
task.wait()
arith_section("Medium", M1, M2)
task.wait()
arith_section("Large",  L1, L2)
task.wait()
arith_section("Mixed S+M", SM[1], SM[2])
task.wait()
arith_section("Mixed S+L", SL[1], SL[2])
task.wait()
arith_section("Mixed M+L", ML[1], ML[2])
task.wait()

------------------------------------------------------------
-- Utilities
------------------------------------------------------------

local function util_section(label, A)
	print("\n-- Utilities (" .. label .. ") --")
	bench("abs()", ITERS, function() local _ = A:abs() end)
	bench("neg()", ITERS, function() local _ = A:neg() end)
	bench("inv()", ITERS, function() local _ = A:inv() end)
	bench("toString()", ITERS, function() local _ = A:toString() end)
	bench("toNumber()", ITERS, function() local _ = A:toNumber() end)
	bench("toMixedRational()", ITERS, function() local _, _ = A:toMixedRational() end)
end

util_section("Small",  S1)
task.wait()
util_section("Medium", M1)
task.wait()
util_section("Large",  L1)
task.wait()

------------------------------------------------------------
-- Comparisons
------------------------------------------------------------

local function cmp_section(label, A, B)
	print("\n-- Comparisons (" .. label .. ") --")
	bench("__eq()", ITERS, function() local _ = (A == B) end)
	bench("__lt()", ITERS, function() local _ = (A < B) end)
	bench("__le()", ITERS, function() local _ = (A <= B) end)
	bench("compare()", ITERS, function() local _ = hello_mpq.compare(A, B) end)
end

cmp_section("Small",  S1, S2)
task.wait()
cmp_section("Medium", M1, M2)
task.wait()
cmp_section("Large",  L1, L2)
task.wait()

cmp_section("Mixed S+M", SM[1], SM[2])
task.wait()
cmp_section("Mixed S+L", SL[1], SL[2])
task.wait()
cmp_section("Mixed M+L", ML[1], ML[2])
task.wait()

print("\n====================================================")
print(" Benchmark Complete")
print("====================================================")