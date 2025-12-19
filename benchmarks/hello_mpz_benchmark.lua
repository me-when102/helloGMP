---------------------------------------------------------------------
-- helloGMP Comprehensive Feature Benchmark
-- Tests all hello_mpz operations and features
---------------------------------------------------------------------

math.randomseed(123456)

local hello_mpz = require(game.ReplicatedStorage.helloGMP.hello_mpz)

local config = {
	iterations = 3,  -- average over runs
	num_samples = 100,  -- sample size for most ops

	-- Test data sizes
	small_digits = 10,
	medium_digits = 50,
	large_digits = 100,
	huge_digits = 500,
}

---------------------------------------------------------------------
-- Utility: generate random digit strings
---------------------------------------------------------------------
local function random_digits(n)
	local t = {}
	t[1] = tostring(math.random(1, 9))  -- no leading zero
	for i = 2, n do
		t[i] = tostring(math.random(0, 9))
	end
	return table.concat(t)
end

---------------------------------------------------------------------
-- Generate test data
---------------------------------------------------------------------
local test_data = {
	small = {},
	medium = {},
	large = {},
	huge = {},
}

print("Generating test data...")
for i = 1, config.num_samples do
	test_data.small[i] = hello_mpz.new(random_digits(config.small_digits))
	test_data.medium[i] = hello_mpz.new(random_digits(config.medium_digits))
	test_data.large[i] = hello_mpz.new(random_digits(config.large_digits))
end

-- Fewer huge samples (very expensive)
for i = 1, 10 do
	test_data.huge[i] = hello_mpz.new(random_digits(config.huge_digits))
end

---------------------------------------------------------------------
-- Timing helper
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
-- Results storage
---------------------------------------------------------------------
local results = {}

local function record(category, operation, size, time)
	if not results[category] then
		results[category] = {}
	end
	if not results[category][operation] then
		results[category][operation] = {}
	end
	results[category][operation][size] = time
end

---------------------------------------------------------------------
-- Benchmark: Basic Arithmetic
---------------------------------------------------------------------
print("\n=== Benchmarking Basic Arithmetic ===")

local sizes = {"small", "medium", "large"}

for _, size in ipairs(sizes) do
	local data = test_data[size]
	print("Testing " .. size .. " numbers...")

	-- Addition
	local t = time_avg(function()
		for i = 1, #data - 1 do
			local _ = data[i] + data[i + 1]
		end
	end, config.iterations)
	record("Arithmetic", "Addition", size, t)

	-- Subtraction
	t = time_avg(function()
		for i = 1, #data - 1 do
			local _ = data[i] - data[i + 1]
		end
	end, config.iterations)
	record("Arithmetic", "Subtraction", size, t)

	-- Multiplication
	t = time_avg(function()
		for i = 1, math.min(20, #data - 1) do  -- limited for large
			local _ = data[i] * data[i + 1]
		end
	end, config.iterations)
	record("Arithmetic", "Multiplication", size, t)

	-- Division
	t = time_avg(function()
		for i = 1, math.min(20, #data - 1) do
			local _ = data[i + 1] / data[i]  -- avoid div by smaller
		end
	end, config.iterations)
	record("Arithmetic", "Division", size, t)

	-- Modulo
	t = time_avg(function()
		for i = 1, math.min(20, #data - 1) do
			local _ = data[i + 1] % data[i]
		end
	end, config.iterations)
	record("Arithmetic", "Modulo", size, t)

	-- Power (small exponents only)
	local small_exp = hello_mpz.new("5")
	t = time_avg(function()
		for i = 1, math.min(10, #data) do
			local _ = data[i] ^ small_exp
		end
	end, config.iterations)
	record("Arithmetic", "Power", size, t)
end

---------------------------------------------------------------------
-- Benchmark: Comparisons
---------------------------------------------------------------------
print("=== Benchmarking Comparisons ===")

for _, size in ipairs(sizes) do
	local data = test_data[size]
	print("Testing " .. size .. " comparisons...")

	local t = time_avg(function()
		for i = 1, #data - 1 do
			local _ = data[i] == data[i + 1]
			local _ = data[i] < data[i + 1]
			local _ = data[i] <= data[i + 1]
		end
	end, config.iterations)
	record("Comparison", "Equality & Ordering", size, t)
end

---------------------------------------------------------------------
-- Benchmark: Conversions
---------------------------------------------------------------------
print("=== Benchmarking Conversions ===")

for _, size in ipairs(sizes) do
	local data = test_data[size]
	print("Testing " .. size .. " conversions...")

	-- toString
	local t = time_avg(function()
		for i = 1, #data do
			local _ = data[i]:toString()
		end
	end, config.iterations)
	record("Conversion", "toString", size, t)

	-- toScientific
	t = time_avg(function()
		for i = 1, #data do
			local _ = data[i]:toScientific(15)
		end
	end, config.iterations)
	record("Conversion", "toScientific", size, t)

	-- toHex
	t = time_avg(function()
		for i = 1, math.min(20, #data) do  -- hex is expensive for large
			local _ = data[i]:toHex()
		end
	end, config.iterations)
	record("Conversion", "toHex", size, t)

	-- toBinary
	t = time_avg(function()
		for i = 1, math.min(10, #data) do  -- very expensive
			local _ = data[i]:toBinary()
		end
	end, config.iterations)
	record("Conversion", "toBinary", size, t)
end

---------------------------------------------------------------------
-- Benchmark: Roots
---------------------------------------------------------------------
print("=== Benchmarking Roots ===")

for _, size in ipairs(sizes) do
	local data = test_data[size]
	print("Testing " .. size .. " roots...")

	-- Square root
	local t = time_avg(function()
		for i = 1, math.min(20, #data) do
			local _ = data[i]:isqrt()
		end
	end, config.iterations)
	record("Roots", "Square Root", size, t)

	-- Cube root
	t = time_avg(function()
		for i = 1, math.min(10, #data) do
			local _ = data[i]:iroot("3")
		end
	end, config.iterations)
	record("Roots", "Cube Root", size, t)
end

---------------------------------------------------------------------
-- Benchmark: Number Theory
---------------------------------------------------------------------
print("=== Benchmarking Number Theory ===")

for _, size in ipairs({"small", "medium"}) do  -- GCD expensive on large
	local data = test_data[size]
	print("Testing " .. size .. " number theory...")

	-- GCD
	local t = time_avg(function()
		for i = 1, math.min(20, #data - 1) do
			local _ = hello_mpz.GCD(data[i], data[i + 1])
		end
	end, config.iterations)
	record("Number Theory", "GCD", size, t)

	-- LCM
	t = time_avg(function()
		for i = 1, math.min(20, #data - 1) do
			local _ = hello_mpz.LCM(data[i], data[i + 1])
		end
	end, config.iterations)
	record("Number Theory", "LCM", size, t)
end

---------------------------------------------------------------------
-- Benchmark: Factorials
---------------------------------------------------------------------
print("=== Benchmarking Factorials ===")

local factorial_inputs = {
	hello_mpz.new("50"),
	hello_mpz.new("100"),
	hello_mpz.new("200"),
}

for i, n in ipairs(factorial_inputs) do
	local t = time_avg(function()
		local _ = n:factorial()
	end, 1)  -- single run, expensive
	record("Factorial", "factorial", tostring(n), t)

	t = time_avg(function()
		local _ = n:doubleFactorial()
	end, 1)
	record("Factorial", "doubleFactorial", tostring(n), t)
end

---------------------------------------------------------------------
-- Benchmark: Combinatorics
---------------------------------------------------------------------
print("=== Benchmarking Combinatorics ===")

local comb_tests = {
	{n = "100", r = "10"},
	{n = "1000", r = "50"},
	{n = "5000", r = "100"},
}

for _, test in ipairs(comb_tests) do
	local n = hello_mpz.new(test.n)
	local r = hello_mpz.new(test.r)

	local t = time_avg(function()
		local _ = hello_mpz.comb(n, r)
	end, 1)
	record("Combinatorics", "comb", test.n .. "C" .. test.r, t)

	t = time_avg(function()
		local _ = hello_mpz.perm(n, r)
	end, 1)
	record("Combinatorics", "perm", test.n .. "P" .. test.r, t)
end

---------------------------------------------------------------------
-- Benchmark: Random Generation
---------------------------------------------------------------------
print("=== Benchmarking Random ===")

for _, size in ipairs({"small", "medium", "large"}) do
	local max = test_data[size][1]

	local t = time_avg(function()
		for i = 1, 20 do
			local _ = hello_mpz.random(hello_mpz.new("0"), max)
		end
	end, config.iterations)
	record("Random", "random", size, t)
end

---------------------------------------------------------------------
-- Benchmark: Iterators
---------------------------------------------------------------------
print("=== Benchmarking Iterators ===")

local iter_tests = {
	{start = "1", stop = "1000", name = "1K range"},
	{start = "1", stop = "10000", name = "10K range"},
}

for _, test in ipairs(iter_tests) do
	local start = hello_mpz.new(test.start)
	local stop = hello_mpz.new(test.stop)

	local t = time_avg(function()
		local count = 0
		for i in start:to(stop) do
			count = count + 1
		end
	end, 1)
	record("Iterator", "range iteration", test.name, t)
end

---------------------------------------------------------------------
-- Print Results
---------------------------------------------------------------------
print(string.rep("=", 70))
print("helloGMP Comprehensive Benchmark Results")
print(string.rep("=", 70))

for category, ops in pairs(results) do
	print("### " .. category)
	for op, sizes in pairs(ops) do
		print("  " .. op .. ":")
		for size, time in pairs(sizes) do
			print(string.format("    %-20s: %.6f seconds", size, time))
		end
	end
end

print(string.rep("=", 70))
print("Benchmark complete!")
print(string.rep("=", 70))