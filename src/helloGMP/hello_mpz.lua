-- comment directives, may be removed if currently debugging, insert a space to disable
--!nolint
--!nocheck

-- hello_mpz, big integer module of the helloGMP library

local base_settings = require(script.Parent.base_settings)
local hello_mpz = {}

local setting_mode = base_settings.MODE

-- sure
hello_mpz.__index = hello_mpz

-- getting base (caching)
local BASE = base_settings.BASE
local BASE_DIGS = math.log10(BASE)

----------------------------------------------------
-- Function Caching
----------------------------------------------------

-- string functions

local string_rep = string.rep
local string_format = string.format

-- math functions

local math_random = math.random
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil
local math_abs = math.abs

-- table functions

local table_create = table.create
local table_insert = table.insert
local table_concat = table.concat
local table_unpack = table.unpack or unpack

-- bit 32 replacements

local bit32_band = bit32.band
local bit32_lshift = bit32.lshift

-- direct local caching replacements

local tostring = tostring
local tonumber = tonumber
local type = type
local assert = assert

local setmetatable = setmetatable
local getmetatable = getmetatable

local ipairs = ipairs

local rawequal = rawequal

----------------------------------------------------
-- Main Constructor System
----------------------------------------------------
-- Create a new bigint from sign, limbs (little-endian table)
local function make(sign, limbs)
	local t = setmetatable({}, hello_mpz)
	t.sign = sign or 0 -- 0 for zero, 1 or -1
	t.limbs = limbs or {0}
	return t
end

local function trim(t)
	local l = t.limbs
	while #l > 1 and l[#l] == 0 do l[#l] = nil end
	if #l == 1 and l[1] == 0 then t.sign = 0 end
	return t
end

-- normalize to ensure limbs < BASE and no negative limbs
-- Normalize limbs so that:
--   0 <= limbs[i] < BASE
--   no sparse entries
--   no leading zero limbs
local function normalize_limbs(limbs)
	local carry = 0

	for i = 1, #limbs do
		local v = (limbs[i] or 0) + carry

		-- compute carry toward next limb
		-- works for both positive and negative v
		carry = math_floor(v / BASE)
		v = v - carry * BASE

		-- ensure limb is in [0, BASE)
		if v < 0 then
			v = v + BASE
			carry = carry - 1
		end

		limbs[i] = v
	end

	-- propagate remaining carry
	while carry ~= 0 do
		local v = carry
		carry = math_floor(v / BASE)
		v = v - carry * BASE

		if v < 0 then
			v = v + BASE
			carry = carry - 1
		end

		limbs[#limbs + 1] = v
	end

	-- trim leading zeros
	while #limbs > 1 and limbs[#limbs] == 0 do
		limbs[#limbs] = nil
	end
end

-- normalizes parameters for certain functions to accept both string and hello_mpz number
local function normalize_parameters(...)
	local parameters = {...}
	for i, parameter in ipairs(parameters) do
		if getmetatable(parameter) ~= hello_mpz then
			-- convert strings (or other types) into hello_mpz
			-- accepts both number and string
			parameters[i] = hello_mpz.new(parameter)
		end
	end
	return table_unpack(parameters)
end

-- shared helper of checking the parameter if it is a hello_mpz type
local function checkhello_mpzType(k, n)
	assert(getmetatable(k) == hello_mpz or type(k) == "string", 
		n.." must be a hello_mpz number or string. Got "..type(k)
	)
end

-- Constructs the hello_mpz number with optional leading + or - from the given string.
function hello_mpz.fromString(s)
	assert(type(s) == "string", "Expected string, got "..type(s))

	local i = 1
	local sign = 1
	if s:sub(1,1) == '+' then
		i = 2
	elseif s:sub(1,1) == '-' then
		sign = -1
		i = 2
	end

	-- strip leading zeros
	s = s:sub(i):gsub("^0+", "")

	-- default to zero if s = empty string
	if s == '' then return make(0, {0}) end -- ZERO is not available in this scope

	-- strict validation: only digits allowed
	assert(s:match("^%d+$") or setting_mode ~= "strict", "Invalid string: contains non-digit characters ("..s..")")

	local limbs = {}
	local p = #s
	while p > 0 do
		local starti = math_max(1, p - BASE_DIGS + 1)
		local chunk = tonumber(s:sub(starti, p))

		-- assert chunk (should never fail if validation passed)
		assert(chunk ~= nil or setting_mode ~= "strict", "Invalid numeric chunk at position "..starti.."-"..p)

		table_insert(limbs, chunk)
		p = starti - 1
	end

	normalize_limbs(limbs)
	local t = make(sign, limbs)
	trim(t)
	return t
end

-- handle scientific notations for fromNumber (above 2^53 bit limit)
local function expandScientific(str)
	local base, exp = str:match("^(%-?%d+%.?%d*)[eE]([%+%-]?%d+)$")
	if not base then return str end

	exp = tonumber(exp)
	-- remove decimal point
	local int, frac = base:match("^(%-?%d+)%.?(%d*)$")
	frac = frac or ""
	local digits = int .. frac
	local shift = exp - #frac

	if shift >= 0 then
		return digits .. string_rep("0", shift)
	else
		local pos = #digits + shift
		return digits:sub(1, pos) .. "." .. digits:sub(pos+1)
	end
end

-- checks if the number is finite/valid
local function checkFiniteNumber(n, errMsg)
	assert(n ~= math.huge -- positive infinity
		and n ~= -math.huge -- negative infinity
		and n == n,  -- nan
		errMsg
	)
end

-- Constructs the hello_mpz number with optional leading + or - from the given number.
-- Bounded to Lua numbers and can lose precision from it.
function hello_mpz.fromNumber(n)
	assert(type(n) == "number", "Expected number, got "..type(n))

	-- reject infinities and NaN
	checkFiniteNumber(n, "Invalid number: cannot construct hello_mpz integer from "..tostring(n)..", use fromString and parse the number in string for exact big integers.")

	local s = tostring(n)
	s = expandScientific(s)
	return hello_mpz.fromString(s)
end

-- Converts the hello_mpz number into a string. 
-- Also can be done when printed or used under tostring function.
function hello_mpz:toString()
	if self.sign == 0 then return "0" end
	local parts = {}
	local n = #self.limbs

	-- cache the format once
	local fmt = "%0"..BASE_DIGS.."d"

	-- most significant limb first
	parts[1] = tostring(self.limbs[n])
	for i = n-1, 1, -1 do
		parts[#parts+1] = string_format(fmt, self.limbs[i])
	end
	local out = table_concat(parts)
	if self.sign < 0 then out = "-" .. out end
	return out
end

-- Converts the hello_mpz number to a scientific string.
function hello_mpz:toScientific(precision)
	precision = precision or 15 -- digits in mantissa
	assert(precision > 0, "Precision must be 1 or greater, got: ".. precision)

	if self.sign == 0 then return "0" end

	local str = self:toString()
	local firstDigit = str:sub(1,1)
	local mantissa = str:sub(1, precision)
	if #mantissa > 1 then
		mantissa = mantissa:sub(1,1) .. "." .. mantissa:sub(2)
	end

	local exponent = #str - 1
	if self.sign < 0 then
		mantissa = "-" .. mantissa
	end

	return mantissa .. " * 10^" .. exponent
end

-- Converts the hello_mpz number into a number.
-- This conversion can lose precision or delve into inf.
function hello_mpz:toNumber()
	return tonumber(self:toString())
end

-- Returns the raw limb table of a hello_mpz number (DEBUG)
function hello_mpz:toRawTable()
	local raw = {}
	for i = 1, #self.limbs do
		raw[i] = self.limbs[i]
	end
	return { sign = self.sign, limbs = raw }
end

-- Converts the hello_mpz number into a string.
function hello_mpz.__tostring(a)
	return a:toString()
end

----------------------------------------------------
-- Absolute and Negate Functions
----------------------------------------------------

-- Returns the absolute value of the hello_mpz number.
function hello_mpz:abs()
	if self.sign < 0 then
		local copy = self:clone()
		copy.sign = 1
		return copy
	else
		return self:clone()
	end
end

-- Returns the negated value of the hello_mpz number.
-- For example, n:neg() = -n, -n:neg() = n
function hello_mpz:neg()
	local copy = self:clone()
	copy.sign = copy.sign * -1
	return copy
end

-- Returns the negated value of the hello_mpz number.
function hello_mpz.__unm(a)
	return a:neg()
end

----------------------------------------------------
-- Pre-computed / Constant Numbers
-- Cached numbers to speed up performance a little.
-- Additionally construct using the raw constructor as micro-optimization set up
----------------------------------------------------
local ZERO = make(0, {0})
local ONE = make(1, {1})
local TWO = make(1, {2})

----------------------------------------------------
-- Base Representation System
----------------------------------------------------

-- Formats the hello_mpz number with base (number) and provided with alphabet (string) for representation.
function hello_mpz:toBase(base, alphabet, prefix)
	assert(type(base) == "number" and base >= 1, "Base must be at least 1")
	assert(type(alphabet) == "string", "Alphabet must be a string, got "..type(alphabet))
	assert(#alphabet >= base, "Alphabet must have at least ".. base .." unique symbols")

	-- Zero case
	if self:isZero() then
		return alphabet:sub(1,1)
	end

	local isNegative = self.sign < 0

	-- Unary/base-1 case (streaming in limb chunks)
	if base == 1 then

		self = self:abs()

		local symbol = alphabet:sub(1,1)
		local result = {}

		local limbBase = BASE
		local limbHGMP = hello_mpz.fromNumber(limbBase)

		while not self:isZero() do
			local chunk = self
			if chunk > limbHGMP then
				chunk = limbHGMP
			end
			table_insert(result, string_rep(symbol, chunk:toNumber()))
			self = self - chunk
		end

		local str = table_concat(result)
		if isNegative then str = "-" .. str end
		return str
	end

	-- Precompute alphabet lookup table
	local alphabetChars = {}
	for i = 1, base do
		alphabetChars[i-1] = alphabet:sub(i,i)
	end

	-- Normal base >= 2

	self = self:abs()

	local baseHGMP = hello_mpz.fromNumber(base)
	local result = {}

	-- If hello_mpz has divmod, use it here for efficiency
	while not self:isZero() do
		local q, r = hello_mpz.divmod(self, baseHGMP)

		table_insert(result, alphabetChars[r:toNumber()])
		self = q
	end

	-- Build final string (reverse digits once at the end)
	local str = table_concat(result):reverse()
	if prefix then str = prefix .. str end
	if isNegative then str = "-" .. str end

	return str
end

-- Parses a string in the given base and alphabet into a hello_mpz number.
function hello_mpz.fromBase(str, base, alphabet, prefix)
	assert(type(str) == "string", "Input must be a string")
	assert(type(base) == "number" and base >= 1, "Base must be at least 1")
	assert(type(alphabet) == "string", "Alphabet must be a string, got "..type(alphabet))
	assert(#alphabet >= base, "Alphabet must have at least ".. base .." unique symbols")

	-- handle empty string case
	if str == "" then
		return ZERO
	end

	local isNegative = str:sub(1,1) == "-"
	if isNegative then
		str = str:sub(2)
	end

	if prefix and str:sub(1, #prefix) == prefix then
		str = str:sub(#prefix + 1)
	end
	-- Unary/base-1 case
	if base == 1 then
		local count = #str
		local result = hello_mpz.fromNumber(count)
		if isNegative then result.sign = -1 end
		return result
	end

	-- Normal base >= 2
	local charToValue = {}
	for i = 1, base do
		local c = alphabet:sub(i,i)
		charToValue[c] = i - 1
	end

	local result = ZERO:clone()
	local baseHGMP = hello_mpz.fromNumber(base)

	for i = 1, #str do
		local c = str:sub(i,i)
		local val = charToValue[c]
		assert(val ~= nil, "Invalid character in input string: "..c)
		result = result * baseHGMP + hello_mpz.fromNumber(val)
	end

	if isNegative then result.sign = -1 end
	return result
end

-- look up tables for convenience functions.
local BASE_ALPHABETS = {
	-- practical bases
	hex     = "0123456789ABCDEF",
	binary  = "01",
	octal   = "01234567",
	base36  = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	base62	= "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",

	-- ascii characters (ascii-95 and ascii-256)
	ascii95 = (function()
		local chars = {}
		for i = 32, 126 do  -- printable ASCII
			chars[#chars+1] = string.char(i)
		end
		return table_concat(chars)
	end)(),
	ascii256 = (function()
		local chars = {}
		for i = 0, 255 do
			chars[#chars+1] = string.char(i)
		end
		return table_concat(chars)
	end)()
}

local BASE_PREFIXES = {
	hex     = "0x",
	binary  = "0b",
	octal   = "0o",
	base36  = "36#",
	base62 	= "62#",
	ascii95  = "95#",
	ascii256 = "256#"
}

-- Formats the hello_mpz number to unary (base 1). Supports custom symbol, default 1.
function hello_mpz:toUnary(symbol)
	symbol = symbol or "1"  -- default symbol for base 1
	return self:toBase(1, symbol)
end
-- Formats the hello_mpz number to hex.
function hello_mpz:toHex()
	return self:toBase(16, BASE_ALPHABETS.hex, BASE_PREFIXES.hex)
end
-- Formats the hello_mpz number to binary.
function hello_mpz:toBinary()
	return self:toBase(2, BASE_ALPHABETS.binary, BASE_PREFIXES.binary)
end
-- Formats the hello_mpz number to octal.
function hello_mpz:toOctal()
	return self:toBase(8, BASE_ALPHABETS.octal, BASE_PREFIXES.octal)
end
-- Formats the hello_mpz number to base 36.
function hello_mpz:toBase36()
	return self:toBase(36, BASE_ALPHABETS.base36, BASE_PREFIXES.base36)
end
-- Formats the hello_mpz number to base 62.
function hello_mpz:toBase62()
	return self:toBase(62, BASE_ALPHABETS.base62, BASE_PREFIXES.base62)
end
-- Formats the hello_mpz number to base-ASCII
function hello_mpz:toAscii95()
	return self:toBase(95, BASE_ALPHABETS.ascii95, BASE_PREFIXES.ascii95)
end
-- Formats the hello_mpz number to base-ASCII (full byte range)
function hello_mpz:toAscii256()
	return self:toBase(256, BASE_ALPHABETS.ascii256, BASE_PREFIXES.ascii256)
end

-- Converts unary format to hello_mpz number. Supports custom symbol, default 1.
function hello_mpz.fromUnary(str, symbol)
	symbol = symbol or "1"
	return hello_mpz.fromBase(str, 1, symbol)
end
-- Converts hex format to hello_mpz number.
function hello_mpz.fromHex(str)
	return hello_mpz.fromBase(str, 16, BASE_ALPHABETS.hex, BASE_PREFIXES.hex)
end
-- Converts binary format to hello_mpz number.
function hello_mpz.fromBinary(str)
	return hello_mpz.fromBase(str, 2, BASE_ALPHABETS.binary, BASE_PREFIXES.binary)
end
-- Converts octal format to hello_mpz number.
function hello_mpz.fromOctal(str)
	return hello_mpz.fromBase(str, 8, BASE_ALPHABETS.octal, BASE_PREFIXES.octal)
end
-- Converts base 36 format to hello_mpz number.
function hello_mpz.fromBase36(str)
	return hello_mpz.fromBase(str, 36, BASE_ALPHABETS.base36, BASE_PREFIXES.base36)
end
-- Converts base 62 format to hello_mpz number.
function hello_mpz.fromBase62(str)
	return hello_mpz.fromBase(str, 62, BASE_ALPHABETS.base62, BASE_PREFIXES.base62)
end
-- Converts base-ASCII format to hello_mpz number.
function hello_mpz.fromAscii95(str)
	return hello_mpz.fromBase(str, 95, BASE_ALPHABETS.ascii95, BASE_PREFIXES.ascii95)
end
-- Converts base-ASCII (full byte range) format to hello_mpz number.
function hello_mpz.fromAscii256(str)
	return hello_mpz.fromBase(str, 256, BASE_ALPHABETS.ascii256, BASE_PREFIXES.ascii256)
end

----------------------------------------------------
-- Comparison
----------------------------------------------------
-- compare absolute values: returns -1,0,1
-- worse performace for __eq function, that's why we have to put a separate one
local function cmpAbs(a, b)
	local na, nb = #a.limbs, #b.limbs
	if na ~= nb then
		return (na > nb) and 1 or -1
	end
	-- single-limb fast path
	if na == 1 then
		local av, bv = a.limbs[1], b.limbs[1]
		if av == bv then return 0 end
		return (av > bv) and 1 or -1
	end
	-- scan from high limb down
	for i = na, 1, -1 do
		local av, bv = a.limbs[i], b.limbs[i]
		if av ~= bv then
			return (av > bv) and 1 or -1
		end
	end
	return 0
end

-- compare function handler
local function compare(a, b)
	if a.sign == 0 and b.sign == 0 then return 0 end
	if a.sign ~= b.sign then
		return (a.sign > b.sign) and 1 or -1
	end
	if a.sign >= 0 then
		return cmpAbs(a, b)
	else
		return -cmpAbs(a, b)
	end
end

-- equality metamethods
-- covers all standard lua comparisons
-- for __eq, have its own function for performance

-- Checks if a (hello_mpz number) is equal to b (hello_mpz number), use metamethods for full comparator coverage + readability.
function hello_mpz.__eq(a, b)
	-- pointer identity
	if rawequal(a, b) then return true end

	-- sign mismatch
	if a.sign ~= b.sign then return false end

	-- both zero
	if a.sign == 0 then return true end

	local na, nb = #a.limbs, #b.limbs
	if na ~= nb then return false end

	-- single-limb fast path
	if na == 1 then
		return a.limbs[1] == b.limbs[1]
	end

	-- scan from high limb down
	for i = na, 1, -1 do
		if a.limbs[i] ~= b.limbs[i] then
			return false
		end
	end
	return true
end

-- Checks if a (hello_mpz number) is less than b (hello_mpz number), use metamethods for full comparator coverage.
function hello_mpz.__lt(a, b) return compare(a, b) < 0 end

-- Checks if a (hello_mpz number) is less or equal to b (hello_mpz number), use metamethods for full comparator coverage.
function hello_mpz.__le(a, b) return compare(a, b) <= 0 end

-- sign comparators for convenience

-- Checks if hello_mpz number is zero. (a == 0)
function hello_mpz:isZero() return self.sign == 0 end

-- Checks if hello_mpz number is positive. (a > 0)
function hello_mpz:isPositive() return self.sign > 0 end

-- Checks if hello_mpz number is negative. (a < 0)
function hello_mpz:isNegative() return self.sign < 0 end

----------------------------------------------------
-- Other Utilities
----------------------------------------------------

-- Determines if a number is even using bit32 band for maximum performance.
function hello_mpz:isEven()
	return bit32_band(self.limbs[1], 1) == 0
end

-- Determines if a number is odd using bit32 band for maximum performance.
function hello_mpz:isOdd()
	return bit32_band(self.limbs[1], 1) == 1
end

-- Clones (deep-copy) the hello_mpz number to prevent mutation.
function hello_mpz:clone()
	local limbs = {}
	for i = 1, #self.limbs do limbs[i] = self.limbs[i] end
	return make(self.sign, limbs)
end

----------------------------------------------------
-- Limb Manipulation Helpers
----------------------------------------------------
-- add numbers by limbs
local function addLimbs(A, B)
	local n = math_max(#A, #B)
	local R = {}
	local carry = 0
	for i = 1, n do
		local av = A[i] or 0
		local bv = B[i] or 0
		local s = av + bv + carry
		if s >= BASE then
			carry = 1
			s = s - BASE
		else
			carry = 0
		end
		R[i] = s
	end
	if carry > 0 then R[n+1] = carry end
	return R
end

-- subtract numbers by limbs
local function subLimbs(A, B)
	-- assume A >= B in absolute (length-wise or value-wise as used)
	local R = {}
	local borrow = 0
	for i = 1, #A do
		local av = A[i] or 0
		local bv = B[i] or 0
		local s = av - bv - borrow
		if s < 0 then
			s = s + BASE
			borrow = 1
		else
			borrow = 0
		end
		R[i] = s
	end
	return R
end

-- shift left by k limbs (multiply by BASE^k), mutate
local function shiftLimbsInPlace(L, times)
	if times <= 0 then return L end
	local n = #L
	for i = n, 1, -1 do
		L[i + times] = L[i]
	end
	for i = 1, times do
		L[i] = 0
	end
	return L
end

-- returns a new mpz with limbs[lo..hi]
local function slice(N, lo, hi)
	local limbs = N.limbs
	local out = {}

	if lo > hi or lo > #limbs then
		return ZERO
	end

	hi = math_min(hi, #limbs)

	for i = lo, hi do
		out[#out + 1] = limbs[i]
	end

	return make(
		#out > 0 and 1 or 0,
		out
	)
end

-- multiply by BASE^k
local function shift_limbs(N, k)
	if N.sign == 0 or k == 0 then
		return N
	end

	local limbs = N.limbs
	local out = {}

	-- insert k zero limbs at front (little-endian)
	for i = 1, k do
		out[i] = 0
	end

	for i = 1, #limbs do
		out[i + k] = limbs[i]
	end

	return make(N.sign, out)
end

-- keep only lowest k limbs
local function mask_low_limbs(N, k)
	if k <= 0 or N.sign == 0 then
		return ZERO
	end

	local limbs = N.limbs
	local out = {}

	local max = math_min(k, #limbs)
	for i = 1, max do
		out[i] = limbs[i]
	end

	return make(
		#out > 0 and 1 or 0,
		out
	)
end

----------------------------------------------------
-- Addition + Subtraction
----------------------------------------------------
-- add absolute values (assume positive), return limbs
local function addAbsLimbs(A, B)
	local n = math_max(#A, #B)
	local R = {}
	local carry = 0
	for i = 1, n do
		local av = A[i] or 0
		local bv = B[i] or 0
		local s = av + bv + carry
		if s >= BASE then
			carry = 1
			s = s - BASE
		else
			carry = 0
		end
		R[i] = s
	end
	if carry > 0 then R[n+1] = carry end
	return R
end

-- subtract absolute values A - B, assuming A >= B
local function subAbsLimbs(A, B)
	local R = {}
	local borrow = 0
	for i = 1, #A do
		local av = A[i]
		local bv = B[i] or 0
		local s = av - bv - borrow
		if s < 0 then
			s = s + BASE
			borrow = 1
		else
			borrow = 0
		end
		R[i] = s
	end
	normalize_limbs(R)
	return R
end

-- Adds a (hello_mpz number) and b (hello_mpz number).
function hello_mpz.__add(a, b)

	-- shortcut: if a == 0 or b == 0 then yes
	if a.sign == 0 then return make(b.sign, b.limbs) end
	if b.sign == 0 then return make(a.sign, a.limbs) end

	-- addition
	if a.sign == b.sign then
		local limbs = addAbsLimbs(a.limbs, b.limbs)
		local r = make(a.sign, limbs)
		trim(r)
		return r
	else
		local c = cmpAbs(a, b)
		if c == 0 then return ZERO end
		if c > 0 then
			local limbs = subAbsLimbs(a.limbs, b.limbs)
			local r = make(a.sign, limbs)
			trim(r)
			return r
		else
			local limbs = subAbsLimbs(b.limbs, a.limbs)
			local r = make(b.sign, limbs)
			trim(r)
			return r
		end
	end
end

-- Subtracts a (HGMP number) and b (HGMP number).
function hello_mpz.__sub(a, b)
	-- simply negate b.
	return hello_mpz.__add(a, b:neg())
end

----------------------------------------------------
-- Multiplication System
-- Yeah this gonna be HUGE.
-- Multiplication algorithm cutoff settings
----------------------------------------------------
-- cutoff system
-- used for changing the behaviour of multiplication to keep ot optimized
-- number of each variable is in limb count.
-- TODO: optimize the cutoffs

-- small multi-limb threshold
-- is used when a huge number is multiplied by a small number for optimization purposes
local SMALL_LIMBS = 3  -- 1-3 limbs considered small

local COMBA_CUTOFF = 10
local KARATSUBA_CUTOFF = 40

----------------------------------------------------
-- Comba system
----------------------------------------------------
local function combaMulLimbs(A, B)
	local na, nb = #A, #B
	local r = {}
	local carry = 0
	for k = 1, na + nb - 1 do
		-- precompute bounds to avoid math_min/math_max in the inner loop
		local i_start = (k > nb) and (k - nb + 1) or 1
		local i_end   = (k < na) and k or na

		local sum = carry
		for i = i_start, i_end do
			sum = sum + A[i] * B[k - i + 1]
		end
		r[k] = sum % BASE
		carry = math_floor(sum / BASE)
	end
	if carry > 0 then r[#r + 1] = carry end
	return r -- defer normalization to outer boundary
end

----------------------------------------------------
-- the Karatsuba system + Schoolbook
----------------------------------------------------

-- schoolbook multiplication (limb-only variant used as base case)
local function schoolbookMulLimbs(A, B)
	local na, nb = #A, #B
	local R = {}
	for i = 1, na + nb do R[i] = 0 end

	for i = 1, na do
		local carry = 0
		local ai = A[i]
		for j = 1, nb do
			local idx = i + j - 1
			local prod = ai * B[j] + R[idx] + carry
			R[idx] = prod % BASE
			carry  = math_floor(prod / BASE)
		end
		R[i + nb] = R[i + nb] + carry
	end

	return R -- defer normalization
end

-- Karatsuba multiplication main function
local function karatsubaMulLimbs(A, B)
	local na, nb = #A, #B
	if na < nb then A, B, na, nb = B, A, nb, na end

	-- balanced split size
	local m = math_floor(math_min(na, nb) / 2)

	-- base case: route to comba or schoolbook to avoid deep recursion for small sizes
	if m <= COMBA_CUTOFF then
		-- pick comba for moderate, schoolbook for very small
		if math_min(na, nb) <= 8 then
			return schoolbookMulLimbs(A, B)
		else
			return combaMulLimbs(A, B)
		end
	end

	-- split A: [1..m], [m+1..]
	local lowA, highA = {}, {}
	for i = 1, m do lowA[i] = A[i] end
	for i = m + 1, na do highA[i - m] = A[i] end

	-- split B similarly (B may be shorter)
	local lowB, highB = {}, {}
	for i = 1, math_min(m, nb) do lowB[i] = B[i] end
	for i = m + 1, nb do highB[i - m] = B[i] end

	local z0 = karatsubaMulLimbs(lowA, lowB)
	local z2 = karatsubaMulLimbs(highA, highB)

	local sumA = addLimbs(lowA, highA) -- assumes no normalization needed
	local sumB = addLimbs(lowB, highB)
	local z1   = karatsubaMulLimbs(sumA, sumB)

	-- z1 = z1 - z2 - z0
	z1 = subLimbs(z1, z2)
	z1 = subLimbs(z1, z0)

	-- assemble R = z0 + (z1 << m) + (z2 << 2m)
	local R = {}
	for i = 1, #z0 do R[i] = (R[i] or 0) + z0[i] end
	for i = 1, #z1 do
		local idx = i + m
		R[idx] = (R[idx] or 0) + z1[i]
	end
	for i = 1, #z2 do
		local idx = i + 2 * m
		R[idx] = (R[idx] or 0) + z2[i]
	end

	return R -- defer normalization
end

----------------------------------------------------
-- Multiplication
----------------------------------------------------
-- check if number is a power of ten (positive)
-- mentally destructive table right there btw
local POW10_LIMB = { [1]=0, [10]=1, [100]=2, [1000]=3, [10000]=4, [100000]=5, [1000000]=6 }

local function isPow10Limbs(h)
	if h.sign <= 0 then return false end
	local L = h.limbs
	local n = #L
	if n == 0 then return false end
	-- canonical: least significant limb at L[1]
	if POW10_LIMB[L[1]] == nil then return false end
	for i = 2, n do
		if L[i] ~= 0 then return false end
	end
	return true
end

local function pow10_k_from_limbs(h)
	local L = h.limbs
	return 7 * (#L - 1) + POW10_LIMB[L[1]]
end

-- multiply by 10^k with minimal allocations, mutating a
local function mulByPow10_inplace(a, k)
	local times = math_floor(k / 7)
	local rem   = k % 7

	-- shift by full limbs in place
	shiftLimbsInPlace(a.limbs, times)

	-- multiply remaining 10^rem in place
	local mulRem = (rem == 0) and 1 or (10 ^ rem)
	local L = a.limbs
	local carry = 0
	for i = 1, #L do
		local v = L[i] * mulRem + carry
		L[i] = v % BASE
		carry = math_floor(v / BASE)
	end
	while carry > 0 do
		L[#L + 1] = carry % BASE
		carry = math_floor(carry / BASE)
	end
	return trim(a)
end

-- fast multiply by a single limb
local function mulBySingleLimb(A, limb)
	local result = {}
	local carry = 0

	local absLimb = math_abs(limb)
	for i = 1, #A.limbs do
		local prod = A.limbs[i] * absLimb + carry
		result[i] = prod % BASE
		carry = math_floor(prod / BASE)
	end
	if carry > 0 then
		table_insert(result, carry)
	end

	-- Determine the sign of the result
	local sign = A.sign * (limb < 0 and -1 or 1)
	return make(sign, result)
end

local function mulSmallByLarge(smallL, largeL)
	local R = {}
	for k = 1, #smallL do
		local carry = 0
		local a = smallL[k]
		for i = 1, #largeL do
			local idx = k + i - 1
			local prod = (R[idx] or 0) + a * largeL[i] + carry
			R[idx] = prod % BASE
			carry  = math_floor(prod / BASE)
		end
		if carry > 0 then
			local tail = k + #largeL
			R[tail] = (R[tail] or 0) + carry
		end
	end
	return R -- defer normalization
end

-- Multiplies two hello_mpz numbers.
-- Uses Schoolbook -> Comba -> Karatsuba when neccessary.
function hello_mpz.__mul(a, b)
	-- zero
	if a.sign == 0 or b.sign == 0 then
		return ZERO
	end

	-- fast path: powers of 10 without toString
	if isPow10Limbs(a) then
		return mulByPow10_inplace(b:clone(), pow10_k_from_limbs(a)) -- return b * 10^k
	elseif isPow10Limbs(b) then
		return mulByPow10_inplace(a:clone(), pow10_k_from_limbs(b)) -- return a * 10^k
	end

	local nALimbs, nBLimbs = #a.limbs, #b.limbs

	-- single-limb fast path
	if nALimbs == 1 then
		return mulBySingleLimb(b, a.limbs[1] * a.sign)
	elseif nBLimbs == 1 then
		return mulBySingleLimb(a, b.limbs[1] * b.sign)
	end

	-- small * small (both small)
	if nALimbs <= SMALL_LIMBS and nBLimbs <= SMALL_LIMBS then
		local limbs = schoolbookMulLimbs(a.limbs, b.limbs)
		normalize_limbs(limbs)
		return make(a.sign * b.sign, limbs)
	end

	-- explicit small * large
	if nALimbs <= SMALL_LIMBS and nBLimbs > SMALL_LIMBS then
		local limbs = mulSmallByLarge(a.limbs, b.limbs)
		normalize_limbs(limbs)
		return make(a.sign * b.sign, limbs)
	elseif nBLimbs <= SMALL_LIMBS and nALimbs > SMALL_LIMBS then
		local limbs = mulSmallByLarge(b.limbs, a.limbs)
		normalize_limbs(limbs)
		return make(a.sign * b.sign, limbs)
	end

	-- choose algorithm without table lookup overhead
	local maxLen = (nALimbs > nBLimbs) and nALimbs or nBLimbs
	local limbs
	if maxLen >= KARATSUBA_CUTOFF then
		limbs = karatsubaMulLimbs(a.limbs, b.limbs)
	elseif maxLen >= COMBA_CUTOFF then
		limbs = combaMulLimbs(a.limbs, b.limbs)
	else
		limbs = schoolbookMulLimbs(a.limbs, b.limbs)
	end
	normalize_limbs(limbs)
	return make(a.sign * b.sign, limbs)
end

----------------------------------------------------
-- Division + Modulation System
----------------------------------------------------
-- Burnikel-Ziegler division isn't worth it through tests, so it's removed
-- Knuth Division is definitely faster and simpler until extremely large limb counts

----------------------------------------------------
-- Knuth Division (Algorithm D, TAOCP Vol. 2)
-- Divides A by B, returning quotient limbs Q and remainder R
----------------------------------------------------

-- this is hard algorithm to maintain ngl
local function knuthLimbs(A, B)
	local n = #B
	local m = #A - n

	-- Case |A| < |B| -> quotient = 0, remainder = A
	if m < 0 then
		local R = {}
		for i = 1, #A do R[i] = A[i] end
		return {0}, R
	end

	-- Single-limb divisor fast path
	-- Uses exact long division with carry
	if n == 1 then
		local div = B[1]
		local Q, carry = {}, 0
		for i = #A, 1, -1 do
			local cur = A[i] + carry * BASE
			local q = math_floor(cur / div)
			local r = cur - q * div
			Q[i] = q
			carry = r
		end
		normalize_limbs(Q)
		return Q, {carry}
	end

	-- Normalization helpers
	-- Ensures highest limb of divisor >= BASE / 2
	local function BZnormalize(X, d)
		local R, carry = {}, 0
		for i = 1, #X do
			local v = X[i] * d + carry
			carry = math_floor(v / BASE)
			R[i] = v - carry * BASE
		end
		if carry > 0 then R[#R + 1] = carry end
		return R
	end

	-- Undo normalization on remainder slice
	local function unnormalize_slice(U, d, n)
		local R = {}
		local carry = 0
		for i = n, 1, -1 do
			local cur = U[i] + carry * BASE
			local q = math_floor(cur / d)
			R[i] = q
			carry = cur - q * d
		end
		normalize_limbs(R)
		return R
	end

	-- D1: Normalize divisor and dividend
	local d = math_floor(BASE / (B[n] + 1))
	if d < 1 then d = 1 end

	local U = BZnormalize(A, d)
	local V = BZnormalize(B, d)
	normalize_limbs(V)

	n = #V

	-- Knuth requires an extra leading zero on U
	U[#U + 1] = 0

	m = #U - n - 1

	-- D2-D7: Main division loop
	local Q = {}
	for i = 1, m + 1 do Q[i] = 0 end

	local vn  = V[n]
	local vn1 = V[n - 1]

	for j = m, 0, -1 do

		-- D3: Estimate quotient digit q^
		local ujn  = U[j + n + 1]
		local ujn1 = U[j + n]
		local ujn2 = U[j + n - 1] or 0

		local num  = ujn * BASE + ujn1
		local qhat = math_floor(num / vn)
		local rhat = num - qhat * vn

		if qhat > BASE - 1 then qhat = BASE - 1 end

		-- Correct q^ if overestimated
		while qhat * vn1 > rhat * BASE + ujn2 do
			qhat = qhat - 1
			rhat = rhat + vn
			if rhat >= BASE then break end
		end

		-- D4: Multiply and subtract q^ * V from U slice
		local borrow = 0
		for i = 1, n do
			local p = qhat * V[i] + borrow
			local u = U[j + i] - p

			if u < 0 then
				-- compute borrow properly
				borrow = math_floor((-u + BASE - 1) / BASE)
				u = u + borrow * BASE
			else
				borrow = 0
			end

			U[j + i] = u
		end

		U[j + n + 1] = U[j + n + 1] - borrow

		-- D5: If subtraction went negative, add back V
		if U[j + n + 1] < 0 then
			qhat = qhat - 1

			local carry = 0
			for i = 1, n do
				local u = U[j + i] + V[i] + carry
				if u >= BASE then
					u = u - BASE
					carry = 1
				else
					carry = 0
				end
				U[j + i] = u
			end
			U[j + n + 1] = U[j + n + 1] + 1
		end

		Q[j + 1] = qhat
	end

	normalize_limbs(Q)

	-- D8: Unnormalize remainder
	local R = unnormalize_slice(U, d, n)
	return Q, R
end

----------------------------------------------------
-- Division
----------------------------------------------------

-- Returns two values: quotient and remainder.
-- Quotient 'q' is the result obtained by dividing one quantity by another
-- Remainder 'r' is the result left over after a division that does not result in a whole number.
-- Recommended to use __div / __idiv (division/integer division) or __mod (modulo) metamethods.
-- Uses Knuth D Algorithm.
function hello_mpz.divmod(a, b)
	assert(b.sign ~= 0, "Division by zero.")
	if a.sign == 0 then return ZERO, ZERO end

	local cmp = cmpAbs(a, b)
	if cmp == 0 then
		return make(a.sign * b.sign, {1}), ZERO
	elseif cmp < 0 then
		return ZERO, make(a.sign, a.limbs)
	end

	local Qa, Ra = knuthLimbs(a.limbs, b.limbs)

	-- wrap results with signs and Lua floor semantics
	local q = make(a.sign * b.sign, Qa)
	local r = make(a.sign, Ra)
	trim(q); trim(r)

	-- Lua floor semantics
	if not r:isZero() and ((a.sign < 0) ~= (b.sign < 0)) then
		q = q - make(1, {1})
		r = r + b
		trim(q); trim(r)
	end

	return q, r
end

-- Divides two hello_mpz numbers.
function hello_mpz.__div(a,b)
	local q,_ = hello_mpz.divmod(a,b)
	return q
end

-- Integer divides two hello_mpz numbers (hello_mpz is strictly integer, no difference).
function hello_mpz.__idiv(a,b)
	local q,_ = hello_mpz.divmod(a,b)
	return q
end

-- Returns the result of a hello_mpz number modulated by b (hello_mpz number).
function hello_mpz.__mod(a,b)
	local _,r = hello_mpz.divmod(a,b)
	return r
end

----------------------------------------------------
-- Power
-- Uses integer exponentiation
----------------------------------------------------

-- Returns the result of the hello_mpz number powered by a native lua number.
function hello_mpz:powNumber(n)
	assert(type(n) == "number" and n >= 0 and math_floor(n) == n, "Exponent must be non-negative integer")
	if n == 0 then return ONE end
	if n == 1 then return self:clone() end

	local result = ONE:clone()
	local base = self:clone()
	while n > 0 do
		if n % 2 == 1 then
			result = result * base
		end
		base = base * base
		n = math_floor(n / 2)
	end
	return result
end

-- Returns the result of the hello_mpz number powered by another hello_mpz number.
function hello_mpz:pow(hgExp)
	hgExp = normalize_parameters(hgExp)
	checkhello_mpzType(hgExp, "Power Indice")

	assert(hgExp.sign >= 0, "Exponent must be non-negative")

	-- shortcut: 1^n = 1
	if self == ONE then
		return ONE
	end

	-- detect if exponent can be a number
	local n = hgExp:toNumber()
	if n then
		return self:powNumber(n)
	end

	-- large exponent hello_mpz ^ hello_mpz
	local result = ONE:clone()
	local base = self:clone()
	local exp = hgExp:clone()

	while exp > ZERO do
		if exp:isOdd() then
			result = result * base
		end
		base = base * base
		exp = exp / TWO
	end

	return result
end

-- Returns the result of the hello_mpz number powered by another hello_mpz number.
hello_mpz.__pow = function(a,b)
	return a:pow(b)
end

----------------------------------------------------
-- Square Root
-- integer square root (floor) using binary search
----------------------------------------------------
-- cutoffs
-- TODO: optimize the cutoffs

local ISQRT_NEWTON_CUTOFF = 25

-- binary square root (base)
local function isqrt_binary(N)
	local low = ZERO:clone()
	local high = N:clone()

	while low <= high do
		local mid = (low + high) / TWO
		local sq = mid * mid

		if sq == N then
			return mid
		elseif sq < N then
			low = mid + ONE
		else
			high = mid - ONE
		end
	end

	return high -- floor(sqrt(self))
end

-- newton square root
local function isqrt_newton(N)
	if N.sign == 0 then
		return ZERO
	end

	-- initial guess: 2^(ceil(bitlen/2))
	local n = #N.limbs
	local x = shift_limbs(ONE, math_floor((n + 1) / 2))

	while true do
		local y = (x + N / x) / TWO
		if y >= x then
			return x
		end
		x = y
	end
end

-- Returns the result of the square rooted hello_mpz number.
function hello_mpz:isqrt()
	if self.sign == 0 then return ZERO end
	assert(self.sign > 0, "Square root of negative number not supported")

	local limbCount = #self.limbs

	if limbCount < ISQRT_NEWTON_CUTOFF then
		return isqrt_binary(self)
	else
		return isqrt_newton(self)
	end
end

----------------------------------------------------
-- N Root
-- integer n-th root (floor)
----------------------------------------------------
-- cutoffs
local IROOT_NEWTON_CUTOFF = 25

local function pow_huge(x, e)
	local result = ONE
	local base = x:clone()
	while e > 0 do
		if e % 2 == 1 then
			result = result * base
		end
		base = base * base
		e = math_floor(e / 2)
	end
	return result
end

-- newton iroot function
local function iroot_newton(N, i)

	if N.sign == 0 then
		return ZERO
	end

	-- initial guess: B^(ceil((#limbs)/n))
	local num_limbs = #N.limbs
	local x = shift_limbs(ONE, math_floor((num_limbs + i.sign) / i.sign))  -- safe initial guess

	while true do
		local x_to_n_minus_1 = pow_huge(x, i:toNumber() - 1)

		if x_to_n_minus_1.sign == 0 then
			return ONE
		end

		local y = ((i - ONE) * x + N / x_to_n_minus_1) / i
		if y >= x then
			return x
		end
		x = y
	end
end

-- binary iroot function
local function iroot_binary(N, i)
	local low = ZERO:clone()
	local high = N:clone()

	while low <= high do
		local mid = (low + high) / TWO  -- integer division by 2 for binary search
		local pow = mid:pow(i)                     -- n is HGMP, pow supports HGMP

		if pow == N then
			return mid
		elseif pow < N then
			low = mid + ONE
		else
			high = mid - ONE
		end
	end

	return high
end

-- Returns the result of the hello_mpz number rooted by i (hello_mpz number).
function hello_mpz:iroot(i)
	i = normalize_parameters(i)
	checkhello_mpzType(i, "Indice")
	assert(i.sign > 0, "Root must be positive")  -- i is HGMP
	assert(self.sign >= 0, "Root of negative number not supported")

	-- shortcut: i = 2 -> square root
	if i == TWO then
		return self:isqrt()
	end

	local limbCount = #self.limbs

	if limbCount < IROOT_NEWTON_CUTOFF then
		return iroot_binary(self, i)
	else
		return iroot_newton(self, i)
	end
end

----------------------------------------------------
-- GCD and LCM Functions
----------------------------------------------------

-- Internal: divide a hello_mpz by 2
local function div2(n)
	local result = n:clone()
	local carry = 0

	for i = #result.limbs, 1, -1 do
		local cur = result.limbs[i] + carry * BASE
		result.limbs[i] = math_floor(cur / 2)  -- integer division
		carry = cur % 2
	end

	trim(result)
	return result
end

-- Internal: multiply a hello_mpz by 2^k
local function mulPow2(n, k)
	local result = n:clone()

	while k > 0 do
		local shift = math_min(k, 32)
		local carry = 0

		for i = 1, #result.limbs do
			-- split each limb safely to avoid overflow
			local v = (result.limbs[i] * 2^shift) + carry
			carry = math_floor(v / BASE)
			result.limbs[i] = v - carry * BASE
		end

		if carry > 0 then
			result.limbs[#result.limbs + 1] = carry
		end

		k = k - shift
	end

	return result
end

-- Finds the Greatest Common Divisor of the hello_mpz number and other (hello_mpz number).
-- Uses binary GCD algorithm.
function hello_mpz.GCD(a, b)
	local a, b = normalize_parameters(a, b)
	a, b = a:abs(), b:abs()

	if a:isZero() then return b end
	if b:isZero() then return a end

	local shift = 0
	while a:isEven() and b:isEven() do
		a = div2(a)
		b = div2(b)
		shift = shift + 1
	end

	while a:isEven() do a = div2(a) end

	while not b:isZero() do
		while b:isEven() do b = div2(b) end

		if a > b then
			a, b = b, a
		end

		b = b - a
	end

	return mulPow2(a, shift)
end

-- Finds the Lowest Common Multiple of the hello_mpz number and other (hello_mpz number).
function hello_mpz.LCM(a, b)
	a, b = normalize_parameters(a, b)

	if a:isZero() or b:isZero() then
		return ZERO
	end

	local gcd_val = hello_mpz.GCD(a, b)
	local a_div_gcd = a / gcd_val
	local lcm_val = a_div_gcd * b

	lcm_val.sign = 1
	return lcm_val
end

----------------------------------------------------
-- Probability functions.
----------------------------------------------------

-- Returns the result of the combination of n and r. (both hello_mpz numbers or string)
function hello_mpz.comb(n, r)
	n, r = normalize_parameters(n, r)

	-- r < 0 or r > n -> 0
	if r < ZERO or r > n then
		return ZERO
	end

	-- min(r, n-r) optimization
	local nr = n - r
	if nr < r then r = nr end

	local result = ONE:clone()
	local i = ONE:clone()

	while i <= r do
		-- result *= (n - i + 1)
		result = result * (n - i + ONE)

		-- result //= i
		result = result // i

		i = i + ONE
	end

	return result
end

-- Returns the result of the permutation of n and r. (both hello_mpz numbers or string)
function hello_mpz.perm(n, r)
	n, r = normalize_parameters(n, r)

	-- invalid cases
	if r < ONE or r > n then
		return ZERO
	end

	local result = ONE
	local i = ZERO:clone()

	while i < r do
		result = result * (n - i)
		i = i + ONE
	end

	return result
end

-- Generates a random integer between the min - max range.
function hello_mpz.random(min, max)
	min, max = normalize_parameters(min, max)
	checkhello_mpzType(min, "min")
	checkhello_mpzType(max, "max")
	assert(max >= min, "Max must be >= min")

	if min == max then
		return min
	end

	local diff = max - min + ONE
	local nLimbs = #diff.limbs
	local limbs = table_create(nLimbs)

	local candidate
	repeat
		for i = 1, nLimbs-1 do
			limbs[i] = math_random(0, BASE-1)
		end
		limbs[nLimbs] = math_random(0, diff.limbs[nLimbs]-1)
		candidate = make(1, limbs)
	until cmpAbs(candidate, diff) < 0

	return min + candidate
end

----------------------------------------------------
-- Factorials
----------------------------------------------------
-- Exact multiplication for factorials
local function factorialMul(a, b)
	-- ensure limbs exist
	if not a.limbs or #a.limbs == 0 then a.limbs = {1} end
	if not b.limbs or #b.limbs == 0 then b.limbs = {1} end

	-- fast path for small numbers
	if #a.limbs <= 3 and #b.limbs <= 3 then
		local limbs = schoolbookMulLimbs(a.limbs, b.limbs)
		normalize_limbs(limbs)
		return make(a.sign * b.sign, limbs)
	end

	-- Karatsuba path
	local limbs = karatsubaMulLimbs(a.limbs, b.limbs)
	normalize_limbs(limbs)
	return make(a.sign * b.sign, limbs)
end

-- Binary splitting product range
local function productRange(a, b)
	if a > b then return ONE end
	if a == b then return a:clone() end
	local mid = (a + b) // TWO
	return factorialMul(productRange(a, mid), productRange(mid + ONE, b))
end

local function productRangeStep(a, b, step)
	-- base case: empty range
	if a > b then 
		return ONE 
	end

	-- base case: only one element
	if a == b then 
		return a:clone() 
	end

	-- base case: only two elements (distance <= step)
	if a + step > b then
		return factorialMul(a, b)
	end

	-- compute midpoint in sequence
	local count = (b - a) // step  -- number of steps
	local mid = a + ((count // TWO) * step)

	-- recursive binary split
	return factorialMul(
		productRangeStep(a, mid, step),
		productRangeStep(mid + step, b, step)
	)
end

-- Returns n! (factorial) as a hello_mpz number.
function hello_mpz:factorial()
	if self:isZero() or self == ONE then
		return ONE
	end
	return productRange(ONE:clone(), self)
end

-- Returns n!! (double factorial) as a hello_mpz number.
function hello_mpz:doubleFactorial()
	if self:isZero() or self == ONE then
		return ONE
	end

	local start = self:isEven() and TWO:clone() or ONE:clone()

	return productRangeStep(start, self, TWO)
end

-- Returns n!_k (multi-factorial) with step k as a hello_mpz number.
function hello_mpz:multiFactorial(step)
	step = step or ONE:clone()  -- default step
	step = normalize_parameters(step)
	checkhello_mpzType(step, "Step")

	-- clone self to avoid modifying original
	local result = self:clone()
	local current = self:clone()

	-- Loop safely until current <= 0
	while true do
		current = current - step
		if current <= ZERO then
			break
		end
		result = result * current
	end

	return result
end

----------------------------------------------------
-- For Loop Support
----------------------------------------------------
-- Iterator handler for all for loop functions.
local function makeIterator(a, b, step, exclusive)
	-- Normalize b
	a, b = normalize_parameters(a, b)

	-- Normalize and type check positive step
	if step == nil then
		step = ONE:clone()
	elseif type(step) == "string" then
		step = hello_mpz.fromString(step)
	end

	checkhello_mpzType(step, "Step")

	assert(step > ZERO, "Step must be positive")

	-- Determine direction
	local forward = a < b

	-- Adjust step sign automatically
	local s = forward and step or -step

	-- Iterator function
	local function iter(_, current)
		local nextValue = current + s

		if forward then
			if exclusive and nextValue >= b then return nil end
			if not exclusive and nextValue > b then return nil end
		else
			if exclusive and nextValue <= b then return nil end
			if not exclusive and nextValue < b then return nil end
		end

		return nextValue
	end

	-- For numeric step, initial = start - step
	local initial = a - s

	return iter, nil, initial
end

-- Normalizes b and step for iteration
local function normalizeRangeParams(a, b, step, callerName)
	-- Normalize a and b
	a, b = normalize_parameters(a, b)

	-- Normalize step (must become hello_mpz)
	if step == nil then
		step = ONE:clone()
	else
		step = normalize_parameters(step)
		checkhello_mpzType(step, "Step")
	end

	-- Validate step
	assert(step > ZERO, "Step must be positive")

	return b, step
end

-- Creates a standalone iterator from 'a' to 'b', optionally using a numeric, string, or object step.
-- The 'exclusive' boolean determines whether 'b' is included in the iteration.
function hello_mpz.range(a, b, step, exclusive)
	return makeIterator(a, b, step, exclusive)
end

-- Iterates from the current hello_mpz value to 'b' inclusively using a numeric, string, or object step.
-- Step must be positive if numeric. Throws an error if start > b.
function hello_mpz:to(b, step)
	b, step = normalizeRangeParams(self, b, step, "to")

	assert(self <= b, "Start value must be <= end value")

	return makeIterator(self, b, step, false)
end

-- Iterates from the current hello_mpz value to 'b' exclusively using a numeric, string, or object step.
-- Step must be positive if numeric. Throws an error if start > b.
function hello_mpz:toExclusive(b, step)
	b, step = normalizeRangeParams(self, b, step, "toExclusive")

	assert(self <= b, "Start value must be <= end value")

	return makeIterator(self, b, step, true)
end

-- Iterates from the current hello_mpz value down to 'b' inclusively using a numeric, string, or object step.
-- Step must be positive if numeric. Throws an error if start < b. Numeric step is negated internally.
function hello_mpz:downTo(b, step)
	b, step = normalizeRangeParams(self, b, step, "downTo")

	assert(self >= b, "Start value must be >= end value")

	return makeIterator(self, b, step, false)
end

-- Iterates from the current hello_mpz value down to 'b' exclusively using a numeric, string, or object step.
-- Step must be positive if numeric. Throws an error if start < b. Numeric step is negated internally.
function hello_mpz:downToExclusive(b, step)
	b, step = normalizeRangeParams(self, b, step, "downToExclusive")

	assert(self >= b, "Start value must be >= end value")

	return makeIterator(self, b, step, true)
end

----------------------------------------------------
-- Polishing & Other
----------------------------------------------------

-- function that handles both strings and numbers.
local function fromAny(n)
	local n_type = type(n)
	assert(n_type == "number" or n_type == "string",
		"Expected string or number, got "..n_type)
	if n_type == "number" then
		checkFiniteNumber(n,
			"Invalid number: cannot construct hello_mpz integer from "..tostring(n)..", convert the input in string first")
		return hello_mpz.fromNumber(n)
	end
	return hello_mpz.fromString(n)
end

-- Constructs the hello_mpz number with optional leading + or - from the given string or number.
-- For using numbers, it can lose precision.
hello_mpz.new = fromAny

-- make the table a callable function
setmetatable(hello_mpz, {
	__call = function(_, x)
		return fromAny(x)
	end,
})

return hello_mpz