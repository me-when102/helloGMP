-- helloGMP Complex module

local HGMP = require(script.Parent.Parent.hello_mpz) -- core

local HGMPComplex = {}
HGMPComplex.__index = HGMPComplex

----------------------------------------------------
-- Constructor
----------------------------------------------------

-- Constructs a helloGMP complex number from real and imaginary parts.
function HGMPComplex.new(real, imag)
	-- Wrap numbers in HGMP if they aren't already
	if getmetatable(real) ~= HGMP then real = HGMP.fromString(real) end
	if getmetatable(imag) ~= HGMP then imag = HGMP.fromString(imag) end

	return setmetatable({real = real, imag = imag}, HGMPComplex)
end

HGMPComplex.fromNumbers = function(real, imag)
	return HGMPComplex.new(HGMP.fromString(tostring(real)), HGMP.fromString(tostring(imag)))
end

----------------------------------------------------
-- Arithmetic
----------------------------------------------------

-- Adds two complex numbers.
function HGMPComplex:__add(other)
	return HGMPComplex.new(
		self.real + other.real,
		self.imag + other.imag
	)
end

-- Subtracts one complex number from another.
function HGMPComplex:__sub(other)
	return HGMPComplex.new(
		self.real - other.real,
		self.imag - other.imag
	)
end

-- Multiplies two complex numbers.
function HGMPComplex:__mul(other)
	local a, b = self.real, self.imag
	local c, d = other.real, other.imag
	return HGMPComplex.new(
		a * c - b * d,
		a * d + b * c
	)
end

-- Divides one complex number by another. (can only return integer)
function HGMPComplex:__div(other)
	local a, b = self.real, self.imag
	local c, d = other.real, other.imag
	local denom = c * c + d * d
	return HGMPComplex.new(
		(a * c + b * d) / denom,
		(b * c - a * d) / denom
	)
end

----------------------------------------------------
-- Other Complex-Exclusive Functions
----------------------------------------------------

-- Returns the complex conjugate (flips the imaginary part's sign).
function HGMPComplex:conjugate()
	return HGMPComplex.new(self.real, -self.imag)
end

-- Returns the magnitude (length) of the complex number. Can only return integer.
function HGMPComplex:magnitude()
	return (self.real * self.real + self.imag * self.imag):isqrt()
end

-- Rotates the complex number by multiples of 90 degrees in-place.
-- n = number of 90° steps (positive = counter-clockwise)
function HGMPComplex:rotate90(n)
	n = math.floor(n or 0) % 4
	local r, i = self.real, self.imag
	if n == 0 then
		-- no change
	elseif n == 1 then
		self.real, self.imag = -i, r
	elseif n == 2 then
		self.real, self.imag = -r, -i
	elseif n == 3 then
		self.real, self.imag = i, -r
	end
	return self
end
----------------------------------------------------
-- Representation
----------------------------------------------------

-- Converts the complex number to a human-readable string.
function HGMPComplex:toString()
	return tostring(self.real) .. " + " .. tostring(self.imag) .. "i"
end

-- Converts the complex number to a human-readable string.
HGMPComplex.__tostring = HGMPComplex.toString

return HGMPComplex