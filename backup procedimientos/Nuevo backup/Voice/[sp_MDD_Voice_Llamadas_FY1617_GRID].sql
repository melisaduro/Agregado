USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Llamadas_FY1617_GRID]    Script Date: 31/10/2017 10:36:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_Llamadas_FY1617_GRID] (
	 --Variables de entrada
		@ciudad as varchar(256),
		@simOperator as int,
		@sheet as varchar(256),				-- all: %%, 4G: 'LTE', 3G: 'WCDMA'
		--@Date as varchar (256),
		@Indoor as int,
		@Report as varchar (256),
		@ReportType as varchar(256)         -- 20170713: @MDM - Nueva variable de entrada para distinguir entre reporte VOLTE y CSFB
)
AS

-----------------------------
----- Testing Variables -----
-----------------------------
--use FY1718_VOICE_JEREZ_4G_H1

--declare @ciudad as varchar(256) = 'JEREZ'
--declare @simOperator as int = 1
--declare @sheet as varchar(256) =''
--declare @Date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @report as varchar(256) = 'MUN' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)
--declare @reportType as  varchar(256)='' --'CSFB'/'VOLTE'/'4G'/'3G' 
---------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------		  
declare @nameProc as varchar(256) ='sp_MDD_Voice_GLOBAL_FILTER'
declare @provider as varchar(256) = 'SQLNCLI11'
declare @server as varchar(256) = '10.1.12.32'
declare @Uid as varchar(256) = 'sa'
declare @Pwd as varchar(256) = 'Sw1ssqual.2015'
declare @cmd nvarchar(4000)
declare @All_Tests as table (sessionid bigint, is_VoLTE int, is_SRVCC int)


set @cmd = '
		select *		
		from  OPENROWSET ('''+ @provider +''','''+ @server +''';'''+ @Uid +''';'''+ @Pwd +''',
		''SET NOCOUNT ON;EXEC '+ db_name() +'.dbo.'+ @nameProc +' '''''+@ciudad+''''', '+convert(varchar,@simOperator)+','''''+@sheet+''''' 
		,'+convert(varchar, @Indoor)+','''''+@Report+''''','''''+@ReportType+''''''')'

insert into @All_Tests EXECUTE sp_executesql @cmd


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

--declare @week as varchar(256)
--declare @tmpDateFirst int 
--declare @tmpWeek int 

----select @tmpDateFirst = @@DATEFIRST
----if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
----	SELECT @tmpWeek =DATEPART(week, (select callendtimestamp
----						from lcc_Calls_Detailed 
----						where sessionid=(select max(c.sessionid) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)))
----else
----	begin
----		SET DATEFIRST 1;  --Primer dia de la semana lunes
----		SELECT @tmpWeek =DATEPART(week, (select callendtimestamp
----						from lcc_Calls_Detailed 
----						where sessionid=(select max(c.sessionid) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)))
----		SET DATEFIRST @tmpDateFirst; --dejamos como primer dia de la semana que el que estaba configurado

----	end

--select @tmpDateFirst = @@DATEFIRST
--if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
--	set @tmpWeek =DATEPART(week, @dateMax)
--else
--	begin
--		SET DATEFIRST 1;  --Primer dia de la semana lunes
--		set @tmpWeek =DATEPART(week, @dateMax)
--		SET DATEFIRST @tmpDateFirst; --dejamos como primer dia de la semana que el que estaba configurado

--	end

--set @week = 'W' + convert(varchar, @tmpWeek)

declare @week as varchar(256)
set @week = 'W' +convert(varchar,DATEPART(iso_week, @dateMax))


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
	Setup_Time numeric(17, 14), 
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
	Handover_Failures int, 
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
	[Region_VF] varchar(256), 
	Num_Medida varchar(256), 
	CR_Affected_Calls int,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP] [varchar](256) NULL,
	[Calltype] [varchar](256) null,
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL,
	--@MDM: 20170823 - se añade el campo is_csfb 
	is_csfb int
)

if (@Indoor=0 OR @Indoor=2)
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
		SUM(case when v.Technology like 'LTE%' then 1 else 0 end) As Started_4G,-- ME:cambio el día 10042017 ya que estaba v.technology like '%LTE%', con lo que technology=UMTS/LTE lo cuenta LTE
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
		'GRID',
		lp.Region_OSP as Region_OSP,
		calltype,
		v.[ASideDevice],
		v.[BSideDevice],
		v.[SWVersion],

		--@MDM: 20170823 - se añade el campo is_csfb 
		sum(v.is_csfb) as is_csfb

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

	group by [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A), v.mnc,lp.Region_VF,lp.Region_OSP, calltype
			, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
	
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
		SUM(case when v.Technology like 'LTE%' then 1 else 0 end) As Started_4G, -- ME:cambio el día 10042017 ya que estaba v.technology like '%LTE%', con lo que technology=UMTS/LTE lo cuenta LTE
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
		'GRID',
		null,
		calltype,
		v.[ASideDevice],
		'Fixed' as 'BSideDevice',
		v.[SWVersion],

		--@MDM: 20170823 - se añade el campo is_csfb 
		sum(v.is_csfb) as is_csfb

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