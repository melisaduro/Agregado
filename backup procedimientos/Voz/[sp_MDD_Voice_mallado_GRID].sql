USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_mallado_GRID]    Script Date: 29/05/2017 13:18:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_mallado_GRID] (
	 --Variables de entrada
		@mob1 as varchar(256),
		@mob2 as varchar(256),
		@mob3 as varchar(256),
		@ciudad as varchar(256),
		@simOperator as int,
		@sheet as varchar(256),				-- all: %%, 4G: 'LTE', 3G: 'WCDMA'
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
		@Report as varchar (256)
)
AS

-----------------------------
----- Testing Variables -----
-----------------------------
--declare @ciudad as varchar(256) = 'RUBI'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @sheet as varchar(256) ='%%'
--declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests as table (sessionid bigint, is_VoLTE int, is_SRVCC int)
declare @operator as varchar(256)
declare @tablaContorno as varchar(256)  
declare @cruceContorno as varchar(1024) 
declare @filtroContorno as varchar(1024)  

set @operator = convert(varchar,@simOperator)

--Dependiendo del contorno pasado por parametro, cruzamos por una tabla u otra
If @Report='VDF'
begin
	set @tablaContorno = 'lcc_position_Entity_List_Vodafone'
end
If @Report='OSP'
begin
	set @tablaContorno = 'lcc_position_Entity_List_Orange'
end
If @Report='MUN'
begin
	set @tablaContorno = 'lcc_position_Entity_List_Municipio'
end

--Si Indoor=0 (M2M), exigimos que en el fin de la llamada los dos terminales este dentro del contorno de la ciudad
--Si Indoor=1 (M2F), exigimos que en el fin de la llamada el terminal este dentro del contorno de la ciudad
if @Indoor = 0
begin
	set @cruceContorno =', '+@tablaContorno+' c, '+@tablaContorno+' c2'
	set @filtroContorno = 'and c.fileid=v.fileid
and c.entity_name = '''+@ciudad+'''
and c2.entity_name = '''+@ciudad+'''
and c.fileid=c2.fileid
and (c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitude_Fin_A], [Latitude_Fin_A])
and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitude_Fin_A]))
and (c2.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitude_Fin_B], [Latitude_Fin_B])
and c2.latid=master.dbo.fn_lcc_latitude2latid ([Latitude_Fin_B]))'
end	
else
begin 
	set @cruceContorno =', '+@tablaContorno+' c'
	set @filtroContorno = 'and c.fileid=v.fileid
and c.entity_name = '''+@ciudad+'''
and (c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitude_Fin_A], [Latitude_Fin_A])
and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitude_Fin_A]))'
end

insert into @All_Tests
exec ('select v.sessionid, v.is_VOLTE, v.is_SRVCC
from lcc_Calls_Detailed v, sessions s'+@cruceContorno+'
Where s.sessionid=v.sessionid
	and s.valid=1
	and v.MNC = '+ @operator +'	--MNC
	and v.MCC= 214				--MCC - Descartamos los valores erróneos
	and callStatus in (''Completed'',''Failed'',''Dropped'')
	'+ @filtroContorno +'
	group by v.sessionid, v.is_VOLTE, v.is_SRVCC')
--select * from @All_Tests


if @sheet = 'VOLTE'
begin
	delete from @All_Tests where (is_VoLTE is NULL or is_VoLTE<>2 or (is_volte=2 and is_SRVCC>0))
end

------ Metemos en variables algunos campos calculados ----------------

declare @Meas_Round as varchar(256)

if (charindex('AVE',db_name())>0 and charindex('Rest',db_name())=0)
	begin 
	 set @Meas_Round= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(6, db_name(),'_')
	end
else
	begin
	 set @Meas_Round= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')
	end

declare @dateMax datetime2(3)= (select max(c.callEndTimeStamp) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

declare @entidad as varchar(256) = @ciudad

declare @medida as varchar(256) 
if @Indoor=1 and @entidad not like '%RLW%' and @entidad not like '%APT%' and @entidad not like '%STD%'
begin
	SET @medida = right(@ciudad,1)
end

declare @week as varchar(256)
set @week = 'W' +convert(varchar,DATEPART(iso_week, @dateMax))

------------------------------------------------------------------------------------
------------------------------- GENERAL SELECT
------------- Calls Related Main Info, Samples per Tech and Codec
------------------------------------------------------------------------------------
declare @voice_calls  as table (
	[Database] nvarchar(128)
	, Parcel varchar(50) 
	, mnc varchar(2)
	, position_count int
	, [Meas_Week] [varchar](3) NULL
	, Meas_Round varchar(256)
	, Meas_Date varchar(256)
	, Entidad varchar(256)
	, [Region_VF] varchar(256)
	, Num_Medida varchar(256),
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP] [varchar](256) NULL
)

if (@Indoor=0 OR @Indoor=2)
begin
	insert into @voice_calls 
	select 
		db_name() as 'Database',
		[master].[dbo].[fn_lcc_getParcel](v.longitude, v.latitude) as Parcel,
		@operator,
		count(v.sessionid),
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'GRID',
		lp.Region_OSP as Region_OSP
	from 
		@All_Tests a,
		lcc_position v,
		Sessions s,
		Agrids.dbo.lcc_parcelas lp

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and s.valid=1
		and lp.Nombre= [master].[dbo].[fn_lcc_getParcel](v.longitude, v.latitude)

	group by [master].[dbo].[fn_lcc_getParcel](v.longitude, v.latitude), lp.Region_VF,lp.Region_OSP
end
else
begin
	insert into @voice_calls
	select distinct
		db_name() as 'Database',
		null,
		@operator,
		null,		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'GRID',
		null
	from 
		@All_Tests a,
		lcc_position v,
		Sessions s

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and s.valid=1

end

select * from @voice_calls

