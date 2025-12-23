-- helloGMP DateTime module

local hello_mpz = require(script.Parent.Parent.hello_mpz) -- core

local hello_datetime = {}
hello_datetime.__index = hello_datetime

-- cache globals
local tonumber = tonumber
local tostring = tostring
local table_unpack = table.unpack

-- Cached hello_mpz constants (avoid re-creating them)
local C0   = hello_mpz.fromString("0")
local C1   = hello_mpz.fromString("1")
local C2   = hello_mpz.fromString("2")
local C3   = hello_mpz.fromString("3")
local C4   = hello_mpz.fromString("4")
local C5   = hello_mpz.fromString("5")
local C7   = hello_mpz.fromString("7")
local C10  = hello_mpz.fromString("10")
local C12  = hello_mpz.fromString("12")
local C24  = hello_mpz.fromString("24")
local C60  = hello_mpz.fromString("60")
local C100 = hello_mpz.fromString("100")
local C153 = hello_mpz.fromString("153")
local C365 = hello_mpz.fromString("365")
local C400 = hello_mpz.fromString("400")
local C1460  = hello_mpz.fromString("1460")
local C1461  = hello_mpz.fromString("1461")
local C36524 = hello_mpz.fromString("36524")
local C146096 = hello_mpz.fromString("146096")
local C146097 = hello_mpz.fromString("146097")
local C719468 = hello_mpz.fromString("719468")

local SECS_PER_DAY  = hello_mpz.fromString("86400")
local SECS_PER_HOUR = hello_mpz.fromString("3600")
local SECS_PER_MIN  = hello_mpz.fromString("60")

-- month lengths (small Lua table: numbers)
local MONTH_LEN = {31,28,31,30,31,30,31,31,30,31,30,31}

----------------------------------------------------
-- Timezone Management
----------------------------------------------------
hello_datetime._timezoneOffset = hello_mpz.fromString("0") -- seconds

-- Sets the timezone to offset (seconds). This is a global setting.
function hello_datetime:setTimezone(offset)
	if type(offset) == "number" then
		self._timezoneOffset = hello_mpz.fromString(tostring(offset))
	elseif getmetatable(offset) == hello_mpz then
		self._timezoneOffset = offset
	else
		error("Timezone offset must be a number or hello_mpz")
	end
end

-- Gets the timezone setting.
function hello_datetime:getTimezone()
	return self._timezoneOffset
end

----------------------------------------------------
-- Leap year (hello_mpz-only)
----------------------------------------------------

-- checks if hello_datetime year is a leap year.
function hello_datetime.isLeapYear(year)
	-- year is hello_mpz
	local mod4   = year:mod(C4)
	local mod100 = year:mod(C100)
	local mod400 = year:mod(C400)

	return mod4:eq(C0) and (not mod100:eq(C0) or mod400:eq(C0))
end

----------------------------------------------------
-- Helpers
----------------------------------------------------
local function daysInMonth(year, month) -- month is hello_mpz (small)
	local idx = tonumber(month:toString())
	local lengths = { table_unpack(MONTH_LEN) }
	if hello_datetime.isLeapYear(year) then lengths[2] = 29 end
	return lengths[idx]
end

----------------------------------------------------
-- Computers
-- (micro-optimised: use cached constants and locals)
----------------------------------------------------
local function computeFieldsFromEpoch(epoch)
	-- locals for speed
	local days = epoch // SECS_PER_DAY
	local rem  = epoch % SECS_PER_DAY

	-- normalize remainder to [0..86399]
	if rem.sign < 0 then
		rem = rem + SECS_PER_DAY
		days = days - C1
	end

	-- shift
	local z = days + C719468

	-- era (floor division for negative z handled)
	local era
	if z.sign >= 0 then
		era = z // C146097
	else
		era = (z - C146096) // C146097
	end

	local doe = z - era * C146097 -- day of era [0..146096]

	-- yoe calculation (use cached constants)
	local yoe = (doe - (doe // C1460) + (doe // C36524) - (doe // C146096)) // C365
	local doy = doe - (yoe * C365 + yoe // C4 - yoe // C100 + yoe // C400)
	local mp  = (doy * C5 + C2) // C153

	local day   = doy - (mp * C153 + C2) // C5 + C1
	local month = mp + C3 - ((mp // C10) * C12)
	local year  = era * C400 + yoe + (mp // C10)

	-- hours/minutes/seconds
	local hour   = rem // SECS_PER_HOUR
	rem          = rem % SECS_PER_HOUR
	local minute = rem // SECS_PER_MIN
	local second = rem % SECS_PER_MIN

	return year, month, day, hour, minute, second
end

local function computeEpochFromFields(year, month, day, hour, minute, second)
	-- Month shift (March = 0)
	local yAdj = year
	local mAdj = month - C3
	if mAdj.sign < 0 then
		mAdj = mAdj + C12
		yAdj = yAdj - C1
	end

	local days = C0
	days = days + yAdj * C365
	days = days + yAdj // C4 - yAdj // C100 + yAdj // C400
	days = days + (mAdj * C153 + C2) // C5
	days = days + (day - C1)

	-- shift origin to 1970-01-01
	days = days - C719468

	-- total seconds
	local epoch = days * SECS_PER_DAY + hour * SECS_PER_HOUR + minute * SECS_PER_MIN + second
	return epoch
end

----------------------------------------------------
-- Constructors
----------------------------------------------------
local function make(epoch, year, month, day, hour, minute, second)
	local self = setmetatable({}, hello_datetime)
	self.epoch  = epoch
	self.year   = year
	self.month  = month
	self.day    = day
	self.hour   = hour
	self.minute = minute
	self.second = second
	return self
end

-- Creates hello_datetime object from epoch value.
-- Is not affected by timezone offset.
function hello_datetime.fromEpoch(epoch)
	local year, month, day, hour, minute, second = computeFieldsFromEpoch(epoch)
	return make(epoch, year, month, day, hour, minute, second)
end

-- Creates hello_datetime object from fields. (year, month, day, hour, minute, second)
-- Is not affected by timezone offset.
function hello_datetime.fromFields(year, month, day, hour, minute, second)
	local epoch = computeEpochFromFields(year, month, day, hour, minute, second)
	return make(epoch, year, month, day, hour, minute, second)
end

----------------------------------------------------
-- Add / Subtract
----------------------------------------------------

-- Adds two hello_datetime objects based on epoch value.
function hello_datetime:add(other)
	return hello_datetime.fromEpoch(self.epoch + other.epoch)
end

-- Subtracts two hello_datetime objects based on epoch value.
function hello_datetime:sub(other)
	return hello_datetime.fromEpoch(self.epoch - other.epoch)
end

----------------------------------------------------
-- Formatting Helpers
----------------------------------------------------
-- weekdayNames indexed 1..7 (Sunday=1)
local weekdayNames = {
	"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"
}

local monthNames = {
	"January","February","March","April","May","June",
	"July","August","September","October","November","December"
}

local function computeWeekday(epoch)
	-- days since epoch
	local days = epoch // SECS_PER_DAY
	local wd = (days + C4) % C7
	-- normalize to non-negative remainder
	if wd.sign < 0 then wd = wd + C7 end
	-- convert to 1..7 index
	return tonumber(wd:toString()) + 1
end

-- Converts the UTC time with the timezone offset applied in hello_datetime.
function hello_datetime:withTimezone()
	if hello_datetime._timezoneOffset == C0 then
		return self -- no offset, return self
	end
	
	local adjustedEpoch = self.epoch + hello_datetime._timezoneOffset
	local year, month, day, hour, minute, second = computeFieldsFromEpoch(adjustedEpoch)
	return make(adjustedEpoch, year, month, day, hour, minute, second)
end

----------------------------------------------------
-- Formatters (micro-optimised)
----------------------------------------------------
-- Pads a year (hello_mpz) to 4 digits, handling negatives
local function padYear(year)
	if year < hello_mpz.fromString("0") then
		return string.format("-%04d", -year:toString())  -- negative years
	else
		return string.format("%04d", year:toString())   -- positive years
	end
end

local function pad2_from_string(s)
	-- s is decimal string without sign; s may be multi-digit for years etc
	if #s == 1 then return "0" .. s end
	return s
end

-- Formats the hello_datetime object to ISO formatting.
function hello_datetime:toISO()
	-- avoid tonumber conversions when possible: use :toString() directly and pad by length
	self = self:withTimezone() -- convert with timezone
	
	local yStr = padYear(self.year)
	local mStr = pad2_from_string(self.month:toString())
	local dStr = pad2_from_string(self.day:toString())
	local hStr = pad2_from_string(self.hour:toString())
	local minStr = pad2_from_string(self.minute:toString())
	local sStr = pad2_from_string(self.second:toString())

	return table.concat({ yStr, "-", mStr, "-", dStr, "T", hStr, ":", minStr, ":", sStr, "Z" })
end

-- Formats the hello_datetime object to human-readable format.
function hello_datetime:toHuman()
	self = self:withTimezone() -- convert with timezone
	
	local wd = computeWeekday(self.epoch)
	local weekday = weekdayNames[wd] or "Unknown"
	local month = monthNames[tonumber(self.month:toString())] or "Unknown"

	-- year string (BCE handling)
	local yearNum = self.year
	local yearStr
	if yearNum <= C0 then
		yearStr = ((-yearNum + C1):toString()) .. " BCE"
	else
		yearStr = yearNum:toString()
	end

	-- build human string
	local dayStr = pad2_from_string(self.day:toString())
	local hStr = pad2_from_string(self.hour:toString())
	local mStr = pad2_from_string(self.minute:toString())
	local sStr = pad2_from_string(self.second:toString())

	return string.format("%s, %s %s %s %s:%s:%s",
		weekday, dayStr, month, yearStr, hStr, mStr, sStr)
end

-- Formats the hello_datetime object to Unix seconds.
function hello_datetime:toUnixSeconds()
	return tonumber(self.epoch:toString())
end

----------------------------------------------------
-- Custom Formatter (micro-optimised)
----------------------------------------------------
-- 12-hour conversion helper (returns strings)
local function to12Hour(hour, minute, second)
	local h = tonumber(hour)
	local m = tonumber(minute)
	local s = tonumber(second)
	local ampm = "AM"

	if h == 0 then
		h = 12
		ampm = "AM"
	elseif h == 12 then
		ampm = "PM"
	elseif h > 12 then
		h = h - 12
		ampm = "PM"
	end

	return string.format("%02d", h), ampm, string.format("%02d", m), string.format("%02d", s)
end

-- Short month and weekday names
local monthShort = {
	[1]="Jan", [2]="Feb", [3]="Mar", [4]="Apr", [5]="May", [6]="Jun",
	[7]="Jul", [8]="Aug", [9]="Sep", [10]="Oct", [11]="Nov", [12]="Dec"
}

local weekdayShort = {
	[1]="Sun", [2]="Mon", [3]="Tue", [4]="Wed", [5]="Thu", [6]="Fri", [7]="Sat"
}

-- Helper for ordinal day
local function ordinalDay(day)
	local d = tonumber(day)
	local suffix = "th"
	if d % 10 == 1 and d % 100 ~= 11 then
		suffix = "st"
	elseif d % 10 == 2 and d % 100 ~= 12 then
		suffix = "nd"
	elseif d % 10 == 3 and d % 100 ~= 13 then
		suffix = "rd"
	end
	return tostring(d) .. suffix
end

-- Formats the hello_datetime object to the following pattern (string):
-- For the following examples: Thursday 0005/3/1 1:21.25 PM UTC
-- YYYY = Year. EG: YYYY = 5
-- yyyy = Padded year. EG: yyyy = 0005
-- YY = Two-digit year. EG: 05
-- MM = Month. EG: MM = 3
-- DD = Day. EG: DD = 1
-- DDO = Ordinal day. EG: DDO = 1st
-- HH = 24-hour. EG: HH = 13
-- hh = 12-hour. EG: hh = 1
-- tt = AM/PM. EG: tt = PM
-- mm = Minutes. EG: 21
-- SS = Seconds. EG: 25
-- MN = Month name. EG: MN = March
-- MN3 = Short month name. EG: MN3 = Mar
-- WD = Weekday. EG: Thursday
-- WD3 = Short weekday. EG: Thu
-- EPOCH = Epoch time.
-- UNIX = Unix time.
function hello_datetime:format(pattern)
	self = self:withTimezone() -- convert with timezone
	
	local yearStr   = self.year:toString()
	local monthStr  = self.month:toString()
	local dayStr    = self.day:toString()
	local hourStr   = self.hour:toString()
	local minStr    = self.minute:toString()
	local secStr    = self.second:toString()

	local monthNum   = tonumber(monthStr)
	local weekdayNum = tonumber(self.weekday)

	-- 12-hour clock
	local h12, ampm, minStr, secStr = to12Hour(hourStr, minStr, secStr)
	
	local replacements = {
		["YYYY"] = yearStr,
		["yyyy"] = padYear(self.year),
		["YY"]   = string.sub(yearStr, -2),

		["MM"]   = string.format("%02d", monthNum),
		["DD"]   = string.format("%02d", tonumber(dayStr)),
		["DDO"]  = ordinalDay(dayStr),

		["HH"]   = string.format("%02d", tonumber(hourStr)), -- 24h
		["hh"]   = h12,                                        -- 12h
		["tt"]   = ampm,                                       -- AM/PM

		["mm"]   = minStr,
		["SS"]   = secStr,

		["MN"]   = monthNames[monthNum] or "",
		["MN3"]  = monthShort[monthNum] or "",

		["WD"]   = weekdayNames[weekdayNum] or "",
		["WD3"]  = weekdayShort[weekdayNum] or "",

		["EPOCH"] = self.epoch:toString(),
		["UNIX"]  = tostring(self:toUnixSeconds())
	}

	-- Apply replacements (longest token first)
	local out = pattern
	local keys = {}
	for k in pairs(replacements) do table.insert(keys, k) end
	table.sort(keys, function(a, b) return #a > #b end)

	for _, token in ipairs(keys) do
		local val = replacements[token]
		local escaped = token:gsub("(%W)", "%%%1")
		out = out:gsub(escaped, val)
	end

	return out
end

return hello_datetime