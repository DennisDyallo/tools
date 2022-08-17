/**************************************
SQL to get max length of values in every table column.

This SQL queries the specified table to get the max length 
of all the values in every column.  

To work, load all the incoming data into a "permanent" temporary table 
where every column is defined as a varchar(max).

Then run this script against that "permanent" temporary table, comparing 
the results against the original table's schema to see what column, and
then what record(s), is/are causing the issue.

Example, if the max length of a value in one of the columns is 270, 
but your original table's schema is varchar(255), obviously either 
the original table's schema will have to be altered or the data corrected. 

Code from: http://cc.davelozinski.com
**************************************/

--The table we'll be performing this query on to get the lengths of every column.
--Default is dbo schema. Change as appropriate for your table.

-- Modified by DennisDyallo 20220713

DECLARE @TableName VARCHAR(200) = 'Audio' --Your Table
       ,@SchemaName VARCHAR(200) = 'dbo' --Your Schema
DECLARE @ScannedForTypes TABLE (type nvarchar(30))
INSERT INTO @ScannedForTypes VALUES ('nvarchar'), ('varchar')
                                   -- ^^ YOUR TYPES HERE ^^
DECLARE @MaxLengthDefault INT
       ,@Column VARCHAR(50)
       ,@MaxLength INT
       ,@ColumnID INT
       ,@MaxColumnID INT
       ,@Command VARCHAR(2000)
	   ,@ColumnType VARCHAR(50)
 
CREATE TABLE #Temp (
       column_name VARCHAR(50)
       ,max_length INT
       ,max_length_default INT
	   ,longest_data VARCHAR(500),
	   column_type NVARCHAR(50)
)
 
SELECT @ColumnID = min(b.[column_id])
       ,@MaxColumnID = max(b.[column_id]) 
FROM sys.tables a
INNER JOIN sys.columns b on a.[object_id] = b.[object_id] 
WHERE a.[name] = @TableName 
       and SCHEMA_NAME(a.[schema_id]) = @SchemaName    
 
--SELECT @ColumnID, @MaxColumnID
 
WHILE(@ColumnID <= @MaxColumnID)
BEGIN
    SET @Column = null
 
    SELECT @Column = b.[name], @MaxLengthDefault = b.[max_length], @ColumnType = t.name
       FROM sys.tables a
       INNER JOIN sys.columns b on a.[object_id] = b.[object_id]
	   INNER JOIN sys.types t on t.user_type_id = b.user_type_id
       WHERE a.[name] = @TableName
              and SCHEMA_NAME(a.[schema_id]) = @SchemaName
              and b.[column_id] = @ColumnID
			  and t.name in (select type from @ScannedForTypes)
			  
 
    --SELECT @Column, @MaxLengthDefault
 
    IF ( @Column is not null )
    BEGIN
		SET @Command = 'INSERT INTO #Temp(column_name, max_length, max_length_default, longest_data, column_type) 
			SELECT ''' + @Column +''' ,
			MAX(LEN(CAST([' + @Column + '] as VARCHAR(8000)))),' + 
			CAST(@MaxLengthDefault as VARCHAR(5)) + ',' + 
			
			'MAX(' + @Column + ')' + ',' +
			'''' + @ColumnType + '''' + ' '+

			'FROM [' + @SchemaName + '].[' + @TableName + '] 
			WHERE [' + @Column + '] IS NOT NULL'
			--SELECT @Command
		EXEC(@Command)        
    END
 
    SET @ColumnID = @ColumnID + 1
END
 
SELECT column_name, column_type, max_length, max_length_default
FROM #Temp
ORDER BY max_length_default, max_length desc
 
DROP TABLE #Temp