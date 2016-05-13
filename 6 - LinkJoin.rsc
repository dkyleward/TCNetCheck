
/*
This macro uses more-advanced spatial analysis
to tag links in one layer with the IDs of links
in a second layer.

Target Hwy DBD: will have a field added with the IDs from the Source Hwy DBD
  and a percent match score (confidence).
*/

dBox "LinkJoin" center,center,170,35 toolbox NoKeyboard Title:"Adv Spatial Join (link)"
    init do
        shared Args

        if Args.General.debug = 1 then do
            ShowItem("Debug")
        end

        step_int = 10

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

    Text 12,2,100 Variable: "The 'Target' layer will have a field added with the IDs from the 'Source' layer" +
      " and a confidence measure."

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

  // Use the selection set button if you only want to perform the join on a
  // subset of the target layer.
  button "tSel" same, after prompt: "Create Target Selection Set" do
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
    SetLayer(tlLyr)

    ShowMessage("Only links in set 'Selection' will be tagged")
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

  // Help Button
  Edit Int same, after, 5 Prompt: "Search Increment (ft)" variable: step_int
  button after, same Prompt: " ? " do
    str = "Controls rate at which search radius around each node grows.\n"
    str = str + "Small numbers increase accuracy and time required.\n"
    str = str + "Use small numbers for complex networks (e.g. that have HOV)"
    ShowMessage(str)
  endItem

  // Actual calculation
  button 20, 16, 23 Prompt:"Join" do

    // Create map with link and node layers from the target and source
    // Don't use G30 macro.  Need better control of layer names.
    // map = RunMacro("G30 new map", Args.LinkJoin.targetHwy)
    if map = null then do
      opts = null
      opts.Scope = Args.LinkJoin.hwyScope
      map = CreateMap("map", opts)
      {snLyr,slLyr} = GetDBLayers(Args.LinkJoin.sourceHwy)
      slLyr = AddLayer(map, "source link", Args.LinkJoin.sourceHwy, slLyr)
      snLyr = AddLayer(map, "source node", Args.LinkJoin.sourceHwy, snLyr)
      tlLyr = AddLayer(map, "target link", Args.LinkJoin.targetHwy, Args.LinkJoin.llayer)
      tnLyr = AddLayer(map, "target node", Args.LinkJoin.targetHwy, Args.LinkJoin.nlayer)
    end

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
    noSet       = RunMacro("G30 create set","Bad Match (<33%)")

    // Collect the vector of source link IDs for tracking
    // Each source ID can only be used once
    // v_sID = GetDataVector(slLyr + "|", "ID", )

    // Progress Bar
    CreateProgressBar("Joining", "True")
    v_tID = GetDataVector(tlLyr + "|", "ID", )
    total = v_tID.length

    // Loop over the target links and begin joining
    if GetSetCount("Selection") > 0 then
      rh = GetFirstRecord(tlLyr + "|Selection", )
    else rh = GetFirstRecord(tlLyr + "|", )
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
          for dist = 5 to 200 step step_int do
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

      if GetSetCount("Selection") > 0 then
        rh = GetNextRecord(tlLyr + "|Selection", rh, )
      else rh = GetNextRecord(tlLyr + "|", rh, )
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
