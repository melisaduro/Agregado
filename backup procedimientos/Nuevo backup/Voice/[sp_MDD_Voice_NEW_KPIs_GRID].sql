USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_NEW_KPIs_GRID]    Script Date: 31/10/2017 13:25:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_NEW_KPIs_GRID] (
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
--declare @sheet as varchar(256) ='LTE'
--declare @Date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)
--declare @reportType as  varchar(256)='' --'CSFB'/'VOLTE'/'4G'/'3G' 
-------------------------------------------------------------------------------
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


declare @week as varchar(256)
set @week = 'W' +convert(varchar,DATEPART(iso_week, @dateMax))

------------------------------------------------------------------------------------
------------------------------- GENERAL SELECT
---------------------- Call Setup Time Disaggregated Info
------------------------------------------------------------------------------------
declare @voice_cst  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	
	[MO_CallType] [int] NULL,
	[MT_CallType] [int] NULL,
	[Calls_CSFB_MO] [int] NULL,
	[Calls_CSFB_MT] [int] NULL,
	[Calls_CSFB_MOMT] [int] NULL,
	[CSFB_MO] [float] NULL,
	[CSFB_MT] [float] NULL,
	[CSFB_MOMT] [float] NULL,	
	[Calls_CST_MO_ALERT_UMTS] [int] NULL,
	[Calls_CST_MT_ALERT_UMTS] [int] NULL,
	[Calls_CST_MOMT_ALERT_UMTS] [int] NULL,
	[CST_MO_ALERT_UMTS] [float] NULL,
	[CST_MT_ALERT_UMTS] [float] NULL,
	[CST_MOMT_ALERT_UMTS] [float] NULL,
	[Calls_CST_MO_ALERT_UMTS900] [int] NULL,
	[Calls_CST_MT_ALERT_UMTS900] [int] NULL,
	[Calls_CST_MOMT_ALERT_UMTS900] [int] NULL,
	[CST_MO_ALERT_UMTS900] [float] NULL,
	[CST_MT_ALERT_UMTS900] [float] NULL,
	[CST_MOMT_ALERT_UMTS900] [float] NULL,
	[Calls_CST_MO_ALERT_UMTS2100] [int] NULL,
	[Calls_CST_MT_ALERT_UMTS2100] [int] NULL,
	[Calls_CST_MOMT_ALERT_UMTS2100] [int] NULL,
	[CST_MO_ALERT_UMTS2100] [float] NULL,
	[CST_MT_ALERT_UMTS2100] [float] NULL,
	[CST_MOMT_ALERT_UMTS2100] [float] NULL,	
	[Calls_CST_MO_ALERT_GSM] [int] NULL,
	[Calls_CST_MT_ALERT_GSM] [int] NULL,
	[Calls_CST_MOMT_ALERT_GSM] [int] NULL,
	[CST_MO_ALERT_GSM] [float] NULL,
	[CST_MT_ALERT_GSM] [float] NULL,
	[CST_MOMT_ALERT_GSM] [float] NULL,
	[Calls_CST_MO_ALERT_GSM900] [int] NULL,
	[Calls_CST_MT_ALERT_GSM900] [int] NULL,
	[Calls_CST_MOMT_ALERT_GSM900] [int] NULL,
	[CST_MO_ALERT_GSM900] [float] NULL,
	[CST_MT_ALERT_GSM900] [float] NULL,
	[CST_MOMT_ALERT_GSM900] [float] NULL,
	[Calls_CST_MO_ALERT_GSM1800] [int] NULL,
	[Calls_CST_MT_ALERT_GSM1800] [int] NULL,
	[Calls_CST_MOMT_ALERT_GSM1800] [int] NULL,
	[CST_MO_ALERT_GSM1800] [float] NULL,
	[CST_MT_ALERT_GSM1800] [float] NULL,
	[CST_MOMT_ALERT_GSM1800] [float] NULL,
	[Calls_CST_MO_CONNECT_UMTS] [int] NULL,
	[Calls_CST_MT_CONNECT_UMTS] [int] NULL,
	[Calls_CST_MOMT_CONNECT_UMTS] [int] NULL,
	[CST_MO_CONNECT_UMTS] [float] NULL,
	[CST_MT_CONNECT_UMTS] [float] NULL,
	[CST_MOMT_CONNECT_UMTS] [float] NULL,
	[Calls_CST_MO_CONNECT_UMTS900] [int] NULL,
	[Calls_CST_MT_CONNECT_UMTS900] [int] NULL,
	[Calls_CST_MOMT_CONNECT_UMTS900] [int] NULL,
	[CST_MO_CONNECT_UMTS900] [float] NULL,
	[CST_MT_CONNECT_UMTS900] [float] NULL,
	[CST_MOMT_CONNECT_UMTS900] [float] NULL,
	[Calls_CST_MO_CONNECT_UMTS2100] [int] NULL,
	[Calls_CST_MT_CONNECT_UMTS2100] [int] NULL,
	[Calls_CST_MOMT_CONNECT_UMTS2100] [int] NULL,
	[CST_MO_CONNECT_UMTS2100] [float] NULL,
	[CST_MT_CONNECT_UMTS2100] [float] NULL,
	[CST_MOMT_CONNECT_UMTS2100] [float] NULL,	
	[Calls_CST_MO_CONNECT_GSM] [int] NULL,
	[Calls_CST_MT_CONNECT_GSM] [int] NULL,
	[Calls_CST_MOMT_CONNECT_GSM] [int] NULL,
	[CST_MO_CONNECT_GSM] [float] NULL,
	[CST_MT_CONNECT_GSM] [float] NULL,
	[CST_MOMT_CONNECT_GSM] [float] NULL,
	[Calls_CST_MO_CONNECT_GSM900] [int] NULL,
	[Calls_CST_MT_CONNECT_GSM900] [int] NULL,
	[Calls_CST_MOMT_CONNECT_GSM900] [int] NULL,
	[CST_MO_CONNECT_GSM900] [float] NULL,
	[CST_MT_CONNECT_GSM900] [float] NULL,
	[CST_MOMT_CONNECT_GSM900] [float] NULL,
	[Calls_CST_MO_CONNECT_GSM1800] [int] NULL,
	[Calls_CST_MT_CONNECT_GSM1800] [int] NULL,
	[Calls_CST_MOMT_CONNECT_GSM1800] [int] NULL,
	[CST_MO_CONNECT_GSM1800] [float] NULL,
	[CST_MT_CONNECT_GSM1800] [float] NULL,
	[CST_MOMT_CONNECT_GSM1800] [float] NULL,
	--Nuevos KPIs 11/01/2017
	Samples_2G [int] NULL,
	MOS_2G [float] NULL,
	Samples_3G [int] NULL,
	MOS_3G [float] NULL,
	Samples_4G [int] NULL,
	MOS_4G [float] NULL,
	Samples_GSM900 [int] NULL,
	MOS_GSM900 [float] NULL,
	Samples_GSM1800 [int] NULL,
	MOS_GSM1800 [float] NULL,
	Samples_UMTS900 [int] NULL,
	MOS_UMTS900 [float] NULL,
	Samples_UMTS2100 [int] NULL,
	MOS_UMTS2100 [float] NULL,
	Samples_LTE800 [int] NULL,
	MOS_LTE800 [float] NULL,
	Samples_LTE1800 [int] NULL,
	MOS_LTE1800 [float] NULL,
	Samples_LTE2100 [int] NULL,
	MOS_LTE2100 [float] NULL,
	Samples_LTE2600 [int] NULL,
	MOS_LTE2600 [float] NULL,
	Duration_4G [numeric](26, 6) NULL,
	Duration_LTE2600 [numeric](26, 6) NULL,
	Duration_LTE2100 [numeric](26, 6) NULL,
	Duration_LTE1800 [numeric](26, 6) NULL,
	Duration_LTE800 [numeric](26, 6) NULL,
	Duration_UMTS2100 [numeric](26, 6) NULL,
	Duration_UMTS900 [numeric](26, 6) NULL,
	Duration_GSM900 [numeric](26, 6) NULL,
	Duration_GSM1800 [numeric](26, 6) NULL,
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

if (@Indoor=0 OR @Indoor=2)
begin
	insert into @voice_cst
	select
		db_name() as 'Database',
		v.mnc,
		[master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A) as Parcel,
		sum (case when v.callstatus = 'Completed' then (case when v.callDir='MO' then 1 else 0 end) end) as MO_CallType,
		sum (case when v.callstatus = 'Completed' then (case when v.callDir='MT' then 1 else 0 end) end) as MT_CallType,
		------------------------------------------------
		--CSFB
		------------------------------------------------
		sum (case when v.callstatus = 'Completed' then (case when v.callDir='MO' and v.csfb_till_connRel is not null then 1 else 0 end) end) [Calls_CSFB_MO],
		sum (case when v.callstatus = 'Completed' then (case when v.callDir='MT' and v.csfb_till_connRel is not null then 1 else 0 end) end) [Calls_CSFB_MT],
		sum (case when v.callstatus = 'Completed' then (case when v.csfb_till_connRel is not null then 1 else 0 end) end) [Calls_CSFB_MOMT],
		
		AVG(case when v.callstatus = 'Completed' then (case when v.callDir = 'MO' then 1.0* v.csfb_till_connRel end) end)/1000.0 as CSFB_MO,
		AVG(case when v.callstatus = 'Completed' then (case when v.callDir = 'MT' then 1.0* v.csfb_till_connRel end) end)/1000.0 as CSFB_MT,
		AVG(case when v.callstatus = 'Completed' then (v.csfb_till_connRel/1000.0) end) as CSFB_MOMT,
		
		------------------------------------------------
		--CST Tecnologia-Banda (respecto a la parte A)
		------------------------------------------------
		--UMTS ALERT
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_UMTS],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_UMTS],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_UMTS],

		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_UMTS,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_UMTS,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_UMTS,
		--UMTS900 ALERT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_UMTS900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_UMTS900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_UMTS900],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_UMTS900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_UMTS900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_UMTS900,

		--UMTS2100 ALERT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_UMTS2100],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_UMTS2100],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_UMTS2100],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_UMTS2100,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_UMTS2100,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_UMTS2100,
		--GSM ALERT
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_GSM],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_GSM],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_GSM],

		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_GSM,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_GSM,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_GSM,
		--GSM900 ALERT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_GSM900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_GSM900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_GSM900],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_GSM900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_GSM900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_GSM900,

		--GSM1800 ALERT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_GSM1800],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_GSM1800],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_GSM1800],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_GSM1800,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_GSM1800,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_GSM1800,

		--UMTS CONNECT
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_UMTS],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_UMTS],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_UMTS],

		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_UMTS,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_UMTS,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_UMTS,
		--UMTS900 CONNECT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_UMTS900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_UMTS900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_UMTS900],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_UMTS900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_UMTS900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_UMTS900,

		--UMTS2100 CONNECT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_UMTS2100],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_UMTS2100],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_UMTS2100],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_UMTS2100,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_UMTS2100,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_UMTS2100,
		--GSM CONNECT
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_GSM],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_GSM],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_GSM],

		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_GSM,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_GSM,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_GSM,
		--GSM900 CONNECT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_GSM900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_GSM900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_GSM900],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_GSM900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_GSM900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_GSM900,

		--GSM1800 CONNECT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_GSM1800],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_GSM1800],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_GSM1800],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_GSM1800,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_GSM1800,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_GSM1800,

		--Nuevos KPIs 17/01/2017
		------------------------------------------------
		--Desglose tecnologia MOS
		------------------------------------------------
		----------------2G----------------
		--El AVG del MOS_2G no lo tenemos de forma directa, lo obtenemos a partir del avg de sus bandas pesando por el peso de cada una
		sum(case when v.callstatus = 'Completed' then (case when v.MOS_WB_GSM_AVG is not null or v.MOS_WB_DCS_AVG is not null then Samples_WB_GSM900+Samples_WB_GSM1800
				when v.MOS_WB_GSM_AVG is null and v.MOS_WB_DCS_AVG is null and (v.MOS_NB_GSM_AVG is not null or v.MOS_NB_DCS_AVG is not null) then Samples_NB_GSM900+Samples_NB_GSM1800
			else 0 end) end) as Samples_2G,
		isnull(sum(case when v.callstatus = 'Completed' then (case when v.MOS_WB_GSM_AVG is not null or v.MOS_WB_DCS_AVG is not null 
				then isnull(MOS_WB_GSM_AVG,0)*Samples_WB_GSM900+isnull(MOS_WB_DCS_AVG,0)*Samples_WB_GSM1800
			when v.MOS_WB_GSM_AVG is null and v.MOS_WB_DCS_AVG is null and (v.MOS_NB_GSM_AVG is not null or v.MOS_NB_DCS_AVG is not null) 
				then isnull(MOS_NB_GSM_AVG,0)*Samples_NB_GSM900+isnull(MOS_NB_DCS_AVG,0)*Samples_NB_GSM1800
			end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when v.MOS_WB_GSM_AVG is not null or v.MOS_WB_DCS_AVG is not null 
				then Samples_WB_GSM900+Samples_WB_GSM1800
			when v.MOS_WB_GSM_AVG is null and v.MOS_WB_DCS_AVG is null and (v.MOS_NB_GSM_AVG is not null or v.MOS_NB_DCS_AVG is not null) 
				then Samples_NB_GSM900+Samples_NB_GSM1800
			end) end),0),0)
		as MOS_2G,
		----------------3G----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_WB_UMTS_AVG is not null then Samples_WB_UMTS900+Samples_WB_UMTS2100
			when v.MOS_WB_UMTS_AVG is null and v.MOS_NB_UMTS_AVG is not null then Samples_NB_UMTS900+Samples_NB_UMTS2100
			else 0 end) end) as Samples_3G,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_UMTS_AVG is not null) then v.MOS_WB_UMTS_AVG*(Samples_WB_UMTS900+Samples_WB_UMTS2100)
					else v.MOS_NB_UMTS_AVG*(Samples_NB_UMTS900+Samples_NB_UMTS2100)end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_UMTS_AVG is not null) then Samples_WB_UMTS900+Samples_WB_UMTS2100 
			else Samples_NB_UMTS900+Samples_NB_UMTS2100 end) end),0),0)
		as MOS_3G,
		----------------4G----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_WB_LTE_AVG is not null then Samples_WB_LTE800+Samples_WB_LTE1800+Samples_WB_LTE2100+Samples_WB_LTE2600
			when v.MOS_WB_LTE_AVG is null and v.MOS_NB_LTE_AVG is not null then Samples_NB_LTE800+Samples_NB_LTE1800+Samples_NB_LTE2100+Samples_NB_LTE2600
			else 0 end) end) as Samples_4G,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_LTE_AVG is not null) then v.MOS_WB_LTE_AVG*(Samples_WB_LTE800+Samples_WB_LTE1800+Samples_WB_LTE2100+Samples_WB_LTE2600)
			else v.MOS_NB_LTE_AVG*(Samples_NB_LTE800+Samples_NB_LTE1800+Samples_NB_LTE2100+Samples_NB_LTE2600) end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_LTE_AVG is not null) then Samples_WB_LTE800+Samples_WB_LTE1800+Samples_WB_LTE2100+Samples_WB_LTE2600
			else Samples_NB_LTE800+Samples_NB_LTE1800+Samples_NB_LTE2100+Samples_NB_LTE2600 end) end),0),0)
		as MOS_4G,
		----------------GSM900----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_WB_GSM_AVG is not null then Samples_WB_GSM900 
			when v.MOS_WB_GSM_AVG is null and v.MOS_NB_GSM_AVG is not null then Samples_NB_GSM900
			else 0 end) end) as Samples_GSM900,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_GSM_AVG is not null) then v.MOS_WB_GSM_AVG*Samples_WB_GSM900
			else v.MOS_NB_GSM_AVG*Samples_NB_GSM900 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_GSM_AVG is not null) then v.Samples_WB_GSM900 
			else v.Samples_NB_GSM900 end) end),0),0)
		as MOS_GSM900,
		----------------GSM1800----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_WB_DCS_AVG is not null then Samples_WB_GSM1800 
			when v.MOS_WB_DCS_AVG is null and v.MOS_NB_DCS_AVG is not null then Samples_NB_GSM1800
			else 0 end) end) as Samples_GSM1800,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_DCS_AVG is not null) then v.MOS_WB_DCS_AVG*Samples_WB_GSM1800
			else v.MOS_NB_DCS_AVG*Samples_NB_GSM1800 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_DCS_AVG is not null) then v.Samples_WB_GSM1800 
			else v.Samples_NB_GSM1800 end) end),0),0)
		as MOS_GSM1800,
		----------------UMTS900----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_UMTS900_WB_AVG is not null then Samples_WB_UMTS900 
			when v.MOS_UMTS900_WB_AVG is null and v.MOS_UMTS900_NB_AVG is not null then Samples_NB_UMTS900
			else 0 end) end) as Samples_UMTS900,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_UMTS900_WB_AVG is not null) then v.MOS_UMTS900_WB_AVG*Samples_WB_UMTS900 
			else v.MOS_UMTS900_NB_AVG*Samples_NB_UMTS900 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_UMTS900_WB_AVG is not null) then v.Samples_WB_UMTS900 
			else v.Samples_NB_UMTS900 end) end),0),0)
		as MOS_UMTS900,
		----------------UMTS2100----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_UMTS2100_WB_AVG is not null then Samples_WB_UMTS2100 
			when v.MOS_UMTS2100_WB_AVG is null and v.MOS_UMTS2100_NB_AVG is not null then Samples_NB_UMTS2100
			else 0 end) end) as Samples_UMTS2100,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_UMTS2100_WB_AVG is not null) then v.MOS_UMTS2100_WB_AVG*Samples_WB_UMTS2100 
			else v.MOS_UMTS2100_NB_AVG*Samples_NB_UMTS2100 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_UMTS2100_WB_AVG is not null) then v.Samples_WB_UMTS2100 
			else v.Samples_NB_UMTS2100 end) end),0),0)
		as MOS_UMTS2100,
		----------------LTE800----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_LTE800_WB_AVG is not null then Samples_WB_LTE800 
			when v.MOS_LTE800_WB_AVG is null and v.MOS_LTE800_NB_AVG is not null then Samples_NB_LTE800
			else 0 end) end) as Samples_LTE800,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE800_WB_AVG is not null) then v.MOS_LTE800_WB_AVG*Samples_WB_LTE800 
			else v.MOS_LTE800_NB_AVG*Samples_NB_LTE800 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE800_WB_AVG is not null) then v.Samples_WB_LTE800 
			else v.Samples_NB_LTE800 end) end),0),0)
		as MOS_LTE800,
		----------------LTE1800----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_LTE1800_WB_AVG is not null then Samples_WB_LTE1800 
			when v.MOS_LTE1800_WB_AVG is null and v.MOS_LTE1800_NB_AVG is not null then Samples_NB_LTE1800
			else 0 end) end) as Samples_LTE1800,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE1800_WB_AVG is not null) then v.MOS_LTE1800_WB_AVG*Samples_WB_LTE1800
			else v.MOS_LTE1800_NB_AVG*Samples_NB_LTE1800 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE1800_WB_AVG is not null) then v.Samples_WB_LTE1800 
			else v.Samples_NB_LTE1800 end) end),0),0)
		as MOS_LTE1800,
		--LTE2100
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_LTE2100_WB_AVG is not null then Samples_WB_LTE2100 
			when v.MOS_LTE2100_WB_AVG is null and v.MOS_LTE2100_NB_AVG is not null then Samples_NB_LTE2100
			else 0 end) end) as Samples_LTE2100,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE2100_WB_AVG is not null) then v.MOS_LTE2100_WB_AVG*Samples_WB_LTE2100
			else v.MOS_LTE2100_NB_AVG*Samples_NB_LTE2100 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE2100_WB_AVG is not null) then v.Samples_WB_LTE2100 
			else v.Samples_NB_LTE2100 end) end),0),0)
		as MOS_LTE2100,
		----------------LTE2600----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_LTE2600_WB_AVG is not null then Samples_WB_LTE2600 
			when v.MOS_LTE2600_WB_AVG is null and v.MOS_LTE2600_NB_AVG is not null then Samples_NB_LTE2600
			else 0 end) end) as Samples_LTE2600,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE2600_WB_AVG is not null) then v.MOS_LTE2600_WB_AVG*Samples_WB_LTE2600
			else v.MOS_LTE2600_NB_AVG*Samples_NB_LTE2600 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE2600_WB_AVG is not null) then v.Samples_WB_LTE2600 
			else v.Samples_NB_LTE2600 end) end),0),0)
		as MOS_LTE2600,
		------------------------------------------------
		--Desglose tecnologia duracion
		------------------------------------------------
		SUM(LTE_Duration) as Duration_4G,
		SUM(LTE2600_Duration) as Duration_LTE2600,
		SUM(LTE2100_Duration) as Duration_LTE2100,
		SUM(LTE1800_Duration) as Duration_LTE1800,
		SUM(LTE800_Duration) as Duration_LTE800,
		SUM(UMTS2100_Duration) as Duration_UMTS2100,
		SUM(UMTS900_Duration) as Duration_UMTS900,
		SUM(GSM900_Duration) as Duration_GSM900,
		SUM(GSM1800_Duration) as Duration_GSM1800,
		

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

	OPTION (RECOMPILE)
end
else
begin
	insert into @voice_cst
	select
		db_name() as 'Database',
		v.mnc,
		null,
		sum (case when v.callstatus = 'Completed' then (case when v.callDir='MO' then 1 else 0 end) end) as MO_CallType,
		sum (case when v.callstatus = 'Completed' then (case when v.callDir='MT' then 1 else 0 end) end) as MT_CallType,
		------------------------------------------------
		--CSFB
		------------------------------------------------
		sum (case when v.callstatus = 'Completed' then (case when v.callDir='MO' and v.csfb_till_connRel is not null then 1 else 0 end) end) [Calls_CSFB_MO],
		sum (case when v.callstatus = 'Completed' then (case when v.callDir='MT' and v.csfb_till_connRel is not null then 1 else 0 end) end) [Calls_CSFB_MT],
		sum (case when v.callstatus = 'Completed' then (case when v.csfb_till_connRel is not null then 1 else 0 end) end) [Calls_CSFB_MOMT],
		
		AVG(case when v.callstatus = 'Completed' then (case when v.callDir = 'MO' then 1.0* v.csfb_till_connRel end) end)/1000.0 as CSFB_MO,
		AVG(case when v.callstatus = 'Completed' then (case when v.callDir = 'MT' then 1.0* v.csfb_till_connRel end) end)/1000.0 as CSFB_MT,
		AVG(case when v.callstatus = 'Completed' then (v.csfb_till_connRel/1000.0) end) as CSFB_MOMT,
		
		------------------------------------------------
		--CST Tecnologia-Banda (respecto a la parte A)
		------------------------------------------------
		--UMTS ALERT
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_UMTS],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_UMTS],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_UMTS],

		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_UMTS,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_UMTS,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_UMTS,
		--UMTS900 ALERT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_UMTS900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_UMTS900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_UMTS900],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_UMTS900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_UMTS900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_UMTS900,

		--UMTS2100 ALERT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_UMTS2100],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_UMTS2100],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_UMTS2100],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_UMTS2100,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_UMTS2100,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_UMTS2100,
		--GSM ALERT
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_GSM],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_GSM],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_GSM],

		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_GSM,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_GSM,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_GSM,
		--GSM900 ALERT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_GSM900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_GSM900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_GSM900],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_GSM900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_GSM900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_GSM900,

		--GSM1800 ALERT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MO_ALERT_GSM1800],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MT_ALERT_GSM1800],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.cst_till_alerting is not null then 1 else 0 end) end) [Calls_CST_MOMT_ALERT_GSM1800],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir = 'MO' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MO_ALERT_GSM1800,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir = 'MT' then 1.0* v.cst_till_alerting end) end)/1000.0 as CST_MT_ALERT_GSM1800,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' then 1.0*v.cst_till_alerting end) end)/1000.0 as CST_MOMT_ALERT_GSM1800,

		--UMTS CONNECT
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_UMTS],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_UMTS],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_UMTS],

		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_UMTS,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_UMTS,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'UMTS' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_UMTS,
		--UMTS900 CONNECT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_UMTS900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_UMTS900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_UMTS900],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_UMTS900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_UMTS900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 900' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_UMTS900,

		--UMTS2100 CONNECT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_UMTS2100],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_UMTS2100],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_UMTS2100],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_UMTS2100,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_UMTS2100,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='UMTS 2100' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_UMTS2100,
		--GSM CONNECT
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_GSM],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_GSM],
		sum (case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_GSM],

		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_GSM,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_GSM,
		AVG(case when v.callstatus = 'Completed' then (case when left(v.cmservice_band,4) = 'GSM' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_GSM,
		--GSM900 CONNECT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_GSM900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_GSM900],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_GSM900],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_GSM900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_GSM900,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 900' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_GSM900,

		--GSM1800 CONNECT
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MO_CONNECT_GSM1800],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MT_CONNECT_GSM1800],
		sum (case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.cst_till_connAck is not null then 1 else 0 end) end) [Calls_CST_MOMT_CONNECT_GSM1800],

		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir = 'MO' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MO_CONNECT_GSM1800,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' and v.callDir = 'MT' then 1.0* v.cst_till_connAck end) end)/1000.0 as CST_MT_CONNECT_GSM1800,
		AVG(case when v.callstatus = 'Completed' then (case when cmservice_band='GSM 1800' then 1.0*v.cst_till_connAck end) end)/1000.0 as CST_MOMT_CONNECT_GSM1800,

		--Nuevos KPIs 17/01/2017
		------------------------------------------------
		--Desglose tecnologia MOS
		------------------------------------------------
		----------------2G----------------
		--El AVG del MOS_2G no lo tenemos de forma directa, lo obtenemos a partir del avg de sus bandas pesando por el peso de cada una
		sum(case when v.callstatus = 'Completed' then (case when v.MOS_WB_GSM_AVG is not null or v.MOS_WB_DCS_AVG is not null then Samples_WB_GSM900+Samples_WB_GSM1800
				when v.MOS_WB_GSM_AVG is null and v.MOS_WB_DCS_AVG is null and (v.MOS_NB_GSM_AVG is not null or v.MOS_NB_DCS_AVG is not null) then Samples_NB_GSM900+Samples_NB_GSM1800
			else 0 end) end) as Samples_2G,
		isnull(sum(case when v.callstatus = 'Completed' then (case when v.MOS_WB_GSM_AVG is not null or v.MOS_WB_DCS_AVG is not null 
				then isnull(MOS_WB_GSM_AVG,0)*Samples_WB_GSM900+isnull(MOS_WB_DCS_AVG,0)*Samples_WB_GSM1800
			when v.MOS_WB_GSM_AVG is null and v.MOS_WB_DCS_AVG is null and (v.MOS_NB_GSM_AVG is not null or v.MOS_NB_DCS_AVG is not null) 
				then isnull(MOS_NB_GSM_AVG,0)*Samples_NB_GSM900+isnull(MOS_NB_DCS_AVG,0)*Samples_NB_GSM1800
			end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when v.MOS_WB_GSM_AVG is not null or v.MOS_WB_DCS_AVG is not null 
				then Samples_WB_GSM900+Samples_WB_GSM1800
			when v.MOS_WB_GSM_AVG is null and v.MOS_WB_DCS_AVG is null and (v.MOS_NB_GSM_AVG is not null or v.MOS_NB_DCS_AVG is not null) 
				then Samples_NB_GSM900+Samples_NB_GSM1800
			end) end),0),0)
		as MOS_2G,
		----------------3G----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_WB_UMTS_AVG is not null then Samples_WB_UMTS900+Samples_WB_UMTS2100
			when v.MOS_WB_UMTS_AVG is null and v.MOS_NB_UMTS_AVG is not null then Samples_NB_UMTS900+Samples_NB_UMTS2100
			else 0 end) end) as Samples_3G,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_UMTS_AVG is not null) then v.MOS_WB_UMTS_AVG*(Samples_WB_UMTS900+Samples_WB_UMTS2100)
					else v.MOS_NB_UMTS_AVG*(Samples_NB_UMTS900+Samples_NB_UMTS2100)end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_UMTS_AVG is not null) then Samples_WB_UMTS900+Samples_WB_UMTS2100 
			else Samples_NB_UMTS900+Samples_NB_UMTS2100 end) end),0),0)
		as MOS_3G,
		----------------4G----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_WB_LTE_AVG is not null then Samples_WB_LTE800+Samples_WB_LTE1800+Samples_WB_LTE2100+Samples_WB_LTE2600
			when v.MOS_WB_LTE_AVG is null and v.MOS_NB_LTE_AVG is not null then Samples_NB_LTE800+Samples_NB_LTE1800+Samples_NB_LTE2100+Samples_NB_LTE2600
			else 0 end) end) as Samples_4G,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_LTE_AVG is not null) then v.MOS_WB_LTE_AVG*(Samples_WB_LTE800+Samples_WB_LTE1800+Samples_WB_LTE2100+Samples_WB_LTE2600)
			else v.MOS_NB_LTE_AVG*(Samples_NB_LTE800+Samples_NB_LTE1800+Samples_NB_LTE2100+Samples_NB_LTE2600) end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_LTE_AVG is not null) then Samples_WB_LTE800+Samples_WB_LTE1800+Samples_WB_LTE2100+Samples_WB_LTE2600
			else Samples_NB_LTE800+Samples_NB_LTE1800+Samples_NB_LTE2100+Samples_NB_LTE2600 end) end),0),0)
		as MOS_4G,
		----------------GSM900----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_WB_GSM_AVG is not null then Samples_WB_GSM900 
			when v.MOS_WB_GSM_AVG is null and v.MOS_NB_GSM_AVG is not null then Samples_NB_GSM900
			else 0 end) end) as Samples_GSM900,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_GSM_AVG is not null) then v.MOS_WB_GSM_AVG*Samples_WB_GSM900
			else v.MOS_NB_GSM_AVG*Samples_NB_GSM900 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_GSM_AVG is not null) then v.Samples_WB_GSM900 
			else v.Samples_NB_GSM900 end) end),0),0)
		as MOS_GSM900,
		----------------GSM1800----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_WB_DCS_AVG is not null then Samples_WB_GSM1800 
			when v.MOS_WB_DCS_AVG is null and v.MOS_NB_DCS_AVG is not null then Samples_NB_GSM1800
			else 0 end) end) as Samples_GSM1800,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_DCS_AVG is not null) then v.MOS_WB_DCS_AVG*Samples_WB_GSM1800
			else v.MOS_NB_DCS_AVG*Samples_NB_GSM1800 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_WB_DCS_AVG is not null) then v.Samples_WB_GSM1800 
			else v.Samples_NB_GSM1800 end) end),0),0)
		as MOS_GSM1800,
		----------------UMTS900----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_UMTS900_WB_AVG is not null then Samples_WB_UMTS900 
			when v.MOS_UMTS900_WB_AVG is null and v.MOS_UMTS900_NB_AVG is not null then Samples_NB_UMTS900
			else 0 end) end) as Samples_UMTS900,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_UMTS900_WB_AVG is not null) then v.MOS_UMTS900_WB_AVG*Samples_WB_UMTS900 
			else v.MOS_UMTS900_NB_AVG*Samples_NB_UMTS900 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_UMTS900_WB_AVG is not null) then v.Samples_WB_UMTS900 
			else v.Samples_NB_UMTS900 end) end),0),0)
		as MOS_UMTS900,
		----------------UMTS2100----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_UMTS2100_WB_AVG is not null then Samples_WB_UMTS2100 
			when v.MOS_UMTS2100_WB_AVG is null and v.MOS_UMTS2100_NB_AVG is not null then Samples_NB_UMTS2100
			else 0 end) end) as Samples_UMTS2100,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_UMTS2100_WB_AVG is not null) then v.MOS_UMTS2100_WB_AVG*Samples_WB_UMTS2100 
			else v.MOS_UMTS2100_NB_AVG*Samples_NB_UMTS2100 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_UMTS2100_WB_AVG is not null) then v.Samples_WB_UMTS2100 
			else v.Samples_NB_UMTS2100 end) end),0),0)
		as MOS_UMTS2100,
		----------------LTE800----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_LTE800_WB_AVG is not null then Samples_WB_LTE800 
			when v.MOS_LTE800_WB_AVG is null and v.MOS_LTE800_NB_AVG is not null then Samples_NB_LTE800
			else 0 end) end) as Samples_LTE800,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE800_WB_AVG is not null) then v.MOS_LTE800_WB_AVG*Samples_WB_LTE800 
			else v.MOS_LTE800_NB_AVG*Samples_NB_LTE800 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE800_WB_AVG is not null) then v.Samples_WB_LTE800 
			else v.Samples_NB_LTE800 end) end),0),0)
		as MOS_LTE800,
		----------------LTE1800----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_LTE1800_WB_AVG is not null then Samples_WB_LTE1800 
			when v.MOS_LTE1800_WB_AVG is null and v.MOS_LTE1800_NB_AVG is not null then Samples_NB_LTE1800
			else 0 end) end) as Samples_LTE1800,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE1800_WB_AVG is not null) then v.MOS_LTE1800_WB_AVG*Samples_WB_LTE1800
			else v.MOS_LTE1800_NB_AVG*Samples_NB_LTE1800 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE1800_WB_AVG is not null) then v.Samples_WB_LTE1800 
			else v.Samples_NB_LTE1800 end) end),0),0)
		as MOS_LTE1800,
		--LTE2100
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_LTE2100_WB_AVG is not null then Samples_WB_LTE2100 
			when v.MOS_LTE2100_WB_AVG is null and v.MOS_LTE2100_NB_AVG is not null then Samples_NB_LTE2100
			else 0 end) end) as Samples_LTE2100,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE2100_WB_AVG is not null) then v.MOS_LTE2100_WB_AVG*Samples_WB_LTE2100
			else v.MOS_LTE2100_NB_AVG*Samples_NB_LTE2100 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE2100_WB_AVG is not null) then v.Samples_WB_LTE2100 
			else v.Samples_NB_LTE2100 end) end),0),0)
		as MOS_LTE2100,
		----------------LTE2600----------------
		sum (case when v.callstatus = 'Completed' then (case when v.MOS_LTE2600_WB_AVG is not null then Samples_WB_LTE2600 
			when v.MOS_LTE2600_WB_AVG is null and v.MOS_LTE2600_NB_AVG is not null then Samples_NB_LTE2600
			else 0 end) end) as Samples_LTE2600,
		isnull(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE2600_WB_AVG is not null) then v.MOS_LTE2600_WB_AVG*Samples_WB_LTE2600
			else v.MOS_LTE2600_NB_AVG*Samples_NB_LTE2600 end) end)
		/
		nullif(sum(case when v.callstatus = 'Completed' then (case when (v.MOS_LTE2600_WB_AVG is not null) then v.Samples_WB_LTE2600 
			else v.Samples_NB_LTE2600 end) end),0),0)
		as MOS_LTE2600,
		------------------------------------------------
		--Desglose tecnologia duracion
		------------------------------------------------
		SUM(LTE_Duration) as Duration_4G,
		SUM(LTE2600_Duration) as Duration_LTE2600,
		SUM(LTE2100_Duration) as Duration_LTE2100,
		SUM(LTE1800_Duration) as Duration_LTE1800,
		SUM(LTE800_Duration) as Duration_LTE800,
		SUM(UMTS2100_Duration) as Duration_UMTS2100,
		SUM(UMTS900_Duration) as Duration_UMTS900,
		SUM(GSM900_Duration) as Duration_GSM900,
		SUM(GSM1800_Duration) as Duration_GSM1800,

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
	OPTION (RECOMPILE)
end


select * from @voice_cst
