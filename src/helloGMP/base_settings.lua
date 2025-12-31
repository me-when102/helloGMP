local settings = {}

-- helloGMP settings
-- You will be able to modify / tune settings to change helloGMP's behaviour

-- set-based settings are always lower-case, otherwise error.

-- [[ CORE SETTINGS ]]
settings.BASE = 10^7 -- limb base (10^7 recommended, and results will likely change, so don't change this)
settings.MODE = "strict" -- parsing mode; options: strict, nonstrict

-- [[ FLOAT SETTINGS ]]
settings.DEFAULT_PRECISION = 256 -- in bits
settings.DEFAULT_DIGITS = 10 -- shows how many digits should it be displayed.
settings.FLOAT_DISPLAY_MODE = "fixed" -- float mode; options: fixed, scientific
settings.ROUNDING_MODE = "normal" -- rounding mode; options: normal, up, down (unsure if this is really used though)

-- DO NOT MODIFY PAST THIS POINT
--------------------------------------------------------------------------------------------
-- VALIDATION
local assert = assert

local function assert_valid(option, valid_set, label, opts)
	-- categorical check
	if valid_set then
		if not valid_set[option] then
			local valid_keys = {}
			for k in pairs(valid_set) do
				table.insert(valid_keys, k)
			end
			error(("Invalid %s: must be one of {%s}, got '%s'")
				:format(label, table.concat(valid_keys, ", "), tostring(option)), 2)
		end
	end

	-- numeric/range check
	if opts then
		if opts.type and type(option) ~= opts.type then
			error(("Invalid %s: must be a %s, got %s")
				:format(label, opts.type, type(option)), 2)
		end
		if opts.min and option < opts.min then
			error(("Invalid %s: must be >= %s, got %s")
				:format(label, opts.min, option), 2)
		end
		if opts.max and option > opts.max then
			error(("Invalid %s: must be <= %s, got %s")
				:format(label, opts.max, option), 2)
		end
		if opts.integer and option % 1 ~= 0 then
			error(("Invalid %s: must be an integer, got %s")
				:format(label, option), 2)
		end
	end
end

local function validate_settings(settings)
	-- MODE
	local valid_modes = { strict = true, nonstrict = true }
	assert_valid(settings.MODE, valid_modes, "MODE")

	-- ROUNDING MODE
	local valid_rounding_modes = { normal = true, up = true, down = true }
	assert_valid(settings.ROUNDING_MODE, valid_rounding_modes, "ROUNDING MODE")

	-- BASE
	assert_valid(settings.BASE, nil, "BASE", { type = "number", min = 10^3, integer = true })

	-- DEFAULT PRECISION
	assert_valid(settings.DEFAULT_PRECISION, nil, "DEFAULT PRECISION", { type = "number", min = 1, integer = true })
	
	-- FLOAT DISPLAY MODE
	local valid_float_modes = { scientific = true, fixed = true }
	assert_valid(settings.FLOAT_DISPLAY_MODE, valid_float_modes, "FLOAT MODE")
end

validate_settings(settings)
table.freeze(settings) -- read-only!!!

return settings