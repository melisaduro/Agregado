USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Causas_Caidas_GRID]    Script Date: 31/10/2017 10:36:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_Causas_Caidas_GRID] (
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
declare @voice_causeDrop  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[MO_Dropped, Call Re-Establishment attempt] [int] NULL,
	[MO_Dropped, Disconnect received] [int] NULL,
	[MO_Dropped, Disconnect sent] [int] NULL,
	[MO_Dropped, Failed Handover] [int] NULL,
	[MO_Dropped, Handover uncompleted] [int] NULL,
	[MO_Dropped, High BLER] [int] NULL,
	[MO_Dropped, High RxQual] [int] NULL,
	[MO_Dropped, Low Total Ec/Io] [int] NULL,
	[MO_Dropped, Low RxLev] [int] NULL,
	[MO_Dropped, Low UE Rx Power] [int] NULL,
	[MO_Dropped, others] [int] NULL,
	[MO_Dropped, Radio Link Timeout] [int] NULL,
	[MO_Dropped, RRCConnectionRelease received] [int] NULL,
	[MT_Dropped, Call Re-Establishment attempt] [int] NULL,
	[MT_Dropped, Disconnect received] [int] NULL,
	[MT_Dropped, Disconnect sent] [int] NULL,
	[MT_Dropped, Failed Handover] [int] NULL,
	[MT_Dropped, Handover uncompleted] [int] NULL,
	[MT_Dropped, High BLER] [int] NULL,
	[MT_Dropped, High RxQual] [int] NULL,
	[MT_Dropped, Low Total Ec/Io] [int] NULL,
	[MT_Dropped, Low RxLev] [int] NULL,
	[MT_Dropped, Low UE Rx Power] [int] NULL,
	[MT_Dropped, others] [int] NULL,
	[MT_Dropped, Radio Link Timeout] [int] NULL,
	[MT_Dropped, RRCConnectionRelease received] [int] NULL,
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
	insert into @voice_causeDrop 
	select 
		db_name() as 'Database',
		v.mnc,
		[master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A) as Parcel,
		sum (case when (v.callDir='MO'and v.callStatus like '%Call%Re-Establishment%') then 1 else 0 end) as 'MO_Dropped, Call Re-Establishment attempt',
		SUM (case when (v.callDir='MO'and v.callStatus like '%Disconnect%received%') then 1 else 0 end) as 'MO_Dropped, Disconnect received',
		SUM (case when (v.callDir='MO'and v.callStatus like '%Disconnect%sent%') then 1 else 0 end) as 'MO_Dropped, Disconnect sent',
		sum (case when (v.callDir='MO'and v.callStatus like '%Failed%Handover%') then 1 else 0 end) as 'MO_Dropped, Failed Handover',
		sum (case when (v.callDir='MO'and v.callStatus like '%Handover%uncompleted%') then 1 else 0 end) as 'MO_Dropped, Handover uncompleted',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, High BLER%') then 1 else 0 end) as 'MO_Dropped, High BLER',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, High RxQual%') then 1 else 0 end) as 'MO_Dropped, High RxQual',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low Total Ec/Io%') then 1 else 0 end) as 'MO_Dropped, Low Total Ec/Io',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low RxLev%') then 1 else 0 end) as 'MO_Dropped, Low RxLev',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low UE Rx Power%') then 1 else 0 end) as 'MO_Dropped, Low UE Rx Power',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, others%') then 1 else 0 end) as 'MO_Dropped, others',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Radio Link Timeout%') then 1 else 0 end) as 'MO_Dropped, Radio Link Timeout',
		sum (case when (v.callDir='MO'and v.callStatus like 'RRCConnectionRelease%received%') then 1 else 0 end) as 'MO_Dropped, RRCConnectionRelease received',
		sum (case when (v.callDir='MT'and v.callStatus like '%Call%Re-Establishment%') then 1 else 0 end) as 'MT_Dropped, Call Re-Establishment attempt',
		SUM (case when (v.callDir='MT'and v.callStatus like '%Disconnect%received%') then 1 else 0 end) as 'MT_Dropped, Disconnect received',
		SUM (case when (v.callDir='MT'and v.callStatus like '%Disconnect%sent%') then 1 else 0 end) as 'MT_Dropped, Disconnect sent',
		sum (case when (v.callDir='MT'and v.callStatus like '%Failed%Handover%') then 1 else 0 end) as 'MT_Dropped, Failed Handover',
		sum (case when (v.callDir='MT'and v.callStatus like '%Handover%uncompleted%') then 1 else 0 end) as 'MT_Dropped, Handover uncompleted',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, High BLER%') then 1 else 0 end) as 'MT_Dropped, High BLER',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, High RxQual%') then 1 else 0 end) as 'MT_Dropped, High RxQual',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low Total Ec/Io%') then 1 else 0 end) as 'MT_Dropped, Low Total Ec/Io',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low RxLev%') then 1 else 0 end) as 'MT_Dropped, Low RxLev',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low UE Rx Power%') then 1 else 0 end) as 'MT_Dropped, Low UE Rx Power',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, others%') then 1 else 0 end) as 'MT_Dropped, others',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Radio Link Timeout%') then 1 else 0 end) as 'MT_Dropped, Radio Link Timeout',
		sum (case when (v.callDir='MT'and v.callStatus like 'RRCConnectionRelease%received%') then 1 else 0 end) as 'MT_Dropped, RRCConnectionRelease received',
		
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
		and v.callStatus = 'Dropped' -- Only Drop Calls
		and s.valid=1
		and lp.Nombre= [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A)
	group by [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A), v.mnc,lp.Region_VF,lp.Region_OSP

end
else
begin
	insert into @voice_causeDrop 
	select 
		db_name() as 'Database',
		v.mnc,
		null,
		sum (case when (v.callDir='MO'and v.callStatus like '%Call%Re-Establishment%') then 1 else 0 end) as 'MO_Dropped, Call Re-Establishment attempt',
		SUM (case when (v.callDir='MO'and v.callStatus like '%Disconnect%received%') then 1 else 0 end) as 'MO_Dropped, Disconnect received',
		SUM (case when (v.callDir='MO'and v.callStatus like '%Disconnect%sent%') then 1 else 0 end) as 'MO_Dropped, Disconnect sent',
		sum (case when (v.callDir='MO'and v.callStatus like '%Failed%Handover%') then 1 else 0 end) as 'MO_Dropped, Failed Handover',
		sum (case when (v.callDir='MO'and v.callStatus like '%Handover%uncompleted%') then 1 else 0 end) as 'MO_Dropped, Handover uncompleted',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, High BLER%') then 1 else 0 end) as 'MO_Dropped, High BLER',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, High RxQual%') then 1 else 0 end) as 'MO_Dropped, High RxQual',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low Total Ec/Io%') then 1 else 0 end) as 'MO_Dropped, Low Total Ec/Io',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low RxLev%') then 1 else 0 end) as 'MO_Dropped, Low RxLev',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low UE Rx Power%') then 1 else 0 end) as 'MO_Dropped, Low UE Rx Power',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, others%') then 1 else 0 end) as 'MO_Dropped, others',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Radio Link Timeout%') then 1 else 0 end) as 'MO_Dropped, Radio Link Timeout',
		sum (case when (v.callDir='MO'and v.callStatus like 'RRCConnectionRelease%received%') then 1 else 0 end) as 'MO_Dropped, RRCConnectionRelease received',
		sum (case when (v.callDir='MT'and v.callStatus like '%Call%Re-Establishment%') then 1 else 0 end) as 'MT_Dropped, Call Re-Establishment attempt',
		SUM (case when (v.callDir='MT'and v.callStatus like '%Disconnect%received%') then 1 else 0 end) as 'MT_Dropped, Disconnect received',
		SUM (case when (v.callDir='MT'and v.callStatus like '%Disconnect%sent%') then 1 else 0 end) as 'MT_Dropped, Disconnect sent',
		sum (case when (v.callDir='MT'and v.callStatus like '%Failed%Handover%') then 1 else 0 end) as 'MT_Dropped, Failed Handover',
		sum (case when (v.callDir='MT'and v.callStatus like '%Handover%uncompleted%') then 1 else 0 end) as 'MT_Dropped, Handover uncompleted',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, High BLER%') then 1 else 0 end) as 'MT_Dropped, High BLER',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, High RxQual%') then 1 else 0 end) as 'MT_Dropped, High RxQual',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low Total Ec/Io%') then 1 else 0 end) as 'MT_Dropped, Low Total Ec/Io',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low RxLev%') then 1 else 0 end) as 'MT_Dropped, Low RxLev',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low UE Rx Power%') then 1 else 0 end) as 'MT_Dropped, Low UE Rx Power',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, others%') then 1 else 0 end) as 'MT_Dropped, others',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Radio Link Timeout%') then 1 else 0 end) as 'MT_Dropped, Radio Link Timeout',
		sum (case when (v.callDir='MT'and v.callStatus like 'RRCConnectionRelease%received%') then 1 else 0 end) as 'MT_Dropped, RRCConnectionRelease received',
		
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
		and v.callStatus = 'Dropped' -- Only Drop Calls
		and s.valid=1

	group by v.mnc
end


select * from @voice_causeDrop
