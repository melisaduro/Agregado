--USE [master]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Llamadas_FY1617_GRID]    Script Date: 09/01/2017 16:31:16 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--CREATE PROCEDURE [dbo].[sp_MDD_Voice_VOLTE_FY1617_GRID] (
--	 --Variables de entrada
--		@mob1 as varchar(256),
--		@mob2 as varchar(256),
--		@mob3 as varchar(256),
--		@ciudad as varchar(256),
--		@simOperator as int,
--		@sheet as varchar(256),				-- all: %%, 4G: 'LTE', 3G: 'WCDMA'
--		@fecha_ini_text1 as varchar(256),
--		@fecha_fin_text1 as varchar (256),
--		@fecha_ini_text2 as varchar(256),
--		@fecha_fin_text2 as varchar (256),
--		@fecha_ini_text3 as varchar(256),
--		@fecha_fin_text3 as varchar (256),
--		@fecha_ini_text4 as varchar(256),
--		@fecha_fin_text4 as varchar (256),
--		@fecha_ini_text5 as varchar(256),
--		@fecha_fin_text5 as varchar (256),
--		@fecha_ini_text6 as varchar(256),
--		@fecha_fin_text6 as varchar (256),
--		@fecha_ini_text7 as varchar(256),
--		@fecha_fin_text7 as varchar (256),
--		@fecha_ini_text8 as varchar(256),
--		@fecha_fin_text8 as varchar (256),
--		@fecha_ini_text9 as varchar(256),
--		@fecha_fin_text9 as varchar (256),
--		@fecha_ini_text10 as varchar(256),
--		@fecha_fin_text10 as varchar (256),
--		@Date as varchar (256),
--		@Indoor as int,
--		@Report as varchar (256)
--)
--AS

-----------------------------
----- Testing Variables -----
-----------------------------
use [FY1617_Voice_Main_VOLTE_2]
declare @ciudad as varchar(256) = 'SEVILLA'
declare @simOperator as int = 1
declare @date as varchar(256) = ''
declare @Indoor as bit = 0 -- O = False, 1 = True
declare @sheet as varchar(256) ='%%'
declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests as table (sessionid bigint)
declare @filtroTech as varchar(1024)  
declare @operator as varchar(256)
declare @tablaContorno as varchar(256)  
declare @cruceContorno as varchar(1024) 
declare @filtroContorno as varchar(1024)  

if @sheet = '%%'
	set @filtroTech = ''

else if @sheet = 'LTE'
	--set @filtroTech = 'and (v.technology = ''LTE'' or v.is_csfb=1)'
	if @Indoor = 0 --M2M
		--set @filtroTech = 'and ((v.is_csfb=2 or (v.is_VOLTE > 0 and v.is_CSFB<2))
		--                   or (v.callstatus=''Failed'' and (((v.is_csfb in (0,1) and v.is_volte in (0,1)) and ((v.csfb_device=''A'' and v.technology_Bside=''LTE'') or (v.csfb_device=''B'' and v.technology=''LTE''))) or (v.is_csfb=0 and v.is_volte=0 and v.technology_Bside=''LTE'' and v.technology=''LTE''))))'
		
		set @filtroTech = 'and (
			((v.is_csfb=2 or (v.is_VOLTE in (1,2) and v.is_CSFB in (0,1)))) 
		 or (v.callstatus=''Failed'' and (((v.is_csfb in (0,1) and v.is_volte in (0,1)) and ((v.csfb_device=''A'' and v.technology_Bside=''LTE'') or (v.csfb_device=''B'' and v.technology=''LTE''))) or (v.is_csfb=0 and v.is_volte=0 and v.technology_Bside=''LTE'' and v.technology=''LTE'')))
		 )'
		--set @filtroTech = 'and (v.is_csfb=2 or (v.is_VOLTE > 0 and v.is_CSFB<2))'
	
	else
		set @filtroTech = 'and ((v.is_csfb>0 or v.is_VOLTE>0)
							or (v.callstatus=''Failed'' and (v.is_csfb=0 and v.is_VOLTE=0) and v.technology=''LTE''))'
		--set @filtroTech = 'and (v.is_csfb>0 or v.is_VOLTE>0)'
		
else if @sheet = 'WCDMA'
	--set @filtroTech = 'and v.technology <> ''LTE'' and v.is_csfb=0'
	if @Indoor = 0 --M2M
		set @filtroTech = 'and (v.is_CSFB=0 and (v.technology <> ''LTE'' and v.technology_BSide <> ''LTE'') and v.is_VOLTE = 0)'
	else 
		set @filtroTech = 'and (v.is_CSFB=0 and (v.technology <> ''LTE'') and v.is_VOLTE = 0)'

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
exec ('select v.sessionid
from lcc_Calls_Detailed v, sessions s'+@cruceContorno+'
Where s.sessionid=v.sessionid
	and s.valid=1
	and v.MNC = '+ @operator +'	--MNC
	and v.MCC= 214				--MCC - Descartamos los valores erróneos
	and callStatus in (''Completed'',''Failed'',''Dropped'')
	'+ @filtroContorno +
	@filtroTech +'
	group by v.sessionid')
--select * from @All_Tests






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
declare @volte_calls  as table (
	[Database] nvarchar(128), 
	mnc varchar(2),
	Parcel varchar(50), 
	Count_Speech_Delay int,
	Started_VoLTE int,
	SRVCC int, 
	is_VOLTE int, 
	VOLTE_Speech_Delay float,
	[Meas_Week] [varchar](3) NULL,
	Meas_Round varchar(256), 
	Meas_Date varchar(256), 
	Entidad varchar(256),
	Region varchar(256), 
	Num_Medida varchar(256),
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null
)




if (@Indoor=0 OR @Indoor=2)
begin
	insert into @volte_calls 
	select 
		db_name() as 'Database',
		v.mnc,
		[master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A) as Parcel,

		--Metemos un contador para luego poder ponderar el campo
		SUM(case when (ISNULL(v.Speech_Delay,0)>0) then 1 else 0 end) as 'Count_Speech_Delay',

		
		sum(case when (v.callstatus in ('Completed','Dropped') and (v.is_VoLTE-v.is_SRVCC) >=0) then v.is_VoLTE-v.is_SRVCC else 0 end) as Started_VoLTE,
		sum(case when v.callstatus in ('Completed','Dropped') then v.is_SRVCC end) as SRVCC,
		sum(case when v.callstatus in ('Completed','Dropped') then v.is_VOLTE end) as is_VOLTE,
		avg(v.Speech_Delay) as VOLTE_Speech_Delay,


		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.region as Region,
		null as 'Num_Medida',
		@Report,
		'GRID'
	--into _voice_calls
	from 
		@All_Tests a,
		lcc_Calls_Detailed v,
		Sessions s,
		Agrids.dbo.lcc_parcelas lp

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus in ('Completed','Failed','Dropped') --Discarding System Release and Not Set Calls
		and s.valid=1
		and lp.Nombre= [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A)

	group by [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A), v.mnc,lp.region

	
end
else
begin
	insert into @volte_calls
	select 
		db_name() as 'Database',
		v.mnc,
		null,

		--Metemos un contador para luego poder ponderar el campo
		SUM(case when (ISNULL(v.Speech_Delay,0)>0) then 1 else 0 end) as 'Count_Speech_Delay',

		sum(case when (v.callstatus in ('Completed','Dropped') and (v.is_VoLTE-v.is_SRVCC) >=0) then v.is_VoLTE-v.is_SRVCC else 0 end) as Started_VoLTE,
		sum(case when v.callstatus in ('Completed','Dropped') then v.is_SRVCC end) as SRVCC,
		sum(case when v.callstatus in ('Completed','Dropped') then v.is_VOLTE end) as is_VOLTE,
		avg(v.Speech_Delay) as VOLTE_Speech_Delay,
		
		

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'GRID'
	--into _voice_calls
	from 
		@All_Tests a,
		lcc_Calls_Detailed v,
		Sessions s

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus in ('Completed','Failed','Dropped') --Discarding System Release and Not Set Calls
		and s.valid=1

	group by  v.mnc

end

select * from @volte_calls



-----------Comprobacion de los resultados obtenidos en los KPIs especificos de VOLTE------------------------
------------------------------------------------------------------------------------------------------------
select 
	case when sum(Count_Speech_Delay)>0 then sum(Count_Speech_Delay*volte_speech_delay)/sum(Count_Speech_Delay) 
							else 0 end as VOLTE_Speech_Delay, --se pondera el speech delay para dar el valor real agrupado para la entidad calculada
	sum (Started_VOLTE) as [VOICE CALLS STARTED AND TERMINATED ON VOLTE],
	sum(SRVCC) as [CALLS WITH SRVCC PROCEDURE], 
	1.0*sum(SRVCC)/sum(is_VOLTE) as [% use SRVCC],
	sum(is_volte) as is_VOLTE
	
from @volte_calls


-------------- Espacio reservado para acumular en BBDD de agregados ------------------

--------------------------------------------------------------------------------------

--drop table _voice_calls --@All_Tests, 