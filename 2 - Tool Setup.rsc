dBox "Tool Setup" center,center,170,35 toolbox NoKeyboard Title:"Tool Setup"
    init do
        shared Args
        
        if Args.General.debug = 1 then do
            ShowItem("Debug")
        end
        
        // Initialize the hwy dbd prompt
        //if Args.General.hwyPrompt = null then Args.General.hwyPrompt = "Choose Highway DBD"
        
        // Initialize the count field array
        if Args.General.countFields.length = 0 then Args.General.countFields = {}
        
        // Set the item variables if the Args item exists for it
        dim a_list[0]
        // Format: dbox item name, prompt variable, variable name, position variable
        Args.GUI.Setup.ItemList = 
                {
                {"txt_modName",,Args.General.modelName,,""},
                {"hwy",Args.General.hwyPrompt,Args.General.hwyDBD,,"agg"},
                {"tazID",,Args.General.nodeTAZIdField,Args.General.nodeFieldList,"int3"},
                {"popFClass",,Args.General.fClass,Args.General.linkFieldList,"int10"},
                {"popCC",,Args.General.ccClass,Args.General.uniqueFClasses,"int8"},
                {"popFacType",,Args.General.facType,Args.General.linkFieldList,"int11"},
                {"popSpeed",,Args.General.speed,Args.General.linkFieldList,"int4"},
                {"popABLanes",,Args.General.abLanes,Args.General.linkFieldList,"int5"},
                {"popBALanes",,Args.General.baLanes,Args.General.linkFieldList,"int6"},
                {"popMedian",,Args.General.medType,Args.General.linkFieldList,"int7"},
                {"todTxt",,Args.General.todString,,}
                }


        
        if Args.length <> null then RunMacro("Set Setup Dbox Items")
        
    enditem
    
    Edit Text "txt_modName" 15, 1, 30,1 Prompt:"Name of Model" Variable: Args.General.modelName
    
	// Highway DBD drop down menu
	Popdown Menu "hwy" same, after, 24, 7 prompt: "Highway DBD" list: {Args.General.hwyPrompt,"Choose Highway DBD"} variable:Args.General.PosVars.agg do
        on escape goto quit
        
        if Args.General.PosVars.agg = 2 then do
            Args.General.hwyDBD = ChooseFile({{"Geographic File (*.dbd)", "*.dbd"}}, "Choose Highway DBD",{{"Initial Directory",Args.General.initialDir}})
            Args.General.PosVars.agg = 1
        end
        {Args.General.nlayer,Args.General.llayer} = GetDBLayers(Args.General.hwyDBD)
        a_info = GetDBInfo(Args.General.hwyDBD)
        Args.General.hwyScope = a_info[1]
        
        path = SplitPath(Args.General.hwyDBD)
        Args.General.hwyPrompt = path[3] + path[4]
        Args.General.initialDir = path[1] + path[2]
        
        // Link Field List
        tempLink = AddLayerToWorkspace(Args.General.llayer,Args.General.hwyDBD,Args.General.llayer,)
        fieldList = GetFields(tempLink,"All")
        Args.General.linkFieldList = fieldList[1]
        DropLayerFromWorkspace(tempLink)
        
        
        // Node Field List        
        tempNode = AddLayerToWorkspace(Args.General.nlayer,Args.General.hwyDBD,Args.General.nlayer,)
        fieldList = GetFields(tempNode,"All")
        Args.General.nodeFieldList = fieldList[1]        
        DropLayerFromWorkspace(tempNode)
        
        RunMacro("HwyDropDownEnableItems")
        
        quit:
        on escape default
	enditem 
    
    
    
    
    
    // Choose Node's TAZ ID Field
	Popdown Menu "tazID" after, same, 10, 8 prompt: "Node TAZ Field" list: Args.General.nodeFieldList Disabled variable: Args.General.PosVars.int3 do
        Args.General.nodeTAZIdField = Args.General.nodeFieldList[Args.General.PosVars.int3]
        EnableItem("View Highway DBD")
	enditem 
	
    
    
    
    
    
	
	//	View Highway Button
	button "View Highway DBD" 15,after,23 Disabled do	
		
        // Error Check
        if Args.General.hwyDBD = null or Args.General.nodeTAZIdField = null then do
            ShowMessage("You must select a geographic file and the TAZ field.")
            goto quit
        end
        
       
        map = RunMacro("Create Highway Map")
        // map = CreateMap("Highway",{{"Scope",Args.General.hwyScope}})
        // Args.General.llayer = AddLayer(map,Args.General.llayer,Args.General.hwyDBD,Args.General.llayer,)
        // Args.General.nlayer = AddLayer(map,Args.General.nlayer,Args.General.hwyDBD,Args.General.nlayer,)
        SetLayer(Args.General.nlayer)
        
     
        RedrawMap(map)
        
        // Create an Editor to show the external station data
        // CreateEditor("External Data",dv_join + "|External Stations",,{{"Size",80,25}})
        
        quit:
	enditem
	
    
    
    
    
    
    // Choose Link Functional Class Field
	Popdown Menu "popFClass" same, after, 15, 8 prompt: "Functional Class" list: Args.General.linkFieldList variable: Args.General.PosVars.int10 Disabled do
        Args.General.fClass = Args.General.linkFieldList[Args.General.PosVars.int10]
        
        // Get a unique list of the functional class values
        // for the centroid connector popdown menu
        tempLink = AddLayerToWorkspace(Args.General.llayer,Args.General.hwyDBD,Args.General.llayer,)
        v_temp = GetDataVector(tempLink + "|",Args.General.fClass,)
        a_temp = SortArray( v2a( v_temp ), {{"Unique","True"}} )
        Args.General.uniqueFClasses = CopyArray(a_temp)
        DropLayerFromWorkspace(tempLink)
        
        EnableItem("popCC")
	enditem 
    
    // Choose which functional class represents centroid connectors
    Popdown Menu "popCC" after, same, 15, 8 prompt: "Cent Con. Class" list: Args.General.uniqueFClasses variable: Args.General.PosVars.int8 Disabled do
        Args.General.ccClass = Args.General.uniqueFClasses[Args.General.PosVars.int8]
	enditem 
    
    // Choose Link Facility Type Field
    // Different from Func Class in that it isn't an FHWA-limited designation
	Popdown Menu "popFacType" 15, after, 15, 8 prompt: "Facility Type" list: Args.General.linkFieldList variable: Args.General.PosVars.int11 Disabled do
        Args.General.facType = Args.General.linkFieldList[Args.General.PosVars.int11]
        
        // Get a unique list of the functional class values
        tempLink = AddLayerToWorkspace(Args.General.llayer,Args.General.hwyDBD,Args.General.llayer,)
        v_temp = GetDataVector(tempLink + "|",Args.General.facType,)
        a_temp = SortArray( v2a( v_temp ), {{"Unique","True"}} )
        Args.General.uniqueFacType = CopyArray(a_temp)
        DropLayerFromWorkspace(tempLink)
        
	enditem     
    
    // Choose Link Speed Field
	Popdown Menu "popSpeed" same, after, 20, 8 prompt: "Speed" list: Args.General.linkFieldList variable: Args.General.PosVars.int4 Disabled do
        Args.General.speed = Args.General.linkFieldList[Args.General.PosVars.int4]
	enditem 
    
    // Choose Link AB Lanes Field
	Popdown Menu "popABLanes" 15, after, 20, 8 prompt: "AB Lanes" list: Args.General.linkFieldList variable: Args.General.PosVars.int5 Disabled do
        Args.General.abLanes = Args.General.linkFieldList[Args.General.PosVars.int5]
        
        // Set the BA field if one is automatically found
        {field,int} = RunMacro("getBAField",Args.General.abLanes, Args.General.linkFieldList)
        Args.General.baLanes = field
        Args.General.PosVars.int6 = int
	enditem 
    
    // Choose Link BA Lanes Field
	Popdown Menu "popBALanes" same, after, 20, 8 prompt: "BA Lanes" list: Args.General.linkFieldList variable: Args.General.PosVars.int6 Disabled do
        Args.General.baLanes = Args.General.linkFieldList[Args.General.PosVars.int6]
	enditem 
    
    // Choose Divided Field
	Popdown Menu "popMedian" same, after, 15, 8 prompt: "Median Type" list: Args.General.linkFieldList variable: Args.General.PosVars.int7 Disabled do
        Args.General.medType = Args.General.linkFieldList[Args.General.PosVars.int7]
	enditem 
    
    
    // Main scroll list holding all field names
    Text "Link Fields" 106,.5,20
    Scroll List " " 106, 1.5, 27, 20 List: Args.General.linkFieldList Multiple Variable:chosenFields
    
    // Count Fields
    Text "Count Field(s)" 70,2,13
    Scroll List " " 68, after, 30, 5 List: Args.General.countFields
    button " " after, same, 5 Prompt:"<<" do
        if Args.General.countFields[1] = null then do
            for i = 1 to chosenFields.length do
                if i = 1 then Args.General.countFields[1] = Args.General.linkFieldList[chosenFields[i]]
                else Args.General.countFields = Args.General.countFields + {Args.General.linkFieldList[chosenFields[i]]}
            end
        end else do
            for i = 1 to chosenFields.length do
                Args.General.countFields = Args.General.countFields + {Args.General.linkFieldList[chosenFields[i]]}
            end
        end
    enditem
    
    button " " same, after, 5 Prompt:"X" do
        Args.General.countFields = {}
    enditem
    
    // TOD periods
    Text 70,10 Variable:"TOD Periods (e.g., 'AM,MD,PM,NT')"
    Edit Text "todTxt" same,after,20  variable:Args.General.todString do
        Args.General.TOD = ParseString(Args.General.todString, ", " ,)
    endItem

    
    
    
    
    
    
    
    // Debug Button
    button "Debug" 5, 20, 12 Hidden  do
        ShowMessage(1)
    enditem
    
    
    
    // Save Settings Button
    button "Save Settings" same, after, 12 do
        RunMacro("Save Settings")
    enditem
    
    
    // Load Settings Button
    button "Load Settings" same, after, 12 do
        RunMacro("Load Settings")
        RunMacro("Set Setup Dbox Items")
    enditem
    
    
	// Quit Button
	button "Return" 55, 28, 12 do
        // a_view = GetViewNames()
        // for i = 1 to a_view.length do
            // CloseView(a_view[i])
        // end
        Return(0)
	enditem
    
EndDbox