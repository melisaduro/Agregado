USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_mallado_GRID]    Script Date: 14/07/2017 14:56:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_mallado_GRID] (
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

declare @entidad as varchar(256) = @ciudad

declare @medida as varchar(256) 
if @Indoor=1 and @entidad not like '%RLW%' and @entidad not like '%APT%' and @entidad not like '%STD%'
begin
	SET @medida = right(@ciudad,1)
end

declare @week as varchar(256)
set @week = 'W' +convert(varchar,DATEPART(iso_week, @dateMax))

declare @operator as varchar(256) = convert(varchar,@simOperator)
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

