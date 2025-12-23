-- helloGMP Complex module

local hello_mpz = require(script.Parent.Parent.hello_mpz) -- core

local hello_complex = {}
hello_complex.__index = hello_complex

----------------------------------------------------
-- Constructor
----------------------------------------------------

-- Constructs a helloGMP complex number from real and imaginary parts.
function hello_complex.new(real, imag)
	-- Wrap numbers in hello_mpz if they aren't already
	if getmetatable(real) ~= hello_mpz then real = hello_mpz.fromString(real) end
	if getmetatable(imag) ~= hello_mpz then imag = hello_mpz.fromString(imag) end

	return setmetatable({real = real, imag = imag}, hello_complex)
end

hello_complex.fromNumbers = function(real, imag)
	return hello_complex.new(hello_mpz.fromString(tostring(real)), hello_mpz.fromString(tostring(imag)))
end

----------------------------------------------------
-- Arithmetic
----------------------------------------------------

-- Adds two complex numbers.
function hello_complex:__add(other)
	return hello_complex.new(
		self.real + other.real,
		self.imag + other.imag
	)
end

-- Subtracts one complex number from another.
function hello_complex:__sub(other)
	return hello_complex.new(
		self.real - other.real,
		self.imag - other.imag
	)
end

-- Multiplies two complex numbers.
function hello_complex:__mul(other)
	local a, b = self.real, self.imag
	local c, d = other.real, other.imag
	return hello_complex.new(
		a * c - b * d,
		a * d + b * c
	)
end

-- Divides one complex number by another. (can only return integer)
function hello_complex:__div(other)
	local a, b = self.real, self.imag
	local c, d = other.real, other.imag
	local denom = c * c + d * d
	return hello_complex.new(
		(a * c + b * d) / denom,
		(b * c - a * d) / denom
	)
end

----------------------------------------------------
-- Other Complex-Exclusive Functions
----------------------------------------------------

-- Returns the complex conjugate (flips the imaginary part's sign).
function hello_complex:conjugate()
	return hello_complex.new(self.real, -self.imag)
end

-- Returns the magnitude (length) of the complex number. Can only return integer.
function hello_complex:magnitude()
	return (self.real * self.real + self.imag * self.imag):isqrt()
end

-- Rotates the complex number by multiples of 90 degrees in-place.
-- n = number of 90° steps (positive = counter-clockwise)
function hello_complex:rotate90(n)
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
function hello_complex:toString()
	return tostring(self.real) .. " + " .. tostring(self.imag) .. "i"
end

-- Converts the complex number to a human-readable string.
hello_complex.__tostring = hello_complex.toString

return hello_complex