/*

*/

dBox "Point Data" center, center toolbox NoKeyboard
  Title:"Load Point Data"

  init do
    shared Args

    if Args.General.debug = 1 then do
        ShowItem("Debug")
    end

  enditem

  // Point DBD box
  Text 10, 1, 15 Framed Prompt: "Point Layer" Variable: layer_prompt
  Button after, same Prompt: "..." do

    on escape goto skip
    Args.LoadPoint.point_file = ChooseFile(
      {{"Geographic File (*.dbd)", "*.dbd"}},
      "Choose Point DBD",
      {{"Initial Directory",Args.General.initialDir}}
    )
    a_path = SplitPath(Args.LoadPoint.point_file)
    layer_prompt = a_path[3] + a_path[4]

    {plyr} = GetDBLayers(Args.LoadPoint.point_file)
    plyr = AddLayerToWorkspace(plyr, Args.LoadPoint.point_file, plyr)
    a_fields = GetFields(plyr, "All")
    a_fieldnames = a_fields[1]

    DropLayerFromWorkspace(plyr)
    skip:
  EndItem

  // Select the point field to tag (will be used to join attributes)
  Popdown Menu 10, 3, 24, 8 prompt: "Select Tag Field"
    list: a_fieldnames variable: Args.LoadPoint.tag_field Editable

  // Load button
  Button 10, 5 Prompt: "Load Point Data" do
    RunMacro("Load Point Data")
    ShowMessage("Point Data Loaded")
  EndItem

  // Quit Button
  button "Return" same, after, 12 do
        Return(0)
  enditem

  // Debug Button
  button "Debug" same, after, 12 Hidden  do
      Throw("User pressed debug button")
  enditem
EndDbox

Macro "Load Point Data"
  shared Args

  // Add field for the point ID (must be integer)
  {nlyr, llyr} = GetDBLayers(Args.General.hwyDBD)
  map = RunMacro("G30 new map", Args.General.hwyDBD)
  SetLayer(llyr)
  a_fields = {{"PointID", "Integer", 10,}}
  RunMacro("TCB Add View Fields", {llyr, a_fields})

  // Add point layer to map
  {plyr} = GetDBLayers(Args.LoadPoint.point_file)
  plyr = AddLayer(map, plyr, Args.LoadPoint.point_file, plyr)

  // Create set of non-CC links (to avoid tagging point data to them)
  SetLayer(llyr)
  qry = "Select * where " + Args.General.fClass + " <> '" +
    Args.General.ccClass + "'"
  n1 = SelectByQuery("non-CCs", "Several", qry)
  if n1 = 0 then Throw("No non-CC links found to tag")

  // Tag Layer
  TagLayer(
    "Value", llyr + "|non-CCs", "PointID", plyr,
    plyr + "." + Args.LoadPoint.tag_field
  )
  DropLayer(map, plyr)
  RunMacro("Close All")

  // Permanently join the point data to the link layer
  masterDBD = Args.General.hwyDBD
  mID = "PointID"
  slaveTbl = Substitute(Args.LoadPoint.point_file, ".dbd", ".bin", 1)
  sID = Args.LoadPoint.tag_field
  RunMacro("Append Columns to DBD", masterDBD, mID, slaveTbl, sID)
EndMacro
