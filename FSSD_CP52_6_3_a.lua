--[[-----------------------------------------------------
	Clause ID：  FSSD_CP52_6_3_a
	Author:      Wei Xubo
	Tester:      Wang Shuai,Wang Xinzhuo
	Date:        2014.12.18(Completed)
				 2014.12.18(Tested)
	Description:
	
	Func List：  1.Function Name: CheckDisOfSprinkler
				   Parameter：    [in]  BuildingStorey
				   Description:   Check the Dis Of Sprinkler is less than 2M and whether have proxy

				 2.Function Name:  CheckWhetherHaveProxy
				   Parameter：    [in]  Sprk,Spri,CheckProxy
				   Description: 	check the sprk and spri whether Collided proxy

	History:	1.Date:	2014.12.19
				  Author: Wei Xubo
				  Modification: Fix
				2. ...
--]]-----------------------------------------------------
-----------------------------
function Distances(Element1,Element2)
	assert(type(Element1) == "table" and Element1.Id > 0)
	assert(type(Element2) == "table" and Element2.Id > 0)

	local Element1Obb = FXGeom.GetBoundingBox(Element1);
	local Element2Obb = FXGeom.GetBoundingBox(Element2);
	
	local Pos1 = Element1Obb:GetPos();
	local Pos2 = Element2Obb:GetPos();

	local Distanc = math.abs(math.sqrt(math.pow((Pos1.x-Pos2.x),2)+math.pow((Pos1.y-Pos2.y),2)+math.pow((Pos1.z-Pos2.z),2)));
	local Dis = math.floor(Distanc);
	return Dis;
end
-----------------------------




function CheckDisOfSprinkler(BuildingStorey)
	assert(type(BuildingStorey) == "table" and BuildingStorey.Id > 0)

	local SpaceGrp = BuildingStorey:GetChildren("Space")
	SpaceGrp:ForEach(function (SpaceEle)
		local CheckSprGrp = FXGroup:new()
		local CheckProxy = FXGroup:new()
		local AllElement = SpaceEle:GetInSpaceElement()

		AllElement:ForEach(function (ElementEle)
			if string.find(string.lower(ElementEle.Type),"buildingelementproxy") ~= nil then
				CheckProxy:Add(ElementEle)
			end
			if string.find(string.lower(ElementEle.Type),"flowterminal") ~= nil then
				local ID = ElementEle:GetAuxAttri("IfcTypeObject.IFCFIRESUPPRESSIONTERMINALTYPE")
				local ele = NewElement("UnknownObject",ID)
				local Type = ele:GetAuxAttri("Entity.PredefinedType")
				if Type ~= nil and string.find(string.lower(Type),"sprinkler") ~= nil then
					CheckSprGrp:Add(ElementEle)
				end
			end
		end)
		if #CheckSprGrp == 0 then
			CheckSprGrp = SpaceEle:GetChildren("FlowTerminal")
		end
		CheckSprGrp = CheckSprGrp:Unique()
		CheckProxy = CheckProxy:Unique()
		CheckSprGrp:EachPair(CheckSprGrp,function (i,k,wari,wark)
			if(wari.Id ~= wark.Id) then
				--local Dis = Distances(wari,wark)
				local Dis = FXMeasure.Distance(wari,wark):Length()
				if(Dis < 2000) then
					local SprkObb = FXGeom.GetBoundingBox(wari);
					local SpriObb = FXGeom.GetBoundingBox(wark);
					local SprkCenPot3D = SprkObb:GetPos();
					local SpriCenPot3D = SpriObb:GetPos();

					--构建两个Sprinkle之间的连线到地板的虚拟面
					local SprkCornerPoint1Z = SprkObb:CornerPoint(1).z;
					local SpriCornerPoint1Z = SpriObb:CornerPoint(1).z;
					local FirstPoint3D = Point3D(SprkCenPot3D.x,SprkCenPot3D.y,SprkCornerPoint1Z);
					local SecondPoint3D = Point3D(SpriCenPot3D.x,SpriCenPot3D.y,SpriCornerPoint1Z);
					local ThirdPoint3D = Point3D(SpriCenPot3D.x,SpriCenPot3D.y,HighSlab1Z);
					local LastPoint3D = Point3D(SprkCenPot3D.x,SprkCenPot3D.y,HighSlab1Z);

					local PlyLine =  PolyLine3D(TRUE);
					PlyLine:AddPoint(FirstPoint3D);
					PlyLine:AddPoint(SecondPoint3D);
					PlyLine:AddPoint(ThirdPoint3D);
					PlyLine:AddPoint(LastPoint3D);

					PlyLine:ClosePolyline();
					local PolyLineFace3D = PlyLine:Face3D();

					local pNode = FXClashDetection.CreateNode()
					FXClashDetection.AddGeometry(pNode, PolyLineFace3D)

					--检测此面是否与Sprinkler碰撞
					CheckSprGrp:Sub(wark)
					CheckSprGrp:Sub(wari)
					local IsCollidedSprinker = false
					if(CheckSprGrp:Size() > 0) then
						CheckSprGrp:ForEach(function(sprinklerEle)
							if(FXClashDetection.IsCollided(sprinklerEle, pNode)) then
								IsCollidedSprinker = true
							end
						end)
					end
					CheckSprGrp:Add(wark)
					CheckSprGrp:Add(wari)

					if (IsCollidedSprinker == false) then
						--检测此面是否与 Baffle 碰撞
						CheckProxy:ForEach(function (ProxyEle)
							local IsCollided = FXClashDetection.IsCollided(ProxyEle,pNode)
							if IsCollided == false then
								CheckReport.Error(wari,"The distance between sprinklers ("..wari.Id..") ("..wark.Id..") is ("..Dis..") m. The required minimum distance is 2 m")
							end
						end)
					end
				end
			end 
		end)
	end)
end

function main()
	CheckEngine.SetCheckType("BuildingStorey")
	.BindCheckFunc("CheckDisOfSprinkler")
	.Run()
end