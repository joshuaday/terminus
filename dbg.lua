

local function log(...)
	io.stdout:write(...)
	io.stdout:write "\n"
end


return {
	log = log
}

