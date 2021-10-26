sdomain = 'eriko.one'      --set the domain name, set to IP if you do not have one
sport = 30080              --set the port to open
saddress = '45.79.193.124' --set the server IP
snusers = 1                --allow account creation

------------------------------------------
--do not change anything below this line--
------------------------------------------
sversion = '0.5'
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
function decodeURI(s)
	if(s) then
		s = string.gsub(s, '%%(%x%x)', 
			function (hex) return string.char(tonumber(hex,16)) end )
	end
	return s
end

defaulttbl = 'Eriko (system),Eriko (system),Hey! Welcome to Eriko Chat!\\nYour home address is http://' .. sdomain .. ':' .. sport .. ' use this during login otherwise you will be unable to access your account!\\nThe default home address is http://eriko.one:30080\\nYou cannot communicate with other homes at the moment. Please register with other homes if you wish to use them.,'

--/login/[user]/[pass]/[2fpass]/[type]/[target]/[content]/
--|  2  |   3  |   4  |  5     |   6  |    7   |    8    |
--                     update
http.createServer(function (req, res)
	notrequest = 0
	loggedin = 0
	print(req.method .. ' ' .. req.url)
	if (req.method == 'GET') then
		urltbl = splittotable(req.url, '/')
		if (req.url == '/') or (#urltbl < 4) then --not a message request
			notrequest = 1
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
						file:write(os.time() + 10)
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
						res:setHeader("Content-Length", #json.encode(body))
						res:finish(json.encode(body))
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
					res:setHeader("Content-Length", #json.encode(body))
					res:finish(json.encode(body))
				else
					file = io.open('./users/' .. urltbl[3] .. '.key', 'r')
					userkey = file:read('*a')
					file:close()
					if (os.time() > tonumber(userkey)) then
						file = io.open('./users/' .. urltbl[3] .. '.key', 'w')
						file:write(os.time() + 10)
						file:close()
						file = io.open('./users/' .. urltbl[3] .. '.key', 'r')
						userkey = file:read('*a')
						file:close()
					end
					if (tonumber(urltbl[5]) == tonumber(userkey) + (#urltbl[3] * 653987 + #urltbl[4] * 6453765)) then
						loggedin = 1
						body = {
							result = 'success',
							version = sversion,
						}
						if (urltbl[6]) then
							if (urltbl[6] == 'update') then
								body.messages = {}
								for line in io.lines("./users/" .. urltbl[3] .. ".csv") do
									local from, to, contents = line:match("%s*(.-),%s*(.-),%s*(.-),")
									body.messages[#body.messages + 1] = {from = from, contents = contents, to = to,}
								end
							elseif (urltbl[6] == 'post') then
								if (urltbl[7]) and (urltbl[8]) then
									file = io.open('./users/' .. urltbl[7], 'r')
									if not (file) then
										perror(9)
										body = {
											result = 'fail',
											reason = 'invalid target',
											version = sversion,
										}
										res:setHeader("Content-Type", "text/plain")
										res:setHeader("Content-Length", #json.encode(body))
										res:finish(json.encode(body))
										return
									else
										file:close()
									end
									file = io.open('./users/' .. urltbl[7] .. '.csv', 'a+')
									file:write('\n' .. urltbl[3] .. ',' .. urltbl[3] .. ',' .. decodeURI(urltbl[8]) .. ',')
									file:close()
									file = io.open('./users/' .. urltbl[3] .. '.csv', 'a+')
									file:write('\n' .. urltbl[3] .. ',' .. urltbl[7] .. ',' .. decodeURI(urltbl[8]) .. ',')
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
						res:setHeader("Content-Length", #json.encode(body))
						res:finish(json.encode(body))
					else
						perror(7)
						body = {
							result = 'fail',
							reason = 'invalid 2fpass',
							version = sversion,
							time = userkey,
						}
						res:setHeader("Content-Type", "text/plain")
						res:setHeader("Content-Length", #json.encode(body))
						res:finish(json.encode(body))
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