###
Robots!
Copyright © 2012 Martin Tournoij
http://arp242.net/robots/
###


# TODO Many of these should be user-definable settings
_boxsize = 14
_gridsizex = 59
_gridsizey = 22

# Various globals for convencience
_gridheight = _gridsizey * _boxsize
_gridwidth = _gridsizex * _boxsize
_grid = document.getElementById 'grid'
_gridcon = _grid.getContext '2d'
_playerpos = [0, 0]
_junk = []
_robots = []
_level = 0
_numrobots = 10
_maxlevels = 4
_waiting = false
_keybinds = null
_spritesize = 14

###
Load options from localStorage or set defaults
###
LoadOptions = ->
	window._showgrid = if localStorage.getItem('showgrid') == 'true' then true else false
	window._hardcore = if localStorage.getItem('hardcore') == 'true' then true else false
	window._autoteleport = if localStorage.getItem('autoteleport') == 'true' then true else false
	window._graphics = localStorage.getItem 'graphics'
	if !window._graphics then window._graphics = (parseInt(Math.random() * 3) + 1) + ''

	window._sprite = new Image
	window.loaded = false
	window._sprite.onload = -> window.loaded = true

	if window._graphics == '1'
		window._sprite.src = 'graphics/classic.png'
	else if window._graphics == '2'
		window._sprite.src = 'graphics/dalek.png'
	else if window._graphics == '3'
		window._sprite.src = 'graphics/cybermen.png'

	document.getElementById('graphics').selectedIndex = parseInt(window._graphics, 10) - 1
	document.getElementById('showgrid').checked = window._showgrid
	document.getElementById('autoteleport').checked = window._autoteleport
	document.getElementById('hardcore').checked = window._hardcore

	if localStorage.getItem('keybinds') == '1'
		document.getElementById('keybinds0').style.display = 'none'
		document.getElementById('keybinds1').style.display = 'block'
		document.getElementById('keyset').selectedIndex = 1

		window._keybinds = [
			[121, -> MovePlayer ['up', 'left']], # y
			[107, -> MovePlayer ['up']], # k
			[117, -> MovePlayer ['up', 'right']], # u
			[104, -> MovePlayer ['left']], # h
			[108, -> MovePlayer ['right']], # l
			[98,  -> MovePlayer ['down', 'left']], # b
			[106, -> MovePlayer ['down']], # j
			[110, -> MovePlayer ['down', 'right']], # n

			[46, -> MovePlayer []], # .
			[119, -> do Wait], # w
			[116, -> do Teleport], # t
		]
	else
		document.getElementById('keybinds0').style.display = 'block'
		document.getElementById('keybinds1').style.display = 'none'
		document.getElementById('keyset').selectedIndex = 0

		window._keybinds = [
			[55, -> MovePlayer ['up', 'left']], # 7
			[56, -> MovePlayer ['up']], # 8
			[57, -> MovePlayer ['up', 'right']], # 9
			[52, -> MovePlayer ['left']], # 4
			[54, -> MovePlayer ['right']], # 6
			[49,  -> MovePlayer ['down', 'left']], # 1
			[50, -> MovePlayer ['down']], # 2
			[51, -> MovePlayer ['down', 'right']], # 3

			[53, -> MovePlayer []], # 5
			[119, -> do Wait], # w
			[116, -> do Teleport], # t
		]

###
Draw an empty grid aka playfield
###
DrawGrid = ->
	_gridcon.fillStyle = '#fff'
	_gridcon.fillRect 0, 0, _gridwidth, _gridheight

	if _showgrid
		for col in [0.._gridsizex * _boxsize] by _boxsize
			_gridcon.moveTo col + 0.5, 0
			_gridcon.lineTo col + 0.5, _gridheight

		for row in [0.._gridsizey * _boxsize] by _boxsize
			_gridcon.moveTo 0, row + 0.5
			_gridcon.lineTo _gridwidth, row + 0.5

		_gridcon.strokeStyle = '#b7b7b7'
		_gridcon.lineWidth = 1
		do _gridcon.stroke

###
Draw a bunch of robots at a random locations
###
InitRobots = ->
	for i in [1.._numrobots]
		while true
			x = GetRandomCoord 'x'
			y = GetRandomCoord 'y'

			if not RobotAtPosition(x, y) and (x != _playerpos[0] and y != _playerpos[1])
				break

		DrawRobot null, x, y

DrawSprite = (num, x, y) ->
	_gridcon.drawImage _sprite, _spritesize * num, 0, _spritesize, _spritesize,
		x * _boxsize, y * _boxsize, _boxsize, _boxsize

###
Draw a robot
###
DrawRobot = (num, x, y) ->
	if _robots[num] == null
		return
	else if num == null
		num = _robots.length
		_robots.push [x, y]
	else
		ClearGrid _robots[num][0], _robots[num][1]

	DrawSprite 1, x, y

	#_gridcon.font = "bold 8px sans-serif";
	#_gridcon.fillStyle = '#000'
	#_gridcon.fillText num, x * _boxsize + 4, y * _boxsize + 12

	_robots[num] = [x, y]

###
Two robots collided. BBBOOOOOMMM!!
###
DestroyRobots = (x, y) ->
	ClearGrid x, y
	DrawJunk x, y
	_junk.push [x, y]

	i = 0
	for r in _robots
		if r and r[0] == x and r[1] == y
			_robots[i] = null
			_numrobots -= 1
			do UpdateScore
		i += 1

DrawJunk = (x, y) ->
	DrawSprite 2, x, y

###
Move robots around
###
MoveRobots = ->
	i = 0
	for r, i in _robots
		if r == null
			continue

		x = r[0]
		y = r[1]

		if _playerpos[0] > x
			x += 1
		else if _playerpos[0] < x
			x -= 1

		if _playerpos[1] > y
			y += 1
		else if _playerpos[1] < y
			y -= 1

		if RobotAtPosition _playerpos[0], _playerpos[1]
			do Die
			return
		else if JunkAtPosition x, y
			ClearGrid _robots[i][0], _robots[i][1]
			_robots[i] = [x, y]
			DestroyRobots x, y
		else
			DrawRobot i, x, y

	# Check for collisions
	for r, i in _robots
		if r == null
			continue

		c = RobotAtPosition r[0], r[1], true
		if c != false and c != i
			DestroyRobots r[0], r[1]

###
Draw our handsome protagonist
###
DrawPlayer = (x, y) ->
	ClearGrid _playerpos[0], _playerpos[1]
	DrawSprite 0, x, y
	_playerpos = [x, y]

###
Get random coordinates
TODO: How random is Math.random()?
###
GetRandomCoord = (axis) ->
	axis = if axis == 'x' then _gridsizex else _gridsizey

	parseInt(Math.random() * (axis - 1) + 1, 10)

###
Set position of player or robot inside the grid
###
SetPosition = (obj, x, y) ->
	obj.style.left = x + 'px'
	obj.style.top = y + 'px'

###
Deal with keyboard events
###
HandleKeyboard = (event) ->
	if event.ctrlKey or event.altKey
		return

	code = event.keyCode || event.charCode

	# Escape key
	if code == 27
		do CloseAllWindows
		return

	for [keyCode, action] in _keybinds
		if keyCode == code
			do event.preventDefault
			do action

###
Deal with mouse events
###
HandleMouse = (event) ->
	if event.target.id == 'options'
		ShowWindow 'options'
	else if event.target.id == 'help'
		ShowWindow 'help'
	else if event.target.id == 'about'
		ShowWindow 'about'
	else if event.target.id == 'close'
		do CloseAllWindows
	else if event.target.id == 'save'
		localStorage.setItem 'keybinds', document.getElementById('keyset').selectedIndex
		localStorage.setItem 'graphics', document.getElementById('graphics').selectedIndex + 1
		localStorage.setItem 'showgrid', document.getElementById('showgrid').checked
		localStorage.setItem 'autoteleport', document.getElementById('autoteleport').checked
		localStorage.setItem 'hardcore', document.getElementById('hardcore').checked
		do LoadOptions
		do CloseAllWindows
		do DrawGrid

		# Why doesn't Javascript have sleep() ? :-(
		sleep = setInterval(->
			if window.loaded
				clearInterval sleep
				DrawPlayer _playerpos[0], _playerpos[1]

				for r, i in _robots
					if r != null then DrawRobot i, r[0], r[1]

				for j, i in _junk
					DrawJunk i, j[0], j[1]
		, 100)


###
Close all windows
###
CloseAllWindows = ->
	l = document.getElementById 'layover'
	if l then l.parentNode.removeChild l
	for win in document.getElementsByClassName 'window'
		win.style.display = 'none'

###
Show a window
###
ShowWindow = (name) ->
	div = document.createElement 'div'
	div.id = 'layover'
	document.body.appendChild div

	document.getElementById(name + 'window').style.display = 'block'

###
Our bold player decided to wait ... Let's see if that decision was wise ... or fatal!
###
Wait = ->
	_waiting = true

	while true
		do MoveRobots

		if RobotAtPosition _playerpos[0], _playerpos[1]
			return

		if _numrobots == 0
			do NextLevel
			break

	_waiting = false

###
Teleport to a new location ... or to death!
###
Teleport = ->
	x = GetRandomCoord 'x'
	y = GetRandomCoord 'y'

	if RobotAtPosition x, y or JunkAtPosition x, y
		do Die
		return

	DrawPlayer x, y
	do MoveRobots

### Move the player around
###
MovePlayer = (dir) ->
	x = _playerpos[0]
	y = _playerpos[1]

	if 'left' in dir
		x -= 1
	else if 'right' in dir
		x += 1

	if 'up' in dir
		y -= 1
	else if 'down' in dir
		y += 1

	if x < 0 or x > _gridsizex - 1 then return false
	if y < 0 or y > _gridsizey - 1 then return false

	dangerous = false
	for i in [-1..1]
		for j in [-1..1]
			if x + i < 0 or x + i > _gridsizex - 1 then continue
			if y + j < 0 or y + j > _gridsizey - 1 then continue
			if RobotAtPosition x + i, y + j then dangerous = true

	if not _hardcore and dangerous then return false

	if JunkAtPosition x, y then return false
	DrawPlayer x, y
	do MoveRobots

	if _numrobots <= 0
		do NextLevel

	if not _hardcore and _autoteleport and not MovePossible() then do Teleport

###
Check if there is a possible move left
###
MovePossible = ->
	for x1 in [-1..1]
		for y1 in [-1..1]
			dangerous = false
			if _playerpos[0] + x1 < 0 or _playerpos[0] + x1 > _gridsizex - 1
				continue
			if _playerpos[1] + y1 < 0 or _playerpos[1] + y1 > _gridsizey - 1
				continue

			for x2 in [-1..1]
				for y2 in [-1..1]
					if RobotAtPosition _playerpos[0] + x1 + x2, _playerpos[1] + y1 + y2
						dangerous = true

			if not dangerous
				return true

	return false

###
Check of there if a robot at the position
###
RobotAtPosition = (x, y, retnum) ->
	for r, i in _robots
		if r and r[0] == x and r[1] == y
			return if retnum then i else true

	return false

###
Check if there is "junk" at this position
###
JunkAtPosition = (x, y) ->
	for j in _junk
		if j[0] == x and j[1] == y then return true

	return false

###
Clear (blank) this grid positon
TODO: Redraw grid lines if grid is enabled
###
ClearGrid = (x, y) ->
	_gridcon.fillStyle = '#fff'

	_gridcon.fillRect(
		x * _boxsize,
		y * _boxsize,
		_boxsize, _boxsize
	)

###
Oh noes! Our brave hero has died! :-(
###
Die = ->
	ClearGrid _playerpos[0], _playerpos[1]
	DrawSprite 3, _playerpos[0], _playerpos[1]

	curscore = parseInt document.getElementById('score').innerHTML, 10
	scores = localStorage.getItem 'scores'
	scores = JSON.parse scores
	if not scores
		scores = []

	d = new Date
	d = do d.toLocaleDateString
	scores.push [curscore, d, true]
	scores.sort (a, b) ->
		if a[0] > b[0] then return -1
		if a[0] < b[0] then return 1
		return 0

	scores = scores.slice 0, 5

	restart = document.createElement 'div'
	restart.id = 'restart'
	restart.innerHTML = 'AARRrrgghhhh....<br><br>' +
		'Your highscores:<br>'

	for s in scores
		restart.innerHTML += '<span class="row' + (if s[2] then ' cur' else '') + '">' +
			'<span class="score">' + s[0] + '</span>' + s[1] + '</span>'

	restart.innerHTML += '<br>Press any key to try again.'
	document.body.appendChild restart

	scores = scores.map (s) ->
		s[2] = false
		return s
	
	localStorage.setItem 'scores', JSON.stringify scores

	document.body.removeEventListener 'keypress', HandleKeyboard, false

	window.addEventListener 'keypress', ((e) ->
		if e.ctrlKey or e.altKey
			return

		do e.preventDefault
		do window.location.reload),
		false

###
Woohoo! A robot is no more, so lets update the score.
###
UpdateScore = ->
	score = parseInt(document.getElementById('score').innerHTML, 10)
	score += 10
	if _waiting then score += 1

	document.getElementById('score').innerHTML = score

###
Keep IE happy (also shorter to type!)
###
log = (msg) ->
	if console and console.log
		console.log msg

###
Advance to the next level
###
NextLevel = ->
	_level += 1
	_numrobots = 10 + _level * 10
	_waiting = false
	_junk = []

	do DrawGrid
	DrawPlayer GetRandomCoord('x'), GetRandomCoord('y')
	do InitRobots



CheckBrowser = ->
	old = false

	# Opera
	if window.opera
		if parseFloat(do window.opera.version) < 11.60
			old = true
	# Chrome
	else if window.chrome
		if parseInt(navigator.appVersion.match(/Chrome\/(\d+)/)[1], 10) < 18
			old = true
	# Safari
	else if navigator.vendor and navigator.vendor.match(/[aA]pple/)
		if parseFloat(navigator.appVersion.match(/Version\/(\d+\.\d+)/)[1]) < 5
			old = true
	# Firefox
	else if navigator.userAgent.match /Firefox\/\d+/
		if parseFloat(navigator.userAgent.match(/Firefox\/([\d\.]+)/)[1]) < 10
			old = true
	# IE
	else if  navigator.appName == 'Microsoft Internet Explorer'
		if parseInt(navigator.appVersion.match(/MSIE (\d+)/)[1], 10) < 9
			old = true

	if old
		div = document.createElement 'div'
		div.id = 'oldbrowser'
		div.innerHTML = 'Robots requires a fairly new browser with support for canvas, JSON, localStorage, etc.<br>' +
			'Almost all modern browsers support this, but a few may not (IE8, for example, does not).<br>' +
			'Tested versions are Opera 12, Firefox 14, Chrome 20, Internet Explorer 9'

		document.body.insertBefore div, _grid

###
Start the game!
###
InitGame = ->
	_numrobots = 10

	do LoadOptions

	# Why doesn't Javascript have sleep() ? :-(
	sleep = setInterval(->
		if window.loaded
			clearInterval sleep
			do InitGame2
	, 100)

InitGame2 = ->
	do DrawGrid
	DrawPlayer GetRandomCoord('x'), GetRandomCoord('y')
	do InitRobots
	window.addEventListener 'keypress', HandleKeyboard, false
	window.addEventListener 'click', HandleMouse, false

do CheckBrowser
do InitGame
