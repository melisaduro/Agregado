USE [master]
GO
/****** Object:  StoredProcedure [dbo].[FY1718_sp_lcc_create_tables_Data_Aggr_D16]    Script Date: 26/06/2017 18:28:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FY1718_sp_lcc_create_tables_Data_Aggr_D16] (
		@ciudad as varchar(256),
		@simOperator as int,
		@Date as varchar (256),
		@Tech as varchar (256),  ---Filtrará por medidas (collectionNmae) de 3G/4G/CA
		@Indoor as bit,
		@pattern as varchar (256),
		@overwrite as varchar(1), --Y/N se sobreescriben las parcelas o no
		@camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-Report_Type-Entidad', -- Default value
		@Info as varchar (256),
		@Methodology as varchar (50),
		@Report as varchar (256),
		@aggrType as varchar(256)
)
AS

--------------------------------------------------------------------------------------------------
----------------------------------------Testing Variables-----------------------------------------
--------------------------------------------------------------------------------------------------
--declare @ciudad as varchar(256) = 'malaga'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @pattern as varchar (256) = 'ogrove'
--declare @overwrite as varchar(1) = 'n'
--declare @camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round'--'MNC-Parcel-Meas_Round' --MNC-Entidad-Num_Medida-Meas_Date
--declare @Methodology as varchar (50) = 'D15'

--declare @Info as varchar (256) = '%%' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @Tech as varchar (256) = 'CA'
--declare @Report as varchar (256)='VDF'
--declare @aggrType as varchar(256)='GRID'
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
declare @nombTablaOrig as varchar(256)
declare @provider as varchar(256) = 'SQLNCLI11'
declare @server as varchar(256) = '10.1.12.32'
declare @Uid as varchar(256) = 'sa'
declare @Pwd as varchar(256) = 'Sw1ssqual.2015'
declare @cmd nvarchar(4000)
declare @bbddDest varchar(255)
declare @ParmDefinition nvarchar(500)	
declare @Tabla varchar(255)
declare @IsLTE varchar(10) --Ejecutar todos los procedimientos incluidos los de LTE o no

declare @sheets as varchar(256) --Crear sólo la info total o la info total/4G/totalCA
declare @sheetNomb as varchar(256)
declare @TechProc as varchar (256) 

declare @typeInfo_KPI as varchar(5)
declare @type_Measurement as varchar(3)

BEGIN TRY
BEGIN TRANSACTION
	SET @ParmDefinition = N'@TablaOut varchar(255) output' 

	if  CHARINDEX('3G',db_name())  > 0 
	begin 
		set @bbddDest = '[AGGRData3G]'
		set @IsLTE = 'ALL' --Se ejecutaran los procedimientos de datos ALL
		set @sheets = '(''ALL'',''WCDMA'')' --Se creará sólo la info total (de inicio valdra ALL para filtrar en los proc de step 1 pero luego pasara a valer %%)
	end
	else --Indoor es 4G
	begin 
		if  CHARINDEX('ROAD',db_name())  > 0 
			set @bbddDest = '[AGGRData4G_ROAD]'
		else
			set @bbddDest = '[AGGRData4G]'
		set @IsLTE = '%%' --Se ejecutaran todos los procedimientos de datos, ALL y LTE
		set @sheets = '(''ALL'',''LTE'',''CA'',''WCDMA'')' --Se creará la info total/4G/totalCA
	end

	set @TechProc = @Tech
	if @Tech <> 'CA' 
	begin 
		set @TechProc = 'ALL'
	end

	set @pattern = replace(@pattern,'-','_')
	--------------------------------------------------------------------------------------------------
	---------------------------------Borramos las tablas agrupadas origen-----------------------------
	--------------------------------------------------------------------------------------------------
	print 'Inicio borrado tablas agrupadas origen'
	DECLARE @nameTabla varchar(256)

	declare @it2 bigint
	declare @MaxTab2 bigint

	set @it2 = 1

	declare @tmp_Tablas  as table (
		[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		[Name] [nvarchar](256) not NULL
	)

	set @cmd = 'select name
	from sys.tables
	where name like ''lcc_aggr_%'+ @pattern+
		''' and type=''U'''
	print @cmd
	insert into @tmp_Tablas (Name)
	exec (@cmd)

	select @MaxTab2 = MAX(id) 
	from @tmp_Tablas

	while @it2 <= @MaxTab2 --Borramos cada tabla por si existe en ddbb destino
	begin
		--Nombre tabla
		select @nameTabla = name
		from @tmp_Tablas
		where id =@it2
		print 'Nombre de la tabla:  ' + @nameTabla

		set @cmd = 'drop table '+ @nameTabla

		print @cmd
		exec (@cmd)

		set @it2 = @it2 +1
	END 

	--------------------------------------------------------------------------------------------------
	--------------------------------Generar tablas origen agrupadas-----------------------------------
	--------------------------------------------------------------------------------------------------
	--Recorremos los procedimientos de paso 1 existentes y creamos las tablas de agregado origen correspondientes.
	--En el caso que no exista la tabla destino en la bbdd de agregado correspondiente, se crea.

	DECLARE @nameProc varchar(256)
	DECLARE @nameProcAux varchar(256)
	DECLARE @nameTablaData varchar(256)
	declare @aggrTypeAux as varchar(256)

	declare @it1 bigint
	declare @MaxTab bigint

	set @it1 = 1

	declare @tmp_procedures_step1  as table (
		[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		[Name_proc] [varchar](128) not NULL,
		[Type_Info_KPI] [varchar](5) NULL,
		[Type_Measurement] [varchar](3) not NULL,
		[Methodology] [varchar](50) null
	)

	if @aggrType = 'GRID'
	begin
		set @aggrTypeAux = '_GRID'
	end
	else
	begin
		set @aggrTypeAux = ''
	end

	set @cmd = 'select Name_proc,Type_Info_KPI,Type_Measurement
	from [AGRIDS].[dbo].[lcc_procedures_step1'+@aggrTypeAux+'] --Tabla en la que se registran los procedimientos de paso 1
	where type_Info=''Data''
		and Is_LTE like '''+@IsLTE+'''
		and Type_Info_KPI in '+@sheets+'
		and Type_Measurement like '''+@TechProc+'''
		and (Methodology = ''ALL'' or Methodology ='''+@Methodology+''')'

	print(@cmd)
	insert into @tmp_procedures_step1 (Name_proc,Type_Info_KPI,Type_Measurement)
	exec (@cmd)


	select @MaxTab = MAX(id) 
	from @tmp_procedures_step1

	while @it1 <= @MaxTab --Borramos cada tabla por si existe en ddbb destino
	begin
		--Nombre procedimiento
		select @nameProc = Name_proc
		from @tmp_procedures_step1
		where id =@it1
		print 'Nombre del procedimiento:  ' + @nameProc
		--Tipo info KPI
		select @typeInfo_KPI = Type_Info_KPI
		from @tmp_procedures_step1
		where id =@it1
		print 'Tipo info KPI:  ' + @typeInfo_KPI
		--Tipo medida
		select @type_Measurement = Type_Measurement
		from @tmp_procedures_step1
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
		---20170626: - @MDM
		---Para procs de 1718
		if CHARINDEX('FY1718',@nameProc) > 0
		begin	
			--Para el procedimiento de Youtube que separa por los cuatro videos de la nueva metología:
			if CHARINDEX('Youtube_HD',@nameProc) > 0	
			begin
				set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1718',@nameProcAux)) + '_Video'
			end
			else
			begin 
				set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1718',@nameProcAux))
			end
		end
		print @nameProcAux
	

		-------------------
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

		set @nombTablaOrig = 'lcc_aggr_'+ @nameTablaData +'_'+ @pattern
		exec sp_lcc_dropifexists @nombTablaOrig
		--Generar tablas origen agrupadas
		set @cmd = '
		select *
		into lcc_aggr_'+ @nameTablaData +'_'+ @pattern +'
		from  openrowset ('''+ @provider +'''
		,'''+ @server +''';'''+ @Uid +''';'''+ @Pwd +'''
		,''SET NOCOUNT ON;EXEC '+ db_name() +'.dbo.'+ @nameProc +' '''''+@ciudad+''''', '+convert(varchar,@simOperator)+','''''+@typeInfo_KPI+''''', 
		'''''+@date+''''','''''+@Tech+''''','+convert(varchar, @Indoor)+','''''+@Info+''''','''''+@Methodology+''''','''''+@Report+''''''')'

		print @cmd
		execute (@cmd)

		set @Tabla = null
		--Creamos tablas agrupadas en bbdd destino, si no existen
		set @cmd = 'select @TablaOut = name
			from '+ @bbddDest +'.sys.all_objects 
			where  name=''lcc_aggr_'+ @nameTablaData +'''
				and type=''U'''
		print @cmd
		exec sp_executesql @cmd,@ParmDefinition,@TablaOut = @Tabla output	

		print @Tabla
		if @Tabla is null --Si no existe la tabla
		begin
			set @cmd = '
					select top 1 *, '''+@camposLlave+'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'' as ''Key_Fields''
					into '+ @bbddDest +'.dbo.lcc_aggr_'+ @nameTablaData +'
					from lcc_aggr_'+ @nameTablaData +'_'+ @pattern
			print @cmd
			exec (@cmd)


			set @cmd = 'delete '+ @bbddDest +'.dbo.lcc_aggr_'+ @nameTablaData
			print @cmd
			exec (@cmd)
		end

		set @it1 = @it1 +1
	END

	--drop table [dbo].[lcc_aggr_sp_MDD_Data_Llamadas_ogrove]
	--drop table [AGGRData4G].[dbo].[lcc_aggr_sp_MDD_Data_Llamadas]

	--------------------------------------------------------------------------------------------------
	-------------------------------Pasamos la info agrupada a la bbdd agrupada------------------------
	--------------------------------------------------------------------------------------------------
	set @cmd = '[FY1718_sp_lcc_aggregate_parcel] ' +db_name()+', '+@bbddDest+', '+@pattern+', '+@overwrite+', '''+@camposLlave+''''
	print @cmd
	exec (@cmd)

	--------------------------------------------------------------------------------------------------
	---------------------------------Borramos las tablas agrupadas origen-----------------------------
	--------------------------------------------------------------------------------------------------
	print 'Inicio borrado tablas agrupadas origen'
	--DECLARE @nameTabla varchar(256)

	--declare @it2 bigint
	--declare @MaxTab2 bigint

	SET @nameTabla = ''

	delete @tmp_Tablas

	set @cmd = 'select name
	from sys.tables
	where name like ''lcc_aggr_%'+ @pattern+
		''' and type=''U'''
	print @cmd
	insert into @tmp_Tablas (Name)
	exec (@cmd)

	select @MaxTab2 = MAX(id) 
	from @tmp_Tablas

	while @it2 <= @MaxTab2 --Borramos cada tabla por si existe en ddbb destino
	begin
		--Nombre tabla
		select @nameTabla = name
		from @tmp_Tablas
		where id =@it2
		print convert(varchar,@it2)+') Nombre de la tabla:  ' + @nameTabla

		set @cmd = 'drop table '+ @nameTabla

		print @cmd
		exec (@cmd)

		set @it2 = @it2 +1
	END 

	COMMIT TRANSACTION
	SELECT 'Transacción finalizada correctamente'
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
	SELECT 'Transacción restaurada'
END CATCH
IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION	

