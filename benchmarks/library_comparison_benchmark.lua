---------------------------------------------------------------------
-- Neutral Big-Integer Benchmark Harness (Roblox-Safe, strict-safe, scaled)
-- Plug in any library that implements: new, +, -, *, /, %, ^, tostring
---------------------------------------------------------------------

math.randomseed(123456)

local config = {
	num_small = 200,
	num_large = 200,
	small_digits = 5,
	large_digits = 20,
	pow_exponents = 5,
	iterations = 3, -- average over runs to smooth GC noise

	-- Workload scaling per operation (fraction of pair space)
	mul_scale = 0.2,   -- 20% of pairs for mul
	div_scale = 0.2,   -- 20% of pairs for div
	mod_scale = 0.2,   -- 20% of pairs for mod
	pow_scale = 0.05,  -- 5% of pairs for pow (very expensive)
}

---------------------------------------------------------------------
-- Utility: generate raw digit strings ONCE (shared across libraries)
---------------------------------------------------------------------
local function random_digits_string(n)
	local t = {}
	for i = 1, n do
		t[i] = tostring(math.random(0, 9))
	end
	if n > 1 and t[1] == "0" then
		t[1] = tostring(math.random(1, 9))
	end
	return table.concat(t)
end

local raw = {
	small = {},
	large = {},
	pow_exp = {},
}

for i = 1, config.num_small do
	raw.small[i] = random_digits_string(math.random(1, config.small_digits))
end
for i = 1, config.num_large do
	raw.large[i] = random_digits_string(math.random(1, config.large_digits))
end
for i = 1, config.pow_exponents do
	raw.pow_exp[i] = random_digits_string(1)
end

---------------------------------------------------------------------
-- Library registry
---------------------------------------------------------------------
local hello_mpz = require(game.ReplicatedStorage.helloGMP.hello_mpz)
local APInt = require(game.ReplicatedStorage.APInt)

local libs = {
	APInt = {
		new = APInt.new,
		is_zero = function(x) return tostring(x) == "0" end,
		one = function() return APInt.new("1") end,
	},

	hello_mpz = {
		new = hello_mpz.new,
		is_zero = function(x) return x:isZero() end,
		one = function() return hello_mpz.new("1") end,
	},
}

---------------------------------------------------------------------
-- Helper: convert raw strings into library objects
---------------------------------------------------------------------
local function instantiate(lib, list)
	local out = {}
	for i = 1, #list do
		out[i] = lib.new(list[i])
	end
	return out
end

---------------------------------------------------------------------
-- Timing helper (averaged)
---------------------------------------------------------------------
local function time_avg(fn, iterations)
	local total = 0
	for _ = 1, iterations do
		local t0 = os.clock()
		fn()
		total += os.clock() - t0
	end
	return total / iterations
end

---------------------------------------------------------------------
-- Operation definitions (library-aware)
---------------------------------------------------------------------
local ops = {
	add   = function(a, b, lib) return a + b end,
	sub   = function(a, b, lib) return a - b end,
	mul   = function(a, b, lib) return a * b end,

	div   = function(a, b, lib)
		if lib.is_zero(b) then
			b = lib.one()
		end
		return a / b
	end,

	mod   = function(a, b, lib)
		if lib.is_zero(b) then
			b = lib.one()
		end
		return a % b
	end,

	pow   = function(a, b, lib) return a ^ b end,
	eq    = function(a, b, lib) return a == b end,
	lt    = function(a, b, lib) return a < b end,
	unm   = function(a, _, lib) return -a end,
	tostr = function(a, _, lib) return tostring(a) end,
}

---------------------------------------------------------------------
-- Benchmark runners
---------------------------------------------------------------------
local function run_op_full(op, A, B, lib)
	for i = 1, #A do
		for j = 1, #B do
			op(A[i], B[j], lib)
		end
	end
end

local function run_op_scaled(op, A, B, lib, scale)
	local limitA = math.max(1, math.floor(#A * scale))
	local limitB = math.max(1, math.floor(#B * scale))

	for i = 1, limitA do
		for j = 1, limitB do
			op(A[i], B[j], lib)
		end
	end
end

---------------------------------------------------------------------
-- Main benchmark
---------------------------------------------------------------------
local results = {}

for lib_name, lib in pairs(libs) do
	print("Preparing: " .. lib_name)

	local small = instantiate(lib, raw.small)
	local large = instantiate(lib, raw.large)
	local exp   = instantiate(lib, raw.pow_exp)

	results[lib_name] = {}

	for op_name, op in pairs(ops) do
		print("Running " .. op_name .. " for " .. lib_name)

		local t_small, t_large, t_mixed

		if op_name == "pow" then
			t_small = time_avg(function()
				run_op_scaled(op, small, exp, lib, config.pow_scale)
			end, config.iterations)

			t_large = time_avg(function()
				run_op_scaled(op, large, exp, lib, config.pow_scale)
			end, config.iterations)

			t_mixed = "N/A"

		elseif op_name == "unm" or op_name == "tostr" then
			t_small = time_avg(function()
				for i = 1, #small do op(small[i], nil, lib) end
			end, config.iterations)

			t_large = time_avg(function()
				for i = 1, #large do op(large[i], nil, lib) end
			end, config.iterations)

			t_mixed = "N/A"

		elseif op_name == "mul" then
			t_small = time_avg(function()
				run_op_scaled(op, small, small, lib, config.mul_scale)
			end, config.iterations)

			t_large = time_avg(function()
				run_op_scaled(op, large, large, lib, config.mul_scale)
			end, config.iterations)

			t_mixed = time_avg(function()
				run_op_scaled(op, small, large, lib, config.mul_scale)
			end, config.iterations)

		elseif op_name == "div" then
			t_small = time_avg(function()
				run_op_scaled(op, small, small, lib, config.div_scale)
			end, config.iterations)

			t_large = time_avg(function()
				run_op_scaled(op, large, large, lib, config.div_scale)
			end, config.iterations)

			t_mixed = time_avg(function()
				run_op_scaled(op, small, large, lib, config.div_scale)
			end, config.iterations)

		elseif op_name == "mod" then
			t_small = time_avg(function()
				run_op_scaled(op, small, small, lib, config.mod_scale)
			end, config.iterations)

			t_large = time_avg(function()
				run_op_scaled(op, large, large, lib, config.mod_scale)
			end, config.iterations)

			t_mixed = time_avg(function()
				run_op_scaled(op, small, large, lib, config.mod_scale)
			end, config.iterations)

		else
			-- add, sub, eq, lt and others use full workload
			t_small = time_avg(function()
				run_op_full(op, small, small, lib)
			end, config.iterations)

			t_large = time_avg(function()
				run_op_full(op, large, large, lib)
			end, config.iterations)

			t_mixed = time_avg(function()
				run_op_full(op, small, large, lib)
			end, config.iterations)
		end

		results[lib_name][op_name] = {
			small = t_small,
			large = t_large,
			mixed = t_mixed,
		}
	end
end

---------------------------------------------------------------------
-- Print results in a neutral table
---------------------------------------------------------------------
print("\n=== Benchmark Results ===\n")

for lib_name, ops_for_lib in pairs(results) do
	print(lib_name)
	for op_name, r in pairs(ops_for_lib) do
		print(string.format(
			"  %-6s | small: %.6f | large: %.6f | mixed: %s",
			op_name,
			r.small,
			r.large,
			tostring(r.mixed)
			))
	end
	print("")
end

---------------------------------------------------------------------
-- Constructor Benchmark
---------------------------------------------------------------------
print("\n=== Constructor Benchmark ===\n")

for lib_name, lib in pairs(libs) do
	print("Running constructor benchmark for " .. lib_name)

	local t_small = time_avg(function()
		for i = 1, #raw.small do
			lib.new(raw.small[i])
		end
	end, config.iterations)

	local t_large = time_avg(function()
		for i = 1, #raw.large do
			lib.new(raw.large[i])
		end
	end, config.iterations)

	print(string.format(
		"  %-10s | small: %.6f | large: %.6f",
		lib_name,
		t_small,
		t_large
		))
end