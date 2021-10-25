sdomain = 'eriko.one'
sport = 30080
saddress = '45.79.193.124'

print('name set to ' .. sdomain)
print('port opened on ' .. sport)
print('internal ip set to ' .. saddress .. ' (make this autmatic)')

sversion = '0.3'
print('the current server software version is ' .. sversion .. '\nClients older than this will be unable to connect, please consider updating to the latest available version.')
http = require('http')
print('http module loaded')
json = require('deps/json.json')
print('json module loaded')

function dump(o)
	if type(o) == 'table' then
		local s = '{ '
			for k,v in pairs(o) do
				if type(k) ~= 'number' then
					k = '"' .. k .. '"'
				end
				s = s .. '[' .. k .. '] = "' .. dump(v) .. '",'
			end
		return s .. '} '
	else
		return tostring(o)
	end
end
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

defaulttbl = 'Eriko (system),Hey! Welcome to Eriko Chat!\\nYour home address is http://' .. sdomain .. ':' .. sport .. ' use this during login otherwise you will be unable to access your account!\\nThe default home address is http://eriko.one:30080\\nYou cannot communicate with other homes at the moment. Please register with other homes if you wish to use them.,',

--/login/[user]/[pass]/[type]/
--|  2  |   3  |   4  |  5   |
--                     update
http.createServer(function (req, res)
	notrequest = 0
	loggedin = 0
	badrequest = 0
	print(req.method .. ' ' .. req.url)
	if (req.method == 'GET') then
		urltbl = splittotable(req.url, '/')
		if (req.url == '/') or (#urltbl < 4) then --not a message request
			notrequest = 1
		end
		if (urltbl[2] == 'login') then
			print('login requested')
			if (urltbl[3]) and (urltbl[4]) then
				file = io.open('./users/' .. urltbl[3], 'r')
				if not (file) then
					print('user ' .. urltbl[3] .. ' not found')
					file = io.open('./users/' .. urltbl[3], 'w')
					file:write(urltbl[4])
					file:close()
					file = io.open('./users/' .. urltbl[3] .. '.csv', 'w')
					file:write(defaulttbl)
					file:close()
					file = io.open('./users/' .. urltbl[3], 'r')
					print('user registered')
				end
				password = file:read('*a')
				file:close()
				if not (password == urltbl[4]) then
					print('login denied')
					body = {
						result = 'fail',
						reason = 'invalid password',
						version = sversion,
					}
					res:setHeader("Content-Type", "text/plain")
					res:setHeader("Content-Length", #json.encode(body))
					res:finish(json.encode(body))
				else
					print('login passed')
					loggedin = 1
					body = {
						result = 'success',
						version = sversion,
					}
					if (urltbl[5]) then
						if (urltbl[5] == 'update') then
							print('message update requested')
							body.messages = {}
							for line in io.lines("./users/" .. urltbl[3] .. ".csv") do
								local from, contents = line:match("%s*(.-),%s*(.-),")
								body.messages[#body.messages + 1] = {from = from, contents = contents,}
							end
							print(dump(body.messages))
						else
							badrequest = 1
						end
					else
						badrequest = 1
					end
					if (badrequest == 1) then
						print('no valid requests (add a request to the url)')
					end
					res:setHeader("Content-Type", "text/plain")
					res:setHeader("Content-Length", #json.encode(body))
					res:finish(json.encode(body))
				end
			end
		else
			notrequest = 1
			print('no login requested (add /login to url)')
		end
		if (notrequest == 1) then
			body = "Service currently unavailable. Check back later."
			res:setHeader("Content-Type", "text/plain")
			res:setHeader("Content-Length", #body)
			res:finish(body)
		end
	end
end):listen(sport, saddress)

print('Server running at http://' .. sdomain .. ':' .. sport)