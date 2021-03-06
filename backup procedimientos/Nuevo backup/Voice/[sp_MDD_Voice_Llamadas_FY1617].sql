USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Llamadas_FY1617]    Script Date: 31/10/2017 10:30:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_Llamadas_FY1617] (
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

--use FY1617_Voice_Smaller_VOLTE
--declare @ciudad as varchar(256) = 'DONOSTI'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @sheet as varchar(256) ='%%'
--declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests as table (sessionid bigint, is_VoLTE int, is_SRVCC int)
declare @filtroTech as varchar(1024)  
declare @operator as varchar(256)

if @sheet = '%%'
	set @filtroTech = ''

else if @sheet = 'LTE' or @sheet = 'VOLTE'
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

insert into @All_Tests
exec ('select v.sessionid, v.is_VOLTE, v.is_SRVCC
from lcc_Calls_Detailed v
Where v.collectionname like '''+ @Date + '%' + @ciudad + '%' +'''
	and v.MNC = '+ @operator +'	--MNC
	and v.MCC= 214				--MCC - Descartamos los valores erróneos
	and callStatus in (''Completed'',''Failed'',''Dropped'')
	'+	@filtroTech+'
	group by v.sessionid, v.is_VOLTE, v.is_SRVCC')


if @sheet = 'VOLTE'
begin
	delete from @All_Tests where (is_VoLTE is NULL or is_VoLTE<>2 or (is_volte=2 and is_SRVCC>0))
end



------ Metemos en variables algunos campos calculados ----------------

declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

declare @dateMax datetime2(3)= (select max(c.callEndTimeStamp) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

--declare @Meas_Date as varchar(256)= (select max(right(convert(varchar(256),datepart(yy, callendtimestamp)),2) + '_'	 + convert(varchar(256),format(callendtimestamp,'MM')))
--	from lcc_Calls_Detailed where sessionid=(select max(c.sessionid) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from lcc_calls_detailed v, @All_Tests s where s.sessionid=v.sessionid group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max([master].dbo.fn_lcc_getElement(5, v.collectionname,'_')) from lcc_calls_detailed v, @All_Tests s where s.sessionid=v.sessionid)-- group by [master].dbo.fn_lcc_getElement(5, v.collectionname,'_'))

declare @week as varchar(256)
declare @tmpDateFirst int 
declare @tmpWeek int 

--select @tmpDateFirst = @@DATEFIRST
--if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
--	SELECT @tmpWeek =DATEPART(week, (select callendtimestamp
--						from lcc_Calls_Detailed 
--						where sessionid=(select max(c.sessionid) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)))
--else
--	begin
--		SET DATEFIRST 1;  --Primer dia de la semana lunes
--		SELECT @tmpWeek =DATEPART(week, (select callendtimestamp
--						from lcc_Calls_Detailed 
--						where sessionid=(select max(c.sessionid) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)))
--		SET DATEFIRST @tmpDateFirst; --dejamos como primer dia de la semana que el que estaba configurado

--	end

select @tmpDateFirst = @@DATEFIRST
if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
	set @tmpWeek =DATEPART(week, @dateMax)
else
	begin
		SET DATEFIRST 1;  --Primer dia de la semana lunes
		set @tmpWeek =DATEPART(week, @dateMax)
		SET DATEFIRST @tmpDateFirst; --dejamos como primer dia de la semana que el que estaba configurado

	end

set @week = 'W' + convert(varchar, @tmpWeek)
------------------------------------------------------------------------------------
------------------------------- GENERAL SELECT
------------- Calls Related Main Info, Samples per Tech and Codec
------------------------------------------------------------------------------------
declare @voice_calls  as table (
	[Database] nvarchar(128), 
	mnc varchar(2), 
	Parcel varchar(50), 
	MO_Succeeded int, 
	MO_Blocks int, 
	MO_Drops int, 
	MT_Succeeded int, 
	MT_Blocks int, 
	MT_Drops int ,
	SQNS_NB int, 
	SQNS_WB int, 
	Silent int, 
	Duration numeric(38, 6), 
	Speech_Delay float, 
	Setup_Time numeric(17, 6), 
	Started_2G int, 
	Started_3G int, 
	Started_4G int, 
	[2G_To_3G] int, 
	[3G_To_2G] int,
	Started_Ended_3G_Comp int,
	Started_Ended_2G_Comp int,
	Calls_Mixed_Comp int,
	Started_4G_Comp int,
	Duration_3G numeric(38, 6),
	Duration_2G numeric(38, 6),
	GSM_calls_After_CSFB_Comp int,
	UMTS_calls_After_CSFB_Comp int,
	Handovers int, 
	Handover_Failures int , 
	E_GSM_Registers varchar(1), 
	GSM_Registers int, 
	DCS_Registers int, 
	UMTS_Registers int,
	FR int, 
	EFR int, 
	HR int, 
	AMR_HR int, 
	AMR_FR int,
	AMR_WB int, 
	[Codec_Registers] int, 
	[HR_Count] int,
	[FR_Count] int,
	[EFR_Count] int, 
	[AMR_HR_Count] int,
	[AMR_FR_Count] int,
	[AMR_WB_Count] int,
	[AMR_WB_HD_Count] int,
	[Meas_Week] [varchar](3) NULL,
	Meas_Round varchar(256), 
	Meas_Date varchar(256), 
	Entidad varchar(256),
	[Region_VF] [varchar](256), 
	Num_Medida varchar(256), 
	CR_Affected_Calls int,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP] [varchar](256),
	[calltype][varchar](256) NULL,
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL
)

if @Indoor=0
begin
	insert into @voice_calls 
	select 
		db_name() as 'Database',
		v.mnc,
		[master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A) as Parcel,
		sum (case when (v.callDir='MO' and v.callStatus='Completed') then 1 else 0 end) as MO_Succeeded,
		SUM (case when (v.callDir='MO' and v.callStatus='Failed') then 1 else 0 end) as MO_Blocks,
		SUM (case when (v.callDir='MO' and v.callStatus='Dropped') then 1 else 0 end) as MO_Drops,
		sum (case when (v.callDir='MT' and v.callStatus='Completed') then 1 else 0 end) as MT_Succeeded,
		SUM (case when (v.callDir='MT' and v.callStatus='Failed') then 1 else 0 end) as MT_Blocks,
		SUM (case when (v.callDir='MT' and v.callStatus='Dropped') then 1 else 0 end) as MT_Drops,
		
		-- MTP: 27/04/2016 Sólo completas en el cálculo del SQNS
		--sum(v.SQNS_NB) as SQNS_NB,
		--sum(v.SQNS_WB) as SQNS_WB,
		sum(case when (v.callStatus='Completed') then v.SQNS_NB else 0 end) as SQNS_NB,
		sum(case when (v.callStatus='Completed') then v.SQNS_WB else 0 end ) as SQNS_WB,

		SUM (v.Silent_call) as Silent,
		AVG(v.callDuration) as Duration,
		AVG(v.Speech_Delay) as Speech_Delay,
		AVG(case when v.callDir in ('MO','MT') then v.cst_till_alerting end)/1000.0 as Setup_Time,
		SUM(case when v.Technology like 'GSM%' then 1 else 0 end) As Started_2G,
		SUM(case when v.Technology like 'UMTS%' then 1 else 0 end) As Started_3G,
		SUM(case when v.Technology like '%LTE%' then 1 else 0 end) As Started_4G,
		SUM(case when v.StartTechnology ='GSM' and v.EndTechnology like 'UMTS%' then 1 else 0 end) As [2G_To_3G],
		SUM(case when v.StartTechnology ='UMTS' and v.EndTechnology like 'GSM%' then 1 else 0 end) As [3G_To_2G],



		-- MODIF. 18/02/2016 MTP: Se actualiza la forma de contar las llamadas para tener en cuenta los 2 moviles
		------------------
		--SUM(case when (v.Technology = 'UMTS' and v.is_csfb=0 and v.callstatus='Completed') then 1 else 0 end) As Started_Ended_3G_Comp,
		--SUM(case when (v.Technology = 'GSM' and v.is_csfb=0 and v.callstatus='Completed') then 1 else 0 end) As Started_Ended_2G_Comp,
		--SUM(case when (v.Technology like '%/%' and v.Technology <> 'LTE' and v.is_csfb=0 and v.callstatus='Completed') then 1 else 0 end) As Calls_Mixed_Comp,
		--SUM(case when (v.Technology = 'LTE' or v.is_csfb=1) and v.callstatus='Completed' then 1 else 0 end) As Started_4G_Comp,
		--isnull(SUM(v.UMTS_Duration),0) as Duration_3G,
		--isnull(SUM(v.GSM_Duration),0) as Duration_2G,
		--SUM(case when (v.is_csfb=1 and v.cmService_band like 'GSM%' and v.callstatus='Completed') then 1 else 0 end) as GSM_calls_After_CSFB_Comp,
		--SUM(case when (v.is_csfb=1 and v.cmService_band like 'UMTS%' and v.callstatus='Completed') then 1 else 0 end) as UMTS_calls_After_CSFB_Comp,

		--SUM(case when (v.is_csfb=1 and (v.technology='LTE /GSM' or v.technology like 'GSM%')and v.callstatus='Completed') then 1 else 0 end) as GSM_calls_After_CSFB_Comp,
		--SUM(case when (v.is_csfb=1 and (v.technology='LTE /UMTS' or v.technology like 'UMTS%') and v.callstatus='Completed') then 1 else 0 end) as UMTS_calls_After_CSFB_Comp,
		------------------
		SUM(case 
			when ((left(v.cmservice_band,4) = 'UMTS' and left(v.disconnect_band,4) = 'UMTS' and v.CSFB_Device = '') and (left(v.cmservice_band_B,4) = 'UMTS' and left(v.disconnect_band_B,4) = 'UMTS' and v.CSFB_Device = '') and v.is_csfb=0 and v.callstatus in ('Completed','Dropped')) then 2
			when (((left(v.cmservice_band,4) = 'UMTS' and left(v.disconnect_band,4) = 'UMTS' and v.CSFB_Device <> 'A') or (left(v.cmservice_band_B,4) = 'UMTS' and left(v.disconnect_band_B,4) = 'UMTS' and v.CSFB_Device <> 'B')) and v.is_csfb<2 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) As Started_Ended_3G_Comp,
		SUM(case 
			when ((left(v.cmservice_band,3) = 'GSM' and left(v.disconnect_band,3) = 'GSM' and v.CSFB_Device = '') and (left(v.cmservice_band_B,3) = 'GSM' and left(v.disconnect_band_B,3) = 'GSM' and v.CSFB_Device = '') and v.is_csfb=0 and v.callstatus in ('Completed','Dropped')) then 2
			when (((left(v.cmservice_band,3) = 'GSM' and left(v.disconnect_band,3) = 'GSM' and v.CSFB_Device <> 'A') or (left(v.cmservice_band_B,3) = 'GSM' and left(v.disconnect_band_B,3) = 'GSM' and v.CSFB_Device <> 'B')) and v.is_csfb<2 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) As Started_Ended_2G_Comp,
		SUM(case 
			when (((left(v.cmservice_band,3) <> left(v.disconnect_band,3) and v.CSFB_Device = '') and (left(v.cmservice_band_B,3) <> left(v.disconnect_band_B,3) and v.CSFB_Device = '')) and v.is_csfb=0 and v.callstatus in ('Completed','Dropped')) then 2
			when (((left(v.cmservice_band,3) <> left(v.disconnect_band,3) and v.CSFB_Device <> 'A') or (left(v.cmservice_band_B,3) <> left(v.disconnect_band_B,3) and v.CSFB_Device <> 'B')) and v.is_csfb<2 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) As Calls_Mixed_Comp,
		SUM(case when (v.Technology = 'LTE' or v.Technology_Bside = 'LTE' or v.is_csfb>0 or v.is_VoLTE>0) and v.callstatus in ('Completed','Dropped') then v.is_csfb+v.is_VOLTE else 0 end) As Started_4G_Comp,
		isnull(SUM(v.UMTS_Duration),0) as Duration_3G,
		isnull(SUM(v.GSM_Duration),0) as Duration_2G,
		SUM(case 
			when (((v.cmService_band like 'GSM%' and v.CSFB_device like '%A%') and (v.cmService_band_B like 'GSM%' and v.CSFB_device like '%B%')) and v.is_csfb=2 and v.callstatus in ('Completed','Dropped')) then 2 
			when (((v.cmService_band like 'GSM%' and v.CSFB_device = 'A') or (v.cmService_band_B like 'GSM%' and v.CSFB_device = 'B')) and v.is_csfb>0 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) as GSM_calls_After_CSFB_Comp,
		SUM(case 
			when (((v.cmService_band like 'UMTS%' and v.CSFB_device like '%A%') and (v.cmService_band_B like 'UMTS%' and v.CSFB_device like '%B%')) and v.is_csfb=2 and v.callstatus in ('Completed','Dropped')) then 2 
			when (((v.cmService_band like 'UMTS%' and v.CSFB_device = 'A') or (v.cmService_band_B like 'UMTS%' and v.CSFB_device = 'B')) and v.is_csfb>0 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) as UMTS_calls_After_CSFB_Comp,
		------------------
		SUM(v.Handovers) as Handovers,
		SUM(v.Handover_Failures) as Handover_Failures,
		'' as E_GSM_Registers,
		SUM(v.MOS_GSM_Samples) as GSM_Registers,
		SUM(v.MOS_DCS_Samples)as DCS_Registers,
		SUM(v.MOS_UMTS_Samples)as UMTS_Registers,
		SUM(case when v.CodecName = 'AMR 12.2' OR v.codecName = 'AMR 4.75' then 1 else 0 end) as FR,
		SUM(case when v.CodecName = 'EFR' then 1 else 0 end) as EFR,
		SUM(case when v.CodecName = 'AMR 5.9' OR v.CodecName = 'AMR 7.4' then 1 else 0 end) as HR,
		SUM(case when v.CodecName like 'AMR HR%' then 1 else 0 end) as AMR_HR,
		SUM(case when v.CodecName like 'AMR FR%' then 1 else 0 end) as AMR_FR,
		SUM(case when v.CodecName like 'AMR WB%' then 1 else 0 end) as AMR_WB,
		
		--CA 04/07/2016 OSP:(arriba tb se calcula el nº de registros por codec, pero en estos campos nos aseguramos que
		--las condiciones sean siempre iguales a los empleados en tabla intermedia)
		sum(v.Codec_Registers) as Codec_Registers,
		sum(v.HR_Count) as [HR_Count],
		sum(v.FR_Count) as [FR_Count],
		sum(v.EFR_Count) as [EFR_Count],
		sum(v.AMR_HR_Count) as [AMR_HR_Count],
		sum(v.AMR_FR_Count) as [AMR_FR_Count],
		sum(v.AMR_WB_Count) as [AMR_WB_Count],

		sum(v.AMR_WB_HD_Count) as [AMR_WB_HD_Count],


		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null as 'Num_Medida',
		sum(v.CR_Affected_Calls) as CR_Affected_Calls,
		@Report,
		'Collection Name',
		lp.Region_OSP as Region_OSP,
		calltype,
		v.[ASideDevice],
		v.[BSideDevice],
		v.[SWVersion]
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

	group by [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A), v.mnc,lp.Region_VF,lp.Region_OSP
		, calltype, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
	
end
else
begin
	insert into @voice_calls
	select 
		db_name() as 'Database',
		v.mnc,
		null,
		sum (case when (v.callDir='MO' and v.callStatus='Completed') then 1 else 0 end) as MO_Succeeded,
		SUM (case when (v.callDir='MO' and v.callStatus='Failed') then 1 else 0 end) as MO_Blocks,
		SUM (case when (v.callDir='MO' and v.callStatus='Dropped') then 1 else 0 end) as MO_Drops,
		sum (case when (v.callDir='MT' and v.callStatus='Completed') then 1 else 0 end) as MT_Succeeded,
		SUM (case when (v.callDir='MT' and v.callStatus='Failed') then 1 else 0 end) as MT_Blocks,
		SUM (case when (v.callDir='MT' and v.callStatus='Dropped') then 1 else 0 end) as MT_Drops,
		
		-- MTP: 27/04/2016 Sólo completas en el cálculo del SQNS
		--sum(v.SQNS_NB) as SQNS_NB,
		--sum(v.SQNS_WB) as SQNS_WB,	
		sum(case when (v.callStatus='Completed') then v.SQNS_NB else 0 end) as SQNS_NB,
		sum(case when (v.callStatus='Completed') then v.SQNS_WB else 0 end ) as SQNS_WB,
			
		SUM (v.Silent_call) as Silent,
		AVG(v.callDuration) as Duration,
		AVG(v.Speech_Delay) as Speech_Delay,
		AVG(case when v.callDir in ('MO','MT') then v.cst_till_alerting end)/1000.0 as Setup_Time,
		SUM(case when v.Technology like 'GSM%' then 1 else 0 end) As Started_2G,
		SUM(case when v.Technology like 'UMTS%' then 1 else 0 end) As Started_3G,
		SUM(case when v.Technology like '%LTE%' then 1 else 0 end) As Started_4G,
		SUM(case when v.StartTechnology ='GSM' and v.EndTechnology like 'UMTS%' then 1 else 0 end) As [2G_To_3G],
		SUM(case when v.StartTechnology ='UMTS' and v.EndTechnology like 'GSM%' then 1 else 0 end) As [3G_To_2G],
		
		-- MODIF. 18/02/2016 MTP: Se actualiza la forma de contar las llamadas para tener en cuenta los 2 moviles
		------------------
		--SUM(case when (v.Technology = 'UMTS' and v.is_csfb=0 and v.callstatus='Completed') then 1 else 0 end) As Started_Ended_3G_Comp,
		--SUM(case when (v.Technology = 'GSM' and v.is_csfb=0 and v.callstatus='Completed') then 1 else 0 end) As Started_Ended_2G_Comp,
		--SUM(case when (v.Technology like '%/%' and v.Technology <> 'LTE' and v.is_csfb=0 and v.callstatus='Completed') then 1 else 0 end) As Calls_Mixed_Comp,
		--SUM(case when (v.Technology = 'LTE' or v.is_csfb=1) and v.callstatus='Completed' then 1 else 0 end) As Started_4G_Comp,
		--isnull(SUM(v.UMTS_Duration),0) as Duration_3G,
		--isnull(SUM(v.GSM_Duration),0) as Duration_2G,
		--SUM(case when (v.is_csfb=1 and v.cmService_band like 'GSM%' and v.callstatus='Completed') then 1 else 0 end) as GSM_calls_After_CSFB_Comp,
		--SUM(case when (v.is_csfb=1 and v.cmService_band like 'UMTS%' and v.callstatus='Completed') then 1 else 0 end) as UMTS_calls_After_CSFB_Comp,
		------------------
		--SUM(case when (v.is_csfb=1 and (v.technology='LTE /GSM' or v.technology like 'GSM%')and v.callstatus='Completed') then 1 else 0 end) as GSM_calls_After_CSFB_Comp,
		--SUM(case when (v.is_csfb=1 and (v.technology='LTE /UMTS' or v.technology like 'UMTS%') and v.callstatus='Completed') then 1 else 0 end) as UMTS_calls_After_CSFB_Comp,
		------------------
		SUM(case 
			when ((left(v.cmservice_band,4) = 'UMTS' and left(v.disconnect_band,4) = 'UMTS' and v.CSFB_Device = '') and (left(v.cmservice_band_B,4) = 'UMTS' and left(v.disconnect_band_B,4) = 'UMTS' and v.CSFB_Device = '') and v.is_csfb=0 and v.callstatus in ('Completed','Dropped')) then 2
			when (((left(v.cmservice_band,4) = 'UMTS' and left(v.disconnect_band,4) = 'UMTS' and v.CSFB_Device <> 'A') or (left(v.cmservice_band_B,4) = 'UMTS' and left(v.disconnect_band_B,4) = 'UMTS' and v.CSFB_Device <> 'B')) and v.is_csfb<2 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) As Started_Ended_3G_Comp,
		SUM(case 
			when ((left(v.cmservice_band,3) = 'GSM' and left(v.disconnect_band,3) = 'GSM' and v.CSFB_Device = '') and (left(v.cmservice_band_B,3) = 'GSM' and left(v.disconnect_band_B,3) = 'GSM' and v.CSFB_Device = '') and v.is_csfb=0 and v.callstatus in ('Completed','Dropped')) then 2
			when (((left(v.cmservice_band,3) = 'GSM' and left(v.disconnect_band,3) = 'GSM' and v.CSFB_Device <> 'A') or (left(v.cmservice_band_B,3) = 'GSM' and left(v.disconnect_band_B,3) = 'GSM' and v.CSFB_Device <> 'B')) and v.is_csfb<2 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) As Started_Ended_2G_Comp,
		SUM(case 
			when (((left(v.cmservice_band,3) <> left(v.disconnect_band,3) and v.CSFB_Device = '') and (left(v.cmservice_band_B,3) <> left(v.disconnect_band_B,3) and v.CSFB_Device = '')) and v.is_csfb=0 and v.callstatus in ('Completed','Dropped')) then 2
			when (((left(v.cmservice_band,3) <> left(v.disconnect_band,3) and v.CSFB_Device <> 'A') or (left(v.cmservice_band_B,3) <> left(v.disconnect_band_B,3) and v.CSFB_Device <> 'B')) and v.is_csfb<2 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) As Calls_Mixed_Comp,
				SUM(case when (v.Technology = 'LTE' or v.Technology_Bside = 'LTE' or v.is_csfb>0 or v.is_VoLTE>0) and v.callstatus in ('Completed','Dropped') then v.is_csfb+v.is_VOLTE else 0 end) As Started_4G_Comp,
		isnull(SUM(v.UMTS_Duration),0) as Duration_3G,
		isnull(SUM(v.GSM_Duration),0) as Duration_2G,
		SUM(case 
			when (((v.cmService_band like 'GSM%' and v.CSFB_device like '%A%') and (v.cmService_band_B like 'GSM%' and v.CSFB_device like '%B%')) and v.is_csfb=2 and v.callstatus in ('Completed','Dropped')) then 2 
			when (((v.cmService_band like 'GSM%' and v.CSFB_device = 'A') or (v.cmService_band_B like 'GSM%' and v.CSFB_device = 'B')) and v.is_csfb>0 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) as GSM_calls_After_CSFB_Comp,
		SUM(case 
			when (((v.cmService_band like 'UMTS%' and v.CSFB_device like '%A%') and (v.cmService_band_B like 'UMTS%' and v.CSFB_device like '%B%')) and v.is_csfb=2 and v.callstatus in ('Completed','Dropped')) then 2 
			when (((v.cmService_band like 'UMTS%' and v.CSFB_device = 'A') or (v.cmService_band_B like 'UMTS%' and v.CSFB_device = 'B')) and v.is_csfb>0 and v.callstatus in ('Completed','Dropped')) then 1 
			else 0 
			end) as UMTS_calls_After_CSFB_Comp,
		------------------

		SUM(v.Handovers) as Handovers,
		SUM(v.Handover_Failures) as Handover_Failures,
		'' as E_GSM_Registers,
		SUM(v.MOS_GSM_Samples) as GSM_Registers,
		SUM(v.MOS_DCS_Samples)as DCS_Registers,
		SUM(v.MOS_UMTS_Samples)as UMTS_Registers,
		SUM(case when v.CodecName = 'AMR 12.2' OR v.codecName = 'AMR 4.75' then 1 else 0 end) as FR,
		SUM(case when v.CodecName = 'EFR' then 1 else 0 end) as EFR,
		SUM(case when v.CodecName = 'AMR 5.9' OR v.CodecName = 'AMR 7.4' then 1 else 0 end) as HR,
		SUM(case when v.CodecName like 'AMR HR%' then 1 else 0 end) as AMR_HR,
		SUM(case when v.CodecName like 'AMR FR%' then 1 else 0 end) as AMR_FR,
		SUM(case when v.CodecName like 'AMR WB%' then 1 else 0 end) as AMR_WB,
		
		--CA 04/07/2016 OSP:(arriba tb se calcula el nº de registros por codec, pero en estos campos nos aseguramos que
		--las condiciones sean siempre iguales a los empleados en tabla intermedia)
		sum(v.Codec_Registers) as Codec_Registers,
		sum(v.HR_Count) as [HR_Count],
		sum(v.FR_Count) as [FR_Count],
		sum(v.EFR_Count) as [EFR_Count],
		sum(v.AMR_HR_Count) as [AMR_HR_Count],
		sum(v.AMR_FR_Count) as [AMR_FR_Count],
		sum(v.AMR_WB_Count) as [AMR_WB_Count],
		sum(v.AMR_WB_HD_Count) as [AMR_WB_HD_Count],

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		sum(v.CR_Affected_Calls) as CR_Affected_Calls,
		@Report,
		'Collection Name',
		null,
		calltype,
		v.[ASideDevice],
		'Fixed' as 'BSideDevice',
		v.[SWVersion]
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

	group by  v.mnc, calltype, v.[ASideDevice], v.[SWVersion]

end

select * from @voice_calls





-------------- Espacio reservado para acumular en BBDD de agregados ------------------

--------------------------------------------------------------------------------------

--drop table _voice_calls --@All_Tests, 