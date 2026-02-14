-- create a user defined to type/table to store a list of MAC Addresses
if not exists(select * from sys.types where name = 'MACAddressTable' AND is_table_type = 1)
begin
	create type MACAddressTable as Table(
		id int primary key identity(1,1),
		macAddress varchar(17)
	)
end

-- Drop the temporary table
drop table if exists ##FoundTableResults;
go

-- Recreate the temporary table to hold found table result
exec dbo.createDynamicTable
	@databaseName = 'tempdb',
	@tableName = '##FoundTableResults',
	@columnsDefinitions =		N'DBName nvarchar(128) not null\
								, schemaName nvarchar(128) not null\
								, tableName nvarchar(128) not null'

-- Check if the test table exist or not with OBJECT_ID
if  OBJECT_ID('SOCLab.dbo.Table_test', N'U') is not null
begin
	print 'SOCLab.dbo.Table_test table exist.'
end

drop table if exists SOCLab.dbo.connected_devices
go

drop table if exists SOCLab.dbo.connected_devices_report
go

-- Create a table to hold the connected device report
exec dbo.createDynamicTable
	@databaseName = 'SOCLab',
	@tableName = 'connected_devices_report',
	@columnsDefinitions =		N'reportID int identity(1,1) primary key not null\
								, createdDateTime datetime2 \
								, constraint PK_connected_devices_report primary key (reportID)'

-- Create a table to store the unknown devices events
exec dbo.createDynamicTable
	@databaseName = 'SOCLab',
	@tableName = 'connected_devices',
	@columnsDefinitions =	N'eventID int identity(1,1) not null \
							, reportID int not null \
							, deviceID varchar(36) not null \
							, name nvarchar(268) not null \
							, friendlyName nvarchar(268) not null \
							, currentMACAddress char(17) not null \
							, ipv4Address varchar(15) not null \
							, ipv6Address nvarchar(268) not null \
							, connectionType nvarchar(18) not null \
							, operatingSystem nvarchar(268) not null \
							, deviceType nvarchar(268) not null \
							, description nvarchar(268) \
							, signalDecibels int not null \
							, isGuest bit not null \
							, BSSID char(17) not null \
							, constraint PK_connected_devices primary key (eventID)'

-- Connect the report table with the event table
exec dbo.addDynamicForeignKey
	@databaseName = 'SOCLab',
	@baseTable = 'connected_devices',
	@refTable = 'connected_devices_report',
	@refTableColumnName = 'reportID'


drop table if exists SOCLab.dbo.known_MAC_Addresses
go

drop table if exists SOCLab.dbo.known_devices
go

-- Check if the test table exist or not
if not exists (select 1
			from information_schema.tables
			where table_schema = 'dbo'
				and table_name = 'Table_test')
	begin
		print 'table doesn''t exists'
	end
else
	begin
		print 'table exists'
	end
go

-- Create the table to store the known MAC Addresses associated with its device ID
exec dbo.createDynamicTable
	@databaseName = 'SOCLab',
	@tableName = 'known_MAC_Addresses',
	@columnsDefinitions =	'macAddressID int identity (1,1) primary key \
							, deviceID char(36) not null \
							, macAddress char(17) not null\
							, constraint PK_known_MAC_Addresses primary key (macAddressID)'

-- Create the table to store the known devices
exec dbo.createDynamicTable
	@databaseName = 'SOCLab',
	@tableName = 'known_devices',
	@columnsDefinitions =	N'deviceID char(36) not null \
							, name nvarchar(268) not null \
							, friendlyName nvarchar(268) not null \
							, constraint PK_known_devices primary key (deviceID)'

-- Connect the known devices table with the known MAC Addresses table
exec dbo.addDynamicForeignKey
	@databaseName = 'SOCLab',
	@baseTable = 'known_MAC_Addresses', -- the child
	@refTable = 'known_devices', -- the parent
	@refTableColumnName = 'deviceID';
go

declare @foundTables Table (
	databaseName nvarchar(128),
	schemaName nvarchar(128),
	tableName nvarchar(128)
);

-- Search for all tables created so far with database exclusion
insert into @foundTables
exec dbo.findTable
	@tableName = '%',
	@excludeDBs = 'master,model,msdb,tempdb'

select * from @foundTables

declare @refTableName nvarchar(268);
declare @fKey nvarchar(268);


-- Testing the dynamically find reference table stored procedure
exec findDynamicRefTableInfo
	@databaseName = 'SOCLab',
	@tableName = 'known_devices',
	@refTableName = @refTableName output,
	@fKey = @fKey output;

select referenceTableName = @refTableName, foreignKey = @fKey;
go

-- Attempt to truncate the know MAC Address table to start anew
exec dynamicTruncateTable
	@databaseName = 'SOCLab',
	@tableName = 'known_MAC_Addresses',
	@baseColumnName = 'deviceID',
	@refColumnName = 'deviceID';
go






