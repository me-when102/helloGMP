-- hello_mpf, a big float module of the helloGMP library.
-- this is just technically helloMPFR maybe

local hello_mpf = {}
local base_settings = require(script.Parent.base_settings)
local hello_mpz = require(script.Parent.hello_mpz)

-- sure
hello_mpf.__index = hello_mpf

----------------------------------------------------
-- hello_mpz Constants
----------------------------------------------------

-- hello_mpz does not expose the 'make()' function therefore initially constructing constants are slower
local ZERO = hello_mpz.fromString("0")
local ONE = hello_mpz.fromString("1")
local TWO = hello_mpz.fromString("2")
local FIVE = hello_mpz.fromString("5")
local TEN = hello_mpz.fromString("10")

----------------------------------------------------
-- Caching
----------------------------------------------------

-- settings

local DEFAULT_PRECISION = base_settings.DEFAULT_PRECISION
local FLOAT_DISPLAY_MODE = base_settings.FLOAT_DISPLAY_MODE
local DEFAULT_DIGITS  = base_settings.DEFAULT_DIGITS

-- string

local string_format = string.format

-- math

local math_abs = math.abs
local math_floor = math.floor
local math_log = math.log
local math_max = math.max

-- other

local type = type
local setmetable = setmetatable
local tonumber = tonumber

local MPF_MT = getmetatable(setmetatable({}, hello_mpf))

----------------------------------------------------
-- Guarding
----------------------------------------------------

-- assert variable if the variable is hello_mpf
local function require_mpf(v, name)
	if getmetatable(v) ~= MPF_MT then
		error(name .. " must be a hello_mpf instance. Use hello_mpf.new(value) to convert.", 3)
	end
end

----------------------------------------------------
-- Constructor System
----------------------------------------------------

local function make(sign, mantissa, exponent, precision)
	return setmetatable({
		sign = sign or false,
		mantissa = mantissa or ZERO,
		exponent = exponent or 0,
		precision = precision or DEFAULT_PRECISION,
	}, hello_mpf)
end

-- power by 2.
local function pow2(n)
	if n <= 0 then
		return ONE
	end

	local r = ONE
	for _ = 1, n do
		r = r * TWO
	end
	return r
end

-- normalizer function, enforces the invariant:
-- 2^(prec-1) <= mantissa < 2^prec
local function normalize(mpf)
	-- zero check
	if mpf.mantissa:isZero() then
		mpf.sign = false
		mpf.exponent = 0
		return mpf
	end

	local min = pow2(mpf.precision - 1)
	local max = pow2(mpf.precision)

	while mpf.mantissa < min do
		mpf.mantissa = mpf.mantissa * TWO
		mpf.exponent = mpf.exponent - 1
	end

	while mpf.mantissa >= max do
		mpf.mantissa = mpf.mantissa // TWO
		mpf.exponent = mpf.exponent + 1
	end

	return mpf
end

-- converts the decimal string into rational parts
local function parse_decimal(str)
	local s = str:lower()

	-- sign
	local sign = false
	if s:sub(1,1) == "-" then
		sign = true
		s = s:sub(2)
	elseif s:sub(1,1) == "+" then
		s = s:sub(2)
	end

	-- split exponent
	local base, exp = s, 0
	local epos = s:find("e", 1, true)
	if epos then
		base = s:sub(1, epos - 1)
		exp = tonumber(s:sub(epos + 1)) or 0
	end

	-- split decimal
	local int, frac = base, ""
	local dpos = base:find("%.")
	if dpos then
		int = base:sub(1, dpos - 1)
		frac = base:sub(dpos + 1)
	end

	if int == "" then int = "0" end
	if frac == "" then frac = "0" end

	local digits = int .. frac
	local scale = #frac - exp

	local num = hello_mpz.fromString(digits)
	local den = ONE

	if scale > 0 then
		den = TEN:pow(scale)
	elseif scale < 0 then
		num = num * TEN:pow(-scale)
	end

	return sign, num, den
end

-- construct the hello_mpf number from rational form.
local function from_rational(sign, num, den, prec)
	if num:isZero() then
		return make(false, ZERO, 0, prec)
	end

	local exp2 = 0

	-- scale numerator to preserve precision bits
	local mant = (num * pow2(prec)) // den
	exp2 = -prec

	-- normalize mantissa
	local min = pow2(prec - 1)
	local max = pow2(prec)

	while mant < min do
		mant = mant * TWO
		exp2 = exp2 - 1
	end
	while mant >= max do
		mant = mant // TWO
		exp2 = exp2 + 1
	end

	return make(sign, mant, exp2, prec)
end

-- Constructs a hello_mpf double from a string.
-- Precision tooltip here.
function hello_mpf.fromString(value, precision)
	local prec = precision or DEFAULT_PRECISION

	local sign, num, den = parse_decimal(value)

	return normalize(from_rational(sign, num, den, prec))
end

-- Constructs a hello_mpf double from a number (double).
-- Precision tooltip here.
function hello_mpf.fromNumber(value, precision)
	local prec = precision or DEFAULT_PRECISION
	
	if value == 0 then
		return normalize(make(false, ZERO, 0, prec))
	end
	
	local sign = value < 0
	local abs = math_abs(value)
	
	-- decompose number into mantissa * 2^exp
	local exp = math_floor(math_log(abs, 2))
	local scaled = abs / (2 ^ exp)
	
	-- scale mantissa to precision bits
	local mantissa = hello_mpz.new(math_floor(scaled * (2 ^ prec)))
	
	return normalize(make(sign, mantissa, exp - prec, prec))
end

-- tooltip to be determined
function hello_mpf:toScientificString()
	local sign_str = self.sign and "-" or ""
	return string_format(
		"%s%s * 2^%d (precision=%d)",
		sign_str,
		tostring(self.mantissa),
		self.exponent,
		self.precision
	)
end

-- Converts hello_mpf to a decimal string with `digits` decimal places
function hello_mpf:toDecimalString(digits)
	digits = digits or DEFAULT_DIGITS

	if self.mantissa:isZero() then
		return "0"
	end

	local sign_str = self.sign and "-" or ""
	local mant = self.mantissa:clone()
	local exp = hello_mpz.new(self.exponent)

	-- Adjust mantissa to decimal
	local num = mant
	local den = ONE:clone()

	if exp.sign < 0 then
		-- Divide by 2^-exp => multiply numerator by 5^-exp, denominator by 10^-exp
		num = num * FIVE^(-exp)
		den = TEN^(-exp)
	elseif exp.sign > 0 then
		-- Multiply numerator by 2^exp
		num = num * pow2(exp)
	end

	-- Get integer part
	local int_part = num // den
	local frac_part = num % den

	local int_str = tostring(int_part)

	if digits == 0 then
		return sign_str .. int_str
	end

	-- Compute fractional part as decimal
	local frac_str = ""
	for i = 1, digits do
		frac_part = frac_part * TEN
		local digit = frac_part // den
		frac_str = frac_str .. tostring(digit)
		frac_part = frac_part % den
		if frac_part:isZero() then
			break
		end
	end

	-- Remove trailing zeros
	frac_str = frac_str:gsub("0+$", "")
	if frac_str == "" then
		return sign_str .. int_str
	else
		return sign_str .. int_str .. "." .. frac_str
	end
end

-- tooltip to be determined
function hello_mpf:toString(digits)
	digits = digits or DEFAULT_DIGITS
	
	-- yes we use base_setting's modes for this one
	if FLOAT_DISPLAY_MODE == "fixed" then
		return self:toDecimalString(digits)

	elseif FLOAT_DISPLAY_MODE == "scientific" then
		-- Optional: make a prettier scientific notation instead of raw binary
		-- But keeping raw is fine for debug feel
		return self:toScientificString()
	end
	
	-- return nothing because FLOAT_DISPLAY_MODE must be either two of them, they are handled in base_settings anyway.
end

-- tooltip to be determined
hello_mpf.__tostring = hello_mpf.toString

----------------------------------------------------
-- Utilities
----------------------------------------------------

-- Clones the hello_mpf double to prevent mutation.
function hello_mpf:clone()
	return make(self.sign, self.mantissa:clone(), self.exponent, self.precision)
end

-- Returns the negated value of the hello_mpf double.
function hello_mpf:neg()
	if self.mantissa:isZero() then return self:clone() end
	local res = self:clone()
	res.sign = not res.sign
	return res
end

-- Returns the negated value of the hello_mpf double.
function hello_mpf.__unm(a)
	return a:neg()
end

----------------------------------------------------
-- Addition and Subtraction
----------------------------------------------------

-- align both mantissas to the larger exponent
local function align_to_max_exponent(a, b)
	if a.exponent > b.exponent then
		local shift = a.exponent - b.exponent
		local mant_b_shifted = b.mantissa // pow2(shift)
		return a.mantissa, mant_b_shifted, a.exponent
	elseif b.exponent > a.exponent then
		local shift = b.exponent - a.exponent
		local mant_a_shifted = a.mantissa // pow2(shift)
		return mant_a_shifted, b.mantissa, b.exponent
	else
		return a.mantissa, b.mantissa, a.exponent
	end
end

-- tooltip to be determined
function hello_mpf.__add(a, b)
	require_mpf(a, "Left operand")
	require_mpf(b, "Right operand")

	if a.mantissa:isZero() then return b:clone() end
	if b.mantissa:isZero() then return a:clone() end

	local prec = math_max(a.precision, b.precision)

	if a.sign == b.sign then
		-- Same sign → add magnitudes
		local mant_a, mant_b, exp = align_to_max_exponent(a, b)
		local sum_mant = mant_a + mant_b
		local result = make(a.sign, sum_mant, exp, prec)
		return normalize(result)
	else
		-- Opposite signs → subtract magnitudes
		local mant_a, mant_b, exp = align_to_max_exponent(a, b)
		local cmp = mant_a:compare(mant_b)

		if cmp > 0 then
			local diff = mant_a - mant_b
			return normalize(make(a.sign, diff, exp, prec))
		elseif cmp < 0 then
			local diff = mant_b - mant_a
			return normalize(make(b.sign, diff, exp, prec))
		else
			-- Exactly cancel
			return make(false, ZERO, 0, prec)
		end
	end
end

-- tooltip to be determined
function hello_mpf.__sub(a, b)
	require_mpf(a, "Left operand")
	require_mpf(b, "Right operand")
	
	-- base case: 0 - a = -a
	if a.mantissa:isZero() then
		return b:neg()
	end
	
	-- base case: a - 0 = a
	if b.mantissa:isZero() then return a:clone() end

	-- a - b = a + (-b)
	local neg_b = make(not b.sign, b.mantissa:clone(), b.exponent, b.precision)
	return a + neg_b
end

----------------------------------------------------
-- Multiplication
----------------------------------------------------

-- tooltip to be determined
function hello_mpf.__mul(a, b)
	require_mpf(a, "Left operand")
	require_mpf(b, "Right operand")

	-- Handle zeros
	if a.mantissa:isZero() or b.mantissa:isZero() then
		return make(false, ZERO, 0, math_max(a.precision, b.precision))
	end

	-- Sign: XOR of signs
	local result_sign = a.sign ~= b.sign

	-- Exponent sum (may overflow/underflow, but Luau handles big ints for exp fine)
	local result_exp = a.exponent + b.exponent

	-- Mantissa product — this is the heavy part
	local product_mant = a.mantissa * b.mantissa

	-- Result precision = max of both
	local result_prec = math_max(a.precision, b.precision)

	-- Create temporary with full product (may have up to 2*prec bits)
	local temp = make(result_sign, product_mant, result_exp, result_prec)

	-- Normalize will shift right if needed and adjust exponent
	-- It also enforces the [2^(prec-1), 2^prec) invariant
	return normalize(temp)
end

----------------------------------------------------
-- Division
----------------------------------------------------

-- tooltip to be determined
function hello_mpf.__div(a, b)
	require_mpf(a, "Left operand (dividend)")
	require_mpf(b, "Right operand (divisor)")

	-- Handle division by zero
	if b.mantissa:isZero() then
		error("Division by zero", 2)
	end

	-- Handle zero dividend
	if a.mantissa:isZero() then
		return make(false, ZERO, 0, math.max(a.precision, b.precision))
	end

	-- Sign: XOR
	local result_sign = a.sign ~= b.sign

	-- Exponent: subtract
	local result_exp = a.exponent - b.exponent

	-- Result precision = max of both
	local result_prec = math.max(a.precision, b.precision)

	-- To perform division: scale dividend up by precision bits, then integer divide
	-- This gives us enough bits for the quotient
	local scaled_dividend = a.mantissa * pow2(result_prec)

	-- Integer division: scaled_dividend // b.mantissa
	local quotient_mant = scaled_dividend // b.mantissa

	-- If quotient is zero (underflow), return zero
	if quotient_mant:isZero() then
		return make(false, ZERO, 0, result_prec)
	end

	-- Create result
	local result = make(result_sign, quotient_mant, result_exp - result_prec, result_prec)

	-- Normalize to enforce mantissa invariant
	return normalize(result)
end

----------------------------------------------------
-- Polishing & Other
----------------------------------------------------

-- fromAny core function
local function fromAny(value, precision)
	local prec = precision or DEFAULT_PRECISION

	if type(value) == "string" then
		return hello_mpf.fromString(value, prec)
	elseif type(value) == "number" then
		return hello_mpf.fromNumber(value, prec)
	else
		error("Cannot construct hello_mpf from value of type " .. type(value))
	end
end

-- Construct a hello_mpf double from string or number.
hello_mpf.new = fromAny

-- make the table a callable function
setmetatable(hello_mpf, {
	__call = function(_, value, precision)
		return fromAny(value, precision)
	end,
})

return hello_mpf