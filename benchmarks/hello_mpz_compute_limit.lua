local HGMP = require(game.ReplicatedStorage.helloGMP.hello_mpz)

local two = HGMP.new("2")

-- Precompute mpz values for 1..20 to avoid repeated string parsing
local indices = {}
for i = 1, 20 do
	indices[i] = HGMP.new(i)
end

for i = 1, 20 do
	print("x =", i)

	local start = os.clock()

	-- Compute 2^(2^i) explicitly to avoid precedence ambiguity
	local exponent = two ^ indices[i]      -- 2^i
	local value = two ^ exponent           -- 2^(2^i)

	local elapsed = os.clock() - start

	-- Presentations
	local sci = value:toScientific()
	local sciHalf = (value / two):toScientific()

	print("  2^(2^x)      =", sci)
	print("  (2^(2^x))/2  =", sciHalf)
	print(string.format("  took %.6f seconds", elapsed))

	-- If we exceed ~3 seconds, we know x=20 will timeout
	if elapsed > 3 then
		print("  computation too large, stopping early")
		break
	end

	task.wait(1)
end