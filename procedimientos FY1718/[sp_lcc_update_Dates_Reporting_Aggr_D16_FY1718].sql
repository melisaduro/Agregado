USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_update_Dates_Reporting_Aggr_D16]    Script Date: 25/05/2017 10:27:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_lcc_update_Dates_Reporting_Aggr_D16] (				
		@ciudad as varchar(256),
		@Tech as varchar (256),  ---Filtrará por medidas (collectionNmae) de 3G/4G/CA
		@typeInfo as varchar(256),
		@Methodology as varchar (50),
		@aggrType as varchar(256),
		@Report as varchar (256)
)
AS

--------------------------------------------------------------------------------------------------
----------------------------------------Testing Variables-----------------------------------------
--------------------------------------------------------------------------------------------------
--use FY1516_VOLTE_2
--declare @ciudad as varchar(256) = 'CORUNA_2'
--declare @typeInfo as varchar(256) = 'Voice'
--declare @Tech as varchar (256) = ''
--declare @aggrType as varchar(256)='Collectionname'
--declare @Methodology as varchar (50) = 'D15'
--declare @Report as varchar (256)='VDF'
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
declare @nombTablaBBDD as varchar(256)
declare @provider as varchar(256) = 'SQLNCLI11'
declare @server as varchar(256) = '10.1.12.32'
declare @Uid as varchar(256) = 'sa'
declare @Pwd as varchar(256) = 'Sw1ssqual.2015'
declare @cmd nvarchar(4000)
declare @bbddDestData varchar(255)
declare @bbddDestVoice varchar(255)
declare @bbddDestCover varchar(255)
declare @ParmDefinition nvarchar(500)	
declare @Tabla varchar(255)
declare @IsLTE varchar(10) --Ejecutar todos los procedimientos incluidos los de LTE o no

declare @sheetData as varchar(256) --Crear sólo la info total o la info total/4G/totalCA
declare @sheetVoice as varchar(256) --Crear sólo la info total o la info total/4G
declare @sheetNomb as varchar(256)
declare @TechProc as varchar (256) 
DECLARE @nameProcAux varchar(256)

declare @type_info as varchar(256)
declare @typeInfo_KPI as varchar(5)
declare @type_Measurement as varchar(3)

declare @idColDateRep bigint
declare @idColWeekRep bigint
declare @TipoCol varchar(255)
declare @TamCol bigint
declare @maxMeas_Date varchar(10)
declare @maxMeas_Week varchar(10)

DECLARE @nameProc varchar(256)
declare @it1 bigint
declare @MaxTab bigint
declare @aggrTypeAux as varchar(256)

declare @column_tablaBBDD  as table (
	[table_name] [sysname] NOT NULL,
	[column_name] [sysname] NULL,
	[column_id] [int] NOT NULL
)

SET @ParmDefinition = N'@TablaOut varchar(255) output' 

--CAC 08/05/2017:
--ANTES las roads "normales" (A1,...,A7) estaban en CoverageUnion y debiamos distinguir por el nombre de @ciudad
--if CHARINDEX('A1',@ciudad) > 0 or CHARINDEX('A2',@ciudad) > 0 or CHARINDEX('A3',@ciudad) > 0 or CHARINDEX('A4',@ciudad) > 0
--	or CHARINDEX('A5',@ciudad) > 0 or CHARINDEX('A6',@ciudad) > 0 or CHARINDEX('A7',@ciudad) > 0
--AHORA: roads normales estan en CoverageUnion_ROAD (para que la lógica distinga por ronda)
-- y las roads extra estan en CoverageUnion pero se procesan con @Report='ROAD'
if  CHARINDEX('ROAD',db_name())> 0 or @Report='ROAD'
begin
	set @bbddDestCover = '[AGGRCoverage_ROAD]'
end
else
begin
	set @bbddDestCover = '[AGGRCoverage]'
end

if  CHARINDEX('3G',db_name())  > 0 
begin 
	set @bbddDestData = '[AGGRData3G]'
	set @bbddDestVoice = '[AGGRVoice3G]'
	--set @bbddDestCover = '[AGGRCoverage]'
	set @IsLTE = 'ALL' --Se ejecutaran los procedimientos de datos ALL
	set @sheetData = '(''ALL'',''WCDMA'')' --Se creará sólo la info total (de inicio valdra ALL para filtrar en los proc de step 1 pero luego pasara a valer %%)
	set @sheetVoice = '(''ALL'',''WCDMA'')'  --Se creará sólo la info total (de inicio valdra ALL para filtrar en los proc de step 1 pero luego pasara a valer %%)
	set @type_info = '(''Voice'')'
end
else --Indoor es 4G
begin 
	if  CHARINDEX('ROAD',db_name())  > 0 and CHARINDEX('VOLTE',db_name()) = 0
		begin
			set @bbddDestData = '[AGGRData4G_ROAD]'
			set @bbddDestVoice = '[AGGRVoice4G_ROAD]'
			--set @bbddDestCover = '[AGGRCoverage_ROAD]'
			set @sheetData = '(''ALL'',''LTE'',''CA'',''WCDMA'')' --Se creará la info total/4G/totalCA
			set @sheetVoice = '(''ALL'',''LTE'',''WCDMA'')' --Se creará la info total/only 4G	
			set @type_info = '(''Voice'')'
		end
	else
		if  CHARINDEX('VOLTE',db_name())  > 0
			begin
				set @bbddDestVoice = '[AGGRVOLTE]'
				set @sheetVoice = '(''ALL'',''LTE'',''WCDMA'',''VOLTE'')' --Se creará la info total/only 4G	
				set @type_info = '(''Voice'', ''VOLTE'')'
			end
		else
			begin
				set @bbddDestData = '[AGGRData4G]'
				set @bbddDestVoice = '[AGGRVoice4G]'
				--set @bbddDestCover = '[AGGRCoverage]'
				set @sheetData = '(''ALL'',''LTE'',''CA'',''WCDMA'')' --Se creará la info total/4G/totalCA
				set @sheetVoice = '(''ALL'',''LTE'',''WCDMA'',''VOLTE'')' --Se creará la info total/only 4G
				set @type_info = '(''Voice'', ''VOLTE'')'
			end
	set @IsLTE = '%%' --Se ejecutaran todos los procedimientos de datos, ALL y LTE
	
end

set @TechProc = @Tech
if @Tech <> 'CA' 
begin 
	set @TechProc = 'ALL'
end

if @aggrType = 'GRID'
begin
	set @aggrTypeAux = '_GRID'
end
else
begin
	set @aggrTypeAux = ''
end

--------------------------------------------------------------------------------------------------
----------------------------------------------DATA------------------------------------------------
--------------------------------------------------------------------------------------------------
if @typeInfo = 'Data'
begin
	--Recorremos los procedimientos de paso 1 existentes y actualizamos la info de Date_Reporting/Week_Reporting.
	--En el caso que no existan las columnas las creamos.
		
	DECLARE @nameTablaData varchar(256)

	
	set @it1 = 1

	declare @tmp_procedures_step1_Data  as table (
		[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		[Name_proc] [varchar](128) not NULL,
		[Type_Info_KPI] [varchar](5) NULL,
		[Type_Measurement] [varchar](3) not NULL,
		[Methodology] [varchar] (50) NULL
	)

	set @cmd = 'select Name_proc,Type_Info_KPI,Type_Measurement
	from [AGRIDS].[dbo].[lcc_procedures_step1'+@aggrTypeAux+'] --Tabla en la que se registran los procedimientos de paso 1
	where type_Info=''Data''
		and Is_LTE like '''+@IsLTE+'''
		and Type_Info_KPI in '+@sheetData+'
		and Type_Measurement like '''+@TechProc+'''
		and (Methodology = ''ALL'' or Methodology ='''+@Methodology+''')'
	print(@cmd)
	insert into @tmp_procedures_step1_Data (Name_proc,Type_Info_KPI,Type_Measurement)
	exec (@cmd)

	--select * from @tmp_procedures_step1

	if CHARINDEX('3G',db_name())  > 0 --En 3G 
		set @sheetData = '%%'

	select @MaxTab = MAX(id) 
	from @tmp_procedures_step1_Data

	while @it1 <= @MaxTab 
	begin
		set @maxMeas_Date = ''
		set @maxMeas_Week = ''
		set @idColDateRep = 0
		set @idColWeekRep = 0

		--Nombre procedimiento
		select @nameProc = Name_proc
		from @tmp_procedures_step1_Data
		where id =@it1
		print 'Nombre del procedimiento:  ' + @nameProc
		--Tipo info KPI
		select @typeInfo_KPI = Type_Info_KPI
		from @tmp_procedures_step1_Data
		where id =@it1
		print 'Tipo info KPI:  ' + @typeInfo_KPI
		--Tipo medida
		select @type_Measurement = Type_Measurement
		from @tmp_procedures_step1_Data
		where id =@it1
		print 'Tipo medida:  ' + @type_Measurement

		set @sheetNomb = @typeInfo_KPI --Posibles valores actuales ALL, LTE, WCDMA, CA
		if @typeInfo_KPI = 'LTE'
		begin
			set @sheetNomb = '4G'
		end
		if @typeInfo_KPI = 'WCDMA'
		begin
			set @sheetNomb = '3G'
		end
		if @typeInfo_KPI = 'CA'
		begin
			set @sheetNomb = 'CA_ONLY'
		end

		--Para procs por GRID
		if @aggrType = 'GRID' and CHARINDEX('_GRID',@nameProc)>0
		begin
			set @nameProcAux = SUBSTRING(@nameProc,0,CHARINDEX('_GRID',@nameProc))
		end
		else
		begin
			set @nameProcAux = @nameProc
		end
		print @nameProcAux
		---Para procs de 1617
		if CHARINDEX('FY1617',@nameProc) > 0
		begin		
			set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1617',@nameProcAux))
		end
		print @nameProcAux
		---Para procs de 1718
		if CHARINDEX('FY1718',@nameProc) > 0
		begin		
			set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1718',@nameProcAux))
		end
		print @nameProcAux
		

		--Nombre de la tabla dependera del tipo de la medida
		set @nameTablaData = @nameProcAux
		if @type_Measurement <> 'ALL' --Si es CA, el nombre de la tabla llevará esta información
		begin
			set @nameTablaData = @nameTablaData + '_' + @Tech
		end

		if @typeInfo_KPI  <> 'ALL' --Si no es la info total, el nombre de la tabla llevará esta información
		begin
			set @nameTablaData = @nameTablaData + '_' + @sheetNomb
		end
		
		if @typeInfo_KPI = 'ALL' --Si es la info total, el filtro es '%%'
		begin 
			set @typeInfo_KPI ='%%'
		end

		set @nombTablaBBDD = 'lcc_aggr_'+ @nameTablaData 

		--Comprobamos si las tabla agregada tiene creada las columnas Date_Reporting/Week_Reporting
		set @cmd = 'select t.name table_name, c.name column_name, c.column_id 
		from ' + @bbddDestData+ '.sys.tables t, ' + @bbddDestData+ '.sys.columns c
		where t.object_id=c.object_id 
			and t.name = '''+ @nombTablaBBDD +'''
			and t.type=''U'''
		print @cmd	
		insert into @column_tablaBBDD
		exec (@cmd)

	
		--Id de la columna Date_Reporting destino si existe
		select @idColDateRep = column_id
		from @column_tablaBBDD
		where table_name = @nombTablaBBDD
			and column_name ='Date_Reporting'
		
		print convert(varchar,	@idColDateRep)		
		if @idColDateRep = 0 --Columna no existente en la tabla agrupada, la creamos
		begin
			--Añadimos la nueva columna		
			set @cmd ='ALTER TABLE ' + @bbddDestData +'.dbo.'+ @nombTablaBBDD  + CHAR(13)+ ' ADD [Date_Reporting]  varchar(255)'
			print @cmd
			exec (@cmd)
		end

		--Id de la columna Week_Reporting destino si existe
		select @idColWeekRep = column_id
		from @column_tablaBBDD
		where table_name = @nombTablaBBDD
			and column_name ='Week_Reporting'
					
		if @idColWeekRep = 0 --Columna no existente en la tabla agrupada, la creamos
		begin
			--Añadimos la nueva columna		
			set @cmd ='ALTER TABLE ' + @bbddDestData +'.dbo.'+ @nombTablaBBDD  + CHAR(13)+ ' ADD [Week_Reporting]  varchar(3)'	
			print @cmd
			exec (@cmd)
		end


	
		SET @ParmDefinition = N'@TipoColOrigOut varchar(255) output' 
						
		set @cmd = 'select @maxMeas_DateOut = max([Meas_Date]),
			@maxMeas_WeekOut=max([Meas_Week])
		FROM ' + @bbddDestData +'.dbo.'+ @nombTablaBBDD  +'
		where [Database] ='''+ db_name()+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
		print @cmd
		exec sp_executesql @cmd, N'@maxMeas_DateOut varchar(10) output,@maxMeas_WeekOut varchar(10) output',@maxMeas_DateOut = @maxMeas_Date output,@maxMeas_WeekOut = @maxMeas_Week output



		--'select @maxMeas_DateOut = max([Meas_Date]),
		--	@maxMeas_WeekOut=max([Meas_Week])
		--FROM ' + @bbddDest +'.dbo.'+ @nombTablaBBDD  +'
		--where [Database] ='+ db_name()+'
		--and [Entidad] = '+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))

		if @maxMeas_Date <> '' or @maxMeas_Week <> ''
		begin
			set @cmd = 'update ' + @bbddDestData +'.dbo.'+ @nombTablaBBDD  +'
			set Date_reporting = '''+@maxMeas_Date+'''
			where [Database] ='''+ db_name()+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			print @cmd
			exec (@cmd)

			set @cmd ='update ' + @bbddDestData +'.dbo.'+ @nombTablaBBDD  +'
			set Week_reporting = '''+@maxMeas_Week+'''
			where [Database] ='''+ db_name()+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			print @cmd
			exec (@cmd)
		end
	
		set @it1 = @it1 +1
	END
end
--------------------------------------------------------------------------------------------------
----------------------------------------------VOICE-----------------------------------------------
--------------------------------------------------------------------------------------------------
else if @typeInfo = 'Voice'
begin
	--Recorremos los procedimientos de paso 1 existentes y actualizamos la info de Date_Reporting/Week_Reporting.
	--En el caso que no existan las columnas las creamos.

	DECLARE @nameTablaVoice varchar(256)

	set @it1 = 1

	declare @tmp_procedures_step1_Voice  as table (
		[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		[Name_proc] [varchar](128) not NULL,
		[Type_Info_KPI] [varchar](5) NULL
	)
	
	set @cmd = 'select Name_proc,Type_Info_KPI
	from [AGRIDS].[dbo].[lcc_procedures_step1'+@aggrTypeAux+'] --Tabla en la que se registran los procedimientos de paso 1
	where type_Info in '+@type_info+'
		and Type_Info_KPI in '+@sheetVoice+'
		and (Methodology = ''ALL'' or Methodology ='''+@Methodology+''')'
	print(@cmd)
	insert into @tmp_procedures_step1_Voice (Name_proc,Type_Info_KPI)
	exec (@cmd)

	--select * from @tmp_procedures_step1

	if CHARINDEX('3G',db_name())  > 0 --En 3G 
		set @sheetVoice = '%%'

	select @MaxTab = MAX(id) 
	from @tmp_procedures_step1_Voice

	while @it1 <= @MaxTab
	begin
		set @maxMeas_Date = ''
		set @maxMeas_Week = ''
		set @idColDateRep = 0
		set @idColWeekRep = 0

		--Nombre procedimiento
		select @nameProc = Name_proc
		from @tmp_procedures_step1_Voice
		where id =@it1
		print 'Nombre del procedimiento:  ' + @nameProc
		--Tipo info KPI
		select @typeInfo_KPI = Type_Info_KPI
		from @tmp_procedures_step1_Voice
		where id =@it1
		print 'Tipo info KPI:  ' + @typeInfo_KPI

		set @sheetNomb = @typeInfo_KPI --Psoibles valores actuales ALL, LTE
		if @typeInfo_KPI = 'LTE'
		begin
			set @sheetNomb = '4G'
		end
		if @typeInfo_KPI = 'WCDMA'
		begin
			set @sheetNomb = '3G'
		end
		if @typeInfo_KPI = 'VOLTE'
		begin
			set @sheetNomb = 'VOLTE'
		end


		--Para procs por GRID
		if @aggrType = 'GRID' and CHARINDEX('_GRID',@nameProc)>0
		begin
			set @nameProcAux = SUBSTRING(@nameProc,0,CHARINDEX('_GRID',@nameProc))
		end
		else
		begin
			set @nameProcAux = @nameProc
		end
		print @nameProcAux
		---Para procs de 1617
		if CHARINDEX('FY1617',@nameProc) > 0
		begin		
			set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1617',@nameProcAux))
		end
		print @nameProcAux	
		---Para procs de 1718
		if CHARINDEX('FY1718',@nameProc) > 0
		begin		
			set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1718',@nameProcAux))
		end
		print @nameProcAux	
		

		--Nombre de la tabla dependera del tipo de la medida
		set @nameTablaVoice = @nameProcAux
		if @typeInfo_KPI  <> 'ALL' --Si no es la info total, el nombre de la tabla llevará esta información
		begin
			set @nameTablaVoice = @nameTablaVoice + '_' + @sheetNomb
		end
		if @typeInfo_KPI = 'ALL' --Si es la info total, el filtro es '%%'
		begin 
			set @typeInfo_KPI ='%%'
		end


		set @nombTablaBBDD = 'lcc_aggr_'+ @nameTablaVoice

		--Comprobamos si las tabla agregada tiene creada la columna Date_Reporting/Week_Reporting
		set @cmd = 'select t.name table_name, c.name column_name, c.column_id 
		from ' + @bbddDestVoice+ '.sys.tables t, ' + @bbddDestVoice+ '.sys.columns c
		where t.object_id=c.object_id 
			and t.name = '''+ @nombTablaBBDD +'''
			and t.type=''U'''
		print @cmd	
		insert into @column_tablaBBDD
		exec (@cmd)

	
		--Id de la columna Date_Reporting destino si existe
		select @idColDateRep = column_id
		from @column_tablaBBDD
		where table_name = @nombTablaBBDD
			and column_name ='Date_Reporting'
		
		print convert(varchar,	@idColDateRep)		
		if @idColDateRep = 0 --Columna no existente en la tabla agrupada, la creamos
		begin
			--Añadimos la nueva columna		
			set @cmd ='ALTER TABLE ' + @bbddDestVoice +'.dbo.'+ @nombTablaBBDD  + CHAR(13)+ ' ADD [Date_Reporting]  varchar(255)'
			print @cmd
			exec (@cmd)
		end

		--Id de la columna Week_Reporting destino si existe
		select @idColWeekRep = column_id
		from @column_tablaBBDD
		where table_name = @nombTablaBBDD
			and column_name ='Week_Reporting'
					
		if @idColWeekRep = 0 --Columna no existente en la tabla agrupada, la creamos
		begin
			--Añadimos la nueva columna		
			set @cmd ='ALTER TABLE ' + @bbddDestVoice +'.dbo.'+ @nombTablaBBDD  + CHAR(13)+ ' ADD [Week_Reporting]  varchar(3)'	
			print @cmd
			exec (@cmd)
		end


	
		SET @ParmDefinition = N'@TipoColOrigOut varchar(255) output' 
						
		set @cmd = 'select @maxMeas_DateOut = max([Meas_Date]),
			@maxMeas_WeekOut=max([Meas_Week])
		FROM ' + @bbddDestVoice +'.dbo.'+ @nombTablaBBDD  +'
		where [Database] ='''+ db_name()+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
		print @cmd
		exec sp_executesql @cmd, N'@maxMeas_DateOut varchar(10) output,@maxMeas_WeekOut varchar(10) output',@maxMeas_DateOut = @maxMeas_Date output,@maxMeas_WeekOut = @maxMeas_Week output

		
		if @maxMeas_Date <> '' or @maxMeas_Week <> ''
		begin
			set @cmd = 'update ' + @bbddDestVoice +'.dbo.'+ @nombTablaBBDD  +'
			set Date_reporting = '''+@maxMeas_Date+'''
			where [Database] ='''+ db_name()+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			print @cmd
			exec (@cmd)

			set @cmd ='update ' + @bbddDestVoice +'.dbo.'+ @nombTablaBBDD  +'
			set Week_reporting = '''+@maxMeas_Week+'''
			where [Database] ='''+ db_name()+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			print @cmd
			exec (@cmd)
		end
	
		set @it1 = @it1 +1
	END
end
--------------------------------------------------------------------------------------------------
---------------------------------------------COVERAGE---------------------------------------------
--------------------------------------------------------------------------------------------------
else if @typeInfo = 'Coverage'
begin
	--Recorremos los procedimientos de paso 1 existentes y actualizamos la info de Date_Reporting/Week_Reporting.
	--En el caso que no existan las columnas las creamos.
	
	set @it1 = 1

	declare @tmp_procedures_step1_Coverage  as table (
		[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		[Name_proc] [varchar](128) not NULL
	)
	
	set @cmd = 'select Name_proc
	from [AGRIDS].[dbo].[lcc_procedures_step1'+@aggrTypeAux+'] --Tabla en la que se registran los procedimientos de paso 1
	where type_Info=''Coverage''
	and (Methodology = ''ALL'' or Methodology ='''+@Methodology+''')'
	print(@cmd)
	insert into @tmp_procedures_step1_Coverage (Name_proc)
	exec (@cmd)

	--select * from @tmp_procedures_step1

	select @MaxTab = MAX(id) 
	from @tmp_procedures_step1_Coverage

	while @it1 <= @MaxTab 
	begin
		set @maxMeas_Date = ''
		set @maxMeas_Week = ''
		set @idColDateRep = 0
		set @idColWeekRep = 0

		--Nombre procedimiento
		select @nameProc = Name_proc
		from @tmp_procedures_step1_Coverage
		where id =@it1
		print 'Nombre del procedimiento:  ' + @nameProc	

		--CAC 08/05/2017: excepcion, agregado de sp_MDD_Coverage_All_Outdoor SI y SÓLO para AVEs
		if ((@nameProc = 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())> 0)
			or (@nameProc <> 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())= 0))
		begin
			--Para procs por GRID
			if @aggrType = 'GRID' and CHARINDEX('_GRID',@nameProc)>0
			begin
				set @nameProcAux = SUBSTRING(@nameProc,0,CHARINDEX('_GRID',@nameProc))
			end
			else
			begin
				set @nameProcAux = @nameProc
			end
			print @nameProcAux
			---Para procs de 1617
			if CHARINDEX('FY1617',@nameProc) > 0
			begin		
				set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1617',@nameProcAux))
			end
			print @nameProcAux
			---Para procs de 1718
			if CHARINDEX('FY1718',@nameProc) > 0
			begin		
				set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1718',@nameProcAux))
			end
			print @nameProcAux
	
		

			set @nombTablaBBDD = 'lcc_aggr_'+ @nameProcAux 

			--Comprobamos si las tabla agregada tiene creada la columna Date_Reporting/Week_Reporting
			set @cmd = 'select t.name table_name, c.name column_name, c.column_id 
			from ' + @bbddDestCover+ '.sys.tables t, ' + @bbddDestCover+ '.sys.columns c
			where t.object_id=c.object_id 
				and t.name = '''+ @nombTablaBBDD +'''
				and t.type=''U'''
			print @cmd	
			insert into @column_tablaBBDD
			exec (@cmd)

	
			--Id de la columna Date_Reporting destino si existe
			select @idColDateRep = column_id
			from @column_tablaBBDD
			where table_name = @nombTablaBBDD
				and column_name ='Date_Reporting'
		
			print convert(varchar,	@idColDateRep)		
			if @idColDateRep = 0 --Columna no existente en la tabla agrupada, la creamos
			begin
				--Añadimos la nueva columna		
				set @cmd ='ALTER TABLE ' + @bbddDestCover +'.dbo.'+ @nombTablaBBDD  + CHAR(13)+ ' ADD [Date_Reporting]  varchar(255)'
				print @cmd
				exec (@cmd)
			end

			--Id de la columna Week_Reporting destino si existe
			select @idColWeekRep = column_id
			from @column_tablaBBDD
			where table_name = @nombTablaBBDD
				and column_name ='Week_Reporting'
					
			if @idColWeekRep = 0 --Columna no existente en la tabla agrupada, la creamos
			begin
				--Añadimos la nueva columna		
				set @cmd ='ALTER TABLE ' + @bbddDestCover +'.dbo.'+ @nombTablaBBDD  + CHAR(13)+ ' ADD [Week_Reporting]  varchar(3)'	
				print @cmd
				exec (@cmd)
			end


	
			SET @ParmDefinition = N'@TipoColOrigOut varchar(255) output' 
						
			set @cmd = 'select @maxMeas_DateOut = max([Meas_Date]),
				@maxMeas_WeekOut=max([Meas_Week])
			FROM ' + @bbddDestCover +'.dbo.'+ @nombTablaBBDD  +'
			where [Database] ='''+ db_name()+'''
				and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+'''
				and report_Type='''+@Report+''''
			print @cmd
			exec sp_executesql @cmd, N'@maxMeas_DateOut varchar(10) output,@maxMeas_WeekOut varchar(10) output',@maxMeas_DateOut = @maxMeas_Date output,@maxMeas_WeekOut = @maxMeas_Week output

		
			if @maxMeas_Date <> '' or @maxMeas_Week <> ''
			begin
				set @cmd = 'update ' + @bbddDestCover +'.dbo.'+ @nombTablaBBDD  +'
				set Date_reporting = '''+@maxMeas_Date+'''
				where [Database] ='''+ db_name()+'''
					and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+'''
					and report_Type='''+@Report+''''
				print @cmd
				exec (@cmd)

				set @cmd ='update ' + @bbddDestCover +'.dbo.'+ @nombTablaBBDD  +'
				set Week_reporting = '''+@maxMeas_Week+'''
				where [Database] ='''+ db_name()+'''
					and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+'''
					and report_Type='''+@Report+''''
				print @cmd
				exec (@cmd)
			end
		end
		set @it1 = @it1 +1
	END
end

select ''
