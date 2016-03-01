
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
        cutOff = .15
        
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
        
        // Check to see if any count fields have been selected to preserve
        if Args.General.countFields[1] <> null then saveCounts = "True"
        
        // Create a point file to keep track of count locations and add to map
        // (Delete it if it already exists from a previous, incomplete run)
        Args.Simplify.countDBD = Args.General.initialDir + "countLayer.dbd"
        if GetDBInfo(Args.Simplify.countDBD) <> null then DeleteDatabase(Args.Simplify.countDBD)
        Args.Simplify.cLayer = "Counts"
        if saveCounts then do
            CreateDatabase(Args.Simplify.countDBD, "point", {{"Layer name",Args.Simplify.cLayer}})
            Args.Simplify.cLayer = AddLayer(map,Args.Simplify.cLayer,Args.Simplify.countDBD,Args.Simplify.cLayer,)
            RunMacro("G30 new layer default settings", Args.Simplify.cLayer)
        end
        
        // Add fields to count layer
        if saveCounts then do
            for i = 1 to Args.General.countFields.length do
                type = GetFieldType(Args.General.llayer + "." + Args.General.countFields[i])
                if type = "Real" then decimal = 2 else decimal = 0
                strct = strct + {{Args.General.countFields[i], type, 12, decimal, "False", , , , , , , null}}
            end
            // Modify the table
            ModifyTable(Args.Simplify.cLayer, strct)
        end
        
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
                        if saveCounts then do
                            countLink = 0
                            for j = 1 to Args.General.countFields.length do
                                value = RunMacro("GetLinkValue", a_links[i],Args.General.countFields[i])
                                if value <> null then do
                                    countLink = i
                                    a_countVals = GetRecordValues(Args.General.llayer, linkRH,Args.General.countFields)
                                    j = Args.General.countFields.length + 1
                                end
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
                    
                    // Determine which is the shorter/longer link
                    SetLayer(Args.General.nlayer)
                    minLength = VectorStatistic(A2V(a_length),"Min",)
                    minPosition = ArrayPosition(a_length,{minLength},)
                    maxLength = VectorStatistic(A2V(a_length),"Max",)
                    maxPosition = ArrayPosition(a_length,{maxLength},)
                    
                    // After checking both links, create a count node if: 
                        // the node's links will be joined (node is a member of the autoSet)
                        // count data is present on the short link only
                        // (I preserve the longer-link's attributes by listing it first in JoinLinks())
                    if saveCounts then do
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
                    // one-way links will reverse direction.  Catch and correct the Dir field.
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
        if Args.Simplify.runMode = "full" and saveCounts then do
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
