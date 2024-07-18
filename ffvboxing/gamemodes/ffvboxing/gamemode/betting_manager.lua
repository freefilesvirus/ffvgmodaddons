util.AddNetworkString("placeBet")

--{player who placed the bet, player the bet was placed on, amount}
nextRoundBets = {}
thisRoundBets = {}

function payoutBets(winner)
	for k,v in pairs(thisRoundBets) do
		if (IsValid(v[1]) and IsValid(v[2]) and (v[2]==winner)) then
			addMoney(v[1],math.floor(v[3]*1.8))
			v[1]:ChatPrint("You made $"..math.floor(v[3]*1.8).." from your bet")
		end
	end
end

function refundBets()
	for k,v in pairs(thisRoundBets) do
		if (IsValid(v[1]) and IsValid(v[2])) then
			addMoney(v[1],v[3])
		end
	end
end

net.Receive("placeBet",function(len,ply)
	for k,v in pairs(nextRoundBets) do if (v[1]==ply) then return end end
	if (ply:GetNWInt("money")<1) then return end

	local money = net.ReadInt(32)
	local betPly
	if table.HasValue(nextPlayers,ply) then betPly = ply
	else betPly = nextPlayers[net.ReadInt(3)] end

	addMoney(ply,-money)
	table.insert(nextRoundBets,{ply,betPly,money})
end)