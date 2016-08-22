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
    Args.GUI.Benefits.ItemList = {
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
    temp = RunMacro("getBAField",Args.Benefits.abFlow, Args.General.linkFieldList)
    Args.Benefits.baFlow = temp[1]
	enditem

  // Choose AB Cap Field
  Popdown Menu "popCap" same, after, 20, 8 prompt: "AB Daily Capacity" list: Args.General.linkFieldList variable: Args.Benefits.PosVars.abCap do
    Args.Benefits.abCap = Args.General.linkFieldList[Args.Benefits.PosVars.abCap]
    temp = RunMacro("getBAField",Args.Benefits.abCap, Args.General.linkFieldList)
    Args.Benefits.baCap = temp[1]
	enditem

  // Choose FF Speed
  Popdown Menu "popFFSpeed" same, after, 20, 8 prompt: "AB FF Speed" list: Args.General.linkFieldList variable: Args.Benefits.PosVars.abffSpeed do
    Args.Benefits.abffSpeed = Args.General.linkFieldList[Args.Benefits.PosVars.abffSpeed]
    temp = RunMacro("getBAField",Args.Benefits.abffSpeed, Args.General.linkFieldList)
    Args.Benefits.baffSpeed = temp[1]
	enditem

  // Choose AB Delay Field
  Popdown Menu "popDelay" same, after, 20, 8 prompt: "AB Daily Delay" list: Args.General.linkFieldList variable: Args.Benefits.PosVars.abDelay do
    Args.Benefits.abDelay = Args.General.linkFieldList[Args.Benefits.PosVars.abDelay]
    temp = RunMacro("getBAField",Args.Benefits.abDelay, Args.General.linkFieldList)
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

    /*
    Discount delay
    This is an optional feature that is currently not used.
    The idea is to dampen the effects of extreme deficiency while still
    being sensitive to changes in V/C above 1.  A discount value of .5,
    for example, would reduce delay from congestion above V/C = 1
    (i.e. below half the FFS) by 50%.

    There is really no way to calibrate this number, and to date, using the
    conical VDF and scanning the no-build network for extreme V/C and making
    needed corrections has been adequate.  Setting the discount = 1 effectively
    turns off this feature.
    */
    discount = 1

    // calculate delay at V/C = 1
    //                                                   [trav time at half speed]     * flow
    v_abABmaxDelay = if v_abABffSpeed = 0 then 0 else v_length / ( v_abABffSpeed / 2 ) * v_abABVol
    v_abBAmaxDelay = if v_abBAffSpeed = 0 then 0 else v_length / ( v_abBAffSpeed / 2 ) * v_abBAVol
    v_nbABmaxDelay = if v_nbABffSpeed = 0 then 0 else v_length / ( v_nbABffSpeed / 2 ) * v_nbABVol
    v_nbBAmaxDelay = if v_nbBAffSpeed = 0 then 0 else v_length / ( v_nbBAffSpeed / 2 ) * v_nbBAVol

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
    // Determine which projects change capacity
    // (includes road diets as well as widenings)
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
        Increase Capacity (New Road)	  |                 |
            Increase Volume	            | n/a             |Primary
            Decrease Volume	            | n/a             |n/a
                                        |                 |
                                        |                 |
    Existing Links				              |                 |
                                        | Decrease Delay  |Increase Delay
        Increase Capacity (Widening)   	|                 |
            Increase Volume	            | Primary         |Secondary
            Decrease Volume	            | Both (D.D.)     |n/a	                D.D. = decreased delay
        Decrease Capacity (Road Diet)	  |                 |
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

    This metric will determine how much of the change in delay on the project is
    due to the project and how much is the secondary benefit from other projects.

    Example 1: if a link's capacity increases by 20% and it's volume decreases by 10%:
    2/3 of the delay reduction is due to the project.  That is primary benefit.
    1/3 is due to improvements from other projects drawing volume away.  Secondary benefit.

    Example 2: if a link's capacity decreases by 30% and it's volume increases by 10%:
    3/4 of the delay increase is due to the project.
    1/4 is due to changes in other links.
    */

    // For this section of code, ab/ba once again refers to direction (ab is not "all build").
    // Confusing.  Clean up if given time.

    // Determine which cell (from the commented table above) the links fall into.
    v_linkCategory = Vector(v_allprojid.length,"String",)
    v_linkCategory =    if (v_totDelayDiff < 0) then             // Decreased Delay
        (if v_totCapDiff >= 0 then                               // Increased Capacity
          (if v_totVolDiff >= 0 then "Primary" else "Both")      // Increased/Decreased Volume
        else(if v_totCapDiff < 0 then                            // Decreased Capacity
          (if v_totVolDiff >= 0 then "n/a" else "Secondary")     // Increased/Decreased Volume
          )
        )

      else if (v_totDelayDiff >= 0) then                         // Increased Delay
        (if v_totCapDiff >= 0 then                               // Increased Capacity
          (if v_totVolDiff >= 0 then "Secondary" else "n/a")     // Increased/Decreased Volume
        else(if v_totCapDiff < 0 then                            // Decreased Capacity
          (if v_totVolDiff >= 0 then "Both" else "Primary")      // Increased/Decreased Volume
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
    v_abPrimBen = if v_linkCategory = "Primary" then v_ABDelayDiff * -1 else 0
    v_abPrimBen = if v_linkCategory = "Both" then
      v_ABDelayDiff * -1 * v_abCapRatio else v_abPrimBen
    v_baPrimBen = if v_linkCategory = "Primary" then v_BADelayDiff * -1 else 0
    v_baPrimBen = if v_linkCategory = "Both" then
      v_BADelayDiff * -1 * v_baCapRatio else v_baPrimBen

    v_abSecBen  = if v_linkCategory = "Secondary" then v_ABDelayDiff * -1 else 0
    v_abSecBen  = if v_linkCategory = "Both" then
      v_ABDelayDiff * -1 * v_abVolRatio else v_abSecBen
    v_baSecBen  = if v_linkCategory = "Secondary" then v_BADelayDiff * -1 else 0
    v_baSecBen  = if v_linkCategory = "Both" then
      v_BADelayDiff * -1 * v_baVolRatio else v_baSecBen

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
          + "," + String(v_abSecBen[i]) + "," + String(v_baSecBen[i]))
      end
      CloseFile(file)
    end

    // For some reason, these equations can lead to "negative zero"
    // results that sort as smaller than, for example, -80
    // Doesn't make sense - Have to set them to 0
    v_abPrimBen = if ( v_abPrimBen < .0001 and v_abPrimBen > -.0001 ) then 0
      else v_abPrimBen
    v_baPrimBen = if ( v_baPrimBen < .0001 and v_baPrimBen > -.0001 ) then 0
      else v_baPrimBen
    v_abSecBen = if ( v_abSecBen < .0001 and v_abSecBen > -.0001 ) then 0
      else v_abSecBen
    v_baSecBen = if ( v_baSecBen < .0001 and v_baSecBen > -.0001 ) then 0
      else v_baSecBen

    // Create a copy of the all-build dbd
    path = SplitPath(Args.Benefits.allBuildHwy)
    Args.Benefits.outputDir = path[1] + path[2] + "\\BenefitCalculation\\"
    Args.Benefits.resultHwy = Args.Benefits.outputDir + "BenefitCalculation.dbd"
    CopyDatabase(Args.Benefits.allBuildHwy,Args.Benefits.resultHwy)

    // Modify the structure to add benefit-related fields
    dv_temp = AddLayerToWorkspace(
      Args.Benefits.llayer,Args.Benefits.resultHwy,Args.Benefits.llayer,
    )
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
    if discount <> 1 then do
      strct = strct + {{"ABDelayChange"   , "Real", 12, 2, "False", , , "Discounted AB Delay Change on Link. Delay above V/C = 1 multiplied by " + String(discount), , , , null}}
      strct = strct + {{"BADelayChange"   , "Real", 12, 2, "False", , , "Discounted AB Delay Change on Link. Delay above V/C = 1 multiplied by " + String(discount), , , , null}}
    end else do
      strct = strct + {{"ABDelayChange"   , "Real", 12, 2, "False", , , "Total AB Delay Change on Link", , , , null}}
      strct = strct + {{"BADelayChange"   , "Real", 12, 2, "False", , , "Total BA Delay Change on Link", , , , null}}
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
      if Args.Benefits.projIDType = "String" then
        projQuery = "Select * where " + Args.Benefits.projID + " = '" +
        projID + "'"
      else projQuery = "Select * where " + Args.Benefits.projID + " = " +
        String(projID)
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

    DropLayerFromWorkspace(dv_temp)

    // Create a map of the resulting highway layer
    {map,nlayer,llayer} = RunMacro("Create Highway Map",Args.Benefits.resultHwy)
    SetLayer(llayer)

    // Create a selection set of project links (where projs change cap)
    // Written this way because there is an upper limit on the number
    // of conditions (project IDs) that can be listed in a single query
    projectSet = RunMacro("G30 create set","Capacity-Changing Project Links")
    for i = 1 to v_projID.length do
      projID = v_projID[i]
      // Some models use strings for project IDs, others don't.  Catch both.
      if Args.Benefits.projIDType = "String" then
        projQuery = "Select * where " + Args.Benefits.projID + " = '" +
        projID + "'"
      else projQuery = "Select * where " + Args.Benefits.projID + " = " +
        String(projID)
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
This macro takes an open highway layer (in a map) and a project id.
Exports the project links to a project layer.
Returns a vector describing the distance of every link in the highway layer
from the project layer.  Also appends the information to the highway layer
in field "dist_2_proj".
*/

Macro "Distance to Project" (map, llyr, p_id_field, proj_id)

  SetLayer(llyr)
  qry = "Select * where " + p_id_field + " = " +
    (if TypeOf(proj_id) = "string" then "'" + proj_id + "'"
    else String(proj_id))
  n = SelectByQuery("proj", "Several", qry)
  if n = 0 then Throw("No project records found")

  file = GetTempFileName("*.dbd")
  opts = null
  opts.[Layer Name] = "temp"
  ExportGeography(llyr + "|proj", file, opts)
  {p_nlyr, p_llyr} = GetDBLayers(file)
  AddLayer(map, p_llyr, file, p_llyr)

  a_fields = {{"dist_2_proj", "Real", 10, 2, }}
  RunMacro("TCB Add View Fields", {llyr, a_fields})

  SetLayer(llyr)
  TagLayer("Distance", llyr + "|", "dist_2_proj", p_llyr, )

  v_dist = GetDataVector(llyr + "|", "dist_2_proj", )

  DropLayer(map, p_llyr)
  return(v_dist)
Endmacro

/*
This macro is used to prepare a csv table that can be used to estimate
a distance profile for projects.  A no build scenario is required. Each
comparison sceanrio must be the same as the no-build, but with one
project added.
*/

Macro "Prepare Dist Est File"

  // Prepare arrays of scenario folder names and project IDs.
  // Each scenario (other than no-build) must have one extra project
  // included in addition to any projects in the no-build.
  scen_dir = "C:\\projects/HamptonRoads/Repo/scenarios"
  no_build = "EC2040"
  a_scens = {"SEPG_1", "SEPG_1_8L", "SEPG_2", "SEPG_3", "SEPG_4"}
  a_proj_id = {1001, 1001, 1002, 1003, 1004}

  // Add no_build highway to the workspace before looping over scenarios
  nb_hwy = scen_dir + "/" + no_build + "/Outputs/HR_Highway.dbd"
  {nb_n, nb_l} = GetDBLayers(nb_hwy)
  nb_l = AddLayerToWorkspace("no build", nb_hwy, nb_l)

  // Open a file to write results to and add header row
  file = OpenFile(scen_dir + "/dist_estimation.csv", "w")
  WriteLine(file, "scenario,id,distance,vmt,abs_vmt_diff")

  // Loop over each scenario
  for s = 1 to a_scens.length do
    scen = a_scens[s]
    proj_id = a_proj_id[s]

    // Open a map of the scenario output highway layer
    hwy_file = scen_dir + "/" + scen + "/Outputs/HR_Highway.dbd"
    {nlyr, llyr} = GetDBLayers(hwy_file)
    map = RunMacro("G30 new map", hwy_file)

    // Call the distance to project macro to calculate distances
    p_id_field = "PROJ_ID"
    RunMacro("Distance to Project", map, llyr, p_id_field, proj_id)

    // Join no-build layer and collect data
    jv = JoinViews("jv", llyr + ".ID", nb_l + ".ID", )
    opts = null
    opts.[Sort Order] = {{llyr + ".ID", "Ascending"}}
    opts.[Missing as Zero] = "True"
    v_id = GetDataVector(jv + "|", llyr + ".ID", opts)
    v_length = GetDataVector(jv + "|", llyr + ".Length", opts)
    v_dist = GetDataVector(jv + "|", llyr + ".dist_2_proj", opts)
    v_nb_vol = GetDataVector(jv + "|", nb_l + ".TOT_FlowDAY", opts)
    v_vol = GetDataVector(jv + "|", llyr + ".TOT_FlowDAY", opts)

    // Calculate vmt
    v_vmt = v_vol * v_length
    v_nb_vmt = v_nb_vol * v_length

    // Calculate absolute change and absolute percent change in vmt
    v_abs_diff = abs(v_vmt - v_nb_vmt)

    // Write each line of the vectors to a row in the csv
    for i = 1 to v_id.length do
      line = scen + "," + String(v_id[i]) + "," + String(v_dist[i]) +
      "," + String(v_vmt[i]) +
      "," + String(v_abs_diff[i])
      WriteLine(file, line)
    end

    CloseView(jv)
    CloseMap(map)
  end

  CloseFile(file)
  ShowMessage("Done")
EndMacro
