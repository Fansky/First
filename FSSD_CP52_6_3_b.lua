 --[[--------------------------------------------------------------------------------------
	Clause ID：  IBS_PUB_5_6_6 FIG 10
	Author:      Wang Xinzhuo
	Tester:      

	Date:        2014.12.11(Completed)
				 2014.--.--(Tested)
				 2014.--.--(Amend)

	Description：的两个模型 scenario 1 和 scenario 2中没有Space，因此条例无错误报出。 			  
    			  

	Func List：  1.Function Name: CheckTheFlushValve
				   Parameter：    [in]  Building
				   Description:   Used to complete the Desciption.
			
				 2.Function Name: CheckTwoElementDistance
				   Parameter：    [in]  Element1,Element2
				   				  [out] nil or number
				   
				 3.Function Name: CheckTheHighestSubMeter
				   Parameter：    [in]  SubMeterGrp,Slab
				   				  [out] number and Element
				  		  
	History:	1.Date:   2014.--.--
				  Author:  
				  Modification:  
--]]--------------------------------------------------------------------------------------

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




function CheckTheElementTypeIsSprinkler(Element)
	local Flag = false;
	local ID  = Element:GetAuxAttri("IfcTypeObject.IFCFIRESUPPRESSIONTERMINALTYPE");
	local ElementType =  Element:GetPredefinedTypeOfSubType();
	if(ElementType ~= nil) then
		if(string.find(string.lower(ElementType),"sprinkler") ~= nil) then
			Flag = true;
		end
	end
	return Flag;
end


function FindWideAndHighOfBaffle(BaffleObb,CenterSpr1,CenterSpr2)
	
	local High;
	local Wide;

	local Spr1NewCenter = Vector(CenterSpr1.x,CenterSpr1.y,CenterSpr1.z);
	local Spr2NewCenter = Vector(CenterSpr2.x,CenterSpr2.y,CenterSpr1.z);

	local Spr1ToSpr2Vec = Spr1NewCenter:Sub(Spr2NewCenter);

	local BaffleObbPoint1 = BaffleObb:CornerPoint(1);

	local BaffleObbPoint0 = BaffleObb:CornerPoint(0);
	local BaffleObbPoint2 = BaffleObb:CornerPoint(2);
	local BaffleObbPoint4 = BaffleObb:CornerPoint(4);
	local Vector0 = Vector(BaffleObbPoint0.x,BaffleObbPoint0.y,BaffleObbPoint0.z);
	local Vector2 = Vector(BaffleObbPoint2.x,BaffleObbPoint2.y,BaffleObbPoint2.z);
	local Vector4 = Vector(BaffleObbPoint4.x,BaffleObbPoint4.y,BaffleObbPoint4.z);

	High = math.abs(BaffleObbPoint1.z - BaffleObbPoint0.z);

	local Point0ToPoint2Vec = Vector0:Sub(Vector2);
	local Point0ToPoint4Vec = Vector0:Sub(Vector4);

	local Vec1ToStandardProjection = math.abs( (Point0ToPoint2Vec:Dot(Spr1ToSpr2Vec) ) / ( Spr1ToSpr2Vec:Len() ) );
	local Vec2ToStandardProjection = math.abs( (Point0ToPoint4Vec:Dot(Spr1ToSpr2Vec) ) / ( Spr1ToSpr2Vec:Len() ) );

	if(Vec1ToStandardProjection < Vec2ToStandardProjection) then
		Wide = Point0ToPoint2Vec:Len();
	else
		Wide = Point0ToPoint4Vec:Len();
	end
	return Wide,High;
end






function CheckingTheSprinklerBaffles( Space )
	assert(type(Space) == "table" and Space.Id > 0);

	local HighSlab1Z
	local Slabs = Space:GetSlabsBelow();
	if(Slabs:Size() > 0) then
		Slabs:ForEach(function(SlabEle)
			local SlabObb = FXGeom.GetBoundingBox(SlabEle);
			local SlabCornerPoint1Z = SlabObb:CornerPoint(1).z;
			if(HighSlab1Z == nil) then
				HighSlab1Z = SlabCornerPoint1Z;
			elseif(SlabCornerPoint1Z > HighSlab1Z) then
				HighSlab1Z = SlabCornerPoint1Z;
			end
		end)
	end
	
	local BaffleGrp = FXGroup:new();
	local SprinklerGrp = FXGroup:new();

	--找到Space里所有的 Baffle
	local InSpaceElements = Space:GetInSpaceElement();
	if(InSpaceElements:Size() > 0) then
		InSpaceElements:ForEach(function(Element)
			local ElementType = Element.Type;
			if(ElementType ~= nil) then
				if(string.find(string.lower(ElementType),"buildingelementproxy") ~= nil) then
					local Description = Element:GetAuxAttri("Entity.Description")
					if(Description ~= nil) then
						if(string.find(string.lower(Description),"baffle") ~= nil) then
							BaffleGrp:Add(Element);
						end
					end
				end
			end
		end)
	end
	--找到 Space 里所有的 sprinkler
	local FlowTerminals = Space:GetChildren("FlowTerminal");
	if(FlowTerminals:Size() > 0) then
		FlowTerminals:ForEach(function(FlowTerminalEle)
			local IsSprinkler = CheckTheElementTypeIsSprinkler(FlowTerminalEle);
			if(IsSprinkler == true) then
				SprinklerGrp:Add(FlowTerminalEle);
			end
		end)
	end
	SprinklerGrp = SprinklerGrp:Unique();
	BaffleGrp = BaffleGrp:Unique();

	--判断Space里的Sprinkle和Baffle是否存在
	if(( SprinklerGrp:Size() > 1 ) and ( BaffleGrp:Size() > 0 ) and ( HighSlab1Z ~= nil )) then 
			
		SprinklerGrp:EachPair(SprinklerGrp,
		function(k,i,Sprk,Spri)
			if(k > i and Sprk ~= Spri) then
				--替换的方法
				--local Dis =  Distances(Sprk,Spri);
				local Dis =  FXMeasure.Distance(Sprk, Spri):Length();
				if(Dis < 2000) then
					local SprkObb = FXGeom.GetBoundingBox(Sprk);
					local SpriObb = FXGeom.GetBoundingBox(Spri);
					local SprkCenPot3D = SprkObb:GetPos();
					local SpriCenPot3D = SpriObb:GetPos();

					--找出底部最高的Sprinkle 的Z坐标
					local TheHighSprCornPoint0Z;
					local SprkCornerPoint0Z = SprkObb:CornerPoint(0).z;
					local SpriCornerPoint0Z = SpriObb:CornerPoint(0).z; 
					if(SprkCornerPoint0Z > SpriCornerPoint0Z) then
						TheHighSprCornPoint0Z = SprkCornerPoint0Z;
					else
						TheHighSprCornPoint0Z = SpriCornerPoint0Z;
					end
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
					SprinklerGrp:Sub(Sprk);
					SprinklerGrp:Sub(Spri);

					local IsCollidedSprinker = false;
					if(SprinklerGrp:Size() > 0) then
						SprinklerGrp:ForEach(function(sprinklerEle)
							if(FXClashDetection.IsCollided(sprinklerEle, pNode)) then
								IsCollidedSprinker = true;
							end
						end)
					end
					SprinklerGrp:Add(Sprk);
					SprinklerGrp:Add(Spri);

					if not(IsCollidedSprinker == true) then
						--检测此面是否与 Baffle 碰撞
						BaffleGrp:ForEach(function(BaffleEle)
							if(FXClashDetection.IsCollided(BaffleEle, pNode)) then
								--得到Baffle的宽度与高度
								local BaffleObb = FXGeom.GetBoundingBox(BaffleEle);

								local BafflesWide,BafflesHigh = FindWideAndHighOfBaffle(BaffleObb,SprkCenPot3D,SpriCenPot3D);
								
								if not (BafflesWide == 200 and BafflesHigh == 150) then
									CheckReport.Error(BaffleEle,"Baffle between sprinkler should be 200mm wide by 150mm high");
								else
									if(TheHighSprCornPoint0Z ~= nil) then
										local BaffleTopPoint3DZ = BaffleObb:CornerPoint(1).z;
										local Distance =  BaffleTopPoint3DZ - TheHighSprCornPoint0Z;
										if not ( (50 < Distance) and (Distance < 75)) then
											CheckReport.Error(BaffleEle,"Top of the baffle should be 50-75mm above the sprinkler deflector");
										end
									end
								end
							end
						end)
					end
				end
				
			end	
		end)
	end
end



function main()
	CheckEngine.SetCheckType("Space")
	.BindCheckFunc("CheckingTheSprinklerBaffles")
	.Run()
end