sdomain = 'eriko.one'      --set the domain name, set to IP if you do not have one
sport = 30080              --set the port to open
saddress = '45.79.193.124' --set the server IP
snusers = 1                --allow account creation
masterkey = 'enable69420'  --skip authentication for testing, change any letter in enable to disable this
csva = 0                   --always return modified csv format (disable most 3rd party clients)
maxdelay = 2               --number of seconds allowed to login before 2fpass is reset, set this to a whole number

------------------------------------------
--do not change anything below this line--
------------------------------------------
sversion = '0.7'
print('The current server software version is ' .. sversion .. '\nClients older than this will be unable to connect, please consider updating to the latest available version.')
http = require('http')
json = require('deps/json.json')

function splittotable(str, splt)
	local tmp = {}
	local cleaner = {
		{ splt, "\n" },
	}
	for i=1, #cleaner do
		local cleans = cleaner[i]
		str = string.gsub( str, cleans[1], cleans[2] )
	end
	strlist = {}
	for line in str:gmatch("([^\n]*)\n?") do
	   	table.insert(strlist, line)
	end
	return strlist
end
codes = {
	[1] = 'Error 1: No login requested',
	[2] = 'Error 2: No request specified',
	[3] = 'Error 3: Request not supported',
	[4] = 'Error 4: Login failed',
	[5] = 'Error 5: User does not exist',
	[6] = 'Error 6: New users are not allowed',
	[7] = 'Error 7: Bad 2fpass',
	[8] = 'Error 8: No message content or target',
	[9] = 'Error 9: Target does not exist',
}
function perror(num)
	print(codes[num])
end

--https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
char_to_hex = function(c)
	return string.format("%%%02X", string.byte(c))
end
function urlencode(url)
	if url == nil then
		return
	end
	url = url:gsub("\n", "\r\n")
	str = string.gsub(str, "([^%w _%%%-%.~])", char_to_hex)
	url = url:gsub(" ", "+")
	return url
end
hex_to_char = function(x)
	return string.char(tonumber(x, 16))
end
urldecode = function(url)
	if url == nil then
		return
	end
	url = url:gsub("+", " ")
	url = url:gsub("%%(%x%x)", hex_to_char)
	return url
end

defaulttbl = 'Eriko (system),Eriko (system),Hey! Welcome to Eriko Chat!\\nYour home address is http://' .. sdomain .. ':' .. sport .. ' use this during login otherwise you will be unable to access your account!\\nThe default home address is http://eriko.one:30080\\nYou cannot communicate with other homes at the moment. Please register with other homes if you wish to use them.,'

--/login/[user]/[pass]/[2fpass]/[format]/[type]/[target]/[content]/
--|  2  |   3  |   4  |  5     |   6    |  7   |   8    |    9    |
--                              json     update
--                              csv      post
http.createServer(function (req, res)
	notrequest = 0
	loggedin = 0
	print(req.method .. ' ' .. req.url)
	if (req.method == 'GET') then
		urltbl = splittotable(req.url, '/')
		if (req.url == '/') or (#urltbl < 6) then --not a message request
			notrequest = 1
		end
		if (csva == 1) then
			urltbl[6] = 'csv'
		end
		if (urltbl[2] == 'login') then
			if (urltbl[3]) and (urltbl[4]) and (urltbl[5]) then
				file = io.open('./users/' .. urltbl[3], 'r')
				if not (file) then
					perror(5)
					if (snusers == 1) then
						file = io.open('./users/' .. urltbl[3], 'w')
						file:write(urltbl[4])
						file:close()
						file = io.open('./users/' .. urltbl[3] .. '.key', 'w')
						file:write(os.time() + maxdelay)
						file:close()
						file = io.open('./users/' .. urltbl[3] .. '.csv', 'w')
						file:write(defaulttbl)
						file:close()
						file = io.open('./users/' .. urltbl[3], 'r')
					else
						perror(6)
						body = {
							result = 'fail',
							reason = 'account creation not allowed',
							version = sversion,
						}
						res:setHeader("Content-Type", "text/plain")
						if (urltbl[6] == 'csv') then
							csvb = body.result .. ',' .. body.reason .. ',' .. body.version .. ',eof,nothing,nothing,nothing,'
							res:setHeader("Content-Length", #csvb)
							res:finish(csvb)
						else
							res:setHeader("Content-Length", #json.encode(body))
							res:finish(json.encode(body))
						end
						return
					end
				end
				password = file:read('*a')
				file:close()
				if not (password == urltbl[4]) then
					perror(4)
					body = {
						result = 'fail',
						reason = 'invalid password',
						version = sversion,
					}
					res:setHeader("Content-Type", "text/plain")
					if (urltbl[6] == 'csv') then
						csvb = body.result .. ',' .. body.reason .. ',' .. body.version .. ',eof,nothing,nothing,nothing,'
						res:setHeader("Content-Length", #csvb)
						res:finish(csvb)
					else
						res:setHeader("Content-Length", #json.encode(body))
						res:finish(json.encode(body))
					end
				else
					file = io.open('./users/' .. urltbl[3] .. '.key', 'r')
					userkey = file:read('*a')
					file:close()
					if (os.time() > tonumber(userkey)) then
						file = io.open('./users/' .. urltbl[3] .. '.key', 'w')
						file:write(os.time() + maxdelay)
						file:close()
						file = io.open('./users/' .. urltbl[3] .. '.key', 'r')
						userkey = file:read('*a')
						file:close()
					end
					if (tonumber(urltbl[5]) == (tonumber(userkey) / 200) + (#urltbl[3] * 653987 + #urltbl[4] * 6453765) + (tonumber(userkey) % 69)) or (urltbl[5] == masterkey) and (masterkey:match('enable')) then
						loggedin = 1
						body = {
							result = 'success',
							version = sversion,
						}
						if (urltbl[7]) then
							if (urltbl[7] == 'update') then
								body.messages = {}
								for line in io.lines("./users/" .. urltbl[3] .. ".csv") do
									local from, to, contents = line:match("%s*(.-),%s*(.-),%s*(.-),")
									body.messages[#body.messages + 1] = {from = from, contents = contents, to = to,}
								end
							elseif (urltbl[7] == 'post') then
								if (urltbl[8]) and (urltbl[9]) then
									file = io.open('./users/' .. urltbl[8], 'r')
									if not (file) then
										perror(9)
										body = {
											result = 'fail',
											reason = 'invalid target',
											version = sversion,
										}
										res:setHeader("Content-Type", "text/plain")
										if (urltbl[6] == 'csv') then
											csvb = body.result .. ',' .. body.reason .. ',' .. body.version .. ',eof,nothing,nothing,nothing,'
											res:setHeader("Content-Length", #csvb)
											res:finish(csvb)
										else
											res:setHeader("Content-Length", #json.encode(body))
											res:finish(json.encode(body))
										end
										return
									else
										file:close()
									end
									file = io.open('./users/' .. urltbl[8] .. '.csv', 'a+')
									file:write('\n' .. urltbl[3] .. ',' .. urltbl[8] .. ',' .. urldecode(urltbl[9]) .. ',')
									file:close()
									file = io.open('./users/' .. urltbl[3] .. '.csv', 'a+')
									file:write('\n' .. urltbl[3] .. ',' .. urltbl[8] .. ',' .. urldecode(urltbl[9]) .. ',')
									file:close()
								else
									perror(8)
								end
							else
								perror(3)
							end
						else
							perror(2)
						end
						res:setHeader("Content-Type", "text/plain")
						if (urltbl[6] == 'csv') then
							file = io.open("./users/" .. urltbl[3] .. ".csv", "r")
							csvc = file:read("*a")
							csvb = body.result .. ',' .. body.version .. ',eof,' .. csvc
							file:close()
							res:setHeader("Content-Length", #csvb)
							res:finish(csvb)
						else
							res:setHeader("Content-Length", #json.encode(body))
							res:finish(json.encode(body))
						end
					else
						perror(7)
						body = {
							result = 'fail',
							reason = 'invalid 2fpass',
							version = sversion,
							time = userkey,
						}
						res:setHeader("Content-Type", "text/plain")
						if (urltbl[6] == 'csv') then
							csvb = body.result .. ',' .. body.reason .. ',' .. body.version .. ',' .. body.time .. ',eof,nothing,nothing,nothing,'
							res:setHeader("Content-Length", #csvb)
							res:finish(csvb)
						else
							res:setHeader("Content-Length", #json.encode(body))
							res:finish(json.encode(body))
						end
					end
				end
			end
		else
			notrequest = 1
		end
		if (notrequest == 1) then
			perror(1)
			body = "Service currently unavailable. Check back later."
			res:setHeader("Content-Type", "text/plain")
			res:setHeader("Content-Length", #body)
			res:finish(body)
		end
	end
end):listen(sport, saddress)

print('Server running at http://' .. sdomain .. ':' .. sport)