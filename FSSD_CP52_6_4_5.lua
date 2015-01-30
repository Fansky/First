--[[---------------------------------------------------
	Clause ID:   FSSD_CP52_6_4_5
	Author:      Guo Chunwei
	Tester:		 Wang Shuai, Wei Xubo
	Date:		

	Description :   Check for the sprinklers. 
					If any of the sprinklers is spaced less than or equal to 600mm from a column, there should be another sprinkler on the opposite side of that column. Else, skip the clause. 
					Distance of the other sprinkler from the opposite side of that column should be less than or equal to 1.80m. 
					Point of measurement is from center of the sprinkler to the face of the column. 
					Result Message (FAIL) There is a sprinkler within 0.6m from a column. Required maximum distance of the sprinkler at the opposite face of that column is 1.8m.

	Func List:   1.Function Name: CheckSprinklers ()
				   Parameter :    [in]  Building
				   Description:   Used to complete the Desciption.
	History:	none
--]]---------------------------------------------------

function CheckSprinklers( Building )
	assert(type(Building) == "table" and Building.Id > 0)
	local MaxValue = 1800
	local MinValue = 600
	local PI = 3.14159
	local Columns = Building:GetDescendants("Column") 
	local Terminals = Building:GetDescendants("FlowTerminal")
	local Sprinklers = FXGroup:new()
	Terminals:ForEach(function ( TerminalEle )
		local subType = TerminalEle:GetSubType()
		local PredefinedType = TerminalEle:GetPredefinedTypeOfSubType()
		if subType ~= nil and PredefinedType ~= nil then
			if string.find(string.lower(subType),"firesuppressionterminal") ~= nil and string.find(string.upper(PredefinedType),"SPRINKLER") ~= nil then
				Sprinklers:Add(TerminalEle)
			end
		end
	end)
	Columns = Columns:Unique()
	Columns:ForEach(function ( ColumnEle )
		local closeSprinklerList = FXGroup:new()
		local ColumnObb = FXGeom.GetBoundingBox(ColumnEle)
		local ColumnZmin = ColumnObb:CornerPoint(0).z 
		local ColumnZmax = ColumnObb:CornerPoint(7).z
		local ColumnCenterPiont = ColumnObb:GetPos();
 		local ColumnVector = Vector(ColumnCenterPiont.x,ColumnCenterPiont.y,ColumnCenterPiont.z)

		Sprinklers:ForEach(function ( SprinklerEle )
			local SprinklerObb = FXGeom.GetBoundingBox(SprinklerEle)
			local SprinklerZmin = SprinklerObb:CornerPoint(0).z
			local SprinklerXmin = SprinklerObb:CornerPoint(0).x
			local SprinklerXmax = SprinklerObb:CornerPoint(4).x

			if SprinklerZmin > ColumnZmin and SprinklerZmin < ColumnZmax then
				local SprinklerRadius = math.abs(SprinklerXmax - SprinklerXmin)/2
				local ClosestDistance =  FXMeasure.Distance(ColumnEle,SprinklerEle):Length()

				if ClosestDistance <= (MaxValue - SprinklerRadius) then
					closeSprinklerList:Add(SprinklerEle)
				end
			end
		end)
		closeSprinklerList = closeSprinklerList:Unique()
		local flag1 = false
		local flag2 = false

		closeSprinklerList:ForEach(function ( ListEle )
			local SprinklerListObb = FXGeom.GetBoundingBox(ListEle)
			local SprinklerXmin = SprinklerListObb:CornerPoint(0).x
			local SprinklerXmax = SprinklerListObb:CornerPoint(4).x
			local ListEleCenterPiont = SprinklerListObb:GetPos()
			local ListEleCenterVector = Vector(ListEleCenterPiont.x,ListEleCenterPiont.y,ListEleCenterPiont.z)
			local Direction1  = ListEleCenterVector:Sub(ColumnVector)
			
			local SprinklerRadius = math.abs(SprinklerXmax - SprinklerXmin)/2
			local ClosestDistance =  FXMeasure.Distance(ColumnEle,ListEle):Length()

			if ClosestDistance <= (MinValue - SprinklerRadius) then
				flag1 = true
				closeSprinklerList:ForEach(function ( clSprinklerEle )
					local clSprinklerEleObb = FXGeom.GetBoundingBox(clSprinklerEle)
					local clSprinklerCenterPiont = clSprinklerEleObb:GetPos()
					local SprinklerCenterVector = Vector(clSprinklerCenterPiont.x,clSprinklerCenterPiont.y,clSprinklerCenterPiont.z)
					local Direction2  = SprinklerCenterVector:Sub(ColumnVector)
					local angle = Direction2:Angle(Direction1)/PI*180 
					if angle > 90 then
						flag2 = true
					end
				end)
			end
		
		end)
		

		if  flag1 == true and flag2 == false then
			CheckReport.Error(ColumnEle,"There is a sprinkler within 0.6m from a column. Required maximum distance of the sprinkler at the opposite face of that column is 1.8m.")
		end
	end)
	
end

function main()
	CheckEngine.SetCheckType("Building")
	.BindCheckFunc("CheckSprinklers")
	.Run()
end	