USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_tables_Voice_Aggr_D16_FY1718]    Script Date: 05/07/2017 16:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_lcc_create_tables_Voice_Aggr_D16_FY1718] (
		@mob1 as varchar(256),
		@mob2 as varchar(256),
		@mob3 as varchar(256),
		@ciudad as varchar(256),
		@simOperator as int,
		@fecha_ini_text1 as varchar(256),
		@fecha_fin_text1 as varchar (256),
		@fecha_ini_text2 as varchar(256),
		@fecha_fin_text2 as varchar (256),
		@fecha_ini_text3 as varchar(256),
		@fecha_fin_text3 as varchar (256),
		@fecha_ini_text4 as varchar(256),
		@fecha_fin_text4 as varchar (256),
		@fecha_ini_text5 as varchar(256),
		@fecha_fin_text5 as varchar (256),
		@fecha_ini_text6 as varchar(256),
		@fecha_fin_text6 as varchar (256),
		@fecha_ini_text7 as varchar(256),
		@fecha_fin_text7 as varchar (256),
		@fecha_ini_text8 as varchar(256),
		@fecha_fin_text8 as varchar (256),
		@fecha_ini_text9 as varchar(256),
		@fecha_fin_text9 as varchar (256),
		@fecha_ini_text10 as varchar(256),
		@fecha_fin_text10 as varchar (256),
		@Date as varchar (256),
		@Indoor as int,
		@pattern as varchar (256),
		@overwrite as varchar(1), --Y/N se sobreescriben las parcelas o no
		@camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-Report_Type-Entidad', -- Default value
		@Methodology as varchar (50),
		@Report as varchar (256),
		@aggrType as varchar(256)
)
AS

--------------------------------------------------------------------------------------------------
----------------------------------------Testing Variables-----------------------------------------
--------------------------------------------------------------------------------------------------
--declare @mob1 as varchar(256) = '354720054741835'
--declare @mob2 as varchar(256) = 'Ninguna'
--declare @mob3 as varchar(256) = 'Ninguna'

--declare @fecha_ini_text1 as varchar (256) = '2015-05-27 09:10:00.000'
--declare @fecha_fin_text1 as varchar (256) = '2015-05-27 14:30:00.000'
--declare @fecha_ini_text2 as varchar (256) = '2015-05-27 15:15:00.000'
--declare @fecha_fin_text2 as varchar (256) = '2015-05-27 22:00:00.000'
--declare @fecha_ini_text3 as varchar (256) = '2015-05-28 08:20:00.000'
--declare @fecha_fin_text3 as varchar (256) = '2015-05-28 15:40:00.000'
--declare @fecha_ini_text4 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_fin_text4 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_ini_text5 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_fin_text5 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_ini_text6 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_fin_text6 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_ini_text7 as varchar (256) = '2014-08-07 10:40:00:000'
--declare @fecha_fin_text7 as varchar (256) = '2014-08-07 10:40:00:000'
--declare @fecha_ini_text8 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_fin_text8 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_ini_text9 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_fin_text9 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_ini_text10 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_fin_text10 as varchar (256) = '2014-08-12 09:40:00:000'


--declare @ciudad as varchar(256) = 'BADAJOZ'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @pattern as varchar (256) = 'BADAJOZ'
--declare @overwrite as varchar(1) = 'N'
--declare @camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round'
--declare @Methodology as varchar (50) = 'D16'
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

declare @sheet as varchar(256) --Crear sólo la info total o la info total/4G
declare @type_info as varchar(256) 
declare @sheetNomb as varchar(256)

declare @typeInfo_KPI as varchar(5)

declare @All_Tests_volte as table (sessionid bigint, fileid bigint)

insert into @All_Tests_volte 
select v.sessionid,v.fileid
from Lcc_Calls_Detailed v, filelist f
where f.collectionname like '%volte%'
and f.fileid=v.fileid

declare @All_Tests_csfb as table (sessionid bigint, fileid bigint)

insert into @All_Tests_csfb 
select v.sessionid,v.fileid
from Lcc_Calls_Detailed v, filelist f
where f.collectionname not like '%volte%'
and f.fileid=v.fileid

BEGIN TRY
BEGIN TRANSACTION
	SET @ParmDefinition = N'@TablaOut varchar(255) output' 

	if  CHARINDEX('3G',db_name())  > 0 
		begin 
			set @bbddDest = '[AGGRVoice3G]'
			set @sheet = '(''ALL'',''WCDMA'')' --Se creará sólo la info total (de inicio valdra ALL para filtrar en los proc de step 1 pero luego pasara a valer %%)
			set @type_info = '(''Voice'')'
		end
	else --Indoor es 4G
		begin 
			if  CHARINDEX('ROAD',db_name())  > 0 and CHARINDEX('VOLTE',db_name()) = 0
				begin
					set @bbddDest = '[AGGRVoice4G_ROAD]'
					set @sheet= '(''ALL'',''LTE'',''WCDMA'')'  --Se creará la info total/only 4G
					set @type_info = '(''Voice'')'
				end
			else 
				begin
					if CHARINDEX('VOLTE',db_name()) >0
					begin
						set @bbddDest='[AGGRVOLTE]'
						set @sheet= '(''VOLTE'',''ALL'',''LTE'',''WCDMA'')' 
						set @type_info = '(''Voice'', ''VOLTE'')'
					end
					else 
					begin
						set @bbddDest = '[AGGRVoice4G]'
						set @sheet= '(''ALL'',''LTE'',''WCDMA'')'
						set @type_info = '(''Voice'')'
					end
				end
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
	DECLARE @nameTablaVoice varchar(256)
	DECLARE @nameProcAux varchar(256)
	declare @aggrTypeAux as varchar(256)

	declare @it1 bigint
	declare @MaxTab bigint

	set @it1 = 1

	declare @tmp_procedures_step1  as table (
		[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		[Name_proc] [varchar](128) not NULL,
		[Type_Info_KPI] [varchar](5) NULL
	)

	if @aggrType = 'GRID'
	begin
		set @aggrTypeAux = '_GRID'
	end
	else
	begin
		set @aggrTypeAux = ''
	end

	set @cmd = 'select Name_proc,Type_Info_KPI
	from [AGRIDS].[dbo].[lcc_procedures_step1_FY1718'+@aggrTypeAux+'] --Tabla en la que se registran los procedimientos de paso 1
	where type_Info in '+@type_info+'
		and Type_Info_KPI in '+@sheet+'
		and (Methodology = ''ALL'' or Methodology ='''+@Methodology+''')'
	print(@cmd)
	insert into @tmp_procedures_step1 (Name_proc,Type_Info_KPI)
	exec (@cmd)

	select @MaxTab = MAX(id) 
	from @tmp_procedures_step1

	while @it1 <= @MaxTab
	BEGIN
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

		set @sheetNomb = @typeInfo_KPI --Psoibles valores actuales ALL, LTE, WCDMA
		if @typeInfo_KPI = 'LTE'
		begin
			set @sheetNomb = '4G'
		end
		if @typeInfo_KPI = 'WCDMA'
		begin
			set @sheetNomb = '3G'
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

		set @nombTablaOrig = 'lcc_aggr_'+ @nameTablaVoice +'_'+ @pattern
		exec sp_lcc_dropifexists @nombTablaOrig

		--Generar tablas origen agrupadas
		set @cmd = '
		select *
		into lcc_aggr_'+ @nameTablaVoice +'_'+ @pattern +'
		from  openrowset ('''+ @provider +'''
		,'''+ @server +''';'''+ @Uid +''';'''+ @Pwd +'''
		,''SET NOCOUNT ON;EXEC '+ db_name() +'.dbo.'+ @nameProc +' '''''+@mob1+''''','''''+@mob2+''''','''''+@mob3+''''','''''+@ciudad+''''', '+convert(varchar,@simOperator)+','''''+@typeInfo_KPI+''''', 
		'''''+@fecha_ini_text1+''''','''''+@fecha_fin_text1+''''','''''+@fecha_ini_text2+''''','''''+@fecha_fin_text2+''''','''''+@fecha_ini_text3+''''','''''+@fecha_fin_text3+''''','''''+@fecha_ini_text4+''''','''''+@fecha_fin_text4+''''','''''+@fecha_ini_text5+''''','''''+@fecha_fin_text5+''''',
		'''''+@fecha_ini_text6+''''','''''+@fecha_fin_text6+''''','''''+@fecha_ini_text7+''''','''''+@fecha_fin_text7+''''','''''+@fecha_ini_text8+''''','''''+@fecha_fin_text8+''''','''''+@fecha_ini_text9+''''','''''+@fecha_fin_text9+''''','''''+@fecha_ini_text10+''''','''''+@fecha_fin_text10+''''','''''+@date+''''','+convert(varchar, @Indoor)+','''''+@Report+''''''')'

		print @cmd
		execute (@cmd)

		set @Tabla = null
		--Creamos tablas agrupadas en bbdd destino, si no existen
		set @cmd = 'select @TablaOut = name
			from '+ @bbddDest +'.sys.all_objects 
			where  name=''lcc_aggr_'+ @nameTablaVoice +'''
				and type=''U'''
		print @cmd
		exec sp_executesql @cmd,@ParmDefinition,@TablaOut = @Tabla output	

		print @Tabla
		if @Tabla is null --Si no existe la tabla
		begin
			set @cmd = '
					select top 1 *, '''+@camposLlave+'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'' as ''Key_Fields''
					into '+ @bbddDest +'.dbo.lcc_aggr_'+ @nameTablaVoice +'
					from lcc_aggr_'+ @nameTablaVoice +'_'+ @pattern
			print @cmd
			exec (@cmd)


			set @cmd = 'delete '+ @bbddDest +'.dbo.lcc_aggr_'+ @nameTablaVoice
			print @cmd
			exec (@cmd)
		end

		set @it1 = @it1 +1
	END 

	
	--drop table [dbo].[lcc_aggr_sp_MDD_Voice_Llamadas_ogrove]
	--drop table [AGGRVoice4G].[dbo].[lcc_aggr_sp_MDD_Voice_Llamadas]

	--------------------------------------------------------------------------------------------------
	-------------------------------Pasamos la info agrupada a la bbdd agrupada------------------------
	--------------------------------------------------------------------------------------------------
	set @cmd = '[sp_lcc_aggregate_parcel_FY1718] ' +db_name()+', '+@bbddDest+', '+@pattern+', '+@overwrite+', '''+@camposLlave+''''
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
	SELECT 'Transacción finalizada correctamente en ' + @ciudad + ' - Tipo de reporte:' + @Report + ' - MNC:' +convert(varchar,@simOperator)
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
	SELECT 'Transacción restaurada.Vuelva a ejecutar procedimiento de voz en: ' + @ciudad + ' - Tipo de reporte:' + @Report
END CATCH
IF @@TRANCOUNT > 0
	ROLLBACK TRANSACTION	

