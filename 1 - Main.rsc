/*
To Do:

Need to add in a section where the count point layer is automatically
put back onto the links.  6/25/2015: code section exists, but has error.

*/


/*

Kyle

This is a generalized network review tool box.

Each tool is meant to be modularized so that they can be built one
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
**only Save/Load can handle sub arrays.  Read/WriteArray cannot.

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
    RunDbox("Main")
    
    // v_id = a2v({1,2,3})
    // RunDbox("routeCont",v_id)
    
EndMacro
	


// Main Dialog Box

dBox "Main" center,center,125,25 toolbox NoKeyboard Title:"Network Check Tool"


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
        RunDbox("Tool Setup")
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



