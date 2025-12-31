-- hello_mpq, big rational module of the helloGMP library

local hello_mpq = {}
local base_settings = require(script.Parent.base_settings)
local hello_mpz = require(script.Parent.hello_mpz) -- hello_mpq relies on hello_mpz integers

-- sure
hello_mpq.__index = hello_mpq

-- NOTE: This module assumes hello_mpz implements value-based __eq, __lt, etc comparison metamethods

----------------------------------------------------
-- Caching
----------------------------------------------------

-- other caching functions
local setmetatable = setmetatable
local getmetatable = getmetatable

local type = type

local MPQ_MT = getmetatable(setmetatable({}, hello_mpq))

-- hello_mpz caching
local mpz_fromString = hello_mpz.fromString
local mpz_fromNumber = hello_mpz.fromNumber
local mpz_GCD = hello_mpz.GCD

----------------------------------------------------
-- hello_mpz Constants
----------------------------------------------------

-- hello_mpz does not expose the 'make()' function therefore initially constructing constants are slower
local ZERO = hello_mpz.fromString("0")
local ONE = hello_mpz.fromString("1")
local TWO = hello_mpz.fromString("2")

----------------------------------------------------
-- Constructor
----------------------------------------------------
-- create a new bigrational from two bigint limbs (little-endian table)
local function make(num, den)
	return setmetatable({
		num = num, -- hello_mpz number
		den = den -- hello_mpz number
	}, hello_mpq)
end

-- convert to hello_mpz if possible
local function to_mpq(x)
	local mt = getmetatable(x)
	if mt == hello_mpz then
		return x
	end

	local t = type(x)
	if t == "string" then
		return mpz_fromString(x)
	elseif t == "number" then
		return mpz_fromNumber(x)
	else
		error("Unsupported type for mpz conversion: " .. t)
	end
end

local function require_mpq(v, name)
	if getmetatable(v) ~= MPQ_MT then
		error(name .. " must be a hello_mpq instance. Use hello_mpq.new(num, den) to convert.", 3)
	end
end

-- canoncializes rationals
local function normalize(q)
	-- handle 0 denominator
	if q.den:isZero() then
		error("Denominator cannot be zero.")
	end

	-- if denominator < 0, flip both
	if q.den.sign < 0 then
		q.num = -q.num
		q.den = -q.den
	end

	-- zero numerator == zero
	if q.num:isZero() then
		q.den = ONE:clone()
		return q
	end
	
	if q.den == ONE then return q end -- Skip GCD if denominator is already 1
	
	-- GCD reduction
	local g = mpz_GCD(q.num, q.den)
	if g ~= ONE then
		-- simplification
		q.num = q.num // g
		q.den = q.den // g
	end

	return q
end

-- Constructs a hello_mpq rational from numerator and denominator strings.
function hello_mpq.fromString(num, den)
	local n = hello_mpz.fromString(num)
	local d = hello_mpz.fromString(den)
	return normalize(make(n, d))
end

-- Constructs a hello_mpq rational from numerator and denominator native lua numbers
function hello_mpq.fromNumber(num, den)
	local n = hello_mpz.fromNumber(num)
	local d = hello_mpz.fromNumber(den)
	return normalize(make(n, d))
end

-- Converts the hello_mpq rational into a string.
-- Also can be done when printed or used under tostring function.
function hello_mpq:toString()

	-- print "0" if numerator == 0
	if self.num:isZero() then
		return "0"
	end

	-- if Denominator == 1 then just print out the numerator
	if self.den == ONE then
		return tostring(self.num)
	end

	-- general representation
	return tostring(self.num) .. "/" .. tostring(self.den)
end

-- Converts the hello_mpq rational into a string.
hello_mpq.__tostring = hello_mpq.toString

-- Converts the hello_mpq rational into a native lua number.
-- warning: converting it into a native lua number can guarantee loss of precision when it is a recurring decimal.
function hello_mpq:toNumber()
	return tonumber(self.num:toNumber() / self.den:toNumber())
end

-- Converts the hello_mpq rational into a mixed fraction.
-- Returns two values: intPart and fracPart
function hello_mpq:toMixedRational()
	local intPart, remainder = hello_mpz.divmod(self.num, self.den)
	local absDen = self.den:abs()
	
	-- Ensure the proper fraction numerator is positive
	if remainder:isNegative() then
		remainder = remainder + absDen
		intPart = intPart - 1
	end

	local fracPart = hello_mpq.new(remainder, absDen)
	return intPart, fracPart
end

----------------------------------------------------
-- Addition + Subtraction + Multiplication + Division
----------------------------------------------------

-- Adds two hello_mpq rationals.
function hello_mpq.__add(q1, q2)
	
	require_mpq(q1, "Left operand")
	require_mpq(q2, "Right operand")
	
	-- Same denominator shortcut (often occurs	 in loops or series)
	if q1.den == q2.den then
		return normalize(make(q1.num + q2.num, q1.den:clone()))
	end

	local n1, d1 = q1.num, q1.den
	local n2, d2 = q2.num, q2.den

	local g = mpz_GCD(d1, d2)

	if g == ONE then
		-- Standard cross-multiplication if no common factors
		return normalize(make((n1 * d2) + (n2 * d1), d1 * d2))
	end

	-- L = d1/g * d2  (This is the LCM)
	local d1_reduced = d1 // g
	local d2_reduced = d2 // g

	local final_nom = (n1 * d2_reduced) + (n2 * d1_reduced)
	local final_den = d1_reduced * d2 -- Denominator is now the LCD

	-- run a quick normalize because final_nom and g might share factors
	return normalize(make(final_nom, final_den))
end

-- Subtracts two hello_mpq rationals.
function hello_mpq.__sub(q1, q2)
	
	require_mpq(q1, "Left operand")
	require_mpq(q2, "Right operand")
	
	local n1, d1 = q1.num, q1.den
	local n2, d2 = q2.num, q2.den

	local g = mpz_GCD(d1, d2)

	if g == ONE then
		return normalize(make((n1 * d2) - (n2 * d1), d1 * d2))
	end

	local d1_reduced = d1 // g
	local d2_reduced = d2 // g

	local final_nom = (n1 * d2_reduced) - (n2 * d1_reduced)
	local final_den = d1_reduced * d2

	return normalize(make(final_nom, final_den))
end

-- Multiplies two hello_mpq rationals.
-- Uses cross-simplification.
function hello_mpq.__mul(q1, q2)
	
	require_mpq(q1, "Left operand")
	require_mpq(q2, "Right operand")
	
	local n1, d1 = q1.num, q1.den
	local n2, d2 = q2.num, q2.den

	-- simplify n1 with d2 and n2 with d1
	local g1 = mpz_GCD(n1, d2)
	local g2 = mpz_GCD(n2, d1)

	-- we use floor division // for exact results
	local final_nom = (n1 // g1) * (n2 // g2)
	local final_den = (d1 // g2) * (d2 // g1)

	-- no need for a full normalize() here because they are already reduced,
	-- but we use make() to ensure the object structure is correct.
	return make(final_nom, final_den)
end

-- Divides two hello_mpq rationals.
-- Uses cross-simplification.
function hello_mpq.__div(q1, q2)
	
	require_mpq(q1, "Left operand")
	require_mpq(q2, "Right operand")
	
	local n1, d1 = q1.num, q1.den
	local n2, d2 = q2.num, q2.den

	if n2:isZero() then error("Division by zero") end

	-- simplify n1 with n2 and d1 with d2
	local g1 = mpz_GCD(n1, n2)
	local g2 = mpz_GCD(d1, d2)

	local final_nom = (n1 // g1) * (d2 // g2)
	local final_den = (d1 // g2) * (n2 // g1)

	-- ensure denominator is positive after cross-division
	if final_den.sign < 0 then
		final_nom = -final_nom
		final_den = -final_den
	end

	return make(final_nom, final_den)
end

----------------------------------------------------
-- Utilities
----------------------------------------------------

-- Clones the hello_mpq rational to prevent mutation.
function hello_mpq:clone()
	return make(self.num:clone(), self.den:clone())
end

-- Returns the absolute value of the hello_mpq rational.
function hello_mpq:abs()
	return make(self.num:abs(), self.den:clone())
end

-- Returns the negated value of the hello_mpq rational.
function hello_mpq:neg()
	return make(-self.num, self.den:clone())
end

-- Returns the negated value of the hello_mpq rational.
function hello_mpq.__unm(q)
	return q:neg()
end

-- Returns the reciprocal of the hello_mpq rational (inverse).
function hello_mpq:inv()
	if self.num:isZero() then error("Division by zero (reciprocal of 0)") end
	-- We use normalize just in case the numerator was negative
	return normalize(make(self.den:clone(), self.num:clone()))
end

----------------------------------------------------
-- Compare
----------------------------------------------------

-- Determines if the hello_mpq rational is equal to another hello_mpq rational.
function hello_mpq.__eq(q1, q2)
	-- Assumes both are already normalized
	return q1.num == q2.num and q1.den == q2.den
end

-- Determines if the hello_mpq rational is less than another hello_mpq rational.
function hello_mpq.__lt(q1, q2)

	-- reference check first
	if q1.den == q2.den then
		return q1.num < q2.num
	end

	-- Cross-multiply to avoid floating point issues
	-- n1/d1 < n2/d2  =>  n1*d2 < n2*d1
	return (q1.num * q2.den) < (q2.num * q1.den)
end

-- Determines if the hello_mpq rational is less than or equal to another hello_mpq rational.
function hello_mpq.__le(q1, q2)
	-- n1*d2 <= n2*d1
	return (q1.num * q2.den) <= (q2.num * q1.den)
end

-- Returns -1 if q1 < q2, 0 if q1 == q2, 1 if q1 > q2
function hello_mpq.compare(q1, q2)
	-- Optimization: Reference equality
	if q1 == q2 then return 0 end

	-- Optimization: Same denominator check
	if q1.den == q2.den then
		if q1.num == q2.num then return 0 end
		return q1.num < q2.num and -1 or 1
	end

	-- General case: Cross-multiply
	local left = q1.num * q2.den
	local right = q2.num * q1.den

	if left == right then return 0 end
	return left < right and -1 or 1
end

----------------------------------------------------
-- Polishing & Other
----------------------------------------------------
-- from any function handler
local function fromAny(num, den)
	if den == nil then
		den = 1
	end

	local n = to_mpq(num)
	local d = to_mpq(den)

	return normalize(make(n, d))
end

-- Constructs a hello_mpq rational from numerator and denominator.
hello_mpq.new = fromAny

-- make the table a callable function
setmetatable(hello_mpq, {
	__call = function(_, num, den)
		return fromAny(num, den)
	end,
})

return hello_mpq