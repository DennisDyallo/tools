WHILE 1=1
BEGIN
	DECLARE @TableName nvarchar(100) = 'Tabla.dbo.BroadcastSetting'
	DECLARE @ColumnName nvarchar(100) = 'Tabla.dbo.Id'
	DECLARE @ConstraintName nvarchar(200)
	
	SELECT @ConstraintName = Name 
	FROM SYS.DEFAULT_CONSTRAINTS
	WHERE PARENT_OBJECT_ID = OBJECT_ID(@TableName)
	AND PARENT_COLUMN_ID = (SELECT column_id FROM sys.columns
							WHERE NAME = @ColumnName
							AND object_id = OBJECT_ID(@TableName))
	IF @@ROWCOUNT = 0 BREAK
	IF @ConstraintName IS NOT NULL
	EXEC('ALTER TABLE ' + @TableName + 'DROP CONSTRAINT ' + @ConstraintName)

END