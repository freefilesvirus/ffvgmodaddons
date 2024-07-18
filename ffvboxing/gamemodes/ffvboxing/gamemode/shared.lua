function gameText(text,time,ply)
	net.Start("gameText")
		net.WriteInt(time,8)
		net.WriteString(text)
	if (ply==nil) then net.Broadcast()
	else net.Send(ply) end
end
function gameTimer(time,ply)
	net.Start("gameTimer")
		net.WriteInt(time,8)
	if (ply==nil) then net.Broadcast()
	else net.Send(ply) end
end

function nameKD(ply)
	if (not IsValid(ply)) then return "?" end
	return (ply:GetName().." ("..ply:GetNWInt("kills")..":"..ply:GetNWInt("deaths")..")")
end