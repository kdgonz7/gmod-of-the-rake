local RandomName = function() local bn = {
	"RakeKiller07",
	"Micahnator3000",
	"JimBob93",
	"Marcus18Kill",
	"Leafy",
	"NateHicks",
	"Kai",
	"RobotRobert",
	"WatchingMyBack91",
	"SomebodysWatchingMeThriller",
	"MovieSceneCreator12",
	"PassionateEgg14"
} return (bn)[math.random(1, #bn)] end

concommand.Add("rake_AddBot", function(ply, cmd, args, str)
	if ! ply:IsSuperAdmin() then return end
	player.CreateNextBot(RandomName())
end)

-- An A* pathfinding algorithm, which returns the path from start to goal
-- start and goal are CNavAreas
-- F = G + H
-- G = cost of path from start to current
-- H = estimated cost of path from current to goal
function Pathfind_AS( start, goal )
	if ( !IsValid( start ) || !IsValid( goal ) ) then return false end
	if ( start == goal ) then return true end

	start:ClearSearchLists()	-- start over, we're doing a new search
	start:AddToOpenList()			-- Add the start area to the open list

	local cameFrom = {}

	start:SetCostSoFar( 0 )
	start:SetTotalCost( heuristicCostEstimate( start, goal ) )
	start:UpdateOnOpenList()

	while ( !start:IsOpenListEmpty() ) do
		local current = start:PopOpenList() -- Remove the area with lowest cost in the open list and return it
		if ( current == goal ) then
			return reThinkPath( cameFrom, current )
		end

		-- add the current area to the closed list,
		-- since we've looked at it now
		current:AddToClosedList()

		-- get the adjacent areas
		for k, neighbor in pairs( current:GetAdjacentAreas() ) do
			-- for each neighbor, calculate the cost of getting to that neighbor
			local newCostSoFar = current:GetCostSoFar() + heuristicCostEstimate( current, neighbor )

			-- if it's underwater, we'll skip it because we don't
			-- like water
			if ( neighbor:IsUnderwater() ) then -- Add your own area filters or whatever here
				continue
			end

			-- if the new cost is cheaper, or if the neighbor is not on the open list
			if ( ( neighbor:IsOpen() || neighbor:IsClosed() ) && neighbor:GetCostSoFar() <= newCostSoFar ) then
				continue
			else
				-- we'll update the cost
				neighbor:SetCostSoFar( newCostSoFar );
				neighbor:SetTotalCost( newCostSoFar + heuristicCostEstimate( neighbor, goal ) ) -- set the total cost to the estimate from this area to the goal

				-- if the neighbor is on the closed list, remove it
				if ( neighbor:IsClosed() ) then
					neighbor:RemoveFromClosedList()
				end

				-- if the neighbor is on the open list
				if ( neighbor:IsOpen() ) then
					-- This area is already on the open list, update its position in the list to keep costs sorted
					neighbor:UpdateOnOpenList()
				else
					neighbor:AddToOpenList()
				end

				-- remember where we got to from here
				cameFrom[ neighbor:GetID() ] = current:GetID()
			end
		end
	end

	return false
end

-- estimates the cost of the start position to the goal
-- the higher this value the more pathfinding you may need
function heuristicCostEstimate( start, goal )
	-- TODO: modify this if it needs modifying
	return start:GetCenter():Distance( goal:GetCenter() )
end

-- using CNavAreas as table keys doesn't work, we use IDs
function reThinkPath( cameFrom, current )
	local total_path = { current }

	current = current:GetID()

	while ( cameFrom[ current ] ) do
		current = cameFrom[ current ]
		table.insert( total_path, navmesh.GetNavAreaByID( current ) )
	end

	return total_path
end

function RandomPatrolPoint( area )
	local r = math.random( 1, area:GetSize() - 1 )
	return area:Get( r )
end

rePathDelay = 1

hook.Add("StartCommand", "RakeStartCommand", function(ply, cmd)
	if ! ply:IsBot() then return end
	cmd:ClearButtons()
	cmd:ClearMovement()

	if roundManage:GetRoundStatus() == IN_LOBBY then
		return
	end

	if ! ply:HasWeapon("mg_xm4") then
		ply:Give("mg_xm4")
	end

	ply:SelectWeapon("mg_xm4")
	ply:DrawViewModel(false)

	local currentArea = navmesh.GetNearestNavArea( ply:GetPos() )

	ply.lastRePath = ply.lastRePath || 0		-- regeneration
	ply.lastRePath2 = ply.lastRePath2 || 0 	-- regeneration limit

	-- We are not in the same area, or we can't navigate to the target
	if ( ply.path && ply.lastRePath + rePathDelay < CurTime() && currentArea != ply.targetArea ) then
		ply.path = nil
		ply.lastRePath = CurTime()
	end

	-- if there's no path, and our delay is past we'll get a new path
	if ( !ply.path && ply.lastRePath2 + rePathDelay < CurTime() ) then
		local aPlayer = player.GetHumans()[ math.random( 1, #player.GetHumans() ) ]

		-- the target position to go to
		local targetPos = aPlayer:GetPos()

		-- the area the target is in
		local targetArea = navmesh.GetNearestNavArea( targetPos )

		ply.targetArea = nil
		ply.path = Pathfind_AS( currentArea, targetArea )

		if ( !istable( ply.path ) ) then -- We are in the same area as the target, or we can't navigate to the target
			ply.path = nil -- Clear the path, bail and try again next time
			ply.lastRePath2 = CurTime()
			return
		end

		-- TODO: Add inbetween points on area intersections
		-- TODO: On last area, move towards the target position, not center of the last area
		table.remove( ply.path ) -- Just for this example, remove the starting area, we are already in it!
	end


	-- we have no path, or its empty (we arrived at the goal), try to get a new path.
	if ( !ply.path || #ply.path < 1 ) then
		ply.path = nil
		ply.targetArea = nil
		return
	end

	-- Select the next area we want to go into
	if ( !IsValid( ply.targetArea ) ) then
		ply.targetArea = ply.path[ #ply.path ]
	end

	-- The area we selected is invalid or we are already there, remove it, bail and wait for next cycle
	if ( !IsValid( ply.targetArea ) || ( ply.targetArea == currentArea && ply.targetArea:GetCenter():Distance( ply:GetPos() ) < 64 ) ) then
		table.remove( ply.path ) -- Removes last element
		ply.targetArea = nil
		return
	end

	local enemy = ents.FindByClass("drg_sf2_therake")

	local targetAngle = ( ply.targetArea:GetCenter() - ply:GetPos() ):GetNormalized():Angle()

	if IsValid(enemy[1]) && enemy[1]:GetPos():Distance(ply:GetPos()) < 300 then
			local targetAngle = (enemy[1]:GetPos() - ply:GetPos()):GetNormalized():Angle()
			cmd:SetViewAngles(targetAngle)
			cmd:SetButtons(IN_ATTACK)
			ply:SetEyeAngles(targetAngle)

			if ply:GetActiveWeapon():Clip1() == 0 then
				ply:GiveAmmo(1000, ply:GetActiveWeapon():GetPrimaryAmmoType())
				cmd:AddKey(IN_RELOAD)
			end

			return -- Ensure that shooting takes priority over navigation
	end

	local targetPos = ply.targetArea:GetCenter()
	local targetAngle = (targetPos - ply:GetPos()):GetNormalized():Angle()
	cmd:SetViewAngles(targetAngle)
	ply:SetEyeAngles(targetAngle)
	cmd:SetForwardMove(1000)
end)
