/*
These macros provide a layer of abstraction to work with table data
in GISDK.  Think something like a basic tidyr.

Once a table is created, you could calculate a new density column
like so:

TABLE.density = TABLE.population / TABLE.area
*/

Macro "test"
  a_colNames = {"col1", "col2"}
  a_data = {A2V({1, 2, 3}), A2V({"one", "two", "three"})}

  // Test table creation
  cTABLE = RunMacro("Create Table", a_colNames, a_data)

  // Test table read
  dir = "C:\\Users\\warddk\\Documents\\SAG\\Tools\\GISDK Tables"
  view = OpenTable("tbl", "FFB", {dir + "\\FreeFlowSpeed.bin", })
  rTABLE = RunMacro("Read Table", view)
  CloseView(view)

  // Test calculation and table write
  rTABLE.test = rTABLE.PSTtoFFMod * 2
  RunMacro("Write Table", rTABLE, dir + "\\test.csv", )
  ShowMessage("Done with test")
EndMacro

/*
Create Table
Take field names and vectors and create a table in memory
Returns a GISDK options array that represents a table.

a_colNames: Array of strings of column names
a_data: array of vectors.  Each must be the same length

See the "View to Table" function for creating a table object
from an existing view.  See "Matrix to Table" for matrix
conversion.
*/
Macro "Create Table" (a_colNames, a_data)

  // Check for required arguments
  if a_colNames = null or a_data = null then do
    Throw("Required argument missing or null.")
  end

  // Check dimensions of the three input arrays
  length = a_colNames.length
  if a_data.length <> length then do
    Throw("Create Table: Input arrays must have same length.")
  end

  // Check vector lengths
  for i = 1 to a_data.length do
    if i = 1 then length = a_data[i].length
    else do
      if length <> a_data[i].length then do
        Throw("Create Table: Not all data vectors have equal length.")
      end
    end
  end

  // Create a table object
  TABLE = null
  for c = 1 to a_colNames.length do
    name = a_colNames[c]
    vec = a_data[c]

    TABLE.(name) = vec
  end

  return(TABLE)
EndMacro


/*
This macro writes a table object to csv

file (string): file name
TABLE (array) object
append (string): If true, then append data to file.
*/
Macro "Write Table" (TABLE, file, append)

  // Check for required arguments
  if TABLE = null or file = null then do
    Throw("Required argument missing or null.")
  end

  // Check TABLE to make sure all vectors are the same length
  for i = 1 to TABLE.length do
    if i = 1 then length = TABLE[i][2].length
    else do
      if length <> TABLE[i][2].length then do
        Throw("Write Table: Not all columns have equal length.")
      end
    end
  end

  // Check that the file name ends in CSV
  if Right(file, 3) <> "csv" then do
    Throw("Write Table: File must be a CSV")
  end

  // Open a csv file for writing
  if append then file = OpenFile(file, "a")
  else file = OpenFile(file, "w")

  // Write the row of column names
  for i = 1 to TABLE.length do
    if i = 1 then firstLine = TABLE[i][1]
    else firstLine = firstLine + "," + TABLE[i][1]
  end
  WriteLine(file, firstLine)

  // Write each remaining row
  for r = 1 to TABLE[1][2].length do
    line = null
    for c = 1 to TABLE.length do
      type = TABLE[c][2].type

      if type = "string" then strVal = TABLE[c][2][r]
      else strVal = String(TABLE[c][2][r])
      if c = 1 then line = strVal
      else line = line + "," + strVal
    end
    WriteLine(file, line)
  end

  CloseFile(file)
EndMacro


/*
View to Table

This macro converts a view into a table object.
view (string): TC view name
set (string): optional set name
*/

Macro "View to Table" (view, set)

  // Check for required arguments
  if view = null then do
    Throw("Required argument 'view' missing or null.")
  end

  a_fields = GetFields(view, )
  a_fields = a_fields[1]

  TABLE = null
  for f = 1 to a_fields.length do
    field = a_fields[f]

    // When a view has too many rows, a "???" will appear in the editor
    // meaning that TC did not load the entire view into memory.
    // Creating a selection set will force TC to load the entire view.
    if f = 1 then do
      SetView(view)
      qry = "Select * where nz(" + field + ") >= 0"
      SelectByQuery("temp", "Several", qry)
    end

    TABLE.(field) = GetDataVector(view + "|" + set, field, )
  end

  return(TABLE)
EndMacro

/*
Converts a matrix to a table object.

mtxcur: a matrix currency that fully defines the matrix
handle, core name, and row/column index to convert.

*/

Macro "Matrix to Table" (mtxcur)

  // Validate arguments
  if mtxcur.matrix.Name = null then do
    Throw("mtxcur variable must be a matrix currency")
  end

  // Create a temporary bin file
  file_name = GetTempFileName(".bin")

  // Set the matrix index and export to a table
  SetMatrixIndex(mtxcur.matrix, mtxcur.rowindex, mtxcur.colindex)
  opts = null
  opts.Tables = {mtxcur.corename}
  CreateTableFromMatrix(mtxcur.matrix, file_name, "FFB", opts)

  // Open exported table into view
  view = OpenTable("view", "FFB", {file_name})

  // Read the view into a table
  TABLE = RunMacro("View to Table", view)

  // Clean up workspace
  CloseView(view)
  DeleteFile(file_name)
  DeleteFile(Substitute(file_name, ".bin", ".DCB", ))

  return(TABLE)
EndMacro

/*
Performs the equivalent of vlookup in excel,
similar to match() in R.

input: a vector/array contiaining the values that will be looked up
index: a vector/array the same length as value.  Determines position.
value: a vector/array of the values to find and return.

Returns a vector the same length as "input" that contains the
values from the value vector.
*/

Macro "Match" (input, index, value)

  // Make sure arguments are vectors or arrays
  if TypeOf(input) <> "array" and TypeOf(input) <> "vector" then do
    Throw("input must be either a vector or array.")
  end else if TypeOf(index) <> "array" and TypeOf(index) <> "vector" then do
    Throw("index must be either a vector or array.")
  end else if TypeOf(value) <> "array" and TypeOf(value) <> "vector" then do
    Throw("value must be either a vector or array.")
  end

  // If inputs are vectors, convert to arrays
  if TypeOf(input) = "vector" then input = V2A(input)
  if TypeOf(index) = "vector" then index = V2A(index)
  if TypeOf(value) = "vector" then value = V2A(value)

  // Make sure v_index and value are same length
  if index.length <> value.length then do
    Throw("v_index and value must be same length.")
  end

  // Perform the match
  for i = 1 to input.length do
    in = input[i]

    pos = ArrayPosition(index, {in}, )
    ret = value[pos]
    a_ret = a_ret + {ret}
  end

  return(A2V(a_ret))

EndMacro

/*
Takes a TBL object and makes sure all data is stored in a vector.
This is useful if the table object was built using arrays to enable
vector math.

TABLE: table object to be checked/converted
*/

Macro "Vectorize Table" (TABLE)

  // Validate Arguments
  if TypeOf(TABLE) <> "array" then do
    Throw("Table object must be an array.")
  end

  for i = 1 to TABLE.length do
    colname = TABLE[i][1]
    data = TABLE[i][2]

    if TypeOf(data) = "array" then TABLE.(colname) = A2V(data)
  end

  return(TABLE)
EndMacro

/*
Like dply or SQL "select", returns a table with only
the columns listed in a_fields

TABLE: table object
a_fields: list of fields to select
*/

Macro "Select" (TABLE, a_fields)

  NEWTABLE = null
  for f = 1 to a_fields.length do
    field = a_fields[f]

    if !(TABLE.(field).length > 0) then
      Throw("Select: " + field + " not found in table")
    else NEWTABLE.(field) = TABLE.(field)
  end

  return(NEWTABLE)
EndMacro

/*
Similar to dplyr group_by() %>% summarize(), this macro groups a table
by specified columns and returns aggregate results.  The stats are calculated
for all columns in the table that are not listed as grouping columns.

TABLE: A table object
a_groupFields: Array of column names to group by
agg:
  Options array listing field and aggregation info
  e.g. agg.weight = {"sum", "avg"}
  This will sum and average the weight field
  The possible aggregations are:
    first, sum, high, low, avg, stddev

Returns
A table object of the summarized input table object
In the example above, the aggregated fields would be
  sum_weight and avg_weight
*/

Macro "Summarize" (TABLE, a_groupFields, agg)

  // Remove fields from TABLE that aren't listed for summary
  for i = 1 to a_groupFields.length do
    a_selected = a_selected + {a_groupFields[i]}
  end
  for i = 1 to agg.length do
    a_selected = a_selected + {agg[i][1]}
  end
  TABLE = RunMacro("Select", TABLE, a_selected)

  // Convert the TABLE object into a view in order
  // to leverage GISDKs SelfAggregate() function
  {view, fileName} = RunMacro("Table to View", TABLE)

  // Create field specs for SelfAggregate()
  agg_field_spec = view + "." + a_groupFields[1]

  // Create the "Additional Groups" option for SelfAggregate()
  opts = null
  if a_groupFields.length > 1 then do
    for g = 2 to a_groupFields.length do
      opts.[Additional Groups] = opts.[Additional Groups] + {a_groupFields[g]}
    end
  end

  // Create the fields option for SelfAggregate()
  for i = 1 to agg.length do
    name = agg[i][1]
    stats = agg[i][2]

    new_stats = null
    for j = 1 to stats.length do
      stat = stats[j]

      new_stats = new_stats + {{Proper(stat)}}
    end
    fields.(name) = new_stats
  end
  opts.Fields = fields

  // Create the new view using SelfAggregate()
  agg_view = SelfAggregate("aggview", agg_field_spec, opts)

  /*opts1.Fields = {{"vmt_change", {{"Sum"}, {"Avg"}}}}*/
  /*agg_view = SelfAggregate("aggview", agg_field_spec, opts1)*/

  // Read the view into a table object
  TBL = RunMacro("View to Table", agg_view)

  // The field names from SelfAggregate() are messy.  Clean up.
  // The first fields will be of the format "GroupedBy(ID)".
  // Next is a "Count(bin)" field.
  // Then there is a first field for each group variable ("First(ID)")
  // Then the stat fields in the form of "Sum(trips)"

  // Set group columns back to original name
  for c = 1 to a_groupFields.length do
    TBL[c][1] = a_groupFields[c]
  end
  // Set the count field name
  TBL[a_groupFields.length + 1][1] = "Count"
  // Remove the First() fields
  TBL = ExcludeArrayElements(
    TBL,
    a_groupFields.length + 2,
    a_groupFields.length
  )
  // Change fields like Sum(x) to sum_x
  for i = 1 to agg.length do
    field = agg[i][1]
    stats = agg[i][2]

    for j = 1 to stats.length do
      stat = stats[j]

      current_field = "[" + Proper(stat) + "(" + field + ")]"
      new_field = lower(stat) + "_" + field
      TBL = RunMacro("Rename Field", TBL, current_field, new_field)
    end
  end

  CloseView(agg_view)
  return(TBL)
EndMacro

/*
Creates a view based on a temporary binary file.  The primary purpose of
this macro is to make GISDK functions/operations available for a table object.
The view is often read back into a table object afterwards.

TABLE: table object to convert to a view

Returns:
view_name:  Name of the view as opened in TrandCAD
file_name:  Name of the temporary file
*/

Macro "Table to View" (TABLE)

  // Convert the TABLE object into a CSV and open the view
  tempFile = GetTempFileName(".csv")
  RunMacro("Write Table", TABLE, tempFile)
  csv = OpenTable("csv", "CSV", {tempFile})

  // Export to binary and open
  file_name = GetTempFileName(".bin")
  ExportView(csv + "|", "FFB", file_name, , )
  view_name = OpenTable("bin", "FFB", {file_name})

  // Clean up - even though temp files are deleted on program close,
  // unsure what happens if the program crashes.  Also, the CSV will generate
  // a .DCC file when opened.  Unsure if it gets deleted automatically, too.
  CloseView(csv)
  DeleteFile(tempFile)
  DeleteFile(Substitute(tempFile, ".csv", ".DCC", ))

  return({view_name, file_name})
EndMacro


/*
Returns an array of the column names of a table object
*/

Macro "Get Column Names" (TABLE)

  for c = 1 to TABLE.length do
    a_colnames = a_colnames + {TABLE[c][1]}
  end

  return(a_colnames)
EndMacro

/*
Applies a query to a table object.

TABLE: table object
query: Valid TransCAD query (e.g. "ID = 5" or "Name = 'Sam'")
*/

Macro "Filter Table" (TABLE, query)

  {view, file} = RunMacro("Table to View", TABLE)
  SetView(view)
  query = "Select * where " + query
  SelectByQuery("set", "Several", query)
  TBL = RunMacro("View to Table", view, "set")

  return(TBL)
EndMacro

/*
Changes the name of a column in a table object

TABLE: table object
current_name: current name of the field in the table
              can be string or array of fields
new_name: desired new name of the field
          can be string or array of fields
          if array, must be the same length as current_name
*/

Macro "Rename Field" (TABLE, current_name, new_name)

  // Argument checking
  if TypeOf(current_name) <> TypeOf(new_name)
    then Throw("Rename Field: current and new name must be same type")
  if TypeOf(current_name) <> "string" then do
    if current_name.lenth <> new_name.length
      then Throw("Rename Field: Field name arrays must be same length")
  end

  // If a single field string, convert string to array
  if TypeOf(current_name) = "string" then do
    current_name = {current_name}
  end
  if TypeOf(new_name) = "string" then do
    new_name = {new_name}
  end

  for n = 1 to current_name.length do
    cName = current_name[n]
    nName = new_name[n]

    for c = 1 to TABLE.length do
      if TABLE[c][1] = cName then TABLE[c][1] = nName
    end
  end

  return(TABLE)
EndMacro

/*
Sets the names of a table.  Unlike "Rename Field", it doesn't
matter what the current names are.

Inputs:
a_names
  Array
  Array of strings that are the field names.  Must be the same
  length as the table object.

Returns:
Table object with new names
*/

Macro "Set Table Names" (TABLE, a_names)

  // Argument checking
  if TABLE.length <> a_names.length
    then Throw("Set Table Names: Argument 'a_names' must\n" +
      "be the same length as table object."
    )

  NEWTABLE = TABLE
  for c = 1 to TABLE.length do
    NEWTABLE[c][1] = a_names[c]
  end

  return(NEWTABLE)
EndMacro

/*
Similar to dplyr's spread().  Unlike dplyr, a complete set of rows
must exist for each unique value of the key field.  There is no
fill option for missing combinations.

TABLE: table object
key: field whose unique values will become column names
value: field whose data will populate the new columns

Returns a new table object
*/

Macro "Spread" (TABLE, key, value)

  a_colnames = RunMacro("Get Column Names", TABLE)
  if ArrayPosition(a_colnames, {key}, ) = 0
    then Throw("Spread: key not found in table")
  if ArrayPosition(a_colnames, {value}, ) = 0
    then Throw("Spread: value not found in table")

  opts = null
  opts.Unique = "True"
  a_unique = SortVector(TABLE.(key), opts)
  for u = 1 to a_unique.length do
    uniqueVal = a_unique[u]

    if u = 1 then do
      // Create new table
      TBL = RunMacro(
        "Filter Table", TABLE, key + " = '" + uniqueVal + "'"
      )
      TBL.(uniqueVal) = TBL.(value)
      TBL.(key) = null
      TBL.(value) = null
    end else do
      TEMP = RunMacro(
        "Filter Table", TABLE, key + " = '" + uniqueVal + "'"
      )
      TBL.(uniqueVal) = TEMP.(value)
    end
  end

  return(TBL)
EndMacro

/*
Joins two table objects.

master_tbl and slave_tbl
  Table objects

m_id and s_id
  String or array
  The id fields from master and slave to use for join.  Use an array to
  specify multiple fields to join by.

Returns a table object.
*/

Macro "Join Tables" (master_tbl, m_id, slave_tbl, s_id)

  {master_view, master_file} = RunMacro("Table to View", master_tbl)
  {slave_view, slave_file} = RunMacro("Table to View", slave_tbl)

  if TypeOf(m_id) = "string" then m_id = {m_id}
  if TypeOf(s_id) = "string" then s_id = {s_id}
  if m_id.length <> s_id.length then
    Throw("Different number of fields used to join by")
  dim m_spec[m_id.length]
  dim s_spec[s_id.length]
  for i = 1 to m_id.length do
    m_spec[i] = master_view + "." + m_id[i]
    s_spec[i] = slave_view + "." + s_id[i]
  end

  jv = JoinViewsMulti("jv", m_spec, s_spec, )
  TABLE = RunMacro("View to Table", jv)

  // JoinViewsMulti() will attach the view names to the m_id and s_id fields
  // if they are the same.
  // Remove the s_id fields, and clean the m_id fields (if needed)
  for i = 1 to m_id.length do
    m = m_id[i]
    s = s_id[i]

    if m = s then do
      // Rename master field
      current_name = "[" + master_view + "]." + m
      TABLE = RunMacro("Rename Field", TABLE, current_name, m)
      // Delete slave field
      TABLE.("[" + slave_view + "]." + s) = null
    end else do
      // Delete slave field
      TABLE.(s) = null
    end
  end

  // Clean up the workspace
  CloseView(jv)
  CloseView(master_view)
  DeleteFile(master_file)
  DeleteFile(Substitute(master_file, ".bin", ".DCB", ))
  CloseView(slave_view)
  DeleteFile(slave_file)
  DeleteFile(Substitute(slave_file, ".bin", ".DCB", ))

  return(TABLE)
EndMacro

/*
Combines the rows of two tables. They must have the
same columns.
*/

Macro "Bind Rows" (first, second)

  // Check that tables have same columns
  col1 = RunMacro("Get Column Names", first)
  col2 = RunMacro("Get Column Names", second)
  for i = 1 to col1.length do
    if col1[i] <> col2[i] then Throw("Bind Rows: Columns are not the same")
  end

  // Make sure both tables are vectorized
  first = RunMacro("Vectorize Table", first)
  second = RunMacro("Vectorize Table", second)

  // Combine tables
  final = null
  for i = 1 to col1.length do
    col_name = col1[i]

    a1 = V2A(first.(col_name))
    a2 = V2A(second.(col_name))
    final.(col_name) = a1 + a2
  end

  // Vectorize the final table
  final = RunMacro("Vectorize Table", final)

  return(final)
EndMacro
