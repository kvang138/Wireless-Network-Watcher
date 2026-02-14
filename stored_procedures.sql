-- Dynamically create a database
create or alter procedure dbo.createDatabase
	@databaseName nvarchar(268)
as
begin
	set nocount on;

	declare @sql nvarchar(max);

	if not exists (select 1 from sys.databases where name = @databaseName)
		begin
			set @sql = N'create database ' + quotename(@databaseName);

			exec sp_executesql @sql;
		end
	else
		begin
			print 'Database already exist.';
		end
end
go

-- Dynamically create a table
create or alter procedure dbo.createDynamicTable
	@databaseName nvarchar(128),
	@tableName nvarchar(128),
	@columnsDefinitions nvarchar(max)
as
begin
	set nocount on;
	
	-- Create the desired dynamic table if doesn't exist and assign the correct schema based on the table name.
	if OBJECT_ID(quotename(@databaseName) + (case when charindex(@tableName, '#') < 0 then '.dbo.' else '..' end) + quotename(@tableName), N'U') is null
		begin
			declare @targetDatabaseSP nvarchar(max) = quotename(@databaseName) + N'.sys.sp_executesql';
			declare @dynamicTable nvarchar(max) = N'create table ' + quotename(@tableName) + N' (' + @columnsDefinitions + N')';

			begin try
				exec @targetDatabaseSP @dynamicTable;

				print '[i] ' + @databaseName + '.dbo.' + @tableName + ' created successfully.';
			end try
			begin catch
				print '[!] Error creating ' + @databaseName + '.dbo.' + @tableName + '.';
				print '';
				print '[i] Error message: ' + error_message();
			end catch
		end
	else
		begin
			print @databaseName + '.dbo.' + @tableName + ' already exist.';
		end
end
go

-- Find table(s) with the name/pattern specify by the @table and exclude tables on excluded database(s) specifiy by @excludeDBs
create or alter procedure dbo.findTable
	@tableName nvarchar(128),
	@excludeDBs nvarchar(300)
as 
begin
	declare @sql nvarchar(max);
	declare @DBName nvarchar(268);

	declare db_cursor cursor for
	select name
	from sys.databases
	where state = 0
		and name not in (select * from string_split(@excludeDBs, ',')) -- exclude specific databases

	open db_cursor;
	fetch next from db_cursor into @DBName;

	-- Create a temp table to store the result temporary
	exec dbo.createDynamicTable
	@databaseName = 'tempdb',
	@tableName = '##FoundTableResults',
	@columnsDefinitions =		N'DBName nvarchar(128) not null\
								, schemaName nvarchar(128) not null\
								, tableName nvarchar(128) not null'

	-- Search through all non excluded databases to find table with the specify name
	while @@FETCH_STATUS = 0
	begin
		set @sql = '
			if exists (
				select 1
				from ' + QUOTENAME(@DBName) + '.information_schema.tables
				where table_name like ''' + @tableName + '''
			)
			begin
				insert into ##FoundTableResults (DBName, schemaName, tableName)
				select ' + quotename(@DBName, '''') + ' as DatabaseName, TABLE_SCHEMA, TABLE_NAME
				from ' + quotename(@DBName) + '.information_schema.tables
				where table_name like ''' + @tableName + ''';
			end';

		exec sp_executesql @sql, N'@tableName nvarchar(128)', @tableName;

		fetch next from db_cursor into @DBName;
	end

	close db_cursor;
	deallocate db_cursor;
end
go

-- Dynamically add a foreign key to the child table and connecting it with the parent table
create or alter procedure dbo.addDynamicForeignKey
	@databaseName nvarchar(128),
	@baseTable nvarchar(128), -- the child table
	@refTable nvarchar(128), -- the parent table
	@refTableColumnName nvarchar(128)
as
begin
	set nocount on;

	declare @fkName nvarchar(255) = N'FK_' + @baseTable + N'_' + @refTable;
	declare @targetSP nvarchar(268) = quotename(@databaseName) + N'.sys.sp_executesql';

	-- Dynamic SQL for create a foreign key if it doesn't exist
	declare @sql nvarchar(max) = N'
		if not exists (select 1 from sys.foreign_keys where name = ' + quotename(@fkName, '''') + N')
			begin
				alter table ' + quotename(@baseTable) 
				+ N' add constraint ' + quotename(@fkName)
				+ N' foreign key ( ' + quotename(@refTableColumnName) + N')
				references ' + quotename(@refTable) + N'(' + quotename(@refTableColumnName) + N');
				
				print ''Foreign key ' + @fkName + ' created successfully'';
			end
		else
			begin
				print ''Foreign key ' + @fkName + ' already existed.'';
			end
	';
	
	begin try
		exec @targetSP @sql
	end try
	begin catch
		print 'Error unable to add foreign key ' + @fkName + '.';
		print error_message();
	end catch
end
go

-- Dynamically find child table reference info
create or alter procedure dbo.findDynamicRefTableInfo
	@databaseName nvarchar(268),
	@tableName nvarchar(268),
	@refTableName nvarchar(268) output,
	@fKey nvarchar(268) output
as 
begin
	set nocount on;

	declare @refTableFKeyInfo table(
		tableName nvarchar(268),
		fKey nvarchar(268)
	);

	declare @targetSP nvarchar(268) = quotename(@databaseName) + N'.sys.sp_executesql';

	-- Dynamic SQL to find the child table that referenced the table specify by @tableName
	declare @sql nvarchar(max) = N'
		select object_name(parent_object_id) as refTable, name as fKeyName from sys.foreign_keys
		where referenced_object_id = object_id('''+ quotename(@tableName) + N''')';

	begin try
		insert into @refTableFKeyInfo
		exec @targetSP @sql

		select @refTableName = tableName, @fKey = fKey from @refTableFKeyInfo

	end try
	begin catch
		;throw;
	end catch
end
go

-- Dynamically truncate a table with/without constraints
create or alter procedure dynamicTruncateTable
	@databaseName nvarchar(268),
	@tableName nvarchar(268),
	@baseColumnName nvarchar(268),
	@refColumnName nvarchar(268)
as
begin
	set nocount on;

	declare @refTable nvarchar(268);
	declare @fKey nvarchar(268);

	exec findDynamicRefTableInfo
		@databaseName = @databaseName,
		@tableName = @tableName,
		@refTableName = @refTable output,
		@fKey = @fKey output

	declare @targetSP nvarchar(max) = quotename(@databaseName) + '.sys.sp_executesql';
	declare @sql nvarchar(max) = N'
		alter table ' + quoteName(@refTable) + N' drop constraint ' + @fKey + N';';

	exec @targetSP @sql

	set @sql = N'truncate table ' + @tableName + N';';

	exec @targetSP @sql;

	set @sql = N'alter table ' + quotename(@refTable) + N' with check add constraint ' + quotename(@fKey)
				+ N' foreign key (' + quoteName(@baseColumnName) + N') references ' + quotename(@tableName) + N'(' + quotename(@refColumnName) + N');';

	exec @targetSP @sql;
end
go

-- Determine if the list of devices are known devices by the database
create or alter procedure isKnownDevice
	@unknownMACAddressTable MACAddressTable readonly
as
begin
	select unknownMACAddresses.macAddress from @unknownMACAddressTable as unknownMACAddresses
	where not exists (
		select 1 from known_MAC_Addresses as knownMACAddresses
		where knownMACAddresses.macAddress = unknownMACAddresses.macAddress
	)
end
go







