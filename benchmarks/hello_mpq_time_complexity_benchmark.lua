local mpq = require(game.ReplicatedStorage.helloGMP.hello_mpq)

local function run_benchmark(digits)
	print(string.format("--- Benchmarking %d Digits ---", digits))

	-- 1. Setup Data
	local s1 = "9" .. string.rep("1", digits)
	local s2 = "7" .. string.rep("3", digits)

	-- 2. Construction & Normalization Benchmark
	local t0 = os.clock()
	local q1 = mpq.new(s1, s2)
	local q2 = mpq.new("1", "3")
	local t_construct = os.clock() - t0
	print(string.format("Construction & GCD:  %.4fs", t_construct))

	-- 3. Arithmetic Benchmark (LCD + Addition)
	local t1 = os.clock()
	local result = q1 + q2
	local t_add = os.clock() - t1
	print(string.format("LCD Addition:        %.4fs", t_add))

	-- 4. Multiplication (Cross-Simplification)
	local t2 = os.clock()
	local prod = q1 * q2
	local t_mul = os.clock() - t2
	print(string.format("Cross-Simp Multiply: %.4fs", t_mul))

	print(string.format("Total Time:          %.4fs\n", t_construct + t_add + t_mul))
end

run_benchmark(500)
run_benchmark(5000)

print("Benchmark Complete.")