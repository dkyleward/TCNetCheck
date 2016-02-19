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