USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_tables_Coverage_Aggr_D16_NEW]    Script Date: 26/06/2017 17:56:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_lcc_create_tables_Coverage_Aggr_D16_NEW] (
		@ciudad as varchar(256),
		@simOperator as int,
		@umbralIndoor varchar(256),
		@Date as varchar (256),
		@Indoor as bit,
		@Pillot as bit,             
		@pattern as varchar (256),
		@overwrite as varchar(1), --Y/N se sobreescriben las parcelas o no
		@camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-Report_Type-Entidad', -- Default value
		@monthYearDash as varchar(100),
		@weekDash as varchar(50),
		@Methodology as varchar (50),
		@Report as varchar (256),
		@aggrType as varchar(256)--,
		--No es necesario ya que tenemos @Report='ROAD', si no fuera así, necesitariamos un param para identicar las roads extras
		--@RoadOrange as bit
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
--declare @Methodology as varchar (50) = 'D15'
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

SET @ParmDefinition = N'@TablaOut varchar(255) output' 

--ANTES las roads "normales" (A1,...,A7) estaban en CoverageUnion y debiamos distinguir por el nombre de @ciudad
--if CHARINDEX('A1',@ciudad) > 0 or CHARINDEX('A2',@ciudad) > 0 or CHARINDEX('A3',@ciudad) > 0 or CHARINDEX('A4',@ciudad) > 0
--	or CHARINDEX('A5',@ciudad) > 0 or CHARINDEX('A6',@ciudad) > 0 or CHARINDEX('A7',@ciudad) > 0
--AHORA: roads normales estan en CoverageUnion_ROAD (para que la lógica distinga por ronda)
-- y las roads extra estan en CoverageUnion pero se procesan con @Report='ROAD'
if  CHARINDEX('ROAD',db_name())> 0 or @Report='ROAD'
	set @bbddDest = '[AGGRCoverage_ROAD]'
else
	set @bbddDest = '[AGGRCoverage]'


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
declare @aggrTypeAux as varchar(256)

declare @it1 bigint
declare @MaxTab bigint

set @it1 = 1

declare @tmp_procedures_step1  as table (
	[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Name_proc] [varchar](128) not NULL
)

if @aggrType = 'GRID'
begin
	set @aggrTypeAux = '_GRID'
end
else
begin
	set @aggrTypeAux = ''
end

set @cmd = 'select Name_proc
from [AGRIDS].[dbo].[lcc_procedures_step1'+@aggrTypeAux+'] --Tabla en la que se registran los procedimientos de paso 1
where type_Info=''Coverage''
and (Methodology = ''ALL'' or Methodology ='''+@Methodology+''')'
print(@cmd)
insert into @tmp_procedures_step1 (Name_proc)
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

	--CAC 26_04_2017: excepcion, se incluye el agregado de sp_MDD_Coverage_All_Outdoor pero SÓLO para AVEs
	if @nameProc <> 'sp_MDD_Coverage_All_Outdoor' or CHARINDEX('AVE',db_name())> 0
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

		set @nombTablaOrig = 'lcc_aggr_'+ @nameProcAux +'_'+ @pattern
		exec sp_lcc_dropifexists @nombTablaOrig

		set @nameProc=@nameProc+'_NEW'
		--Generar tablas origen agrupadas
		set @cmd = '
		select *
		into lcc_aggr_'+ @nameProcAux +'_'+ @pattern +'
		from  openrowset ('''+ @provider +'''
		,'''+ @server +''';'''+ @Uid +''';'''+ @Pwd +'''
		,''SET NOCOUNT ON;EXEC '+ db_name() +'.dbo.'+ @nameProc +' '''''+@ciudad+''''','''''''', '+convert(varchar,@simOperator)+',''''total'''','''''+@umbralIndoor+''''',
		'''''+@monthYearDash+''''','''''+@weekDash+''''','''''+@Report+''''','''''+@aggrType+''''''')'

		print @cmd
		execute (@cmd)

		set @Tabla = null
		--Creamos tablas agrupadas en bbdd destino, si no existen
		set @cmd = 'select @TablaOut = name
			from '+ @bbddDest +'.sys.all_objects 
			where  name=''lcc_aggr_'+ @nameProcAux +'''
				and type=''U'''
		print @cmd
		exec sp_executesql @cmd,@ParmDefinition,@TablaOut = @Tabla output	

		print @Tabla
		if @Tabla is null --Si no existe la tabla
		begin
			set @cmd = '
					select top 1 *, '''+@camposLlave+'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'' as ''Key_Fields''
					into '+ @bbddDest +'.dbo.lcc_aggr_'+ @nameProcAux +'
					from lcc_aggr_'+ @nameProcAux +'_'+ @pattern
			print @cmd
			exec (@cmd)

			set @cmd = 'delete '+ @bbddDest +'.dbo.lcc_aggr_'+ @nameProcAux
			print @cmd
			exec (@cmd)
		end
	end
	set @it1 = @it1 +1
END
	
--drop table [dbo].[lcc_aggr_sp_MDD_Voice_Llamadas_ogrove]
--drop table [AGGRVoice4G].[dbo].[lcc_aggr_sp_MDD_Voice_Llamadas]

--------------------------------------------------------------------------------------------------
-------------------------------Pasamos la info agrupada a la bbdd agrupada------------------------
--------------------------------------------------------------------------------------------------
set @cmd = '[sp_lcc_aggregate_parcel_cober] ' +db_name()+', '+@bbddDest+', '+@pattern+', '+@overwrite+', '''+@camposLlave+''''
print @cmd
exec (@cmd)

---------------------------------------------------------------------------------------------------
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
	print 'Nombre de la tabla:  ' + @nameTabla

	set @cmd = 'drop table '+ @nameTabla

	print @cmd
	exec (@cmd)

	set @it2 = @it2 +1
END 



