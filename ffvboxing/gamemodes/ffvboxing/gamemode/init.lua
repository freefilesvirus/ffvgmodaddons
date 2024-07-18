AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_menu.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")
include("betting_manager.lua")
include("round_manager.lua")

util.AddNetworkString("updateMoney")
util.AddNetworkString("gameText")
util.AddNetworkString("gameTimer")
util.AddNetworkString("roundWon")
util.AddNetworkString("setPlayermodel")
util.AddNetworkString("setPlayercolor")
util.AddNetworkString("tryLoadFile")

hook.Add("PlayerInitialSpawn","ffvboxSingleplayerWarning",function(ply)
	if game.SinglePlayer() then gameText("This gamemode won't work in singleplayer",999)
	elseif (not string.StartWith(game.GetMap(),"box_")) then gameText("This gamemode is meant to be played in one of the Boxing & Betting maps",999) end

	ply.playermodel = "models/player/Group01/male_07.mdl"
	ply:SetNWInt("money",20)
	ply:SetNWInt("kills",0)
	ply:SetNWInt("deaths",0)
	ply:SetNWInt("roundsSincePicked",1)

	net.Start("tryLoadFile")
	net.Send(ply)
end)

net.Receive("setPlayermodel",function(len,ply)
	ply.playermodel = net.ReadString()
	ply:SetModel(ply.playermodel)
end)
function GM:PlayerSetModel(ply) ply:SetModel(ply.playermodel) end

net.Receive("setPlayercolor",function(len,ply)
	ply:SetPlayerColor(net.ReadVector())
end)

function addMoney(ply,amount)
	ply:SetNWInt("money",math.Clamp(ply:GetNWInt("money")+amount,0,math.huge))
	net.Start("updateMoney")
		net.WriteInt(ply:GetNWInt("money"),32)
	net.Send(ply)
end

hook.Add("PlayerSpawn","ffvboxSpawn",function(ply)
	ply.important = table.HasValue(currentPlayers,ply)
	if (not ply.important) then ply:Give("box_loadsamoney") end

	if roundWaiting then startDowntime() end
end)

hook.Add("PlayerNoClip","ffvboxNoNoclip",function() return false end)