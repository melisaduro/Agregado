USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_PESQ_Detailed_GRID]    Script Date: 29/05/2017 13:18:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_PESQ_Detailed_GRID] (
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
--declare @ciudad as varchar(256) = 'MAD-BCN-R1'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 1 -- O = False, 1 = True
--declare @sheet as varchar(256) ='%%'
--declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------		  
declare @All_Tests as table (sessionid bigint, is_VoLTE int, is_SRVCC int)
declare @filtroTech as varchar(1024)  
declare @operator as varchar(256)
declare @tablaContorno as varchar(256)  
declare @cruceContorno as varchar(1024) 
declare @filtroContorno as varchar(1024)

if @sheet = '%%'
	set @filtroTech = ''

else if @sheet = 'LTE' or @sheet = 'VOLTE'
	--set @filtroTech = 'and (v.technology = ''LTE'' or v.is_csfb=1)'
	if @Indoor = 0
		set @filtroTech = 'and ((v.is_csfb=2 or (v.is_VOLTE > 0 and v.is_CSFB<2))
		                   or (v.callstatus=''Failed'' and (((v.is_csfb in (0,1) and v.is_volte in (0,1)) and ((v.csfb_device=''A'' and v.technology_Bside=''LTE'') or (v.csfb_device=''B'' and v.technology=''LTE''))) or (v.is_csfb=0 and v.is_volte=0 and v.technology_Bside=''LTE'' and v.technology=''LTE''))))'
		--set @filtroTech = 'and (v.is_csfb=2 or (v.is_VOLTE > 0 and v.is_CSFB<2))'
	
	else
		set @filtroTech = 'and ((v.is_csfb>0 or v.is_VOLTE>0)
							or (v.callstatus=''Failed'' and (v.is_csfb=0 and v.is_VOLTE=0) and v.technology=''LTE''))'
		--set @filtroTech = 'and (v.is_csfb>0 or v.is_VOLTE>0)'
		
else if @sheet = 'WCDMA'
	--set @filtroTech = 'and v.technology <> ''LTE'' and v.is_csfb=0'
	if @Indoor = 0
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
	'+ @filtroContorno +
	@filtroTech +'
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

--declare @Meas_Date as varchar(256)= (select max(right(convert(varchar(256),datepart(yy, callendtimestamp)),2) + '_'	 + convert(varchar(256),format(callendtimestamp,'MM')))
--	from lcc_Calls_Detailed where sessionid=(select max(c.sessionid) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid))

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
----------------------- Disaggregated Samples Histogram
------------------------------------------------------------------------------------
declare @voice_pesq_det  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Registers] [int] NULL,
	[MOS] [float] NULL,
	[MOS_DL] [float] NULL,
	[MOS_UL] [float] NULL,
	[1-1.5] [int] NULL,
	[1.5-2] [int] NULL,
	[2-2.1] [int] NULL,
	[2.1-2.2] [int] NULL,
	[2.2-2.3] [int] NULL,
	[2.3-2.4] [int] NULL,
	[2.4-2.5] [int] NULL,
	[2.5-2.6] [int] NULL,
	[2.6-2.7] [int] NULL,
	[2.7-2.8] [int] NULL,
	[2.8-2.9] [int] NULL,
	[2.9-3] [int] NULL,
	[3-3.1] [int] NULL,
	[3.1-3.2] [int] NULL,
	[3.2-3.3] [int] NULL,
	[3.3-3.4] [int] NULL,
	[3.4-3.5] [int] NULL,
	[3.5-3.6] [int] NULL,
	[3.6-3.7] [int] NULL,
	[3.7-3.8] [int] NULL,
	[3.8-3.9] [int] NULL,
	[3.9-4] [int] NULL,
	[4-4.5] [int] NULL,
	[4.5-5] [int] NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF] [varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP] [varchar](256) NULL,
	[Calltype] [varchar](256) null,
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL
)

if (@Indoor=0 OR @Indoor=2) --M2M: MOS WB
begin
	insert into @voice_pesq_det
	select 
		db_name() as 'Database',
		v.mnc,
		[master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A) as Parcel,
		SUM(v.MOS_Samples_WB) as Registers,
		AVG(v.MOS_WB) as MOS,
		AVG(v.MOS_WB_DL) as MOS_DL,
		AVG(v.MOS_WB_UL) as MOS_UL,
		SUM(v.[MOS_1-1.5_WB]) as [1-1.5],
		SUM(v.[MOS_1.5-2_WB]) as [1.5-2],
		SUM(v.[MOS_2-2.1_WB]) as [2-2.1],
		Sum(v.[MOS_2.1-2.2_WB]) as [2.1-2.2],
		sum(v.[MOS_2.2-2.3_WB]) as [2.2-2.3],
		SUM(v.[MOS_2.3-2.4_WB]) as [2.3-2.4],
		SUM(v.[MOS_2.4-2.5_WB]) as [2.4-2.5],
		SUM(v.[MOS_2.5-2.6_WB]) as [2.5-2.6],
		SUM(v.[MOS_2.6-2.7_WB]) as [2.6-2.7],
		SUM(v.[MOS_2.7-2.8_WB]) as [2.7-2.8],
		SUM(v.[MOS_2.8-2.9_WB]) as [2.8-2.9],
		SUM(v.[MOS_2.9-3_WB]) as [2.9-3],
		SUM(v.[MOS_3-3.1_WB]) as [3-3.1],
		SUM(v.[MOS_3.1-3.2_WB]) as [3.1-3.2],
		SUM(v.[MOS_3.2-3.3_WB]) as [3.2-3.3],
		SUM(v.[MOS_3.3-3.4_WB]) as [3.3-3.4],
		SUM(v.[MOS_3.4-3.5_WB]) as [3.4-3.5],
		SUM(v.[MOS_3.5-3.6_WB]) as [3.5-3.6],
		SUM(v.[MOS_3.6-3.7_WB]) as [3.6-3.7],
		SUM(v.[MOS_3.7-3.8_WB]) as [3.7-3.8],
		SUM(v.[MOS_3.8-3.9_WB]) as [3.8-3.9],
		SUM(v.[MOS_3.9-4_WB]) as [3.9-4],
		SUM(v.[MOS_4-4.5_WB]) as [4-4.5],
		SUM(v.[MOS_4.5-5_WB]) as [4.5-5],
		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'GRID',
		lp.Region_OSP as Region_OSP,
		calltype,
		v.[ASideDevice],
		v.[BSideDevice],
		v.[SWVersion]

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

	group by [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A), v.mnc,lp.Region_VF,lp.Region_OSP,
		calltype, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]

end
else --Indoor: MOS NB
begin
	insert into @voice_pesq_det
	select 
		db_name() as 'Database',
		v.mnc,
		null,
		SUM(v.MOS_Samples_NB) as Registers,
		AVG(v.MOS_NB) as MOS,
		AVG(v.MOS_NB_DL) as MOS_DL,
		AVG(v.MOS_NB_UL) as MOS_UL,
		SUM(v.[MOS_1-1.5_NB]) as [1-1.5],
		SUM(v.[MOS_1.5-2_NB]) as [1.5-2],
		SUM(v.[MOS_2-2.1_NB]) as [2-2.1],
		Sum(v.[MOS_2.1-2.2_NB]) as [2.1-2.2],
		sum(v.[MOS_2.2-2.3_NB]) as [2.2-2.3],
		SUM(v.[MOS_2.3-2.4_NB]) as [2.3-2.4],
		SUM(v.[MOS_2.4-2.5_NB]) as [2.4-2.5],
		SUM(v.[MOS_2.5-2.6_NB]) as [2.5-2.6],
		SUM(v.[MOS_2.6-2.7_NB]) as [2.6-2.7],
		SUM(v.[MOS_2.7-2.8_NB]) as [2.7-2.8],
		SUM(v.[MOS_2.8-2.9_NB]) as [2.8-2.9],
		SUM(v.[MOS_2.9-3_NB]) as [2.9-3],
		SUM(v.[MOS_3-3.1_NB]) as [3-3.1],
		SUM(v.[MOS_3.1-3.2_NB]) as [3.1-3.2],
		SUM(v.[MOS_3.2-3.3_NB]) as [3.2-3.3],
		SUM(v.[MOS_3.3-3.4_NB]) as [3.3-3.4],
		SUM(v.[MOS_3.4-3.5_NB]) as [3.4-3.5],
		SUM(v.[MOS_3.5-3.6_NB]) as [3.5-3.6],
		SUM(v.[MOS_3.6-3.7_NB]) as [3.6-3.7],
		SUM(v.[MOS_3.7-3.8_NB]) as [3.7-3.8],
		SUM(v.[MOS_3.8-3.9_NB]) as [3.8-3.9],
		SUM(v.[MOS_3.9-4_NB]) as [3.9-4],
		SUM(v.[MOS_4-4.5_NB]) as [4-4.5],
		SUM(v.[MOS_4.5-5_NB]) as [4.5-5],
		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'GRID',
		null,
		calltype,
		v.[ASideDevice],
		'Fixed' as 'BSideDevice',
		v.[SWVersion]

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

	group by v.mnc, calltype, v.[ASideDevice], v.[SWVersion]
end


select * from @voice_pesq_det