
// ------------------------
//      Helper Macros
// ------------------------

// Save Settings Macro
Macro "Save Settings"
    shared Args
    on escape goto quit
    Opts = null
    Opts.[Initial Directory] = Args.General.initialDir
    settingsFile = ChooseFileName({{"Array (*.arr)", "*.arr"}},"Save Settings As",Opts)
    SaveArray(Args,settingsFile)
    quit: 
EndMacro



// Load Settings Macro
Macro "Load Settings"
    shared Args
    on escape goto quit
    Opts = null
    Opts.[Initial Directory] = Args.General.initialDir
    settingsFile = ChooseFile({{"Array (*.arr)", "*.arr"}},"Load Settings From",Opts)
    Args = LoadArray(settingsFile)
    
    // Update Setup GUI items
    
    quit:
EndMacro



// Create highway map macro
// Extending this macro to accept optional arguments
Macro "Create Highway Map" (hwyDBD)
    // If the hwyDBD argument is not passed, then create a map of the
    // highway layer referenced in Args.General
    if hwyDBD = null then do
        shared Args
        map = CreateMap("Highway Map",{{"Scope",Args.General.hwyScope}})
        Args.General.llayer = AddLayer(map,Args.General.llayer,Args.General.hwyDBD,Args.General.llayer,)
        Args.General.nlayer = AddLayer(map,Args.General.nlayer,Args.General.hwyDBD,Args.General.nlayer,)
        RunMacro("G30 new layer default settings", Args.General.nlayer)
        RunMacro("G30 new layer default settings", Args.General.llayer)
        return(map)
    end
    
    // If hwyDBD is passed, then create the map on it.
    if hwyDBD <> null then do
        scope = GetDBInfo(hwyDBD)
        scope = scope[1]
        map = CreateMap("Highway Map",{{"Scope",scope}})
        {nlayer,llayer} = GetDBLayers(hwyDBD)
        llayer = AddLayer(map,llayer,hwyDBD,llayer,)
        nlayer = AddLayer(map,nlayer,hwyDBD,nlayer,)
        RunMacro("G30 new layer default settings", nlayer)
        RunMacro("G30 new layer default settings", llayer)
        return({map,nlayer,llayer})
    end
    
EndMacro



// Helper macro to get a link's field value
// (needed because of the Args object format)
Macro "GetLinkValue" (linkID,fieldName)
    shared Args
    fieldPos = ArrayPosition(Args.General.linkFieldList, {fieldName},)
    linkRH = LocateRecord(Args.General.llayer + "|","ID",{linkID},)
    vals = GetRecordValues(Args.General.llayer, linkRH,)
    return(vals[fieldPos][2])
EndMacro

 
// Fill in the Setup dbox items with any Args that exist
Macro "Set Setup Dbox Items"
    shared Args
    // required format for Args.GUI.Setup.ItemList
    //{ItemName,PromptVar,ValueVar,ListVar,PositionVar}

    for i = 1 to Args.GUI.Setup.ItemList.length do
        itemName  = Args.GUI.Setup.ItemList[i][1]
        promptVar = Args.GUI.Setup.ItemList[i][2]
        value     = Args.GUI.Setup.ItemList[i][3]
        list      = Args.GUI.Setup.ItemList[i][4]
        pos       = Args.GUI.Setup.ItemList[i][5]
        
        // Before doing anything, the value variable must not be null
        if value <> null then do
            // if it's the highway dbd item, enable the related items
            if itemName = "hwy" and value <> null then RunMacro("HwyDropDownEnableItems")
            // if the list variable does not exist, then simply set the position var to 1
            if list = null and pos <> null then Args.General.PosVars.(pos) = 1
            // if the list variable does exist, then set the position variable to match value
            if list <> null then Args.General.PosVars.(pos) = ArrayPosition(list,{value},)
        end
    end
EndMacro


// Fill in the Benefits dbox items with any Args that exist
Macro "Set Benefits Dbox Items"
    shared Args
    // required format for Args.GUI.Benefits.ItemList
    //{ItemName,PromptVar,ValueVar,ListVar,PositionVar}

    for i = 1 to Args.GUI.Benefits.ItemList.length do
        itemName  = Args.GUI.Benefits.ItemList[i][1]
        promptVar = Args.GUI.Benefits.ItemList[i][2]
        value     = Args.GUI.Benefits.ItemList[i][3]
        list      = Args.GUI.Benefits.ItemList[i][4]
        pos       = Args.GUI.Benefits.ItemList[i][5]
        // Before doing anything, the value variable must not be null
        if value <> null then do
            // if the list variable does not exist, then simply set the position var to 1
            if list = null and pos <> null then Args.Benefits.PosVars.(pos) = 1
            // if the list variable does exist, then set the position variable to match value
            if list <> null then Args.Benefits.PosVars.(pos) = ArrayPosition(list,{value},)
        end
    end
EndMacro

// Fill in the LinkJoin dbox items with any Args that exist
Macro "Set LinkJoin Dbox Items"
    shared Args
    // required format for Args.GUI.LinkJoin.ItemList
    //{ItemName,PromptVar,ValueVar,ListVar,PositionVar}

    for i = 1 to Args.GUI.LinkJoin.ItemList.length do
        itemName  = Args.GUI.LinkJoin.ItemList[i][1]
        promptVar = Args.GUI.LinkJoin.ItemList[i][2]
        value     = Args.GUI.LinkJoin.ItemList[i][3]
        list      = Args.GUI.LinkJoin.ItemList[i][4]
        pos       = Args.GUI.LinkJoin.ItemList[i][5]
        // Before doing anything, the value variable must not be null
        if value <> null then do
            // if the list variable does not exist, then simply set the position var to 1
            if list = null and pos <> null then Args.LinkJoin.PosVars.(pos) = 1
            // if the list variable does exist, then set the position variable to match value
            if list <> null then Args.LinkJoin.PosVars.(pos) = ArrayPosition(list,{value},)
        end
    end
EndMacro

// Runs when a highwayDBD is selected in the settings dbox (or when settings are loaded)
Macro "HwyDropDownEnableItems"
        EnableItem("View Highway DBD")
        EnableItem("tazID")
        EnableItem("popFClass")
        EnableItem("popCC")
        EnableItem("popFacType")
        EnableItem("popSpeed")
        EnableItem("popABLanes")
        EnableItem("popBALanes")
        EnableItem("popMedian")
        EnableItem("popFacType")
EndMacro

// This in the setup dialog box, this macro takes the ab field
// and searches for the ba.  Returns name and position
/* Macro "getBAField" (abField)
    shared Args
    // search for ba direction if ab field contains a unique "AB"
    firstPos = Position(abField,"AB")
    // if the field contains "AB"
    if firstPos <> 0 then do
        // if the field contains only one "AB"
        if PositionFrom(firstPos + 2,abField,"AB") = 0 then do
            // Change "AB" to "BA" and test to see if that field exists
            baName = Substitute(abField,"AB","BA",)
            pos = ArrayPosition(Args.General.linkFieldList,{baName},{{"Case Sensitive",True}})            
            if pos <> 0 then do
                field = baName
                int = pos
                return({field,int})
            end
        end
    end
EndMacro */

// Generalize the macro to accept a field and field list arguments

Macro "getBAField" (abField, fieldList)
    // search for ba direction if ab field contains a unique "AB"
    firstPos = Position(abField,"AB")
    // if the field contains "AB"
    if firstPos <> 0 then do
        // if the field contains only one "AB"
        if PositionFrom(firstPos + 2,abField,"AB") = 0 then do
            // Change "AB" to "BA" and test to see if that field exists
            baName = Substitute(abField,"AB","BA",)
            pos = ArrayPosition(fieldList,{baName},{{"Case Sensitive",True}})            
            if pos <> 0 then do
                field = baName
                int = pos
                return({field,int})
            end
        end
    end
EndMacro
