--[[
hello! i wrote this addon in a way that people could easily add spells to it if they wanted,
and i sorta doubt that anyone will but its cool to have the option.

to add a spell put an initialize hook then call dw_add_spell(spell)
spell should be a table that looks like this:
(everything after the equals sign is default, except for pattern and action which need
to be specified or else the spell wont be added. anything else can be blank)

spell.pattern = {1,2,3,4,5,6,7,8,9}
	the pattern is how the spell is drawn, to write it out in a table
	imagine a circle with 8 spots around it, 1 is the topmost circle
	and 2-8 is also around the circle going clockwise. 9 is in the center
spell.action = function(target,wand)
	this is what happens when the spell is cast, target will either be
	an entity or a position depending on what you specify below. wand
	is the weapon the spell was fired from
spell.targetEntity = false
	whether or not the spell requires an entity. if false itll be a position
	vector, if true itll be an entity
spell.symmetric = {false,false}
	whether the spell should work symmetric. the table is {horizontal,vertical}
spell.canStack = false
	whether multiple instances of a spell can be loaded into a wand
spell.sound = Sound("buttons/blip1.wav")
	a string for a sound when the spell gets accepted

if ya still dont get it look at the bottom of this script to see what i did

if you do make any sort of spell packs please send them to me through steam,
friend me and send the link in dms or just leave a comment, id love to see it
]]

local spells = {}
function dw_add_spell(spell)
	if (not istable(spell.pattern)) then
		print("spell doesnt have a pattern!")
		return
	end
	if (not isfunction(spell.action)) then
		print("spell doesnt have a function!")
		return
	end
	--cant run a spell w/o either of the above
	if (spell.targetEntity == nil) then spell.targetEntity = false end
	if (spell.symmetric == nil) then spell.symmetric = {false,false} end
	if (spell.canStack == nil) then spell.canStack = false end
	if (spell.sound == nil) then spell.sound = Sound("buttons/blip1.wav") end
	table.insert(spells,spell)
end

function dw_find_spell(pointTable)
	for k, v in pairs(spells) do
		if (#v.pattern == #pointTable) then
			--same length, check if it matches
			local matching = true
			for k1, v1 in pairs(v.pattern) do
				if (not dw_in_group(pointTable[k1],v1,v.symmetric)) then matching = false end
			end
			--all good, send it off
			if matching then return v end
		end
	end
	--couldnt find anything
	return nil
end

function dw_in_group(point,group,symmetric)
	local matching = {{5},{5,6},{6},{6,7},{7},{7,8},{8},{8,1},{1},{1,2},{2},{2,3},{3},{3,4},{4},{4,5},{9}}
	local points = {point}
	--horizontal sym
	if symmetric[1] then
		local hsym = {{1},{16},{15},{14},{13},{12},{11},{10},{9},{8},{7},{6},{5},{4},{3},{2},{9}}
		for k, v in pairs(hsym[point]) do
			table.insert(points,v)
		end
	end
	--vertical symm
	if symmetric[2] then
		local vsym = {{9},{8},{7},{6},{5},{4},{3},{2},{1},{16},{15},{14},{13},{12},{11},{10},{9}}
		for k, v in pairs(vsym[point]) do
			table.insert(points,v)
		end
	end

	for k, v in pairs(points) do
		for k1, v1 in pairs(matching[v]) do
			if (group == v1) then return true end
		end
	end
	return false
end

hook.Add("Initialize","initDWSpells",function()
	if CLIENT then return end
	local bulletSpell = {}
	bulletSpell.pattern = {6,1,4,6}
	bulletSpell.symmetric = {true,false}
	bulletSpell.canStack = true
	bulletSpell.sound = Sound("weapons/shotgun/shotgun_reload2.wav")
	bulletSpell.action = function(target,wand)
		local bullet = {}
		bullet.Attacker = wand:GetOwner()
		bullet.Damage = 6
		bullet.Num = 3
		bullet.Dir = wand:GetOwner():GetAimVector()
		bullet.Spread = Vector(.04,.04,0)
		bullet.Src = wand:GetOwner():GetShootPos()
		wand:FireBullets(bullet)
		wand:EmitSound(Sound("weapons/shotgun/shotgun_fire6.wav"))
	end
	dw_add_spell(bulletSpell)

	local teleportSpell = {}
	teleportSpell.pattern = {5,1,3,7,1}
	teleportSpell.symmetric = {true,false}
	teleportSpell.canStack = false
	teleportSpell.action = function(target,wand)
		wand:GetOwner():SetPos(target)
		wand:EmitSound(Sound("ambient/machines/teleport4.wav"))
	end
	dw_add_spell(teleportSpell)

	local killSpell = {}
	killSpell.pattern = {9,1,9,2,9,3,9,4,9,5,9,6,9,7,9,8,9}
	killSpell.targetEntity = true
	killSpell.action = function(target,wand)
		target:TakeDamage(target:Health(),wand:GetOwner())
	end
	dw_add_spell(killSpell)

	local healSpell = {}
	healSpell.pattern = {9,9}
	healSpell.canStack = true
	healSpell.sound = {"vo/npc/female01/health01.wav","vo/npc/female01/health04.wav","vo/npc/female01/health05.wav",
	"vo/npc/male01/health02.wav","vo/npc/male01/health05.wav","vo/npc/male01/health03.wav"}
	healSpell.action = function(target,wand)
		local ply = wand:GetOwner()
		ply:SetHealth(ply:Health()+5)
		wand:EmitSound(Sound("items/smallmedkit1.wav"))
	end
	dw_add_spell(healSpell)

	local fireSpell = {}
	fireSpell.pattern = {6,1,4,7,3,6}
	fireSpell.symmetric = {true,false}
	fireSpell.targetEntity = true
	fireSpell.action = function(target,wand)
		target:EmitSound(Sound("ambient/fire/gascan_ignite1.wav"))
		target:Ignite(30)
	end
	dw_add_spell(fireSpell)

	local danceSpell = {}
	danceSpell.pattern = {5,1,3,5}
	danceSpell.symmetric = {false,true}
	danceSpell.action = function(target,wand)
		wand:GetOwner():ConCommand("act dance")
	end
	dw_add_spell(danceSpell)
end)