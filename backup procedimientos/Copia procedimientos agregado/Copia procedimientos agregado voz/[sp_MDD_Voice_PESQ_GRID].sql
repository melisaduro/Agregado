USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_PESQ_GRID]    Script Date: 12/07/2017 15:27:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_PESQ_GRID] (
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
--use [FY1617_Voice_Rest_4G_H1_6]
--declare @ciudad as varchar(256) = 'CIUDADREAL'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @sheet as varchar(256) ='%%'
--declare @report as varchar(256) = 'MUN' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

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
----- Directional AVG, Samples Percentage Histogram, AVG per Codec and Tech
------------------------------------------------------------------------------------
declare @voice_pesq  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Calls_MOS][int] NULL,
	[Calls_MOS_NB] [int] NULL,
	[Registers_NB] [int] NULL,
	[MOS_NB] [float] NULL,
	[MOS_NB_DESV] [float] NULL,
	[MOS_DL_NB] [float] NULL,
	[MOS_UL_NB] [float] NULL,
	[MOS_NB_Samples_Under_2.5] [int] NULL,
	[Registers] [int] NULL,
	[MOS] [float] NULL,
	[MOS_DL] [float] NULL,
	[MOS_UL] [float] NULL,
	[MOS_Samples_Under_2.5] [int] NULL,
	[MOS_ALL] [float] NULL,
	[MOS_ALL_DESV] [float] NULL,
	[Calls_WB_only] [int] NULL,
	[MOS_WBOnly] [float] NULL,
	[Calls_AVG_WB_ONLY] [int] NULL,
	[1-1.5 WB] [numeric](26, 12) NULL,
	[1.5-2 WB] [numeric](26, 12) NULL,
	[2-2.5 WB] [numeric](26, 12) NULL,
	[2.5-3 WB] [numeric](26, 12) NULL,
	[3-3.5 WB] [numeric](26, 12) NULL,
	[3.5-4 WB] [numeric](26, 12) NULL,
	[4-4.5 WB] [numeric](26, 12) NULL,
	[4.5-5 WB] [numeric](26, 12) NULL,
	[1-1.5 NB] [numeric](26, 12) NULL,
	[1.5-2 NB] [numeric](26, 12) NULL,
	[2-2.5 NB] [numeric](26, 12) NULL,
	[2.5-3 NB] [numeric](26, 12) NULL,
	[3-3.5 NB] [numeric](26, 12) NULL,
	[3.5-4 NB] [numeric](26, 12) NULL,
	[4-4.5 NB] [numeric](26, 12) NULL,
	[4.5-5 NB] [numeric](26, 12) NULL,
	[FR] [float] NULL,
	[EFR] [float] NULL,
	[HR] [float] NULL,
	[AMR_HR] [float] NULL,
	[AMR_FR] [float] NULL,
	[AMR_WB] [float] NULL,
	[E-GSM] [varchar](1) NOT NULL,
	[GSM] [float] NULL,
	[DCS] [float] NULL,
	[UMTS] [float] NULL,
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
	
	insert into @voice_pesq 
	select 
		db_name() as 'Database',
		v.mnc,
		[master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A) as Parcel,
		sum (case when v.MOS_WB is not null then 1 
					when v.MOS_WB is null and v.MOS_NB is not null then 1
					else 0 end) as Calls_MOS,
		sum (case when v.MOS_NB is not null then 1 
			else 0 end) as Calls_MOS_NB,
		SUM(v.MOS_Samples_NB) as Registers_NB,
		AVG(v.MOS_NB) as MOS_NB,
		STDEV(v.MOS_NB) as MOS_NB_DESV,
		AVG(v.MOS_NB_DL) as MOS_DL_NB,
		AVG(v.MOS_NB_UL) as MOS_UL_NB,
		SUM(v.[MOS_NB_Samples_Under_2.5]) as [MOS_NB_Samples_Under_2.5],
		SUM(v.MOS_Samples_WB) as Registers,
		AVG(v.MOS_WB) as MOS,
		AVG(v.MOS_WB_DL) as MOS_DL,
		AVG(v.MOS_WB_UL) as MOS_UL,
		SUM(v.[MOS_WB_Samples_Under_2.5]) as [MOS_Samples_Under_2.5],

		AVG(case when (v.MOS_WB is not null) then v.MOS_WB else v.MOS_NB end) as MOS_ALL,
		STDEV(case when (v.MOS_WB is not null) then v.MOS_WB else v.MOS_NB end) as MOS_ALL_DESV,
		SUM(case when v.MOS_Samples_NB = 0 and v.MOS_Samples_WB > 0 then 1 else 0 end) as Calls_WB_only,
		AVG(case when v.MOS_Samples_NB = 0 and v.MOS_Samples_WB > 0 then v.MOS_WB end) as MOS_WBOnly,
		--- MTP: 07/04/2016
		SUM(case when v.MOS_Samples_NB = 0 and v.MOS_Samples_WB > 0 and v.MOS_WB is not null then 1 else 0 end) as Calls_AVG_WB_ONLY,
			
		--CA: 21/11/2016 cogemos los valores de la tabla lcc para que sean misma consideraciones que procesado		
		--- MTP: 21/03/2016
		--SUM(m.[MOS_1-1.5_WB]) as [1-1.5 WB],
		--SUM(m.[MOS_1.5-2_WB]) as [1.5-2 WB],
		--SUM(m.[MOS_2-2.5_WB]) as [2-2.5 WB],
		--SUM(m.[MOS_2.5-3_WB]) as [2.5-3 WB],
		--SUM(m.[MOS_3-3.5_WB]) as [3-3.5 WB],
		--SUM(m.[MOS_3.5-4_WB]) as [3.5-4 WB],
		--SUM(m.[MOS_4-4.5_WB]) as [4-4.5 WB],
		--SUM(m.[MOS_4.5-5_WB]) as [4.5-5 WB],
		--SUM(m.[MOS_1-1.5_NB]) as [1-1.5 NB],
		--SUM(m.[MOS_1.5-2_NB]) as [1.5-2 NB],
		--SUM(m.[MOS_2-2.5_NB]) as [2-2.5 NB],
		--SUM(m.[MOS_2.5-3_NB]) as [2.5-3 NB],
		--SUM(m.[MOS_3-3.5_NB]) as [3-3.5 NB],
		--SUM(m.[MOS_3.5-4_NB]) as [3.5-4 NB],
		--SUM(m.[MOS_4-4.5_NB]) as [4-4.5 NB],
		--SUM(m.[MOS_4.5-5_NB]) as [4.5-5 NB],

		SUM(v.[MOS_1-1.5_WB]) as [1-1.5 WB],
		SUM(v.[MOS_1.5-2_WB]) as [1.5-2 WB],
		SUM(v.[MOS_2-2.1_WB] + v.[MOS_2.1-2.2_WB] + v.[MOS_2.2-2.3_WB] + v.[MOS_2.3-2.4_WB] + v.[MOS_2.4-2.5_WB]) as [2-2.5 WB],
		SUM(v.[MOS_2.5-2.6_WB] + v.[MOS_2.6-2.7_WB] + v.[MOS_2.7-2.8_WB] + v.[MOS_2.8-2.9_WB] + v.[MOS_2.9-3_WB]) as [2.5-3 WB],
		SUM(v.[MOS_3-3.1_WB] + v.[MOS_3.1-3.2_WB] + v.[MOS_3.2-3.3_WB] + v.[MOS_3.3-3.4_WB] + v.[MOS_3.4-3.5_WB]) as [3-3.5 WB],
		SUM(v.[MOS_3.5-3.6_WB] + v.[MOS_3.6-3.7_WB] + v.[MOS_3.7-3.8_WB] + v.[MOS_3.8-3.9_WB] + v.[MOS_3.9-4_WB]) as [3.5-4 WB],
		SUM(v.[MOS_4-4.5_WB]) as [4-4.5 WB],
		SUM(v.[MOS_4.5-5_WB]) as [4.5-5 WB],
		SUM(v.[MOS_1-1.5_NB]) as [1-1.5 NB],
		SUM(v.[MOS_1.5-2_NB]) as [1.5-2 NB],
		SUM(v.[MOS_2-2.1_NB] + v.[MOS_2.1-2.2_NB] + v.[MOS_2.2-2.3_NB] + v.[MOS_2.3-2.4_NB] + v.[MOS_2.4-2.5_NB]) as [2-2.5 NB],
		SUM(v.[MOS_2.5-2.6_NB] + v.[MOS_2.6-2.7_NB] + v.[MOS_2.7-2.8_NB] + v.[MOS_2.8-2.9_NB] + v.[MOS_2.9-3_NB]) as [2.5-3 NB],
		SUM(v.[MOS_3-3.1_NB] + v.[MOS_3.1-3.2_NB] + v.[MOS_3.2-3.3_NB] + v.[MOS_3.3-3.4_NB] + v.[MOS_3.4-3.5_NB]) as [3-3.5 NB],
		SUM(v.[MOS_3.5-3.6_NB] + v.[MOS_3.6-3.7_NB] + v.[MOS_3.7-3.8_NB] + v.[MOS_3.8-3.9_NB] + v.[MOS_3.9-4_NB]) as [3.5-4 NB],
		SUM(v.[MOS_4-4.5_NB]) as [4-4.5 NB],
		SUM(v.[MOS_4.5-5_NB]) as [4.5-5 NB],
		---------

		AVG(case when v.CodecName = 'AMR 12.2' then v.MOS_WB else null end) as FR,
		AVG(case when v.CodecName = 'EFR' then v.MOS_WB else null end) as EFR,
		AVG(case when v.CodecName = 'AMR 5.9' OR v.CodecName = 'AMR 7.4' then v.MOS_WB else null end) as HR,
		AVG(case when v.CodecName like 'AMR HR%' then v.MOS_WB else null end) as AMR_HR,
		AVG(case when v.CodecName like 'AMR FR%' then v.MOS_WB else null end) as AMR_FR,
		AVG(case when v.CodecName like 'AMR WB%' then v.MOS_WB else null end) as AMR_WB,
		'' as 'E-GSM',
		AVG(v.MOS_WB_GSM_AVG) as GSM,
		AVG(v.MOS_WB_DCS_AVG) as DCS,
		AVG(v.MOS_WB_UMTS_AVG) as UMTS,
		
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
		Agrids.dbo.lcc_parcelas lp--,
		--CA: 21/11/2016 cogemos los valores de la tabla lcc para que sean misma consideraciones que procesado
		-- Recalculate ranges of MOS --- MTP: 21/03/2016	
		--(select 
		--	s.sessionid,
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 1 and M.OptionalNB < 1.5) OR (m.bandwidth =0 and M.OptionalWB >= 1 and M.OptionalWB < 1.5) then 1 else 0 end) as 'MOS_1-1.5_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 1.5 and M.OptionalNB < 2) OR (m.bandwidth =0 and M.OptionalWB >= 1.5 and M.OptionalWB < 2) then 1 else 0 end) as 'MOS_1.5-2_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 2 and M.OptionalNB < 2.5) OR (m.bandwidth =0 and M.OptionalWB >= 2 and M.OptionalWB < 2.5) then 1 else 0 end) as 'MOS_2-2.5_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 2.5 and M.OptionalNB < 3) OR (m.bandwidth =0 and M.OptionalWB >= 2.5 and M.OptionalWB < 3) then 1 else 0 end) as 'MOS_2.5-3_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 3 and M.OptionalNB < 3.5) OR (m.bandwidth =0 and M.OptionalWB >= 3 and M.OptionalWB < 3.5) then 1 else 0 end) as 'MOS_3-3.5_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 3.5 and M.OptionalNB < 4) OR (m.bandwidth =0 and M.OptionalWB >= 3.5 and M.OptionalWB < 4) then 1 else 0 end) as 'MOS_3.5-4_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 4 and M.OptionalNB < 4.5) OR (m.bandwidth =0 and M.OptionalWB >= 4 and M.OptionalWB < 4.5) then 1 else 0 end) as 'MOS_4-4.5_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 4.5 and M.OptionalNB <= 5) OR (m.bandwidth =0 and M.OptionalWB >= 4.5 and M.OptionalWB <= 5) then 1 else 0 end) as 'MOS_4.5-5_NB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 1 and M.OptionalWB < 1.5) then 1 else 0 end) as 'MOS_1-1.5_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 1.5 and M.OptionalWB < 2) then 1 else 0 end) as 'MOS_1.5-2_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 2 and M.OptionalWB < 2.5) then 1 else 0 end) as 'MOS_2-2.5_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 2.5 and M.OptionalWB < 3) then 1 else 0 end) as 'MOS_2.5-3_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 3 and M.OptionalWB < 3.5) then 1 else 0 end) as 'MOS_3-3.5_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 3.5 and M.OptionalWB < 4) then 1 else 0 end) as 'MOS_3.5-4_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 4 and M.OptionalWB < 4.5) then 1 else 0 end) as 'MOS_4-4.5_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 4.5 and M.OptionalWB <= 5) then 1 else 0 end) as 'MOS_4.5-5_WB'
		--	from 
		--		ResultsLQ08Avg m,
		--		@All_Tests a,
		--		sessions s
		--	where a.Sessionid=m.SessionId 
		--	and a.sessionid=s.sessionid
		--	group by s.sessionid)  m
	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		--CA: 21/11/2016
		--and m.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus = 'Completed' --Discarding System Release and Not Set Calls
		and s.valid=1
		and lp.Nombre= [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A)

	group by [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A), v.mnc,lp.Region_VF,lp.Region_OSP,
		calltype, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end
else --Indoor: MOS NB
begin
	insert into @voice_pesq 
	select 
		db_name() as 'Database',
		v.mnc,
		null,
		sum (case when v.MOS_WB is not null then 1 
					when v.MOS_WB is null and v.MOS_NB is not null then 1
					else 0 end) as Calls_MOS,
		sum (case when v.MOS_NB is not null then 1 
			else 0 end) as Calls_MOS_NB,
		SUM(v.MOS_Samples_NB) as Registers_NB,
		AVG(v.MOS_NB) as MOS_NB,
		STDEV(v.MOS_NB) as MOS_NB_DESV,
		AVG(v.MOS_NB_DL) as MOS_DL_NB,
		AVG(v.MOS_NB_UL) as MOS_UL_NB,
		SUM(v.[MOS_NB_Samples_Under_2.5]) as [MOS_NB_Samples_Under_2.5],
		null as Registers,
		null as MOS,
		null as MOS_DL,
		null as MOS_UL,
		null as [MOS_Samples_Under_2.5],

		AVG(case when (v.MOS_WB is not null) then v.MOS_WB else v.MOS_NB end) as MOS_ALL,
		STDEV(case when (v.MOS_WB is not null) then v.MOS_WB else v.MOS_NB end) as MOS_ALL_DESV,
		SUM(case when v.MOS_Samples_NB = 0 and v.MOS_Samples_WB > 0 then 1 else 0 end) as Calls_WB_only,
		AVG(case when v.MOS_Samples_NB = 0 and v.MOS_Samples_WB > 0 then v.MOS_WB end) as MOS_WBOnly,
		--- MTP: 07/04/2016
		SUM(case when v.MOS_Samples_NB = 0 and v.MOS_Samples_WB > 0 and v.MOS_WB is not null then 1 else 0 end) as Calls_AVG_WB_ONLY,

		--CA: 21/11/2016 cogemos los valores de la tabla lcc para que sean misma consideraciones que procesado
		--- MTP: 21/03/2016
		--SUM(m.[MOS_1-1.5_WB]) as [1-1.5 WB],
		--SUM(m.[MOS_1.5-2_WB]) as [1.5-2 WB],
		--SUM(m.[MOS_2-2.5_WB]) as [2-2.5 WB],
		--SUM(m.[MOS_2.5-3_WB]) as [2.5-3 WB],
		--SUM(m.[MOS_3-3.5_WB]) as [3-3.5 WB],
		--SUM(m.[MOS_3.5-4_WB]) as [3.5-4 WB],
		--SUM(m.[MOS_4-4.5_WB]) as [4-4.5 WB],
		--SUM(m.[MOS_4.5-5_WB]) as [4.5-5 WB],
		--SUM(m.[MOS_1-1.5_NB]) as [1-1.5 NB],
		--SUM(m.[MOS_1.5-2_NB]) as [1.5-2 NB],
		--SUM(m.[MOS_2-2.5_NB]) as [2-2.5 NB],
		--SUM(m.[MOS_2.5-3_NB]) as [2.5-3 NB],
		--SUM(m.[MOS_3-3.5_NB]) as [3-3.5 NB],
		--SUM(m.[MOS_3.5-4_NB]) as [3.5-4 NB],
		--SUM(m.[MOS_4-4.5_NB]) as [4-4.5 NB],
		--SUM(m.[MOS_4.5-5_NB]) as [4.5-5 NB],

		null as '1-1.5 WB',
		null as '1.5-2 WB',
		null as '2-2.5 WB',
		null as '2.5-3 WB',
		null as '3-3.5 WB',
		null as '3.5-4 WB',
		null as '4-4.5 WB',
		null as '4.5-5 WB',
		SUM(v.[MOS_1-1.5_NB]) as [1-1.5 NB],
		SUM(v.[MOS_1.5-2_NB]) as [1.5-2 NB],
		SUM(v.[MOS_2-2.1_NB] + v.[MOS_2.1-2.2_NB] + v.[MOS_2.2-2.3_NB] + v.[MOS_2.3-2.4_NB] + v.[MOS_2.4-2.5_NB]) as [2-2.5 NB],
		SUM(v.[MOS_2.5-2.6_NB] + v.[MOS_2.6-2.7_NB] + v.[MOS_2.7-2.8_NB] + v.[MOS_2.8-2.9_NB] + v.[MOS_2.9-3_NB]) as [2.5-3 NB],
		SUM(v.[MOS_3-3.1_NB] + v.[MOS_3.1-3.2_NB] + v.[MOS_3.2-3.3_NB] + v.[MOS_3.3-3.4_NB] + v.[MOS_3.4-3.5_NB]) as [3-3.5 NB],
		SUM(v.[MOS_3.5-3.6_NB] + v.[MOS_3.6-3.7_NB] + v.[MOS_3.7-3.8_NB] + v.[MOS_3.8-3.9_NB] + v.[MOS_3.9-4_NB]) as [3.5-4 NB],
		SUM(v.[MOS_4-4.5_NB]) as [4-4.5 NB],
		SUM(v.[MOS_4.5-5_NB]) as [4.5-5 NB],
		---------

		AVG(case when v.CodecName = 'AMR 12.2' then v.MOS_NB else null end) as FR,
		AVG(case when v.CodecName = 'EFR' then v.MOS_NB else null end) as EFR,
		AVG(case when v.CodecName = 'AMR 5.9' OR v.CodecName = 'AMR 7.4' then v.MOS_NB else null end) as HR,
		AVG(case when v.CodecName like 'AMR HR%' then v.MOS_NB else null end) as AMR_HR,
		AVG(case when v.CodecName like 'AMR FR%' then v.MOS_NB else null end) as AMR_FR,
		AVG(case when v.CodecName like 'AMR WB%' then v.MOS_NB else null end) as AMR_WB,
		'' as 'E-GSM',
		AVG(v.MOS_NB_GSM_AVG) as GSM,
		AVG(v.MOS_NB_DCS_AVG) as DCS,
		AVG(v.MOS_NB_UMTS_AVG) as UMTS,
		
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
		Sessions s--,
		--CA: 21/11/2016 cogemos los valores de la tabla lcc para que sean misma consideraciones que procesado
		-- Recalculate ranges of MOS --- MTP: 21/03/2016
		--(select 
		--	s.sessionid,
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 1 and M.OptionalNB < 1.5) OR (m.bandwidth =0 and M.OptionalWB >= 1 and M.OptionalWB < 1.5) then 1 else 0 end) as 'MOS_1-1.5_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 1.5 and M.OptionalNB < 2) OR (m.bandwidth =0 and M.OptionalWB >= 1.5 and M.OptionalWB < 2) then 1 else 0 end) as 'MOS_1.5-2_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 2 and M.OptionalNB < 2.5) OR (m.bandwidth =0 and M.OptionalWB >= 2 and M.OptionalWB < 2.5) then 1 else 0 end) as 'MOS_2-2.5_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 2.5 and M.OptionalNB < 3) OR (m.bandwidth =0 and M.OptionalWB >= 2.5 and M.OptionalWB < 3) then 1 else 0 end) as 'MOS_2.5-3_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 3 and M.OptionalNB < 3.5) OR (m.bandwidth =0 and M.OptionalWB >= 3 and M.OptionalWB < 3.5) then 1 else 0 end) as 'MOS_3-3.5_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 3.5 and M.OptionalNB < 4) OR (m.bandwidth =0 and M.OptionalWB >= 3.5 and M.OptionalWB < 4) then 1 else 0 end) as 'MOS_3.5-4_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 4 and M.OptionalNB < 4.5) OR (m.bandwidth =0 and M.OptionalWB >= 4 and M.OptionalWB < 4.5) then 1 else 0 end) as 'MOS_4-4.5_NB',
		--	SUM(case when (m.bandwidth =0 and M.OptionalNB >= 4.5 and M.OptionalNB <= 5) OR (m.bandwidth =0 and M.OptionalWB >= 4.5 and M.OptionalWB <= 5) then 1 else 0 end) as 'MOS_4.5-5_NB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 1 and M.OptionalWB < 1.5) then 1 else 0 end) as 'MOS_1-1.5_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 1.5 and M.OptionalWB < 2) then 1 else 0 end) as 'MOS_1.5-2_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 2 and M.OptionalWB < 2.5) then 1 else 0 end) as 'MOS_2-2.5_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 2.5 and M.OptionalWB < 3) then 1 else 0 end) as 'MOS_2.5-3_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 3 and M.OptionalWB < 3.5) then 1 else 0 end) as 'MOS_3-3.5_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 3.5 and M.OptionalWB < 4) then 1 else 0 end) as 'MOS_3.5-4_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 4 and M.OptionalWB < 4.5) then 1 else 0 end) as 'MOS_4-4.5_WB',
		--	SUM(case when (m.bandwidth >0 and M.OptionalWB >= 4.5 and M.OptionalWB <= 5) then 1 else 0 end) as 'MOS_4.5-5_WB'
		--	from 
		--		ResultsLQ08Avg m,
		--		@All_Tests a,
		--		sessions s
		--	where a.Sessionid=m.SessionId 
		--	and a.sessionid=s.sessionid
		--	group by s.sessionid) m
	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		--CA: 21/11/2016
		--and m.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus = 'Completed' --Discarding System Release and Not Set Calls
		and s.valid=1

	group by v.mnc,	calltype, v.[ASideDevice], v.[SWVersion]
end

select * from @voice_pesq





