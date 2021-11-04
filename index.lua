if not System.doesDirExist("ux0:/data/phoenix") then
	System.createDirectory("ux0:/data/phoenix")
end
if not System.doesDirExist("ux0:/data/phoenix/chat") then
	System.createDirectory("ux0:/data/phoenix/chat")
end
bg0 = Color.new(38, 35, 34)    --dark
bg1 = Color.new(255, 194, 132) --light
bg2 = Color.new(143, 98, 1)    --middle
sep = Color.new(76, 51, 25)    --dark
tx0 = Color.new(242, 229, 215) --light
tx1 = Color.new(255, 255, 255) --very light
sel = Color.new(203, 171, 155) --eriko
math.randomseed(System.getFreeSpace("ux0:"))
eriko = Graphics.loadImage("app0:/image/Eriko" .. math.random(8) .. ".png")
meiryo = Font.load("app0:/font/Meiyro.ttf")
version = "0.7"

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
function hasValue(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
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

loop = 1
timer = 0
username = "Username"
password = "Password"
server = "http://eriko.one:30080"
fx = 0
fy = 0
keyb = 3
if System.doesFileExist("ux0:/data/phoenix/chat/login.txt") then
	file = System.openFile("ux0:/data/phoenix/chat/login.txt", FREAD)
	size = System.sizeFile(file)
	contents = System.readFile(file, size)
	System.closeFile(file)
	loop = 0
end
while loop == 1 do
	disppassword = ''
	if (#password < 21) then
		for i = 1, #password do
			disppassword = disppassword .. '*'
		end
	else
		disppassword = '*********************'
	end
	Graphics.initBlend()
	Screen.clear()
	Graphics.fillRect(0, 960, 0, 544, bg0)
	Graphics.drawImage(0, 0, eriko)
	Graphics.fillRect(720, 240, 408, 136, bg2)
	Graphics.fillRect(251, 710, 146, 196, bg1)
	Graphics.fillRect(251, 710, 206, 256, bg1)
	Graphics.fillRect(251, 710, 266, 316, bg1)
	Graphics.fillRect(430, 530, 346, 403, bg1)
	Font.setPixelSizes(meiryo, 35)
	Font.print(meiryo, 251, 146, username, bg0)
	Font.print(meiryo, 251, 206, disppassword, bg0)
	Font.print(meiryo, 251, 266, server, bg0)
	Font.print(meiryo, 433, 350, "Login", bg0)
	Graphics.termBlend()
	Screen.flip()
	Screen.waitVblankStart()
	Screen.waitVblankStart()
	status = Keyboard.getState()
	if (status ~= RUNNING) then
		x, y = Controls.readTouch()
		if (x ~= nil) then
			tap = 0
			timer = timer + 1
			fx = x
			fy = y
		else
			if (timer < 5) then
				tap = 1
			end
			timer = 0
		end
		if (keyb == 0) then
			username = Keyboard.getInput()
			if(username:match("%W")) then
				username = 'Username'
			end
		elseif (keyb == 1) then
			password = Keyboard.getInput()
			if(password:match("%W")) then
				password = 'Password'
			end
		elseif (keyb == 2) then
			server = Keyboard.getInput()
		end
		Keyboard.clear()
		keyb = 3
	end
	if (tap == 1) then
		if (fx >= 251) and (fx <= 710) then
			if (fy >= 146) and (fy <= 196) then
				keyb = 0
				Keyboard.start("Enter Username", username)
			end
			if (fy >= 206) and (fy <= 256) then
				keyb = 1
				Keyboard.start("Enter Password", password)
			end
			if (fy >= 266) and (fy <= 316) then
				keyb = 2
				Keyboard.start("Enter Server", server)
			end
		end
		if (fy >= 346) and (fy <= 403) and (fx >= 430) and (fx <= 530) then
			file = System.openFile("ux0:/data/phoenix/chat/login.txt", FCREATE)
			contents = username .. "\n" .. password .. "\n" .. server
			System.writeFile(file, contents, #contents)
			System.closeFile(file)
			loop = 0
		end
		fx = 0
		fy = 0
	end
end

logtbl = splittotable(contents, "\n")
Network.init()
function procupdate()
	if System.doesFileExist("ux0:/data/phoenix/chat/messages.csv") then
		System.deleteFile("ux0:/data/phoenix/chat/messages.csv")
	end
	if System.doesFileExist("ux0:/data/phoenix/chat/messages.ecsv") then
		System.deleteFile("ux0:/data/phoenix/chat/messages.ecsv")
	end
	sres = {
		messages = {},
	}
	conts = splittotable(result, ',')
	sres.result = conts[1]
	sres.reason = conts[2]
	sres.version = conts[3]
	sres.time = conts[4]
	conts = splittotable(result, ',eof,')
	file = System.openFile("ux0:/data/phoenix/chat/messages.csv", FCREATE)
	csvf = ''
	for i = 1, #conts - 1 do
		csvf = csvf .. '\n' .. conts[i + 1]
	end
	System.writeFile(file, csvf, #csvf)
	System.closeFile(file)
	file = System.openFile("ux0:/data/phoenix/chat/messages.ecsv", FCREATE)
	System.writeFile(file, result, #result)
	System.closeFile(file)
	for line in io.lines("ux0:/data/phoenix/chat/messages.csv") do
		local from, to, contents = line:match("%s*(.-),%s*(.-),%s*(.-),")
		sres.messages[#sres.messages + 1] = {from = from, contents = contents, to = to,}
	end
end
function calckeys()
	keys = {
		[0.5] = tonumber(sres.time) + (#logtbl[1] * 653987 + #logtbl[2] * 6453765),
		[0.6] = (tonumber(sres.time) / 200) + (#logtbl[1] * 653987 + #logtbl[2] * 6453765),
		[0.7] = (tonumber(sres.time) / 200) + (#logtbl[1] * 653987 + #logtbl[2] * 6453765 + (tonumber(sres.time) % 69)),
	}
end
function update() --update by csv method, json can be implimented by you
	result = Network.requestString(logtbl[3] .. "/login/" .. logtbl[1] .. "/" .. logtbl[2] .. "/0/csv/update")
	procupdate()
	if (tonumber(sres.version) < 0.6) then --im too lazy to make json work lol
		System.deleteFile("ux0:/data/phoenix/chat/login.txt")
		System.exit()
	end
	if (sres.reason == "account creation not allowed") or (tonumber(sres.version) > tonumber(version)) or (sres.reason == "invalid password") then
		System.deleteFile("ux0:/data/phoenix/chat/login.txt")
		System.exit()
	end
	calckeys()
	result = Network.requestString(logtbl[3] .. "/login/" .. logtbl[1] .. "/" .. logtbl[2] .. "/" .. keys[tonumber(version)] .. "/csv/update")
	procupdate()
	timer = 0
end
update()

loop = 1
updates = 0
while loop == 1 do
	timer = timer + 1
	if (timer == 60) then
		update()
		updates = updates + 1
	end
	Graphics.initBlend()
	Screen.clear()
	Graphics.fillRect(0, 960, 0, 544, bg0)
	Graphics.drawImage(0, 0, eriko)
	Graphics.fillRect(720, 240, 408, 136, bg2)
	Graphics.fillRect(251, 710, 146, 196, bg1)
	Graphics.fillRect(251, 710, 206, 256, bg1)
	Graphics.fillRect(251, 710, 266, 316, bg1)
	Graphics.fillRect(430, 530, 346, 403, bg1)
	Font.setPixelSizes(meiryo, 35)
	Font.print(meiryo, 251, 146, 'updates: ' .. updates, bg0)
	Font.print(meiryo, 251, 206, 'recent message: ' .. sres.messages[#sres.messages].contents, bg0)
	Font.print(meiryo, 251, 266, server .. ' ' .. sres.version, bg0)
	Font.print(meiryo, 433, 350, "Logged in put something here faggot", bg0)
	Graphics.termBlend()
	Screen.flip()
	Screen.waitVblankStart()
	Screen.waitVblankStart()
end