local hello_mpz = require(script.Parent.Parent.hello_mpz) -- core

local hello_evaluator = {}

----------------------------------------------------
-- Caching
----------------------------------------------------
local table_insert = table.insert
local table_remove = table.remove

local type = type
local ipairs = ipairs
----------------------------------------------------
-- Parsing Operator Identifier
----------------------------------------------------
-- Operator precedence table
-- Higher number = higher precedence
local precedence = {
	["+"] = 1, ["-"] = 1,
	["*"] = 2, ["/"] = 2,
	["u-"] = 3,
	["^"] = 4
}

-- Right associative operators (right first order instead of left first order)
local rightAssociative = {
	["^"] = true,
	["u-"] = true
}
-- function attachment
local functions = { sqrt = true }

----------------------------------------------------
-- Evaluator System
----------------------------------------------------
-- Checks whether a taken represents a numeric literal
local function isNumberToken(t)
	return type(t) == "string" and t:match("^%d+%.?%d*$") ~= nil
end

-- Converts Infix to Postfix using Shunting Yard Algorithm
local function toPostfix(tokens)
	local output = {} -- final postfix output
	local stack = {} -- operator stack
	
	for _, token in ipairs(tokens) do
		-- Numbers go directly to output
		if isNumberToken(token) then
			table_insert(output, token)
			
		-- Functions are pushed to the operator stack
		elseif functions[token] then
			table_insert(stack, token)
			
		-- Operators
		elseif precedence[token] then
			-- Pop operators from stack while they have 
			-- higher precedence or equal precedence if left-associative
			while #stack > 0 and precedence[stack[#stack]] and
				((not rightAssociative[token] and precedence[stack[#stack]] >= precedence[token]) or
					(rightAssociative[token] and precedence[stack[#stack]] > precedence[token])) do
				table_insert(output, table_remove(stack))
			end
			table_insert(stack, token)
			
		-- Opening brackets/paranthesis always goes on stack
		elseif token == "(" then
			table_insert(stack, token)
			
		-- Closing parenthesis:
		-- pop until matching "(" is found
		elseif token == ")" then
			while #stack > 0 and stack[#stack] ~= "(" do
				table_insert(output, table_remove(stack))
			end
			table_remove(stack) -- remove "("
			
			-- If a function was waiting before the "("
			-- pop it onto output
			if #stack > 0 and functions[stack[#stack]] then
				table_insert(output, table_remove(stack))
			end
		end
	end
	
	-- Drain remaining operators
	while #stack > 0 do
		table_insert(output, table_remove(stack))
	end
	
	return output
end

-- Postfix Evaluation
-- Evalutes a postfix (RPN) token stream
-- Arithmetic handled by hello_mpz's operator overload
local function evalPostfix(postfix)
	local stack = {}
	for _, token in ipairs(postfix) do
		-- Push to hello_mpz number when it is a numeric ltieral
		if isNumberToken(token) then
			table_insert(stack, hello_mpz.fromString(token))
			
		-- Binary operators
		elseif token == "+" then
			local b, a = table_remove(stack), table_remove(stack)
			table_insert(stack, a + b)
		elseif token == "-" then
			local b, a = table_remove(stack), table_remove(stack)
			table_insert(stack, a - b)
		elseif token == "*" then
			local b, a = table_remove(stack), table_remove(stack)
			table_insert(stack, a * b)
		elseif token == "/" then
			local b, a = table_remove(stack), table_remove(stack)
			table_insert(stack, a / b)
		elseif token == "^" then
			local b, a = table_remove(stack), table_remove(stack)
			table_insert(stack, a ^ b)
			
		-- Prefix function: integer square root
		elseif token == "sqrt" then
			local a = table_remove(stack)
			table_insert(stack, a:isqrt())
			
		-- Unary minus
		elseif token == "u-" then
			local a = table_remove(stack)
			table_insert(stack, -a)
		end
	end
	
	-- final result
	return stack[1]
end

-- Tokenizer function
-- Converts an input string into tokens
local function tokenize(expr)
	local tokens = {}
	local i = 1
	local len = #expr

	while i <= len do
		local c = expr:sub(i, i)

		-- Skip whitespace
		if c:match("%s") then
			i += 1

		-- Number literal (integer or decimal)
		elseif c:match("%d") or (c == "." and expr:sub(i+1,i+1):match("%d")) then
			local start = i
			i += 1
			while i <= len and expr:sub(i,i):match("[%d%.]") do
				i += 1
			end
			table_insert(tokens, expr:sub(start, i-1))

		-- Identifier / function name
		elseif c:match("%a") then
			local start = i
			i += 1
			while i <= len and expr:sub(i,i):match("%a") do
				i += 1
			end
			table_insert(tokens, expr:sub(start, i-1))

		-- Operators / parentheses
		elseif c:match("[%+%-%*/%^%(%)]") then
			table_insert(tokens, c)
			i += 1

		else
			error("Invalid character: " .. c)
		end
	end

	return tokens
end

-- Token Post-Processing
-- Handles unary minus detection and implicit multiplication insertion
local function processTokens(tokens)
	local result = {}

	local function isNumber(t)
		return tonumber(t) ~= nil
	end

	local function isFunction(t)
		return functions[t]
	end

	for _, token in ipairs(tokens) do
		local prev = result[#result]

		-- Unary minus
		if token == "-" then
			if not prev or precedence[prev] or prev == "(" then
				token = "u-"
			end
		end

		-- Implicit multiplication
		if prev then
			local prevIsNumber = isNumber(prev)
			local prevIsClose  = prev == ")"
			local tokenIsNumber = isNumber(token)
			local tokenIsOpen   = token == "("
			local tokenIsFunc   = isFunction(token)

			if (prevIsNumber or prevIsClose)
				and (tokenIsNumber or tokenIsOpen or tokenIsFunc) then
				table_insert(result, "*")
			end
		end

		table_insert(result, token)
	end

	return result
end

-- Evaluates an expression given by a string.
-- For example, "1+1" outputs 2
function hello_evaluator.evaluate(expr)
	local tokens = tokenize(expr)
	tokens = processTokens(tokens)
	local postfix = toPostfix(tokens)
	return hello_mpz.fromString(tostring(evalPostfix(postfix)))
end


return hello_evaluator