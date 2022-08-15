DECLARE @TableName VARCHAR(200) = 'Channel'
       ,@SchemaName VARCHAR(200) = 'dbo'
      
DECLARE @MaxLengthDefault INT
       ,@Column VARCHAR(50)
       ,@MaxLength INT
       ,@MaxLengthString VARCHAR(10)
       ,@ColumnID INT
       ,@MaxColumnID INT
       ,@Command VARCHAR(2000)

CREATE TABLE #Temp (
       column_name VARCHAR(50)
       ,max_length INT
       ,max_length_default INT
       ,longest_data VARCHAR(500)
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

    SELECT @Column = b.[name]
              ,@MaxLengthDefault = b.[max_length]
       FROM sys.tables a
       INNER JOIN sys.columns b on a.[object_id] = b.[object_id]
       WHERE a.[name] = @TableName
              and SCHEMA_NAME(a.[schema_id]) = @SchemaName
              and b.[column_id] = @ColumnID

    --SELECT @Column, @MaxLengthDefault

    IF ( @Column is not null )
    BEGIN
        SET @Command = 'INSERT INTO #Temp(column_name, max_length, max_length_default, longest_data)
            SELECT ''' + @Column + ''' ,MAX(LEN(CAST([' + @Column + '] as VARCHAR(8000))))
            ,' + CAST(@MaxLengthDefault as VARCHAR(5)) +
            ',MAX(' + @Column + ')' +
            'FROM [' + @SchemaName + '].[' + @TableName + ']
            WHERE [' + @Column + '] IS NOT NULL'
                        --SELECT @Command
        EXEC(@Command)       
    END

    SET @ColumnID = @ColumnID + 1
END

SELECT * FROM #Temp
ORDER BY max_length_default, max_length desc

DROP TABLE #Temp