/*
The purpose of this tool is to remove all -1 attributes
from the Dir field.  The user must choose which directional
fields should be flipped (e.g., AB/BA_Lanes)
*/




dBox "Flip Link Directions" center,center,170,35 toolbox NoKeyboard Title:"Flip Link Directions"
    init do
        shared Args
        
        if Args.General.debug = 1 then do
            ShowItem("Debug")
        end
        
    enditem
    
    
    // Main scroll list holding all field names
    Text "Link Fields" 106,.5,20
    Scroll List " " 106, 1.5, 27, 20 List: Args.General.linkFieldList Multiple Variable:chosenFields
    
    // Fields to flip
    Text "Directional (AB/BA) Fields to Flip" 70,2,30
    Scroll List " " 68, after, 30, 5 List: Args.DirFlip.dirFields
    button " " after, same, 5 Prompt:"<<" do
        for i = 1 to chosenFields.length do
            Args.DirFlip.dirFields = Args.DirFlip.dirFields + {Args.General.linkFieldList[chosenFields[i]]}
        end
    enditem
    
    // Flip Button
    button "Flip" 40, 16, 12 do
        continue = "Yes"
        if Args.DirFlip.dirFields = null then do
            opts = null
            opts.Buttons = "YesNo"
            str =       "No AB/BA fields have been selected to flip.\n"
            str = str + "Any present in the layer will be wrong if you continue.\n"
            str = str + "Continue?"
            continue = MessageBox(, opts)
        end
        if continue = "Yes" then do
            CreateProgressBar("Flipping Link Directions", "False")
            RunMacro("DirFlip")
            DestroyProgressBar()
            ShowMessage("Done")
        end
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





Macro "DirFlip"
    shared Args
    
    // Create a map
    map = RunMacro("Create Highway Map")
    llayer = Args.General.llayer
    SetLayer(llayer)
    
    // Select links with Dir = -1
    qry = "Select * where Dir = -1"
    n = SelectByQuery("Dir=-1", "Several", qry)
    
    // Continue if some were found
    if n > 0  then do
    
        // Flip directional fields if they were specified
        if Args.DirFlip.dirFields <> null then do
            for i = 1 to Args.DirFlip.dirFields.length do
                abField = Args.DirFlip.dirFields[i]
                
                // If the current field is an AB field, the BA field will be found.
                // If it is a BA field, the macro will return null
                {baField, int} = RunMacro("getBAField", abField, Args.DirFlip.dirFields)
                
                // Continue if a BA field is found
                if baField <> null then do
                    v_ab = GetDataVector(llayer + "|Dir=-1", abField, )
                    v_ba = GetDataVector(llayer + "|Dir=-1", baField, )
                    SetDataVector(llayer + "|Dir=-1", abField, v_ba, )
                    SetDataVector(llayer + "|Dir=-1", baField, v_ab, )
                end
            end
        end
        
        // Reverse link topology
        v_id = GetDataVector(llayer + "|Dir=-1", "ID", )
        for i = 1 to v_id.length do
            id = v_id[i]
            
            UpdateProgressBar("Flipping Link Directions", Round(i / v_id.length * 100, 0))
            ReverseLink(id, )
        end
    end
    
EndMacro

