USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_tables_Coverage_Aggr]    Script Date: 25/05/2017 10:16:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_lcc_create_tables_Coverage_Aggr] (
				@ciudad as varchar(256),
				@simOperator as int,
				@umbralIndoor varchar(256),
				@Date as varchar (256),
				@Indoor as bit,
				@Pillot as bit,             
				@pattern as varchar (256),
				@overwrite as varchar(1), --Y/N se sobreescriben las parcelas o no
				@camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-Meas_Date', -- Default value
				@monthYearDash as varchar(100),
				@weekDash as varchar(50)
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


--declare @ciudad as varchar(256) = 'a_benidorm'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @pattern as varchar (256) = 'benidorm'
--declare @overwrite as varchar(1) = 'Y'
--declare @camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-Meas_Date'
--declare @umbralIndoor varchar(256) = '-70'
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

SET @ParmDefinition = N'@TablaOut varchar(255) output' 

if  CHARINDEX('ROAD',db_name())  > 0 
	set @bbddDest = '[AGGRCoverage_ROAD]'
else
	set @bbddDest = '[AGGRCoverage]'


set @pattern = replace(@pattern,'-','_')
--------------------------------------------------------------------------------------------------
--------------------------------Generar tablas origen agrupadas-----------------------------------
--------------------------------------------------------------------------------------------------
--Recorremos los procedimientos de paso 1 existentes y creamos las tablas de agregado origen correspondientes.
--En el caso que no exista la tabla destino en la bbdd de agregado correspondiente, se crea.

DECLARE @nameProc varchar(256)

DECLARE cursorProcStep1 CURSOR FOR
select Name_proc
from [AGRIDS].[dbo].[lcc_procedures_step1] --Tabla en la que se registran los procedimientos de paso 1
where type_Info='Coverage'

OPEN cursorProcStep1

FETCH NEXT FROM cursorProcStep1 
INTO @nameProc

WHILE @@FETCH_STATUS = 0
BEGIN
	set @nombTablaOrig = 'lcc_aggr_'+ @nameProc +'_'+ @pattern
	exec sp_lcc_dropifexists @nombTablaOrig
	--Generar tablas origen agrupadas
	set @cmd = '
	select *
	into lcc_aggr_'+ @nameProc +'_'+ @pattern +'
	from  openrowset ('''+ @provider +'''
	,'''+ @server +''';'''+ @Uid +''';'''+ @Pwd +'''
	,''SET NOCOUNT ON;EXEC '+ db_name() +'.dbo.'+ @nameProc +' '''''+@ciudad+''''','''''''', '+convert(varchar,@simOperator)+',''''total'''','''''+@umbralIndoor+''''',
	'''''+@monthYearDash+''''','''''+@weekDash+''''''')'

	print @cmd
	execute (@cmd)

	set @Tabla = null
	--Creamos tablas agrupadas en bbdd destino, si no existen
	set @cmd = 'select @TablaOut = name
		from '+ @bbddDest +'.sys.all_objects 
		where  name=''lcc_aggr_'+ @nameProc +'''
			and type=''U'''
	print @cmd
	exec sp_executesql @cmd,@ParmDefinition,@TablaOut = @Tabla output	

	print @Tabla
	if @Tabla is null --Si no existe la tabla
	begin
		set @cmd = '
				select top 1 *, '''+@camposLlave+'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'' as ''Key_Fields''
				into '+ @bbddDest +'.dbo.lcc_aggr_'+ @nameProc +'
				from lcc_aggr_'+ @nameProc +'_'+ @pattern
		print @cmd
		exec (@cmd)

		set @cmd = 'delete '+ @bbddDest +'.dbo.lcc_aggr_'+ @nameProc
		print @cmd
		exec (@cmd)
	end

	FETCH NEXT FROM cursorProcStep1 
    INTO @nameProc
END 
CLOSE cursorProcStep1;
DEALLOCATE cursorProcStep1;

	
--drop table [dbo].[lcc_aggr_sp_MDD_Voice_Llamadas_ogrove]
--drop table [AGGRVoice4G].[dbo].[lcc_aggr_sp_MDD_Voice_Llamadas]

--------------------------------------------------------------------------------------------------
-------------------------------Pasamos la info agrupada a la bbdd agrupada------------------------
--------------------------------------------------------------------------------------------------
set @cmd = '[sp_lcc_aggregate_parcel] ' +db_name()+', '+@bbddDest+', '+@pattern+', '+@overwrite+', '''+@camposLlave+''''
print @cmd
exec (@cmd)

--------------------------------------------------------------------------------------------------
---------------------------------Borramos las tablas agrupadas origen-----------------------------
--------------------------------------------------------------------------------------------------

DECLARE @nameTabla varchar(256)

DECLARE cursorTabAggr CURSOR FOR
--declare @pattern as varchar (256) = 'ogrove'
select name
from sys.tables
where name like 'lcc_aggr_%'+ @pattern
	and type='U'

OPEN cursorTabAggr

FETCH NEXT FROM cursorTabAggr 
INTO @nameTabla

WHILE @@FETCH_STATUS = 0
BEGIN
	--borramos las funciones de agregado que se han creado en este procedimiento
	set @Tabla = null

	select @Tabla =Name_proc
	from [AGRIDS].[dbo].[lcc_procedures_step1] --Tabla en la que se registran los procedimientos de paso 1
	where type_Info='Coverage'
		and 'lcc_aggr_'+ Name_proc +'_'+ @pattern  = @nameTabla

	if @Tabla is not null --Si existe la tabla, la borramos
	begin
		set @cmd = 'drop table '+ @nameTabla

		print @cmd
		exec (@cmd)
	end

	FETCH NEXT FROM cursorTabAggr 
    INTO @nameTabla
END 
CLOSE cursorTabAggr;
DEALLOCATE cursorTabAggr;


