/*
To Do:

Need to add in a section where the count point layer is automatically
put back onto the links.  6/25/2015: code section exists, but has error.

*/


/*

Kyle

This is a generalized network review tool box.

Each tool is meant to be modularize so that they can be built one
at a time.

In order to facilitate this modular construction, a SHARED Args
option array is used.  Each macro/dbox needs simply to reference it.
Not all variables need to help in it, only ones with the potential to be
used by multiple macros/dboxs.

Instead of using abstraction macros, the default behaviour of options
arrays in TC is adequate.  For full help on using options arrays,
search the TC help glossary for:
"Options Arrays and Dot Notation"

I have included the most important stuff below. ** Also, at any time,
you can read and write the array to a text file using the Save/Load
buttons in the main dbox.

Reference a variable by name:
Args.StatePopulation

    if the name has spaces:
    Args.[State Population]
    
    Indirection (if the name of the variable is a string held in local
    variable TestName:
    TestName = "State Population"
    Args.(TestName)
    
    The trickiest is referencing record values using this setup.
    Use GetRecordValues to start
        vals = GetRecordValues(Args.layer, linkRH,)
    Normally, you could then just use layer and field names to get a value
        llayer.Length
    But, this doesn't work
        Args.llayer.(Args.fClass) --(or any of a large # of combos tried)
    Instead, you have to do the following:
    See where the field is positioned in the linkFieldList
        test1 = ArrayPosition(Args.linkFieldList, {Args.fClass},)
    Look that up in the vals array
        test2 = vals[test1][2]      ([1] is name, [2] is value)

Read and Write the Args array to/from text files:
SaveArray() and LoadArray()
*must save to a *.arr file
**only Save/Load can handle sub arrays.  Read/WriteArray cannnot.

Args organization:
Because the Args array will end up holding a lot of variables, they
are organized into sub objects.  The first is called "General", while the
others will be labeled for the tool they are specifically used by.  For
example, the file name of the highway DBD will be used by multiple tools,
and so is stored here:

Args.General.hwyDBD


*/




// Debug Macro
Macro "test"	
	RunMacro("TCB Init")
    RunMacro("G30 File Close All")
    RunDbox("NetworkCheck")
    
    // v_id = a2v({1,2,3})
    // RunDbox("routeCont",v_id)
    
EndMacro
	


// Main Dialog Box

dBox "NetworkCheck" center,center,125,25 toolbox NoKeyboard Title:"Network Check Tool"


	Init do	
        
        RunMacro("TCB Init")
        RunMacro("G30 File Close All")
        
        // Creation of Args array (if empty):
        shared Args
        if Args = null then do
            Args.objName = "Master Variable Container"
            Args.objDescr = "Object used to organize and pass variables between dboxes/macros."
        end
        
        // --- Debug Switch ---
        //shared debug
        //debug = 0 // 1 to turn on debug buttons in each Dbox
        Args.General.debug = 1  // 1 to turn on debug buttons in each Dbox
        
        if Args.General.debug = 1 then do
            ShowItem("Debug")
        end
        
        // Uncomment this if you want to reset the cont grid on open
        //a_cont = null     
        
        extTblPrompt = "Choose External Station Table"
        sePrompt = "Choose SE Table"
        
        
        // Allowed Facility Types
        //a_allowedFC = {"Interstate","Principal Arterial","Minor Arterial","Major Collector","Local"}
        // Regression Factors for Facility Types
        //a_ftFactor = {1,2,3,4,5}
        
        shared population
        population = null
        shared a_cont
        a_cont = null
        shared a_finPctThru
        a_finPctThru = null
        
        
	enditem
	
	
	
	
    
    

    
    
    // Settings Button
    button "Tool Setup" 50, 4, 12 do
        RunDbox("Settings")
    enditem
    
    // Advanced Simplification Button
	button "Advanced Simplification" same, after, 23  do
		
        // Error Check
        if Args.General.hwyDBD = null or Args.General.nodeTAZIdField = null then ShowMessage("You must select a geographic file and the TAZ field.")
        else RunDbox("Simplify")
        
        
	enditem
    
    button "Interchange Check" same, after, 23 do
        if Args.General.hwyDBD = null or Args.General.nodeTAZIdField = null then ShowMessage("You must select a geographic file and the TAZ field.")
        else RunDbox("Interchange")
    enditem
    
    button "Benefit Calculation" same, after, 23 do
        if Args.General.hwyDBD = null
        then ShowMessage("At a minimum, the highway DBD \nmust be specified using 'Tool Setup'.")
        else RunDbox("Benefits")
    enditem
    
    button "Adv Spatial Join (link)" same, after, 23 do
        if Args.General.hwyDBD = null
        then ShowMessage("At a minimum, the highway DBD \nmust be specified using 'Tool Setup'.")
        else RunDbox("LinkJoin")
    enditem    
    
    
    
    
    
    
    
    

    // Debug Button
	
    button "Debug" 5, 16, 12 Hidden do
        ShowMessage(1)
    enditem
    
    
    
	// Quit Button
	button "Quit" 55, 16, 12 do
        // a_view = GetViewNames()
        // for i = 1 to a_view.length do
            // CloseView(a_view[i])
        // end
        //RunMacro("G30 File Close All")
        Return(0)
	enditem
EndDbox




dBox "Settings" center,center,170,35 toolbox NoKeyboard Title:"Tool Setup"
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
        {field,int} = RunMacro("getBAField",Args.General.abLanes)
        Args.General.baLanes = field
        int6 = int
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






dBox "Simplify" center,center,125,25 toolbox NoKeyboard Title:"Advanced Simplification"
/* 
GetEndPoints()      -   Returns IDs of the two end points of a link
GetNodeLinks()      -   Returns the IDs of links that begin or end at a node
GetDistance()       -   distance between two points - may not need

SelectNone()        -   Removes all records from a selection set
SelectRecord()      -   Adds current record to selection set

RH2ID()             -   Converts a record handle into a feature ID
LocateRecord()      -   Locates record based on value of field
GetRecordValues()   -   returns an opts array of field names and values
                        can access with opts.fieldname
SetRecordValues()   -   use this to update fields for a record

SetMapScope()       -   can be used to pan the map
GetSetScope()       -   Gets scope of selection set
*look into other scope tools

JoinLinks()
SplitLinks()

    */ 
    
    
	Init do
        shared Args
        
        if Args.General.debug = 1 then do
            ShowItem("Debug")
        end
        
        // Set the tool to test as the default mode.
        // In test mode, it only selects the links/nodes, which the
        // user can then review to make sure they like the result.
        Args.Simplify.runMode = "test"
        testRadioInt = 1
        
    enditem

    // Additional Field Explanation
    Text" " same,after,45,1.1 Variable:"Optional: Choose count field(s)"
    Text" " same,after,45,1.1 Variable:"to maintain after two links are joined."
    
    button " " after, same, 3, 1 Prompt:"?" do
        ShowMessage("The simplify process will join links even if one has count\n"+
                    "info and the other doesn't. This can lead to a loss of count data.\n"+
                    "Selecting these fields will ensure that the count data is preserved\n"+
                    "even though the links get joined.")
    enditem
    
    // Test or run radio button
    Radio List " " 2, after, 30, 3 Prompt:"Test Settings or Full Run" Variable:testRadioInt
    Radio Button " " 3, 4, 10,1 Prompt:"Test " do
         Args.Simplify.runMode = "test"
         endItem
    Radio Button " " 15, same, 10,1 Prompt:"Full" do
         Args.Simplify.runMode = "full"
         endItem


    
    // Run Simplification Button
	button "Simplify" 85, 23, 12 do
        
        EnableProgressBar("Simplifying the Network",2)
        
        // Test to make sure all required fields are selected
        if Args.General.fClass = null or Args.General.speed = null or Args.General.abLanes = null or Args.General.baLanes = null or Args.General.medType = null then do
            ShowMessage("Not all required fields are selected.")
            goto quit
        end
            
        // If actually joining links, make a backup copy of the dbd
        if Args.Simplify.runMode = "full" then do
            
            on error goto skipfolder
            backupDir = Args.General.initialDir + "backup"
            CreateDirectory(backupDir)
            skipfolder:
            on error default
            
            a_path = SplitPath(Args.General.hwyDBD)
            backupDBD = backupDir + "\\" + a_path[3] + a_path[4]
            CopyDatabase(Args.General.hwyDBD,backupDBD)
        end
        
        // In order to reference record fields easily,
        // put the Args.General.llayer (line layer name)
        // into simple, local variables
        llayer = Args.General.llayer
    
        // Minimum length cutoff for automatic joining
        // Can make this a user input
        cutOff = .25
        
        // Create Map
        map = RunMacro("Create Highway Map")
        SetLayer(Args.General.nlayer)
        
        potentialSet = RunMacro("G30 create set","Potential Nodes to Join")
        autoSet = RunMacro("G30 create set","Nodes to Join Automatically")
        errorSet = RunMacro("G30 create set","Stray Nodes (to delete)")
        
        // Create a selection set of non-centroid nodes to check
        SetLayer(Args.General.nlayer)
        nonCentroidQuery = "Select * where nz(" + Args.General.nodeTAZIdField + ") < 1"
        nonCentroidSet = "non-centroid nodes"
        numNonCentr = SelectByQuery(nonCentroidSet,"Several",nonCentroidQuery)
        
        // Create a point file to keep track of count locations and add to map
        // (Delete it if it already exists from a previous, incomplete run)
        Args.Simplify.countDBD = Args.General.initialDir + "countLayer.dbd"
        if GetDBInfo(Args.Simplify.countDBD) <> null then DeleteDatabase(Args.Simplify.countDBD)
        Args.Simplify.cLayer = "Counts"
        CreateDatabase(Args.Simplify.countDBD, "point", {{"Layer name",Args.Simplify.cLayer}})
        Args.Simplify.cLayer = AddLayer(map,Args.Simplify.cLayer,Args.Simplify.countDBD,Args.Simplify.cLayer,)
        RunMacro("G30 new layer default settings", Args.Simplify.cLayer)
        
        // Add fields
        for i = 1 to Args.General.countFields.length do
            type = GetFieldType(Args.General.llayer + "." + Args.General.countFields[i])
            if type = "Real" then decimal = 2 else decimal = 0
            strct = strct + {{Args.General.countFields[i], type, 12, decimal, "False", , , , , , , null}}
        end
        // Modify the table
        ModifyTable(Args.Simplify.cLayer, strct)
        
        // Create a progress bar to keep track of progress
        numNodeRecords = GetRecordCount(Args.General.nlayer,nonCentroidSet)
        numLinkRecords = GetRecordCount(Args.General.llayer,)
        CreateProgressBar("Checking Nodes", "True")
        

        
        nodeRH = GetFirstRecord(Args.General.nlayer + "|" + nonCentroidSet,)
        nodeCount = 0
        linkCount = 0
        while nodeRH <> null do
            
            // Update the progress bar
            nodeCount = nodeCount + 1
            intPercent = Round(nodeCount / numNodeRecords * 100,0)
            interrupted = UpdateProgressBar("Node " + String(nodeCount) + " of " + String(numNodeRecords),intPercent)
            
            // If the user presses the "Cancel" button, stop simplifying
            if interrupted then do
                ShowMessage("User pressed the 'Cancel' button.")
                goto quit
            end
            
            SetLayer(Args.General.nlayer)
            nodeID = RH2ID(nodeRH)
            
            // Stray nodes (with no links) will throw a NotFound error.
            // Catch it, and place the node into the error set
            on NotFound do
                SelectRecord(errorSet)
                goto skip
            end
            a_links = GetNodeLinks(nodeID)      
            skip:
            on NotFound default
            
            // Only focus on nodes with 2 links attached.
            // More implies an intersection, which can't be joined.
            if a_links.length = 2 then do
                
                // Determine if either of the two links is a CC
                eitherCC = "No"
                for i = 1 to a_links.length do
                    fClass = RunMacro("GetLinkValue", a_links[i],Args.General.fClass)
                    if fClass = Args.General.ccClass then do
                        eitherCC = "Yes"
                        i = a_links.length + 1
                    end
                end
                

                
                // Continue if neither link is a CC
                if eitherCC = "No" then do
                    SelectRecord(potentialSet)
                    a_length = null
                    a_hasCount = null
                    
                    for i = 1 to a_links.length do
                        SetLayer(Args.General.llayer)
                        linkRH = LocateRecord(Args.General.llayer + "|","ID",{a_links[i]},)
                        vals = GetRecordValues(Args.General.llayer, linkRH,)
                        
                        // Check if the link has any count data to preserve.  If so,
                        // set the count link value to the link ID
                        countLink = 0
                        for j = 1 to Args.General.countFields.length do
                            value = RunMacro("GetLinkValue", a_links[i],Args.General.countFields[i])
                            if value <> null then do
                                countLink = i
                                a_countVals = GetRecordValues(Args.General.llayer, linkRH,Args.General.countFields)
                                j = Args.General.countFields.length + 1
                            end
                        end
                        
                        // Check if the link is below the cutoff threshold
                        // If so, move node from potential set to automatic
                        // Because "Length" is a standard/TC field, safe to
                        // reference it directly
                        if llayer.Length < cutOff then do
                            SetLayer(Args.General.nlayer)
                            SelectRecord(autoSet)
                            UnselectRecord(potentialSet)
                        end
                        
                        // Store some data for both links into arrays for next step
                        a_length = a_length + {llayer.Length}
                        if countLink <> 0 then a_hasCount = a_hasCount + {1} else a_hasCount = a_hasCount + {0}
                    end
                    
                    // After checking both links, create a count node if: 
                        // the node's links will be joined (node is a member of the autoSet)
                        // count data is present on the short link only
                        // (I preserve the longer-link's attributes by listing it first in JoinLinks())
                    SetLayer(Args.General.nlayer)
                    minLength = VectorStatistic(A2V(a_length),"Min",)
                    minPosition = ArrayPosition(a_length,{minLength},)
                    maxLength = VectorStatistic(A2V(a_length),"Max",)
                    maxPosition = ArrayPosition(a_length,{maxLength},)
                    
                    if a_hasCount[minPosition] = 1 and a_hasCount[maxPosition] = 0 and IsMember(autoSet,nodeRH) then do
                    // if countLink <> 0 and IsMember(autoSet,nodeRH) then do
                        coord = GetPoint(nodeID)
                        SetLayer(Args.Simplify.clayer)
                        new_id = AddPoint(coord, nodeID) //use the same ID as the merged node
                        
                        // Set the record values
                        countRH = LocateRecord(Args.Simplify.clayer + "|","ID",{new_id},)
                        a_temp = null
                        for j = 1 to Args.General.countFields.length do
                            // if j = 1 then a_temp = {{Args.General.countFields[j],a_countVals[j][2]}}
                            // else a_temp = a_temp + {{Args.General.countFields[j],a_countVals[j][2]}}
                            a_temp = a_temp + {{Args.General.countFields[j],a_countVals[j][2]}}
                        end
                        SetRecordValues(Args.Simplify.clayer, countRH,a_temp)
                    end
                end
            end

            // You have to get the next RH before deleting the current one
            prevNodeRH = nodeRH
            nodeRH = GetNextRecord(Args.General.nlayer + "|" + nonCentroidSet,nodeRH,)
            
            
            
            // Once count data has been preserved, join the links if
            // the node has been placed in the auto set
            // In addition, only join if the runMode is "full"
            if Args.Simplify.runMode = "full" then do
                SetLayer(Args.General.nlayer)
                if IsMember(autoSet,prevNodeRH) then do
                    SetLayer(Args.General.llayer)
                    // the first link id provided has its attributes preserved.
                    // make sure the longer link is the first argument.
                    // In addition, the topology of the new/combined link is
                    // also determined by order of argument.  If the topology changes,
                    // one-way links will reverse direction.  Catch and correct.
                    bigLink = a_links[maxPosition]
                    smallLink = a_links[minPosition]
                    
                    // Get position of first endpoint in the longer link
                    a_bigPts = GetLine(bigLink)
                    before = a_bigPts[1]           // access the lat/long using before.lon and before.lat
                    
                    // Join Links
                    a_newIDs = JoinLinks(bigLink,smallLink,)
                    SetLayer(Args.General.nlayer)
                    a_deletedID = DeleteNode(RH2ID(prevNodeRH),)
                    
                    // Get position of first endpoint in joined line
                    newLink = a_newIDs[1]
                    SetLayer(Args.General.llayer)
                    a_newPts = GetLine(newLink)
                    after = a_newPts[1]
                    
                    if before.lon <> after.lon or before.lat <> after.lat then do
                        dir = GetDirection(newLink)
                        linkRH = IDToRecordHandle(newLink)
                        SetRecordValues(Args.General.llayer,linkRH,{{"Dir",dir * -1}})
                    end
                    
                end
                
                // If the node was a stray (and in the errorSet), delete it
                SetLayer(Args.General.nlayer)
                if IsMember(errorSet,prevNodeRH) then do
                    deleted_id = DeleteNode(RH2ID(prevNodeRH), )
                end
            end
            
            
            
        end
        DestroyProgressBar()
        
        // Erroneous links check
        // Links can sometimes be created where the start and end node
        // are the same point.  This scans through each link marking
        // any found.
        
        // Create a new progress bar
        CreateProgressBar("Checking Links", "True")
        
        
        SetLayer(Args.General.llayer)
        errorLinkSet = RunMacro("G30 create set","Links with Duplicate Endpoints")
        linkRH = GetFirstRecord(Args.General.llayer + "|",)
        while linkRH <> null do
            
            // Update the progress bar
            linkCount = linkCount + 1
            intPercent = Round(linkCount / numLinkRecords * 100,0)
            interrupted = UpdateProgressBar("Link " + String(linkCount) + " of " + String(numLinkRecords),intPercent)
            
            // If the user presses the "Cancel" button, stop checking
            if interrupted then do
                ShowMessage("User pressed the 'Cancel' button.")
                goto quit
            end
            
            
            linkID = RH2ID(linkRH)
            a_nodeIDs = GetEndpoints(linkID)
            
            // If the endpoints are the same, add link to selection set
            if a_nodeIDs[1] = a_nodeIDs[2] then SelectRecord(errorLinkSet)
            
            // Before potentially deleting the link, move the RH to the next link
            linkRH = GetNextRecord(Args.General.llayer + "|",linkRH,)
            
            // If the endpoints are the same, and the runMode is "full", delete the link
            if a_nodeIDs[1] = a_nodeIDs[2] and Args.Simplify.runMode = "full" then DeleteLink(linkID,)
            
        end
        
        // If the links were joined, then tag the new layer with the count points created
        if Args.Simplify.runMode = "full" then do
            SetLayer(Args.General.llayer)
            toTagSet = RunMacro("G30 create set","Links to Tag")
            opts = null
            opts.Inclusion = "Intersecting"
            n = SelectByVicinity(toTagSet,"Several",Args.General.cLayer + "|",.0002,opts) // buffer ~ 1 ft
            if n > 0 then do
                for f = 1 to Args.General.countFields.length do
                    field = Args.General.countFields[f]
                    
                    TagLayer("Value",Args.General.llayer + "|" + toTagSet,Args.General.llayer + "." + field,Args.General.cLayer,Args.General.cLayer + "." + field)
                end
            end
        end
        
        
        
        
        // This is where the script goes if the cancel button is pressed
        // on any progress bar.
        quit:
        DestroyProgressBar()
        DisableProgressBar()
	enditem
    
    
    
    
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
    enditem
    
    
	// Quit Button
	button "Quit" 55, 23, 12 do
        // a_view = GetViewNames()
        // for i = 1 to a_view.length do
            // CloseView(a_view[i])
        // end
        Return(0)
	enditem
EndDbox






// Interchange Checker
dBox "Interchange" center,center,125,25 toolbox NoKeyboard Title:"Interchange Connectivity"
    
    init do
        shared Args
        
        if Args.General.debug = 1 then do
            ShowItem("Debug")
        end
        
        // Initialize the arrays of fac types
        // if Args.Interchange.restrAccess = null then Args.Interchange.restrAccess = {}
        // if Args.Interchange.ramps = null then Args.Interchange.ramps = {}
        
    enditem
    
    // Main scroll list holding all field names
    // Text "Unique Facility Types" 60,.5,30
    // Scroll List " " same, after, 29, 20 List: Args.General.uniqueFacType Multiple Variable:selFields
    
    // Access Restricted Query
    Text "Restricted Access Query" 15,2,35
    Text "Select * where" same, after, 35
    Edit Text same, after, 40, 5 Variable: Args.Interchange.restrAccessQry
    
    // Scroll List " " 15, after, 30, 5 List: Args.Interchange.restrAccess
    // button " " after, same, 5 Prompt:"<<" do
        // if Args.Interchange.restrAccess[1] = null then do
            // for i = 1 to selFields.length do
                // if i = 1 then Args.Interchange.restrAccess[1] = Args.General.uniqueFacType[selFields[i]]
                // else Args.Interchange.restrAccess = Args.Interchange.restrAccess + {Args.General.uniqueFacType[selFields[i]]}
            // end
        // end else do
            // for i = 1 to selFields.length do
                // Args.Interchange.restrAccess = Args.Interchange.restrAccess + {Args.General.uniqueFacType[selFields[i]]}
            // end
        // end
    // enditem
    // button " " same, after, 5 Prompt:"X" do
        // Args.Interchange.restrAccess = {}
    // enditem
    
    // Ramp Query
    Text "Ramp Query" same, after,35
    Text "Select * where" same, after, 35
    Edit Text same, after, 40, 5 Variable: Args.Interchange.rampQry
    
    // Scroll List " " same, after, 30, 5 List: Args.Interchange.ramps
    // button " " after, same, 5 Prompt:"<<" do
        // if Args.Interchange.ramps[1] = null then do
            // for i = 1 to selFields.length do
                // if i = 1 then Args.Interchange.ramps[1] = Args.General.uniqueFacType[selFields[i]]
                // else Args.Interchange.ramps = Args.Interchange.ramps + {Args.General.uniqueFacType[selFields[i]]}
            // end
        // end else do
            // for i = 1 to selFields.length do
                // Args.Interchange.ramps = Args.Interchange.ramps + {Args.General.uniqueFacType[selFields[i]]}
            // end
        // end
    // enditem
    
    // button " " same, after, 5 Prompt:"X" do
        // Args.Interchange.ramps = {}
    // enditem
    
    
    // Check Interchanges Button
    button " " same, after, 20 Prompt:"Check Interchanges" do
        
        // Test to make sure both queries exist
        if Args.Interchange.restrAccessQry = null or Args.Interchange.rampQry = null then do
            ShowMessage("Not all required data has been filled out.")
        end else if Args.General.nodeTAZIdField = null then do
            ShowMessage("A node field specifying centroid IDs must be given.")
        end else do
        
            // In order to reference record fields easily,
            // put the Args.General.llayer (line layer name)
            // into a simple, local variables
            llayer = Args.General.llayer
            
            // Create Map
            map = RunMacro("Create Highway Map")
            SetLayer(Args.General.nlayer)
            potentialSet = RunMacro("G30 create set","Potential Problem Nodes")
            problemSet = RunMacro("G30 create set","Problem Nodes")
            errorSet = RunMacro("G30 create set","Stray Nodes (to delete)")
            SetDisplayStatus(Args.General.nlayer + "|","Invisible")
            
            // Create link selection sets for ramps and restricted access links
            SetLayer(llayer)
            rampSet  = RunMacro("G30 create set","Ramp Links")
            SelectByQuery(rampSet, "Several", "Select * where " + Args.Interchange.rampQry)
            restrSet = RunMacro("G30 create set","Restricted Access Links")
            SelectByQuery(restrSet, "Several", "Select * where " + Args.Interchange.restrAccessQry)
            
            // Create a selection set of non-centroid nodes to check
            SetLayer(Args.General.nlayer)
            nonCentroidQuery = "Select * where nz(" + Args.General.nodeTAZIdField + ") < 1"
            nonCentroidSet = "non-centroid nodes"
            numNonCentr = SelectByQuery(nonCentroidSet,"Several",nonCentroidQuery)
            
            nodeRH = GetFirstRecord(Args.General.nlayer + "|" + nonCentroidSet,)
            
            while nodeRH <> null do
                SetLayer(Args.General.nlayer)
                nodeID = RH2ID(nodeRH)
                
                // Stray nodes (with no links) throw a NotFound error.
                // Catch it, and place the node into the error set
                on NotFound do
                    SelectRecord(errorSet)
                    goto skip
                end
                a_links = GetNodeLinks(nodeID)      
                skip:
                on NotFound default
                
                // Only focus on nodes with 4 or more links attached.
                // This implies an intersection, which can be checked for an interchange.
                if a_links.length > 3 then do
                    
                    // Determine presence of restricted and non-restricted access links
                    restrAccess = 0
                    nonrestrAccess = 0
                    /*
                    facTypePos = ArrayPosition(Args.General.linkFieldList, {Args.General.facType},)
                    for i = 1 to a_links.length do
                        linkRH = LocateRecord(Args.General.llayer + "|","ID",{a_links[i]},)
                        vals = GetRecordValues(Args.General.llayer, linkRH,)
                        // If the record's factype is found in the restrAccess array:
                        if ArrayPosition(Args.Interchange.restrAccess,{vals[facTypePos][2]},) <> 0 then do
                            restrAccess = restrAccess + 1
                        // If not restricted access and if not a ramp:
                        end else if ArrayPosition(Args.Interchange.ramps,{vals[facTypePos][2]},) = 0 then do
                            nonrestrAccess = nonrestrAccess + 1
                        end
                    end
                    */
                    SetLayer(llayer)
                    for i = 1 to a_links.length do
                        linkRH = LocateRecord(Args.General.llayer + "|","ID",{a_links[i]},)
                        // if link is restricted access
                        if IsMember(restrSet, linkRH) then restrAccess = restrAccess + 1
                        // if link is not in the restricted access set and not a ramp
                        if not(IsMember(restrSet, linkRH)) and not(IsMember(rampSet, linkRH)) then nonrestrAccess = nonrestrAccess + 1
                    end
                    
                    // Determine if this node is a potential problem
                    potentialProblem = "No"
                    if restrAccess > 2 then potentialProblem = "Yes"                        
                    if restrAccess > 0 and nonrestrAccess > 0 then potentialProblem = "Yes"
                    
                    
                    // If a potential problem, mark it
                    if potentialProblem = "Yes" then do
                        SetLayer(Args.General.nlayer)
                        SelectRecord(potentialSet)
                    end
                    
                    
                end

                
                nodeRH = GetNextRecord(Args.General.nlayer + "|" + nonCentroidSet,nodeRH,)
            end
            
            
            // After all potential problem nodes have been marked,
            // determine which are near ramp links
            
            // Select ramp links
            // SetLayer(Args.General.llayer)
            // for i = 1 to Args.Interchange.ramps.length do
                // rampQry = "Select * where " + Args.General.facType + " = " + String(Args.Interchange.ramps[i])
                // n1 = SelectByQuery("Ramps","more",rampQry)
            // end
            
            // Select potential problem nodes near ramp links
            // Add those to the problem node set
            SetLayer(Args.General.nlayer)
            Opts = null
            //Opts.Inclusion = "Intersecting"
            Opts.Display = "True"
            Opts.[Source And] = potentialSet
            // numNearby = SelectByVicinity(problemSet,"Several",Args.General.llayer + "|Ramps",.1,Opts)
            numNearby = SelectByVicinity(problemSet,"More",Args.General.llayer + "|" + rampSet,.1,Opts)
            
            
            
            
            
            
        end
        ShowMessage("Check Completed.")
    enditem
    
    
    
    
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
    enditem
    
    
	// Quit Button
	button "Quit" 55, 23, 12 do
        // a_view = GetViewNames()
        // for i = 1 to a_view.length do
            // CloseView(a_view[i])
        // end
        Return(0)
	enditem
EndDbox



// Project Benefit Calculation DBox

dBox "Benefits" center,center,170,35 toolbox NoKeyboard Title:"Benefit Calculation"
    init do
        shared Args
        
        if Args.General.debug = 1 then do
            ShowItem("Debug")
        end
        
        // Default the no-build dbd to the general dbd        
        if Args.Benefits.noBuildHwy = null then Args.Benefits.noBuildHwy = Args.General.hwyDBD
        Args.Benefits.noBuildHwyArray = {"Choose Highway DBD",Args.Benefits.noBuildHwy}
        Args.Benefits.PosVars.nbHwy = 2
        Args.Benefits.allBuildHwyArray = {"Choose Highway DBD",Args.Benefits.allBuildHwy}
        if Args.Benefits.allBuildHwy <> null then Args.Benefits.PosVars.abHwy = 2
        
        // Update the Link Field List
        {Args.Benefits.nlayer,Args.Benefits.llayer} = GetDBLayers(Args.Benefits.noBuildHwy)
        a_info = GetDBInfo(Args.Benefits.noBuildHwy)
        Args.Benefits.hwyScope = a_info[1]        
        tempLink = AddLayerToWorkspace(Args.Benefits.llayer,Args.Benefits.noBuildHwy,Args.Benefits.llayer,)
        fieldList = GetFields(tempLink,"All")
        Args.General.linkFieldList = fieldList[1] // updating the general list so that all dBoxs benefit
        DropLayerFromWorkspace(tempLink)
        
        // Initialize the delay units list
        Args.Benefits.unitList = {"mins","hours"}
        
        // Setup the array that will control which dbox items are updated
        // when the dBox is opened or settings are loaded.
        Args.GUI.Benefits.ItemList = 
                {
                {"popNBHwy",,Args.Benefits.noBuildHwy,Args.Benefits.noBuildHwyArray,"nbHwy"},
                {"popABHwy",,Args.Benefits.allBuildHwy,Args.Benefits.allBuildHwyArray,"abHwy"},
                {"popProjID",,Args.Benefits.projID,Args.General.linkFieldList,"projID"},
                {"popFlow",,Args.Benefits.abFlow,Args.General.linkFieldList,"abFlow"},
                {"popCap",,Args.Benefits.abCap,Args.General.linkFieldList,"abCap"},
                {"popDelay",,Args.Benefits.abDelay,Args.General.linkFieldList,"abDelay"},
                {"popDelayUnits",,Args.Benefits.abDelayUnits,Args.Benefits.unitList,"abDelayUnits"}
                }
        
        if Args.Benefits.length <> null then RunMacro("Set Benefits Dbox Items")
        
    enditem
    
    
	// No-Build Highway DBD drop down menu
	Popdown Menu "popNBHwy" 12, 2, 100, 7 prompt: "No-Build Highway" list: Args.Benefits.noBuildHwyArray variable:Args.Benefits.PosVars.nbHwy do
        on escape goto quit
        if Args.Benefits.PosVars.nbHwy = 1 then do
            Args.Benefits.noBuildHwy = ChooseFile({{"Geographic File (*.dbd)", "*.dbd"}}, "Choose Highway DBD",{{"Initial Directory",Args.General.initialDir}})
            // path = SplitPath(Args.Benefits.noBuildHwy)
            // Args.Benefits.noBuildHwyArray = {"Choose Highway DBD",path[3] + path[4]}
            Args.Benefits.noBuildHwyArray = {"Choose Highway DBD",Args.Benefits.noBuildHwy}
            Args.Benefits.PosVars.nbHwy = 2  
            
            {Args.Benefits.nlayer,Args.Benefits.llayer} = GetDBLayers(Args.Benefits.noBuildHwy)
            a_info = GetDBInfo(Args.Benefits.noBuildHwy)
            Args.Benefits.hwyScope = a_info[1]
            
            tempLink = AddLayerToWorkspace(Args.Benefits.llayer,Args.Benefits.noBuildHwy,Args.Benefits.llayer,)
            fieldList = GetFields(tempLink,"All")
            Args.General.linkFieldList = fieldList[1]
            DropLayerFromWorkspace(tempLink)
        
        end
        quit:
        on escape default
	enditem     
       
    // All-Build Highway DBD drop down menu
	Popdown Menu "popABHwy" same, after, 100, 7 prompt: "All-Build Highway" list: Args.Benefits.allBuildHwyArray variable:Args.Benefits.PosVars.abHwy do
        on escape goto quit
        if Args.Benefits.PosVars.abHwy = 1 then do
            Args.Benefits.allBuildHwy = ChooseFile({{"Geographic File (*.dbd)", "*.dbd"}}, "Choose Highway DBD",{{"Initial Directory",Args.General.initialDir}})
            // path = SplitPath(Args.Benefits.allBuildHwy)
            // Args.Benefits.allBuildHwyArray = {"Choose Highway DBD",path[3] + path[4]}
            Args.Benefits.allBuildHwyArray = {"Choose Highway DBD",Args.Benefits.allBuildHwy}
            Args.Benefits.PosVars.abHwy = 2        
        end
        quit:
        on escape default
	enditem 
    
    // Choose the Project ID Field
    Popdown Menu "popProjID" same, after, 20, 8 prompt: "ProjectID" list: Args.General.linkFieldList variable: Args.Benefits.PosVars.projID do
        Args.Benefits.projID = Args.General.linkFieldList[Args.Benefits.PosVars.projID]
        
        // In order to use the project ID to make selections later, determine if the field
        // is made up of strings or numbers
        temp = AddLayerToWorkspace(Args.Benefits.llayer,Args.Benefits.noBuildHwy,Args.Benefits.llayer)
        Args.Benefits.projIDType = GetFieldTableType(Args.Benefits.llayer + "." + Args.Benefits.projID)
        DropLayerFromWorkspace(temp)
	enditem 
    
    // Choose AB Flow Field
    Text same,after Variable:"(BA fields are found automatically)"
    Popdown Menu "popFlow" same, after, 20, 8 prompt: "AB Daily Flow" list: Args.General.linkFieldList variable: Args.Benefits.PosVars.abFlow do
        Args.Benefits.abFlow = Args.General.linkFieldList[Args.Benefits.PosVars.abFlow]
        temp = RunMacro("getBAField",Args.Benefits.abFlow)
        Args.Benefits.baFlow = temp[1]
	enditem 
    
    // Choose AB Cap Field
    Popdown Menu "popCap" same, after, 20, 8 prompt: "AB Daily Capacity" list: Args.General.linkFieldList variable: Args.Benefits.PosVars.abCap do
        Args.Benefits.abCap = Args.General.linkFieldList[Args.Benefits.PosVars.abCap]
        temp = RunMacro("getBAField",Args.Benefits.abCap)
        Args.Benefits.baCap = temp[1]
	enditem
    
    // Choose FF Speed
    Popdown Menu "popFFSpeed" same, after, 20, 8 prompt: "AB FF Speed" list: Args.General.linkFieldList variable: Args.Benefits.PosVars.abffSpeed do
        Args.Benefits.abffSpeed = Args.General.linkFieldList[Args.Benefits.PosVars.abffSpeed]
        temp = RunMacro("getBAField",Args.Benefits.abffSpeed)
        Args.Benefits.baffSpeed = temp[1]        
	enditem
    
    // Choose AB Delay Field
    Popdown Menu "popDelay" same, after, 20, 8 prompt: "AB Daily Delay" list: Args.General.linkFieldList variable: Args.Benefits.PosVars.abDelay do
        Args.Benefits.abDelay = Args.General.linkFieldList[Args.Benefits.PosVars.abDelay]
        temp = RunMacro("getBAField",Args.Benefits.abDelay)
        Args.Benefits.baDelay = temp[1]
	enditem     

    // Delay units
    Popdown Menu "popDelayUnits" after, same, 10, 8 list: Args.Benefits.unitList variable: Args.Benefits.PosVars.abDelayUnits do
        Args.Benefits.abDelayUnits = Args.Benefits.unitList[Args.Benefits.PosVars.abDelayUnits]
	enditem     
    
    // Buffer size
    Edit Text "ben_buffer" 55, 5.75, 5,1 Prompt:"Buffer Radius (mi)" Variable: Args.Benefits.buffer
    

    
    // Actual calculation
    button 20, 16, 23 Prompt:"Calculate Project Benefits" do
        
        path = SplitPath(Args.Benefits.allBuildHwy)
        Args.Benefits.outputDir = path[1] + path[2] + "\\BenefitCalculation\\"
        
        // In this code "ab" and "nb" stand for "all build" and "no build"
        // Directionality (AB/BA) will be capitalized to avoid confusion
        
        
        
        // Open the allbuild hwy and join the nobuild to it
        a_allBuildLayers = GetDBLayers(Args.Benefits.allBuildHwy)
        a_noBuildLayers = GetDBLayers(Args.Benefits.noBuildHwy)
        allBuildLayer = AddLayerToWorkspace(a_allBuildLayers[2],Args.Benefits.allBuildHwy,a_allBuildLayers[2])
        noBuildLayer = AddLayerToWorkspace(a_noBuildLayers[2],Args.Benefits.noBuildHwy,a_noBuildLayers[2])
        dv_join = JoinViews("allbuild+nobuild",allBuildLayer+".ID",noBuildLayer+".ID",)
        SetView(dv_join)
        
        // Collect projID,vol, cap, and time measures
        Opts = null
        Opts.[Missing As Zero] = "True"
        v_linkID = GetDataVector(dv_join + "|",allBuildLayer + ".ID",Opts)
        v_length = GetDataVector(dv_join + "|",allBuildLayer + ".Length",Opts)
        v_allprojid = GetDataVector(dv_join + "|",allBuildLayer + "." + Args.Benefits.projID,Opts)
        // all build values (convert any nulls to zeros)
        v_abABffSpeed = nz(GetDataVector(dv_join + "|",allBuildLayer + "." + Args.Benefits.abffSpeed,Opts))
        v_abBAffSpeed = nz(GetDataVector(dv_join + "|",allBuildLayer + "." + Args.Benefits.baffSpeed,Opts))
        v_abABVol = nz(GetDataVector(dv_join + "|",allBuildLayer + "." + Args.Benefits.abFlow,Opts))
        v_abBAVol = nz(GetDataVector(dv_join + "|",allBuildLayer + "." + Args.Benefits.baFlow,Opts))
        v_abABCap = nz(GetDataVector(dv_join + "|",allBuildLayer + "." + Args.Benefits.abCap,Opts))
        v_abBACap = nz(GetDataVector(dv_join + "|",allBuildLayer + "." + Args.Benefits.baCap,Opts))        
        v_abABDelay = nz(GetDataVector(dv_join + "|",allBuildLayer + "." + Args.Benefits.abDelay,Opts))
        v_abBADelay = nz(GetDataVector(dv_join + "|",allBuildLayer + "." + Args.Benefits.baDelay,Opts))
        // no build values
        v_nbABffSpeed = nz(GetDataVector(dv_join + "|",noBuildLayer + "." + Args.Benefits.abffSpeed,Opts))
        v_nbBAffSpeed = nz(GetDataVector(dv_join + "|",noBuildLayer + "." + Args.Benefits.baffSpeed,Opts))
        v_nbABVol = nz(GetDataVector(dv_join + "|",noBuildLayer + "." + Args.Benefits.abFlow,Opts))
        v_nbBAVol = nz(GetDataVector(dv_join + "|",noBuildLayer + "." + Args.Benefits.baFlow,Opts))
        v_nbABCap = nz(GetDataVector(dv_join + "|",noBuildLayer + "." + Args.Benefits.abCap,Opts))
        v_nbBACap = nz(GetDataVector(dv_join + "|",noBuildLayer + "." + Args.Benefits.baCap,Opts))        
        v_nbABDelay = nz(GetDataVector(dv_join + "|",noBuildLayer + "." + Args.Benefits.abDelay,Opts))
        v_nbBADelay = nz(GetDataVector(dv_join + "|",noBuildLayer + "." + Args.Benefits.baDelay,Opts))        
        
        CloseView(dv_join)
        DropLayerFromWorkspace(allBuildLayer)
        DropLayerFromWorkspace(noBuildLayer )
        
        // Calculate absolute and pct changes from no build to build
        v_ABVolDiff = v_abABVol - v_nbABVol
        v_BAVolDiff = v_abBAVol - v_nbBAVol
        v_totVolDiff = v_ABVolDiff + v_BAVolDiff
        // if the volume decreases to 0, it should be -100%
        v_ABVolPctDiff = if ( v_nbABVol = 0 ) then 999 else (v_abABVol - v_nbABVol) / v_nbABVol * 100
        v_BAVolPctDiff = if ( v_nbBAVol = 0 ) then 999 else (v_abBAVol - v_nbBAVol) / v_nbBAVol * 100
        v_ABCapDiff = v_abABCap - v_nbABCap
        v_BACapDiff = v_abBACap - v_nbBACap
        v_totCapDiff = v_ABCapDiff + v_BACapDiff
        // if the capacity decreases to 0, it should be -100%
        v_ABCapPctDiff = if ( v_nbABCap = 0 ) then 999 else (v_abABCap - v_nbABCap) / v_nbABCap * 100
        v_BACapPctDiff = if ( v_nbBACap = 0 ) then 999 else (v_abBACap - v_nbBACap) / v_nbBACap * 100
        
        // If delay is in minutes, convert to hours
        if Args.Benefits.abDelayUnits = "mins" then do
            v_abABDelay = v_abABDelay / 60
            v_abBADelay = v_abBADelay / 60
            v_nbABDelay = v_nbABDelay / 60
            v_nbBADelay = v_nbBADelay / 60
        end
        
        // 7/28/15 - Discount delay
        // Full credit is given to delay at V/C levels < 1.0
        // Half credit is given to delay above that.  The goal is to dampen the
        // effects of extreme deficiency while still being sensitive to changes
        // in V/C above 1.  
        
        // calculate delay at V/C = 1
        //                                                   [trav time at half speed]     * flow
        v_abABmaxDelay = if v_abABffSpeed = 0 then 0 else v_length / ( v_abABffSpeed / 2 ) * v_abABVol      
        v_abBAmaxDelay = if v_abBAffSpeed = 0 then 0 else v_length / ( v_abBAffSpeed / 2 ) * v_abBAVol      
        v_nbABmaxDelay = if v_nbABffSpeed = 0 then 0 else v_length / ( v_nbABffSpeed / 2 ) * v_nbABVol      
        v_nbBAmaxDelay = if v_nbBAffSpeed = 0 then 0 else v_length / ( v_nbBAffSpeed / 2 ) * v_nbBAVol
        
        // discount = .50
        discount = 1
        v_abABDelayDiscount = if v_abABDelay <= v_abABmaxDelay then v_abABDelay else v_abABmaxDelay + (v_abABDelay - v_abABmaxDelay) * discount
        v_abBADelayDiscount = if v_abBADelay <= v_abBAmaxDelay then v_abBADelay else v_abBAmaxDelay + (v_abBADelay - v_abBAmaxDelay) * discount
        v_nbABDelayDiscount = if v_nbABDelay <= v_nbABmaxDelay then v_nbABDelay else v_nbABmaxDelay + (v_nbABDelay - v_nbABmaxDelay) * discount
        v_nbBADelayDiscount = if v_nbBADelay <= v_nbBAmaxDelay then v_nbBADelay else v_nbBAmaxDelay + (v_nbBADelay - v_nbBAmaxDelay) * discount
        
        v_ABDelayDiff = v_abABDelayDiscount - v_nbABDelayDiscount
        v_BADelayDiff = v_abBADelayDiscount - v_nbBADelayDiscount
        v_totDelayDiff = v_ABDelayDiff + v_BADelayDiff
        
        // Check calculation in debug mode
        if Args.General.debug = 1 then do
            csvFile = Args.Benefits.outputDir + "delay discount check.csv"
            file = OpenFile(csvFile,"w")
            WriteLine(file,"  ,,No Build,        ,            ,            ,                   ,                   ,,All Build,       ,            ,            ,                   ,                   ")
            WriteLine(file,"ID,,AB Delay,BA Delay,AB Max Delay,BA Max Delay,AB Discounted Delay,BA Discounted Delay,,AB Delay,BA Delay,AB Max Delay,BA Max Delay,AB Discounted Delay,BA Discounted Delay")
            for i = 1 to v_ABDelayDiff.length do
                WriteLine(file,String(v_linkID[i]) + ",," + String(v_nbABDelay[i]) + "," + String(v_nbBADelay[i]) + "," + String(v_nbABmaxDelay[i]) + "," + String(v_nbBAmaxDelay[i]) + "," + String(v_nbABDelayDiscount[i]) + "," + String(v_nbBADelayDiscount[i]) + ",," + String(v_abABDelay[i]) + "," + String(v_abBADelay[i]) + "," + String(v_abABmaxDelay[i]) + "," + String(v_abBAmaxDelay[i]) + "," + String(v_abABDelayDiscount[i]) + "," + String(v_abBADelayDiscount[i]))
            end
            CloseFile(file)
        end
        
        
        // Determine the unique list of project IDs
        Opts = null
        Opts.Unique = "True"
        Opts.Ascending = "False"
        v_uniqueProjID = SortVector(v_allprojid,Opts)
        // Determine which projects increase capacity
        // 7/27/15 - now getting all projects that change capacity
        //           (i.e., includes road diets)
        for i = 1 to v_uniqueProjID.length do
            curProjID = v_uniqueProjID[i]
            
            // Get the capacity change for the current project
            v_capCheck = if ( v_allprojid = curProjID ) then v_totCapDiff else 0
            totCapDiff = VectorStatistic(v_capCheck,"sum",)
            
            // If the project has changed capacity, add it to the list
            if totCapDiff <> 0 then do
                if i = 1 then a_projID = {curProjID}
                else a_projID = a_projID + {curProjID}
            end 
        end 
        v_projID = A2V(a_projID)
        
/*      
        Parcel the benefits out into primary and secondary types
        Primary: caused by improvement to the link
        Secondary: caused by improvements to other, nearby links
        
        For each link, the first step is to calculate the percentage of primary and secondary benefit
        
        Start with rules:

        New Links				
                                            | Decrease Delay  |Increase Delay       
            Increase Capacity (New Road)	|                 |		                
                Increase Volume	            | n/a             |Primary	            
                Decrease Volume	            | n/a             |n/a	                
                                            |                 |                     
                                            |                 |                     
        Existing Links				        |                 |                     
                                            | Decrease Delay  |Increase Delay       
            Increase Capacity (Widening)	|                 |                     
                Increase Volume	            | Primary         |Secondary	        
                Decrease Volume	            | Both (D.D.)     |n/a	                D.D. = decreased delay
            Decrease Capacity (Road Diet)	|                 |                     
                Increase Volume	            | n/a             |Both (I.D.)          I.D. = increased delay
                Decrease Volume	            | Secondary       |Primary	            
        
        
        
        For the cells above labelled "Both", a ratio of primary and secondary benefits
        must be determined.
        
        The change in capacity is used to approximate the proportion of primary benefit.
            i.e. capacity increases are the result of the project
        The change in volume is used to approximate the proportion of secondary benefit.
            i.e. volume decreases are the result of improvement in other projects
        
        Thus, the following ratio of ratios:
        
        abs(%change in Cap) / ( abs(%change in Cap) + abs(%change in Vol) )
        
        Absolute value is needed because, while capacity and volume are moving in opposite
        direction, you want to know their relative magnitude.
        
        This metric will determine how much of the change in delay on the project is due to the project
        and how much is the secondary benefit from other projects.
        
        Example 1: if a link's capacity increases by 20% and it's volume decreases by 10%:
        2/3 of the delay reduction is due to the project.  That is primary benefit.
        1/3 is due to improvements from other projects drawing volume away.  Secondary benefit.
        
        Example 2: if a link's capacity decreases by 30% and it's volume increases by 10%:
        3/4 of the delay increase is due to the project.
        1/4 is due to changes in other links.
        
        
 */
        
        // For this section of code, ab/ba once again refers to direction (ab is not "all build").
        // Confusing I know. Sorry. If I get the time to clean it up, I will.
        
        
        // Determine which cell (from the commented table above) the links fall into.
        v_linkCategory = Vector(v_allprojid.length,"String",)
        v_linkCategory =    if (v_totDelayDiff < 0) then                                 // Decreased Delay
                                (if v_totCapDiff >= 0 then                                  // Increased Capacity
                                    (if v_totVolDiff >= 0 then "Primary" else "Both")        // Increased/Decreased Volume    
                                else(if v_totCapDiff < 0 then                               // Decreased Capacity
                                    (if v_totVolDiff >= 0 then "n/a" else "Secondary")          // Increased/Decreased Volume    
                                    )
                                )
                            
                            else if (v_totDelayDiff >= 0) then                           // Increased Delay
                                (if v_totCapDiff >= 0 then                                  // Increased Capacity
                                    (if v_totVolDiff >= 0 then "Secondary" else "n/a")          // Increased/Decreased Volume
                                else(if v_totCapDiff < 0 then                               // Decreased Capacity                                    
                                    (if v_totVolDiff >= 0 then "Both" else "Primary")          // Increased/Decreased Volume                                
                                    )
                                )
                            else null
        // all delay changes on new facilities are primary
        v_linkCategory = if (v_nbABCap + v_nbBACap = 0) then "Primary" else v_linkCategory
        // if capacity doesn't change, all delay changes are secondary
        v_linkCategory = if v_totCapDiff = 0 then "Secondary" else v_linkCategory
        
        // Calculate the "both" ratios for all links (even though only used for some)
        v_abCapRatio = abs(v_ABCapPctDiff) / ( abs(v_ABCapPctDiff) + abs(v_ABVolPctDiff ))
        v_baCapRatio = abs(v_BACapPctDiff) / ( abs(v_BACapPctDiff) + abs(v_BAVolPctDiff ))
        v_abVolRatio = abs(v_ABVolPctDiff) / ( abs(v_ABCapPctDiff) + abs(v_ABVolPctDiff ))
        v_baVolRatio = abs(v_BAVolPctDiff) / ( abs(v_BACapPctDiff) + abs(v_BAVolPctDiff ))        
        
        // Calculate primary/secondary benefits based on this grouping
        // Multiply the benefit vectors by -1 to change a decrease in delay
        // into a positive benefit metric.
        v_abPrimBen = if v_linkCategory = "Primary"   then v_ABDelayDiff * -1 else 0
        v_abPrimBen = if v_linkCategory = "Both" then      v_ABDelayDiff * -1 * v_abCapRatio else v_abPrimBen
        v_baPrimBen = if v_linkCategory = "Primary"   then v_BADelayDiff * -1 else 0
        v_baPrimBen = if v_linkCategory = "Both" then      v_BADelayDiff * -1 * v_baCapRatio else v_baPrimBen
        
        v_abSecBen  = if v_linkCategory = "Secondary" then v_ABDelayDiff * -1 else 0
        v_abSecBen  = if v_linkCategory = "Both" then      v_ABDelayDiff * -1 * v_abVolRatio else v_abSecBen
        v_baSecBen  = if v_linkCategory = "Secondary" then v_BADelayDiff * -1 else 0
        v_baSecBen  = if v_linkCategory = "Both" then      v_BADelayDiff * -1 * v_baVolRatio else v_baSecBen        
                 
        // Check calculation in debug mode
        if Args.General.debug = 1 then do
            path = SplitPath(Args.Benefits.allBuildHwy)
            Args.Benefits.outputDir = path[1] + path[2] + "\\BenefitCalculation\\"
            testCSV = Args.Benefits.outputDir + "TestLinkCategoryLogic.csv"
            file = OpenFile(testCSV,"w")
            WriteLine(file,"ProjID,nbCap,totDelayDiff,totCapDiff,totVolDiff,Type,abCapRatio,baCapRatio,abVolRatio,baVolRatio,abPrimBen,baPrimBen,abSecBen,baSecBen")
            for i = 1 to v_linkCategory.length do
                WriteLine(file, String(v_allprojid[i]) + "," + String(v_nbABCap[i] + v_nbBACap[i]) + "," + String(v_totDelayDiff[i]) + "," + String(v_totCapDiff[i]) + "," + String(v_totVolDiff[i])
                          + "," + v_linkCategory[i] + "," + String(v_abCapRatio[i]) + "," + String(v_baCapRatio[i]) + "," + String(v_abVolRatio[i]) + "," + String(v_baVolRatio[i]) + "," + String(v_abPrimBen[i]) + "," + String(v_baPrimBen[i])
                          + "," + String(v_abSecBen[i]) + "," + String(v_baSecBen[i])             )
            end
            CloseFile(file)
        end
        
        // For some reason, these equations can lead to "negative zero"
        // results that sort as smaller than, for example, -80
        // Doesn't make sense - Have to set them to 0
        v_abPrimBen = if ( v_abPrimBen < .0001 and v_abPrimBen > -.0001 ) then 0 else v_abPrimBen
        v_baPrimBen = if ( v_baPrimBen < .0001 and v_baPrimBen > -.0001 ) then 0 else v_baPrimBen
        v_abSecBen = if ( v_abSecBen < .0001 and v_abSecBen > -.0001 ) then 0 else v_abSecBen
        v_baSecBen = if ( v_baSecBen < .0001 and v_baSecBen > -.0001 ) then 0 else v_baSecBen
        
        // Create a copy of the all-build dbd
        path = SplitPath(Args.Benefits.allBuildHwy)
        Args.Benefits.outputDir = path[1] + path[2] + "\\BenefitCalculation\\"
        Args.Benefits.resultHwy = Args.Benefits.outputDir + "BenefitCalculation.dbd"
        CopyDatabase(Args.Benefits.allBuildHwy,Args.Benefits.resultHwy)
        
        // Modify the structure to add benefit-related fields        
        dv_temp = AddLayerToWorkspace(Args.Benefits.llayer,Args.Benefits.resultHwy,Args.Benefits.llayer,)
        strct = GetTableStructure(dv_temp)
        for i = 1 to strct.length do
            strct[i] = strct[i] + {strct[i][1]}
        end
        
        strct = strct + {{"ABCapChange"  , "Real", 12, 2, "False", , ,    "AB Pct Capacity Change on Link", , , , null}}
        strct = strct + {{"BACapChange"  , "Real", 12, 2, "False", , ,    "BA Pct Capacity Change on Link", , , , null}}        
        strct = strct + {{"ABPctCapChange"  , "Real", 12, 2, "False", , , "AB Pct Capacity Change on Link", , , , null}}
        strct = strct + {{"BAPctCapChange"  , "Real", 12, 2, "False", , , "BA Pct Capacity Change on Link", , , , null}}
        strct = strct + {{"ABVolChange"  , "Real", 12, 2, "False", , ,    "AB Pct Volume Change on Link", , , , null}}
        strct = strct + {{"BAVolChange"  , "Real", 12, 2, "False", , ,    "BA Pct Volume Change on Link", , , , null}}        
        strct = strct + {{"ABPctVolChange"  , "Real", 12, 2, "False", , , "AB Pct Volume Change on Link", , , , null}}
        strct = strct + {{"BAPctVolChange"  , "Real", 12, 2, "False", , , "BA Pct Volume Change on Link", , , , null}}
        // If the delay is discounted for V/C > 1, state that in the description
        if discount = 1 then do
            strct = strct + {{"ABDelayChange"   , "Real", 12, 2, "False", , , "Total AB Delay Change on Link", , , , null}}
            strct = strct + {{"BADelayChange"   , "Real", 12, 2, "False", , , "Total BA Delay Change on Link", , , , null}}
        end else do
            strct = strct + {{"ABDelayChange"   , "Real", 12, 2, "False", , , "Discounted AB Delay Change on Link. Delay above V/C = 1 multiplied by " + String(discount), , , , null}}
            strct = strct + {{"BADelayChange"   , "Real", 12, 2, "False", , , "Discounted AB Delay Change on Link. Delay above V/C = 1 multiplied by " + String(discount), , , , null}}        
        end
        strct = strct + {{"LinkCategory"   , "String", 12, 2, "False", , , "Whether the link benefits are Primary, Secondary, or Both", , , , null}}
        strct = strct + {{"ABPrimBen"       , "Real", 12, 4, "False", , , "Delay savings from improvements to this link", , , , null}}
        strct = strct + {{"BAPrimBen"       , "Real", 12, 4, "False", , , "Delay savings from improvements to this link", , , , null}}
        strct = strct + {{"ABSecBen"        , "Real", 12, 4, "False", , , "Delay savings from improvements to other links", , , , null}}
        strct = strct + {{"BASecBen"        , "Real", 12, 4, "False", , , "Delay savings from improvements to other links", , , , null}}        
        strct = strct + {{"ProjectLength"  , "Real", 12, 2, "False", , ,    "The approximate length of the project", , , , null}}
        strct = strct + {{"ProjBens"        , "Real", 12, 4, "False", , , "Total benefits assigned to this project ID", , , , null}}        
        strct = strct + {{"Score"        , "Real", 12, 4, "False", , , "Final score of this project ID", , , , null}}        
        ModifyTable(dv_temp, strct)
        
        // Set the values of the new fields
        SetDataVector(	dv_temp + "|",	"ABCapChange",	v_ABCapDiff	,)
        SetDataVector(	dv_temp + "|",	"BACapChange",	v_BACapDiff	,)        
        SetDataVector(	dv_temp + "|",	"ABPctCapChange",	v_ABCapPctDiff	,)
        SetDataVector(	dv_temp + "|",	"BAPctCapChange",	v_BACapPctDiff	,)
        SetDataVector(	dv_temp + "|",	"ABVolChange",	v_ABVolDiff	,)
        SetDataVector(	dv_temp + "|",	"BAVolChange",	v_BAVolDiff	,)
        SetDataVector(	dv_temp + "|",	"ABPctVolChange",	v_ABVolPctDiff	,)
        SetDataVector(	dv_temp + "|",	"BAPctVolChange",	v_BAVolPctDiff	,)
        SetDataVector(	dv_temp + "|",	"ABDelayChange",	v_ABDelayDiff	,)
        SetDataVector(	dv_temp + "|",	"BADelayChange",	v_BADelayDiff	,)
        SetDataVector(	dv_temp + "|",	"LinkCategory",	v_linkCategory	,)
        SetDataVector(	dv_temp + "|",	"ABPrimBen",	v_abPrimBen	,)
        SetDataVector(	dv_temp + "|",	"BAPrimBen",	v_baPrimBen	,)
        SetDataVector(	dv_temp + "|",	"ABSecBen",	v_abSecBen	,)
        SetDataVector(	dv_temp + "|",	"BASecBen",	v_baSecBen	,)
        

        
        
        
        /*
        New Method (8/2015): Vary search radius by project length
        
        Because the previous method looped over every link in the network,
        the search radius had to be constant.  This method will first looped
        over project link IDs.  For each one, a buffer will be created based on
        the total project length.  All links in that buffer will be tagged with
        the project link's ID.  Thus, when finally looping over every link
        in the network, a second search isn't necessary.  The link already
        knows every project link it needs to assign secondary benefit to.
        */
        
        // Loop over each project ID and determine the length
        SetLayer(dv_temp)
        for p = 1 to v_projID.length do
            projID = v_projID[p]
            
            // Some models use strings for project IDs, others don't.  Catch both.
            if Args.Benefits.projIDType = "String" then projQuery = "Select * where " + Args.Benefits.projID + " = '" + projID + "'"
            else projQuery = "Select * where " + Args.Benefits.projID + " = " + String(projID)
            n = SelectByQuery("tempproj","Several",projQuery)
            
            // Get direction and length vectors
            v_dir = GetDataVector(dv_temp + "|tempproj","Dir",)
            v_lengthTemp = GetDataVector(dv_temp + "|tempproj","Length",)
            
            // Divide length by 2 if direction <> 0 (to avoid double counting length)
            v_lengthTemp = if v_dir <> 0 then v_lengthTemp / 2 else v_lengthTemp
            
            // Determine the total project distance and set that value for every
            // link with the same project ID in the network
            projLength = VectorStatistic(v_lengthTemp,"Sum",)
            opts = null
            opts.Constant = projLength
            v_projLength = Vector(v_lengthTemp.length,"Double",opts)
            SetDataVector(dv_temp + "|tempproj","ProjectLength",v_projLength,)
        end
        DeleteSet("tempproj")
        
        
        // CloseView(dv_temp) 
        DropLayerFromWorkspace(dv_temp)
        
        
        
        
        
        // Create a map of the resultant highway layer
        {map,nlayer,llayer} = RunMacro("Create Highway Map",Args.Benefits.resultHwy)
        SetLayer(llayer)
        
        // Create a selection set of project links (where projs change cap)
        // Written this way because there is an upper limit on the number
        // of conditions (project IDs) that can be listed in a single query
        projectSet = RunMacro("G30 create set","Capacity-Changing Project Links")
        for i = 1 to v_projID.length do
            projID = v_projID[i]
            // Some models use strings for project IDs, others don't.  Catch both.
            if Args.Benefits.projIDType = "String" then projQuery = "Select * where " + Args.Benefits.projID + " = '" + projID + "'"
            else projQuery = "Select * where " + Args.Benefits.projID + " = " + String(projID)
            n = SelectByQuery(projectSet,"more",projQuery)
        end
        
        
        /*
        New Method (8/2015): Vary search radius by project length
        
        Create a data structure that, for every link, has a string
        listing every project link to be considered for secondary
        benefit allocation.
        
        e.g. "11975,10938,10999"
        */
        
        DATA = null
        v_allIDs  = GetDataVector(llayer + "|","ID",)
        for i = 1 to v_allIDs.length do
            DATA.(String(v_allIDs[i])) = ""
        end
        
        // Loop over every project link
        v_projLinkID = GetDataVector(llayer + "|" + projectSet,"ID",)
        v_projLength = GetDataVector(llayer + "|" + projectSet,"ProjectLength",)
        CreateProgressBar("Buffering Projects","False")
        for p = 1 to v_projLinkID.length do
            id = v_projLinkID[p]
            buffer = v_projLength[p] * .75
            buffer = max(buffer,1.5)
            buffer = min(buffer,10)
            UpdateProgressBar("Buffering Project Link " + String(p) + " of " + String(v_projLinkID.length),
                              round(p / v_projLinkID.length * 100,0))
            
            // Select the current link
            qry = "Select * where ID = " + String(id)
            SelectByQuery("templink","Several",qry)
            
            // Select all links within the buffer distance of the current project link
            // and collect their link IDs
            opts = null
            opts.Inclusion = "Intersecting"
            SelectByVicinity("tempset","Several",llayer + "|templink",buffer,opts)
            v_bufferLinkIDs = GetDataVector(llayer + "|tempset","ID",)
            
            // Update the DATA object with the results
            for b = 1 to v_bufferLinkIDs.length do
                bufferLinkID = String(v_bufferLinkIDs[b])
                
                if DATA.(bufferLinkID) = "" then DATA.(bufferLinkID) = {id}
                else DATA.(bufferLinkID) = DATA.(bufferLinkID) + {id}
            end
        end
        DeleteSet("templink")
        DeleteSet("tempset")
        DestroyProgressBar()
        
        /* 
        -----------------------------------------------
        Step 2:
        Work through each link and assign its secondary
        benefits to nearby projects  
        -----------------------------------------------       
        */
        
        v_projSecondaryBen = Vector(v_projID.length,"Float",{{"Constant",0}})  // will hold final, secondary benefits for each project ID
        currentLinkSet = RunMacro("G30 create set","Current Link Being Evaluated")
        nearbyProjectSet = RunMacro("G30 create set","Project Links Near Current Link")
        
        EnableProgressBar("Assigning Secondary Benefits to Projects",2)
        CreateProgressBar("Working through each link", "True")
        
        // These links will have their secondary benefit calc written out
        a_traceLinkID = {30855,9635,16117,4476,6077,35344,19289,6077}
        
        for i = 1 to v_linkID.length do
            linkID = v_linkID[i]
            
            // Update the progress bar
            intPercent = Round(i / v_linkID.length * 100,0)
            interrupted = UpdateProgressBar("Link " + String(i) + " of " + String(v_linkID.length),intPercent)
            
            // If the user presses the "Cancel" button, stop
            if interrupted then do
                ShowMessage("User pressed the 'Cancel' button.")
                goto quit
            end
            
            
            
            
            // Create a selection set of the current link
            curLinkQuery = "Select * where ID = " + String(linkID)
            n = SelectByQuery(currentLinkSet,"Several",curLinkQuery)
            // Collect its secondary benefit value
            Opts = null
            Opts.[Missing As Zero] = "True"
            v_linkABSecBen = GetDataVector(llayer + "|" + currentLinkSet,"ABSecBen",Opts)
            v_linkBASecBen = GetDataVector(llayer + "|" + currentLinkSet,"BASecBen",Opts)
            linkSecBen = v_linkABSecBen[1] + v_linkBASecBen[1]
            
            // Only continue if the there is secondary benefit
            // on the link to distribute
            if abs(linkSecBen) > .001 then do
                
                // Select all project links within a buffer area around the current link
                // The choice between "enclosed" and "intersecting" for Inclusion is important.
                // Both have situations where one is better than the other, but intersecting
                // is the better choice for most situations.
                // New Method: no longer appropriate - vicinity search has already taken place
                // Opts = null
                // Opts.[Source And] = projectSet
                // Opts.Inclusion = "Intersecting"
                // n = SelectByVicinity(nearbyProjectSet,"Several",llayer + "|" + currentLinkSet,S2I(Args.Benefits.buffer),Opts)
                
                // Only continue if there are project links within the buffer
                // if n > 0 then do
                // Only continue if the link has been tagged with project link IDs
                if DATA.(String(linkID)) <> "" then do
                    
                    // Create a selection set of the project links that were tagged
                    // the current link
                    a_temp = DATA.(String(linkID))
                    for np = 1 to a_temp.length do
                        id = a_temp[np]
                        qry = "Select * where ID = " + String(id)
                        if np = 1 then SelectByQuery(nearbyProjectSet,"Several",qry)
                        else SelectByQuery(nearbyProjectSet,"More",qry)
                    end
                    
                    // Get a vector of those links' IDs, volume change, and length
                    Opts = null
                    Opts.[Missing As Zero] = "True"
                    v_nearbyProjID = GetDataVector(llayer + "|" + nearbyProjectSet,Args.Benefits.projID,Opts)
                    v_nearbyLinkID = GetDataVector(llayer + "|" + nearbyProjectSet,"ID",Opts)
                    v_nearbyProjABVolDiff = GetDataVector(llayer + "|" + nearbyProjectSet,"ABVolChange",Opts)
                    v_nearbyProjBAVolDiff = GetDataVector(llayer + "|" + nearbyProjectSet,"BAVolChange",Opts)
                    v_nearbyProjLength = GetDataVector(llayer + "|" + nearbyProjectSet,"Length",Opts)
                    
                    // Use the change in VMT to apportion the secondary benefit
                    // Project links increasing in volume can cause increased delay
                    // on nearby links. (Improving MLK tunnel in VB made the approaching roads worse)
                    // Likewise, a road diet can cause traffic to reroute, which can improve delay
                    // on some nearby links.  As a result, the direction of the volume change does
                    // not matter.  Take the absolute value.
                    v_nearbyProjVMTDiff = ( v_nearbyProjABVolDiff + v_nearbyProjBAVolDiff ) * v_nearbyProjLength
                    v_nearbyProjAbsVMTDiff = abs(v_nearbyProjVMTDiff)
                    
                    totalVMTDiff = VectorStatistic(v_nearbyProjAbsVMTDiff,"Sum",)
                    v_nearbyProjPctVMTDiff = v_nearbyProjAbsVMTDiff / totalVMTDiff
                    v_nearbyProjSecBen = linkSecBen * v_nearbyProjPctVMTDiff
                    
                    // Add this current link's apportioned benefit
                    // to the final vector
                    for j = 1 to v_nearbyProjID.length do
                        nearbyProjID = nz(v_nearbyProjID[j])
                        nearbyProjSecBen = nz(v_nearbyProjSecBen[j])
                                                                                                                     // this part is OK - initialized with 0s
                        v_projSecondaryBen = if ( v_projID = nearbyProjID ) then v_projSecondaryBen + nearbyProjSecBen else v_projSecondaryBen
                        
                    end
                    
                    // Trace write out
                    if ArrayPosition(a_traceLinkID,{linkID},) <> 0 then do
                        traceCSV = Args.Benefits.outputDir + "trace for link " + String(linkID) + ".csv"
                        file = OpenFile(traceCSV,"w")
                        WriteLine(file,"Tracing Secondary Benefit Assignment")
                        WriteLine(file,"Link ID:," + String(linkID))
                        WriteLine(file,"Total Secondary Benefit," + String(linkSecBen))
                        WriteLine(file,"Buffer Distance," + Args.Benefits.buffer)
                        WriteLine(file,"")
                        WriteLine(file,"Project ID,Link ID,VMT Change from NoBuild,Abs VMT Change,%VMT Change,SecBen Assigned")
                        for t = 1 to v_nearbyProjID.length do
                            WriteLine(file,String(v_nearbyProjID[t]) + "," + String(v_nearbyLinkID[t]) + "," + String(v_nearbyProjVMTDiff[t]) + "," + String(v_nearbyProjAbsVMTDiff[t]) + "," + String(v_nearbyProjPctVMTDiff[t]) + "," + String(v_nearbyProjSecBen[t])     )
                        end
                        CloseFile(file)
                    end                    
                end 
            end
        end
        DestroyProgressBar()
        
        
              
        /*
        --------------------------------------------------------------
        Step 3:
        Calculate project-level metrics like VMT change and CMA change
        --------------------------------------------------------------
        */
        
        // VMT - Vehicle Miles Traveled
        // CMA - Capacity Miles Available (metric made up for this application)
        //       Currently used to calculate utilization
        // Util - "Utilization" or how much of the project is being used
        // Prime - Primary benefits on the project links
        // Change means the difference between build and no-build
        v_projVMTDiff = Vector(v_projID.length,"Float",{{"Constant",0}})
        v_projCMADiff = Vector(v_projID.length,"Float",{{"Constant",0}})
        v_projPrimeBen = Vector(v_projID.length,"Float",{{"Constant",0}})
        
        for i = 1 to v_projID.length do
            projID = v_projID[i]
            
            // VMT Change
            v_tempVMT = if ( v_allprojid = projID ) then v_length * (v_ABVolDiff + v_BAVolDiff) else 0
            vmt = VectorStatistic(v_tempVMT,"Sum",)
            
            // CMA Change
            v_tempCMA = if ( v_allprojid = projID ) then v_length * (v_ABCapDiff + v_BACapDiff) else 0
            cma = VectorStatistic(v_tempCMA,"Sum",)
            
            v_projVMTDiff[i] = vmt
            v_projCMADiff[i] = cma
            
            // Primary Benefits
            v_tempBen = if ( v_allprojid = projID ) then (v_abPrimBen + v_baPrimBen) else 0
            primeBen = VectorStatistic(v_tempBen,"Sum",)
            
            v_projPrimeBen[i] = primeBen
        end 
        
        // Utilization
        v_projUtil = v_projVMTDiff / v_projCMADiff
        
        // Total Benefit
        v_projTotalBen = v_projPrimeBen + v_projSecondaryBen
        
        
        
        // Write the results out to a CSV
        ouputCSV = Args.Benefits.outputDir + "ProjectBenefitResults.csv"
        file = OpenFile(ouputCSV,"w")
        
        warningString = ""
        v_totalDelayDiff = v_ABDelayDiff + v_BADelayDiff
        if VectorStatistic(v_totalDelayDiff,"sum",) > 0 then 
        warningString = "Warning: Total delay increased from no-build to build scenarios."
        WriteLine(file,warningString)
        
        WriteLine(file,"ProjID,Additional CMA,Additional VMT,Utilization,Primary Benefits,Secondary Benefits,Total Benefits")
        for i = 1 to v_projID.length do
            // WriteLine(file, String(v_projID[i]) + "," + String(v_projCMADiff[i]) + "," + String(v_projVMTDiff[i]) + "," + String(v_projUtil[i]) + "," + String(v_projPrimeBen[i]) + "," + String(v_projSecondaryBen[i]) + "," + String(v_projTotalBen[i]))
            WriteLine(file, String(v_projID[i]) + "," + Format(v_projCMADiff[i],"*.00") + "," + Format(v_projVMTDiff[i],"*.00")
                    + "," + Format(v_projUtil[i],"*%.0") + "," + Format(v_projPrimeBen[i],"*.00") + "," + Format(v_projSecondaryBen[i],"*.00") + "," + Format(v_projTotalBen[i],"*.00"))
        end
        
        CloseFile(file)
        quit:
    enditem
    
    
    
    
    // Debug Button
	
    button "Debug" 5, 16, 12 Hidden do
        ShowMessage(1)
    enditem
    
    // Save Settings Button
    button "Save Settings" same, after, 12 do
        RunMacro("Save Settings")
    enditem

    // Load Settings Button
    button "Load Settings" same, after, 12 do
        RunMacro("Load Settings")
        RunMacro("Set Benefits Dbox Items")
    enditem    
    
	// Quit Button
	button "Quit" 55, 16, 12 do
        // a_view = GetViewNames()
        // for i = 1 to a_view.length do
            // CloseView(a_view[i])
        // end
        //RunMacro("G30 File Close All")
        Return(0)
	enditem
EndDbox





/*
This macro uses more-advanced spatial analysis
to tag links in one layer with the IDs of links
in a second layer.

Target Hwy DBD: will have a field added with the IDs from the Source Hwy DBD
*/

dBox "LinkJoin" center,center,170,35 toolbox NoKeyboard Title:"Adv Spatial Join (link)"
    init do
        shared Args
        
        if Args.General.debug = 1 then do
            ShowItem("Debug")
        end
        
        // Default the target dbd to the general dbd        
        if Args.LinkJoin.targetHwy = null then Args.LinkJoin.targetHwy = Args.General.hwyDBD
        Args.LinkJoin.targetHwyArray = {"Choose Highway DBD",Args.LinkJoin.targetHwy}
        Args.LinkJoin.PosVars.tHwy = 2
        Args.LinkJoin.sourceHwyArray = {"Choose Highway DBD",Args.LinkJoin.sourceHwy}
        if Args.LinkJoin.sourceHwy <> null then Args.LinkJoin.PosVars.sHwy = 2
        
        a_info = GetDBInfo(Args.LinkJoin.targetHwy)
        Args.LinkJoin.hwyScope = a_info[1]        
        {Args.LinkJoin.nlayer,Args.LinkJoin.llayer} = GetDBLayers(Args.LinkJoin.targetHwy)
        // Update the Link Field List
        // tempLink = AddLayerToWorkspace(Args.LinkJoin.llayer,Args.LinkJoin.targetHwy,Args.LinkJoin.llayer,)
        // fieldList = GetFields(tempLink,"All")
        // Args.General.linkFieldList = fieldList[1] // updating the general list so that all dBoxs benefit
        // DropLayerFromWorkspace(tempLink)
        
        // Initialize the delay units list
        // Args.LinkJoin.unitList = {"mins","hours"}
        
        // Setup the array that will control which dbox items are updated
        // when the dBox is opened or settings are loaded.
        Args.GUI.LinkJoin.ItemList = 
                {
                {"popTHwy",,Args.LinkJoin.targetHwy,Args.LinkJoin.targetHwyArray,"tHwy"},
                {"popSHwy",,Args.LinkJoin.sourceHwy,Args.LinkJoin.sourceHwyArray,"sHwy"}
                }
        
        if Args.LinkJoin.length <> null then RunMacro("Set LinkJoin Dbox Items")
        
    enditem
    
    Text 12,2,100 Variable: "The 'Target' layer will have a field added with the IDs from the 'Source' layer" 
    
	// Target Highway DBD drop down menu
	Popdown Menu "popTHwy" same, after, 100, 7 prompt: "Target Highway" list: Args.LinkJoin.targetHwyArray variable:Args.LinkJoin.PosVars.tHwy do
        on escape goto quit
        if Args.LinkJoin.PosVars.tHwy = 1 then do
            Args.LinkJoin.targetHwy = ChooseFile({{"Geographic File (*.dbd)", "*.dbd"}}, "Choose Highway DBD",{{"Initial Directory",Args.General.initialDir}})
            Args.LinkJoin.targetHwyArray = {"Choose Highway DBD",Args.LinkJoin.targetHwy}
            Args.LinkJoin.PosVars.tHwy = 2  
            
            {Args.LinkJoin.nlayer,Args.LinkJoin.llayer} = GetDBLayers(Args.LinkJoin.targetHwy)
            a_info = GetDBInfo(Args.LinkJoin.targetHwy)
            Args.LinkJoin.hwyScope = a_info[1]
            
            // tempLink = AddLayerToWorkspace(Args.LinkJoin.llayer,Args.LinkJoin.targetHwy,Args.LinkJoin.llayer,)
            // fieldList = GetFields(tempLink,"All")
            // Args.General.linkFieldList = fieldList[1]
            // DropLayerFromWorkspace(tempLink)
        
        end
        quit:
        on escape default
	enditem     
       
    // Source Highway DBD drop down menu
	Popdown Menu "popSHwy" same, after, 100, 7 prompt: "Source Highway" list: Args.LinkJoin.sourceHwyArray variable:Args.LinkJoin.PosVars.sHwy do
        on escape goto quit
        if Args.LinkJoin.PosVars.sHwy = 1 then do
            Args.LinkJoin.sourceHwy = ChooseFile({{"Geographic File (*.dbd)", "*.dbd"}}, "Choose Highway DBD",{{"Initial Directory",Args.General.initialDir}})
            Args.LinkJoin.sourceHwyArray = {"Choose Highway DBD",Args.LinkJoin.sourceHwy}
            Args.LinkJoin.PosVars.sHwy = 2        
        end
        quit:
        on escape default
	enditem 
    
    // Actual calculation
    button 20, 16, 23 Prompt:"Join" do
        
        // Create map with link and node layers from the target and source
        // Don't use G30 macro.  Need better control of layer names.
        // map = RunMacro("G30 new map", Args.LinkJoin.targetHwy)
        opts = null
        opts.Scope = Args.LinkJoin.hwyScope
        map = CreateMap("map", opts)
        {snLyr,slLyr} = GetDBLayers(Args.LinkJoin.sourceHwy)
        slLyr = AddLayer(map, "source link", Args.LinkJoin.sourceHwy, slLyr)
        snLyr = AddLayer(map, "source node", Args.LinkJoin.sourceHwy, snLyr)
        tlLyr = AddLayer(map, "target link", Args.LinkJoin.targetHwy, Args.LinkJoin.llayer)
        tnLyr = AddLayer(map, "target node", Args.LinkJoin.targetHwy, Args.LinkJoin.nlayer)
        
        // Set selection inclusion to intersecting for
        // spatial selections
        SetSelectInclusion("Intersecting")
        
        // Add field to target layer
        a_fields = {{"SourceLinkID", "Integer", 8, , },
                    {"PctMatch", "Real", 8, 2, }}
        RunMacro("TCB Add View Fields",{tlLyr,a_fields})    
        
        // Create selection sets that mark the confidence level of the joins
        SetLayer(tlLyr)
        perfectSet  = RunMacro("G30 create set","Perfect Match (100%)")
        aperfectSet = RunMacro("G30 create set","Almost Perfect Match (100%)")
        highSet     = RunMacro("G30 create set","High Confidence Match (>70%)")
        medSet      = RunMacro("G30 create set","Medium Confidence Match (>50%)")
        lowSet      = RunMacro("G30 create set","Low Confidence Match (>33%)")
        noSet       = RunMacro("G30 create set","No Match (<33%)")
        
        // Collect the vector of source link IDs for tracking
        // Each source ID can only be used once
        // v_sID = GetDataVector(slLyr + "|", "ID", )
        
        // Progress Bar
        CreateProgressBar("Joining", "True")
        v_tID = GetDataVector(tlLyr + "|", "ID", )
        total = v_tID.length
        
        // Loop over the target links and begin joining
        rh = GetFirstRecord(tlLyr + "|", )
        count = 0
        while rh <> null do
            linkID = RH2ID(rh)
            
            count = count + 1
            cancel = UpdateProgressBar("Joining link " + String(count), round(count / total * 100, 0))
            if cancel then goto quit
            
            // Create an coordinate array of the current link
            SetLayer(tlLyr)
            a_coords = GetLine(linkID)
            
            // **** Step 1: Check for Perfect Match ****
            
            // Do an initial screen to see if there
            // is a perfect match.  It must have identical:
            // ID, number of shape points, shape point coords
            perfect = 1
            SetLayer(slLyr)
            coord = a_coords[1]
            n = SelectByQuery("nearest", "Several", "Select * where ID = " + String(linkID))
            if n > 0 then do
                {sID} = GetSetIDs("nearest")
                a_scoords = GetLine(sID)
                // a perfect match must have the same number of shape points
                if a_coords.length <> a_scoords.length then perfect = 0
                else do
                    for c = 1 to a_coords.length do
                        t = a_coords[c]
                        s = a_scoords[c]
                        
                        // each shape point must have identical lats/lons
                        if t.lon <> s.lon then perfect = 0
                        if t.lat <> s.lat then perfect = 0
                    end
                end
            // if n = 0
            end else do
                perfect = 0
            end
            
            if perfect = 1 then do
                SetLayer(tlLyr)
                SelectRecord(perfectSet)
                SetRecordValues(tlLyr, rh, {{"SourceLinkID", sID}, {"PctMatch", 100}})
            end else do
                
                // **** Step 2: Collect the link IDs found around each shape point ****
                
                // SetLayer(snLyr)
                SetLayer(slLyr)
                a_sID = null
                for c = 1 to a_coords.length do
                    coord = a_coords[c]
                    
                    // Use a loop to gradually increase the search radius
                    // until links are found.  On interstates, the distance
                    // between some free links and HOV links is <10 ft.
                    for dist = 5 to 200 step 5 do
                        circle = Circle(coord, dist/5280)
                        n = SelectByCircle("nearest", "Several", circle, )
                        if n > 0 then do
                            dist = 201
                            a_sID = a_sID + GetSetIDs("nearest")
                        end
                    end
                    
                end
                
                if a_sID.length > 0 then do
                    
                    // **** Step 3: Determine correct link and confidence ****
                    
                    // Create a unique list of IDs found
                    opts = null
                    opts.Unique = "True"
                    a_uniqsID = SortArray(a_sID, opts)
                    
                    // Create a count vector for each unique source link ID
                    opts = null
                    opts.Constant = 0
                    v_count = Vector(a_uniqsID.length, "Long", opts)
                    
                    // Loop over each unique source link ID found near
                    // the target link's multiple coordinates
                    for i = 1 to a_uniqsID.length do
                        sID = a_uniqsID[i]
                        
                        // Increment the count variable each time that unique
                        // source link ID is found in the non-unique array
                        for j = 1 to a_sID.length do
                            if a_sID[j] = sID then v_count[i] = v_count[i] + 1
                        end
                    end
                     
                    // Determine the ID found most often
                    maxCount = VectorStatistic(v_count, "Max", )
                    pos = ArrayPosition(V2A(v_count), {maxCount}, )
                    sID = a_uniqsID[pos]
                    
                    // Determine the percent of shape points it was found near
                    pct = maxCount / a_coords.length * 100
                    
                    // for debugging
                    // if linkID = 45796 then do
                        // ShowMessage(1)
                    // end
                    
                    // Set the ID and selection set
                    SetLayer(tlLyr)
                    
                    if pct = 100 then do
                        SelectRecord(aperfectSet)
                        SetRecordValues(tlLyr, rh, {{"SourceLinkID", sID}, {"PctMatch", pct}})
                    end else if pct >= 70 then do
                        SelectRecord(highSet)
                        SetRecordValues(tlLyr, rh, {{"SourceLinkID", sID}, {"PctMatch", pct}})
                    end else if pct >= 50 then do
                        SelectRecord(medSet)
                        SetRecordValues(tlLyr, rh, {{"SourceLinkID", sID}, {"PctMatch", pct}})
                    end else if pct >= 33 then do
                        SelectRecord(lowSet)
                        SetRecordValues(tlLyr, rh, {{"SourceLinkID", sID}, {"PctMatch", pct}})
                    end else do
                        SelectRecord(noSet)
                        SetRecordValues(tlLyr, rh, {{"PctMatch", pct}})
                    end
                end 
                if not(a_sID.length > 0) then do
                    SelectRecord(noSet)
                end
            end
            
            rh = GetNextRecord(tlLyr + "|", rh, )
        end
        
        quit:
        DestroyProgressBar()
    enditem
    
    
    
    
    
    
    
    // Debug Button
	
    button "Debug" 5, 16, 12 Hidden do
        ShowMessage(1)
    enditem
    
    // Save Settings Button
    button "Save Settings" same, after, 12 do
        RunMacro("Save Settings")
    enditem

    // Load Settings Button
    button "Load Settings" same, after, 12 do
        RunMacro("Load Settings")
        RunMacro("Set LinkJoin Dbox Items")
    enditem    
    
	// Quit Button
	button "Quit" 55, 16, 12 do
        Return(0)
	enditem
EndDbox







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
    // highway layer references in Args.General
    if hwyDBD = null then do
        shared Args
        map = CreateMap("Network Simplification",{{"Scope",Args.General.hwyScope}})
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
Macro "getBAField" (abField)
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
EndMacro

