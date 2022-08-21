
# Nvarchar(max)
September 30, 2018 at 1:08 am Eddie Wuerch
https://www.sqlservercentral.com/forums/topic/nvarchar4000-and-performance#post-2007434

The counter argument is that while data stored on disk and persisted in the data cache uses actual size (if you use Unicode compression when nvarchar(columns) that hold ASCII data), but memory is allocated using the declared size. You only write the row on disk once, and cache it in memory at most once, but every session querying the data holds at least one full-size copy. Memory is a significantly more finite resource than disk.
You must persist that data in memory (working memory, not data cache) when you use it in a query. Data can be packed on disk pages based on their actual width, but query memory grants have to happen before the data arrives - you don't know the actual width until you read the data into memory, so the memory must be allocated before the actual footprint of the data can be determined. By then, it's too late.

When estimating the width of a row in order to request memory, varchar and nvarchar columns are assumed to be half full. A varchar(2000) column would cause a 1000-byte memory request per row, and an nvarchar(2000) would cause a 2000-byte request (1/2 of 2000 = 1000 characters * 2 bytes per character). 

To demonstrate, I built a table with several varchar and nvarchar columns of different width. I then filled the table from sys.objects, inserting the [name] column value into each of the varchar/nvarchar columns. Each column holds the same data, using a different data type.
``
CREATE TABLE dbo.ColumnSizes(
id    int    NOT NULL,
NVarChar64 nvarchar(64) NOT NULL, 
NVarChar256 nvarchar(256) NOT NULL, 
NVarChar1024 nvarchar(1024) NOT NULL, 
NVarChar4000 nvarchar(4000) NOT NULL,
NVarCharMax nvarchar(max) NOT NULL,
VarChar64  nvarchar(64) NOT NULL,
VarChar256 nvarchar(256) NOT NULL,
VarChar1024 nvarchar(1024) NOT NULL,
VarChar8000 varchar(8000) NOT NULL,
VarCharMax varchar(max) NOT NULL,
CONSTRAINT pkColSz PRIMARY KEY CLUSTERED (id) 
)
GO
INSERT dbo.ColumnSizes(id, NVarChar64, NVarChar256, NVarChar1024, NVarChar4000, NVarCharMax, 
        VarChar64, VarChar256, VarChar1024, VarChar8000, VarCharMax)
SELECT object_id, name, name, name, name, name, name, name, name, name, name FROM sys.all_objects;
I enabled some XE sessions to grab memory usage, then ran a separate query on each column to capture the memory grants for the different columns:
SELECT id FROM dbo.ColumnSizes ORDER BY id;
 GO
SELECT NVarChar64 FROM dbo.ColumnSizes ORDER BY NVarChar64;
 GO
SELECT NVarChar256 FROM dbo.ColumnSizes ORDER BY NVarChar256;
 GO
SELECT NVarChar1024 FROM dbo.ColumnSizes ORDER BY NVarChar1024;
 GO
/* and so on... */
``
**NOTE: NULL values below indicate the query requested less than 5MB of memory.**
The [id] column is included to show the base overhead for a row and primary key. This will be included in all other row totals. Subtract from EstRowWidth to show the column's memory cost.
Because there's a SORT operator in there, the memory request is twice the input set (need memory to hold the full dataset feeding the SORT operator and memory to hold the entire sorted output).
(results for SQL2016 SP2)
The maximum length of any of the values is less than 60 bytes, with 95% of the values at 37 bytes or less. With the proper data type, this query needs less than 256KB to run completely, including the SORT operator. By blowing up the possible sizes for the variable character types, significant extra memory is allocated and wasted. All of the queries tested return the exact same data.
The [Used %] column shows that storing the sample data in an NVarchar(4000) resulted in 99% of the granted memory being wasted.
 TestColumn     EstRowWidth IdealMemKB  GrantedMemKB UsedMemKB   Used % Granted %
 -------------- ----------- ----------- ------------ ----------- ------ ---------
 id             11          NULL        NULL         NULL        NULL   NULL
 NVarChar64     75          NULL        NULL         NULL        NULL   NULL
 VarChar64      75          NULL        NULL         NULL        NULL   NULL
 NVarChar256    267         NULL        NULL         NULL        NULL   NULL
 VarChar256     267         NULL        NULL         NULL        NULL   NULL
 NVarChar1024   1035        5344        5344         216         4      100
 VarChar1024    1035        5344        5344         216         4      100
 NVarChar4000   4011        11872       11872        216         1      100
 VarChar8000    4011        11872       11872        168         1      100
 NVarCharMax    4035        11936       11936        272         2      100
 VarCharMax     4035        11936       11936        224         1      100