USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Causas_Bloqueos_Perdidas_GRID]    Script Date: 14/07/2017 14:49:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_Causas_Bloqueos_Perdidas_GRID] (
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
-------------------- Drop Calls Disaggregated by drop type
------------------------------------------------------------------------------------
declare @voice_causeFail  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[MO_Failed, B-Side not correctly connected] [int] NULL,
	[MO_Failed, Called Party not reached ] [int] NULL,
	[MO_Failed, DCCH Failed/Rejected ] [int] NULL,
	[MO_Failed, Disconnect received by Called Party] [int] NULL,
	[MO_Failed, Disconnect received by Called Party after Alerting] [int] NULL,
	[MO_Failed, Disconnect sent by Called Party] [int] NULL,
	[MO_Failed, No Answer] [int] NULL,
	[MO_Failed, No DCCH Request] [int] NULL,
	[MO_Failed, No FallBack] [int] NULL,
	[MO_Failed, No Progress after Alerting] [int] NULL,
	[MO_Failed, No Progress after Call Confirmed/Proceeding] [int] NULL,
	[MO_Failed, No Progress after DCCH assignment] [int] NULL,
	[MO_Failed, No Progress after FallBack] [int] NULL,
	[MO_Failed, No Progress after Service Request/Page Response] [int] NULL,
	[MO_Failed, No Progress after Setup] [int] NULL,
	[MO_Failed, No Progress after TCH assignment] [int] NULL,
	[MO_Failed, No Service Request/Page Response] [int] NULL,
	[MO_Failed, No Setup -> Location Updating] [int] NULL,
	[MO_Failed, No Setup -> RA Updating] [int] NULL,
	[MO_Failed, Registration failed] [int] NULL,
	[MO_Failed, Release Received] [int] NULL,
	[MO_Failed, Stop with Progress] [int] NULL,
	[MO_Failed, Service Reject] [int] NULL,
	[MO_Failed, TCH assignment Failed] [int] NULL,
	[MO_Failed, LCC CST timeout, original status: completed] [int] NULL,
	[MT_Failed, B-Side not correctly connected] [int] NULL,
	[MT_Failed, Called Party not reached ] [int] NULL,
	[MT_Failed, DCCH Failed/Rejected ] [int] NULL,
	[MT_Failed, Disconnect received by Called Party] [int] NULL,
	[MT_Failed, Disconnect received by Called Party after Alerting] [int] NULL,
	[MT_Failed, Disconnect sent by Called Party] [int] NULL,
	[MT_Failed, No Answer] [int] NULL,
	[MT_Failed, No DCCH Request] [int] NULL,
	[MT_Failed, No FallBack] [int] NULL,
	[MT_Failed, No Progress after Alerting] [int] NULL,
	[MT_Failed, No Progress after Call Confirmed/Proceeding] [int] NULL,
	[MT_Failed, No Progress after DCCH assignment] [int] NULL,
	[MT_Failed, No Progress after FallBack] [int] NULL,
	[MT_Failed, No Progress after Service Request/Page Response] [int] NULL,
	[MT_Failed, No Progress after Setup] [int] NULL,
	[MT_Failed, No Progress after TCH assignment] [int] NULL,
	[MT_Failed, No Service Request/Page Response] [int] NULL,
	[MT_Failed, No Setup -> Location Updating] [int] NULL,
	[MT_Failed, No Setup -> RA Updating] [int] NULL,
	[MT_Failed, Registration failed] [int] NULL,
	[MT_Failed, Release Received] [int] NULL,
	[MT_Failed, Stop with Progress] [int] NULL,
	[MT_Failed, Service Reject] [int] NULL,
	[MT_Failed, TCH assignment Failed] [int] NULL,
	[MT_Failed, LCC CST timeout, original status: completed] [int] NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF] [varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP] [varchar](256) NULL
)

if (@Indoor=0 OR @Indoor=2)
begin
	insert into @voice_causeFail 
	select 
		db_name() as 'Database',
		v.mnc,
		[master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A) as Parcel,
		SUM (case when (v.callDir='MO'and v.codeDescription like '%B%side%') then 1 else 0 end) as 'MO_Failed, B-Side not correctly connected',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%called%not%Reached%') then 1 else 0 end) as 'MO_Failed, Called Party not reached ',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%DCCH%Rejected%') then 1 else 0 end) as 'MO_Failed, DCCH Failed/Rejected ',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Disconnect%received%party%' and v.codeDescription not like '%alerting%') then 1 else 0 end) as 'MO_Failed, Disconnect received by Called Party',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Disconnect%received%party%' and v.codeDescription like '%alerting%') then 1 else 0 end) as 'MO_Failed, Disconnect received by Called Party after Alerting',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Disconnect%sent%party%') then 1 else 0 end) as 'MO_Failed, Disconnect sent by Called Party',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%answer%') then 1 else 0 end) as 'MO_Failed, No Answer',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%DCCH%Request%') then 1 else 0 end) as 'MO_Failed, No DCCH Request',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%FallBack%') then 1 else 0 end) as 'MO_Failed, No FallBack',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%progress%Alerting%') then 1 else 0 end) as 'MO_Failed, No Progress after Alerting',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%call%') then 1 else 0 end) as 'MO_Failed, No Progress after Call Confirmed/Proceeding',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%DCCH%') then 1 else 0 end) as 'MO_Failed, No Progress after DCCH assignment',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%FallBack%') then 1 else 0 end) as 'MO_Failed, No Progress after FallBack',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%Service%') then 1 else 0 end) as 'MO_Failed, No Progress after Service Request/Page Response',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%Setup%') then 1 else 0 end) as 'MO_Failed, No Progress after Setup',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%TCH%') then 1 else 0 end) as 'MO_Failed, No Progress after TCH assignment',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Service%Request%') then 1 else 0 end) as 'MO_Failed, No Service Request/Page Response',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%setup%location%') then 1 else 0 end) as 'MO_Failed, No Setup -> Location Updating',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%setup%RA%') then 1 else 0 end) as 'MO_Failed, No Setup -> RA Updating',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Registration%failed%') then 1 else 0 end) as 'MO_Failed, Registration failed',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Release%') then 1 else 0 end) as 'MO_Failed, Release Received',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%stop%') then 1 else 0 end) as 'MO_Failed, Stop with Progress',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Service%Reject%') then 1 else 0 end) as 'MO_Failed, Service Reject',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%TCH%assignment%Failed%') then 1 else 0 end) as 'MO_Failed, TCH assignment Failed',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%LCC%CST%timeout%') then 1 else 0 end) as 'MO_Failed, LCC CST timeout, original status: completed',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%B%side%') then 1 else 0 end) as 'MT_Failed, B-Side not correctly connected',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%called%not%Reached%') then 1 else 0 end) as 'MT_Failed, Called Party not reached ',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%DCCH%Rejected%') then 1 else 0 end) as 'MT_Failed, DCCH Failed/Rejected ',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Disconnect%received%party%' and v.codeDescription not like '%alerting%') then 1 else 0 end) as 'MT_Failed, Disconnect received by Called Party',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Disconnect%received%party%' and v.codeDescription like '%alerting%') then 1 else 0 end) as 'MT_Failed, Disconnect received by Called Party after Alerting',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Disconnect%sent%party%') then 1 else 0 end) as 'MT_Failed, Disconnect sent by Called Party',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%answer%') then 1 else 0 end) as 'MT_Failed, No Answer',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%DCCH%Request%') then 1 else 0 end) as 'MT_Failed, No DCCH Request',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%FallBack%') then 1 else 0 end) as 'MT_Failed, No FallBack',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%progress%Alerting%') then 1 else 0 end) as 'MT_Failed, No Progress after Alerting',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%call%') then 1 else 0 end) as 'MT_Failed, No Progress after Call Confirmed/Proceeding',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%DCCH%') then 1 else 0 end) as 'MT_Failed, No Progress after DCCH assignment',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%FallBack%') then 1 else 0 end) as 'MT_Failed, No Progress after FallBack',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%Service%') then 1 else 0 end) as 'MT_Failed, No Progress after Service Request/Page Response',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%Setup%') then 1 else 0 end) as 'MT_Failed, No Progress after Setup',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%TCH%') then 1 else 0 end) as 'MT_Failed, No Progress after TCH assignment',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Service%Request%') then 1 else 0 end) as 'MT_Failed, No Service Request/Page Response',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%setup%location%') then 1 else 0 end) as 'MT_Failed, No Setup -> Location Updating',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%setup%RA%') then 1 else 0 end) as 'MT_Failed, No Setup -> RA Updating',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Registration%failed%') then 1 else 0 end) as 'MT_Failed, Registration failed',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Release%') then 1 else 0 end) as 'MT_Failed, Release Received',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%stop%') then 1 else 0 end) as 'MT_Failed, Stop with Progress',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Service%Reject%') then 1 else 0 end) as 'MT_Failed, Service Reject',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%TCH%assignment%Failed%') then 1 else 0 end) as 'MT_Failed, TCH assignment Failed',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%LCC%CST%timeout%') then 1 else 0 end) as 'MT_Failed, LCC CST timeout, original status: completed',
		
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
		lcc_Calls_Detailed v,
		Sessions s,
		Agrids.dbo.lcc_parcelas lp

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus = 'Failed' -- Only Failed Calls
		and s.valid=1
		and lp.Nombre= [master].[dbo].fn_lcc_getParcel(v.longitude_fin_A, v.latitude_fin_A)

	group by [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A), v.mnc,lp.Region_VF,lp.Region_OSP

end
else
begin
	insert into @voice_causeFail 
	select 
		db_name() as 'Database',
		v.mnc,
		null,
		SUM (case when (v.callDir='MO'and v.codeDescription like '%B%side%') then 1 else 0 end) as 'MO_Failed, B-Side not correctly connected',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%called%not%Reached%') then 1 else 0 end) as 'MO_Failed, Called Party not reached ',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%DCCH%Rejected%') then 1 else 0 end) as 'MO_Failed, DCCH Failed/Rejected ',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Disconnect%received%party%' and v.codeDescription not like '%alerting%') then 1 else 0 end) as 'MO_Failed, Disconnect received by Called Party',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Disconnect%received%party%' and v.codeDescription like '%alerting%') then 1 else 0 end) as 'MO_Failed, Disconnect received by Called Party after Alerting',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Disconnect%sent%party%') then 1 else 0 end) as 'MO_Failed, Disconnect sent by Called Party',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%answer%') then 1 else 0 end) as 'MO_Failed, No Answer',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%DCCH%Request%') then 1 else 0 end) as 'MO_Failed, No DCCH Request',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%FallBack%') then 1 else 0 end) as 'MO_Failed, No FallBack',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%progress%Alerting%') then 1 else 0 end) as 'MO_Failed, No Progress after Alerting',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%call%') then 1 else 0 end) as 'MO_Failed, No Progress after Call Confirmed/Proceeding',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%DCCH%') then 1 else 0 end) as 'MO_Failed, No Progress after DCCH assignment',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%FallBack%') then 1 else 0 end) as 'MO_Failed, No Progress after FallBack',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%Service%') then 1 else 0 end) as 'MO_Failed, No Progress after Service Request/Page Response',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%Setup%') then 1 else 0 end) as 'MO_Failed, No Progress after Setup',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Progress%TCH%') then 1 else 0 end) as 'MO_Failed, No Progress after TCH assignment',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%Service%Request%') then 1 else 0 end) as 'MO_Failed, No Service Request/Page Response',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%setup%location%') then 1 else 0 end) as 'MO_Failed, No Setup -> Location Updating',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%No%setup%RA%') then 1 else 0 end) as 'MO_Failed, No Setup -> RA Updating',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Registration%failed%') then 1 else 0 end) as 'MO_Failed, Registration failed',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Release%') then 1 else 0 end) as 'MO_Failed, Release Received',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%stop%') then 1 else 0 end) as 'MO_Failed, Stop with Progress',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%Service%Reject%') then 1 else 0 end) as 'MO_Failed, Service Reject',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%TCH%assignment%Failed%') then 1 else 0 end) as 'MO_Failed, TCH assignment Failed',
		SUM (case when (v.callDir='MO'and v.codeDescription like '%LCC%CST%timeout%') then 1 else 0 end) as 'MO_Failed, LCC CST timeout, original status: completed',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%B%side%') then 1 else 0 end) as 'MT_Failed, B-Side not correctly connected',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%called%not%Reached%') then 1 else 0 end) as 'MT_Failed, Called Party not reached ',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%DCCH%Rejected%') then 1 else 0 end) as 'MT_Failed, DCCH Failed/Rejected ',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Disconnect%received%party%' and v.codeDescription not like '%alerting%') then 1 else 0 end) as 'MT_Failed, Disconnect received by Called Party',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Disconnect%received%party%' and v.codeDescription like '%alerting%') then 1 else 0 end) as 'MT_Failed, Disconnect received by Called Party after Alerting',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Disconnect%sent%party%') then 1 else 0 end) as 'MT_Failed, Disconnect sent by Called Party',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%answer%') then 1 else 0 end) as 'MT_Failed, No Answer',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%DCCH%Request%') then 1 else 0 end) as 'MT_Failed, No DCCH Request',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%FallBack%') then 1 else 0 end) as 'MT_Failed, No FallBack',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%progress%Alerting%') then 1 else 0 end) as 'MT_Failed, No Progress after Alerting',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%call%') then 1 else 0 end) as 'MT_Failed, No Progress after Call Confirmed/Proceeding',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%DCCH%') then 1 else 0 end) as 'MT_Failed, No Progress after DCCH assignment',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%FallBack%') then 1 else 0 end) as 'MT_Failed, No Progress after FallBack',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%Service%') then 1 else 0 end) as 'MT_Failed, No Progress after Service Request/Page Response',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%Setup%') then 1 else 0 end) as 'MT_Failed, No Progress after Setup',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Progress%TCH%') then 1 else 0 end) as 'MT_Failed, No Progress after TCH assignment',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%Service%Request%') then 1 else 0 end) as 'MT_Failed, No Service Request/Page Response',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%setup%location%') then 1 else 0 end) as 'MT_Failed, No Setup -> Location Updating',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%No%setup%RA%') then 1 else 0 end) as 'MT_Failed, No Setup -> RA Updating',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Registration%failed%') then 1 else 0 end) as 'MT_Failed, Registration failed',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Release%') then 1 else 0 end) as 'MT_Failed, Release Received',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%stop%') then 1 else 0 end) as 'MT_Failed, Stop with Progress',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%Service%Reject%') then 1 else 0 end) as 'MT_Failed, Service Reject',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%TCH%assignment%Failed%') then 1 else 0 end) as 'MT_Failed, TCH assignment Failed',
		SUM (case when (v.callDir='MT'and v.codeDescription like '%LCC%CST%timeout%') then 1 else 0 end) as 'MT_Failed, LCC CST timeout, original status: completed',
		
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
		lcc_Calls_Detailed v,
		Sessions s

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus = 'Failed' -- Only Failed Calls
		and s.valid=1

	group by v.mnc
end


select * from @voice_causeFail