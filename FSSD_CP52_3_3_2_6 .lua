  --[[---------------------------------------------------
	Clause ID:    FSSD_CP52_3_3_2_6 
	Author:      Guo Chunwei
	Tester:		
	Date:		2014.12.15

	Description :   This clause describes a pre-action sprinkler system, which is a combination of sprinkler system and smoke/thermal detectors. 
					No need to check a), b), and c) 
					There should be a solenoid valve present. 
					Result Message (FAIL): There is no trip mechanism (solenoid valve) found. 
					Result Message (WARNING): No smoke or heat detector found.

	Func List:   1.Function Name: CheckPreactionSystems ()
				   Parameter :    [in]  Building
				   Description:   Used to complete the Desciption.
	History:	1.Date:2014.12.17
				  Author:Wei Xubo
				  Modification:Fix (add Description solenoid valve)
				2. ...
--]]---------------------------------------------------

function CheckPreactionSystems( Building )
	assert(type(Building) == "table" and Building.Id > 0)
	local Project  = Building:GetParent():GetParent()
	--local pipeTerminals = Project:GetPipeTerminals()  -- 模型得不到
	local pipeTerminals = Project:GetDescendants("FlowTerminal")
	local DistributionControls = Project:GetDescendants("DistributionControlElement")
	local IfcFlowControllers = Project:GetDescendants("FlowController")

	local isSprinklerSystem = false
	pipeTerminals:ForEach(function ( TerminalEle )
		local Type =  TerminalEle:GetPredefinedTypeOfSubType();
		if Type ~= nil and string.find(string.upper(Type),"SPRINKLER") ~= nil then
			isSprinklerSystem = true
		end

	end)
    if isSprinklerSystem == false then
    	CheckReport.Error(Building,"No pre-action system provided.")
    else
    	local haveSmokeDetector = false
    	local haveThermalDetector = false 
    	if DistributionControls:Size() > 0 then
    		DistributionControls:ForEach(function (DisControlEle)
    			local isBell = false
    			local ID = DisControlEle:GetAuxAttri("IfcTypeObject.IFCALARMTYPE")
				if ID ~= nil then
					local Ele = NewElement("UnknownObject",ID)
					local Type = Ele:GetAuxAttri("Entity.PredefinedType")
					if Type ~= nil and string.find(string.upper(Type),"BELL") ~= nil then
						isBell = true
					end
				end
    			local Description = DisControlEle:GetAttri("Description")
    			if Description ~= nil and isBell == true then
    				if string.find(string.lower(Description),"smoke_detector") ~= nil 
    					or string.find(string.lower(Description),"smoke detector") ~= nil 
    					then
		    			haveSmokeDetector = true
					end
				    if string.find(string.lower(Description),"heat_detector") ~= nil 
				    	or string.find(string.lower(Description),"heat detector") ~= nil 
				    	then
				    	haveThermalDetector = true
				    end
				end
    		end)
        end
  		if haveSmokeDetector == false and haveThermalDetector == false then
  			CheckReport.Warning(Building,"no smoke or heat detector is found.")
  		else
  			local haveSolenoidValve = false
  			if IfcFlowControllers:Size() > 0 then
  				IfcFlowControllers:ForEach(function ( ControllerEle )
  					local Description = ControllerEle:GetAttri("Description")
  					if Description ~= nil 
  						and (string.find(string.lower(Description),"solenoid_valve") ~= nil 
  						or string.find(string.lower(Description),"solenoid valve") ~= nil )
  						then
	  					local ID = ControllerEle:GetAuxAttri("IfcTypeObject.IFCVALVETYPE");
						if ID ~= nil then
							local ele = NewElement("UnknownObject",ID)
							local Type = ele:GetAuxAttri("Entity.PredefinedType")
							if(Type ~= nil) then
								if(string.find(string.upper(Type),"SAFETYCUTOFF") ~= nil) then
								    haveSolenoidValve = true
							    end
							end
						end
					end
  				end)
  			end
  			if haveSolenoidValve == false then
  			   CheckReport.Error(Building,"There is no trip mechanism (solenoid valve) found.")
  			end
  		end
    end
end


function main()
	CheckEngine.SetCheckType("Building")
	CheckEngine.BindCheckFunc("CheckPreactionSystems")
	CheckEngine.RunCheckPipeline()
end



