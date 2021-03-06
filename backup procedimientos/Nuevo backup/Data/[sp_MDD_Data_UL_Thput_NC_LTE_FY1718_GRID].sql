USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_UL_Thput_NC_LTE_FY1718_GRID]    Script Date: 31/10/2017 15:39:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_UL_Thput_NC_LTE_FY1718_GRID] (
	 --Variables de entrada
		@ciudad as varchar(256),
		@simOperator as int,
		@sheet as varchar(256),	 -- all: %%, 4G: 'LTE', 3G: 'WCDMA', CA
		@Date as varchar (256),
		@Tech as varchar (256),  -- Para seleccionar entre 3G, 4G y CA
		@Indoor as bit,
		@Info as varchar (256),
		@Methodology as varchar (50),
		@Report as varchar (256)
)
AS

-----------------------------
----- Testing Variables -----
-----------------------------
--use FY1718_DATA_REST_4G_H1_41

--declare @ciudad as varchar(256) = 'CADIZ'
--declare @simOperator as int = 3
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @Info as varchar (256) = 'Completed' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @sheet as varchar(256) = '%%' --%%/LTE/WCDMA
--declare @Tech as varchar (256) = '4G'
--declare @methodology as varchar (256) = 'D16'
--declare @report as varchar(256) = 'MUN' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests_Tech as table (sessionid bigint, TestId bigint,tech varchar(5), hasCA varchar(2))

If @Report='VDF'
begin
	insert into @All_Tests_Tech 
	select v.sessionid, v.testid,
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
			else 'Mixed' 
		end as tech,	
		'SC' hasCA
	from Lcc_Data_HTTPTransfer_UL v, testinfo t, lcc_position_Entity_List_Vodafone c
	where t.testid=v.testid
		and t.valid=1
		and v.info like @Info
		and v.MNC = @simOperator	--MNC
		and v.MCC= 214						--MCC - Descartamos los valores erróneos
		and c.fileid=v.fileid
		and c.entity_name = @Ciudad
		and c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitud Final], [Latitud Final])
		and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitud Final])
	group by v.sessionid, v.testid,
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' end,
		v.[Longitud Final], v.[Latitud Final]
end
If @Report='OSP'
begin
	insert into @All_Tests_Tech 
	select v.sessionid, v.testid,
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
			else 'Mixed' 
		end as tech,	
		'SC' hasCA
	from Lcc_Data_HTTPTransfer_UL v, testinfo t, lcc_position_Entity_List_Orange c
	where t.testid=v.testid
		and t.valid=1
		and v.info like @Info
		and v.MNC = @simOperator	--MNC
		and v.MCC= 214						--MCC - Descartamos los valores erróneos
		and c.fileid=v.fileid
		and c.entity_name = @Ciudad
		and c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitud Final], [Latitud Final])
		and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitud Final])
	group by v.sessionid, v.testid,
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' end,
		v.[Longitud Final], v.[Latitud Final]
end
If @Report='MUN'
begin
	insert into @All_Tests_Tech 
	select v.sessionid, v.testid,
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
			else 'Mixed' 
		end as tech,	
		'SC' hasCA
	from Lcc_Data_HTTPTransfer_UL v, testinfo t, lcc_position_Entity_List_Municipio c
	where t.testid=v.testid
		and t.valid=1
		and v.info like @Info
		and v.MNC = @simOperator	--MNC
		and v.MCC= 214						--MCC - Descartamos los valores erróneos
		and c.fileid=v.fileid
		and c.entity_name = @Ciudad
		and c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitud Final], [Latitud Final])
		and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitud Final])
	group by v.sessionid, v.testid,
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' end,
		v.[Longitud Final], v.[Latitud Final]
end

declare @All_Tests as table (sessionid bigint, TestId bigint)
declare @sheet1 as varchar(255)
declare @CA as varchar(255)

If @sheet = 'CA' --Para la hoja de CA del procesado de CA (medidas con Note4 = CollectionName_CA)
begin
	set @sheet1 = 'LTE'
	set @CA='%CA%'
end
else 
begin
	set @sheet1 = @sheet
	set @CA='%%'
end

insert into @All_Tests
select sessionid, testid
from @All_Tests_Tech 
where tech like @sheet1 
	and hasCA like @CA


------ Metemos en variables algunos campos calculados ----------------
declare @dateMax datetime2(3)= (select max(c.endTime) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

declare @Meas_Round as varchar(256)

if (charindex('AVE',db_name())>0 and charindex('Rest',db_name())=0)
	begin 
	 set @Meas_Round= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(6, db_name(),'_')
	end
else
	begin
	 set @Meas_Round= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')
	end

--declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, endTime)),2) + '_'	 + convert(varchar(256),format(endTime,'MM'))
--	from Lcc_Data_HTTPTransfer_UL where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

declare @entidad as varchar(256) = @ciudad

declare @medida as varchar(256) 
if @Indoor=1 and @entidad not like '%RLW%' and @entidad not like '%APT%' and @entidad not like '%STD%'
begin
	SET @medida = right(@ciudad,1)
end

declare @week as varchar(256)
set @week = 'W' +convert(varchar,DATEPART(iso_week, @dateMax))

-------------------------------------------------------------------------------
--	GENERAL SELECT		-------------------	  
-------------------------------------------------------------------------------
declare @data_ULthputNC_LTE  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Subidas] [int] NULL,
	[Fallos de Acceso] [int] NULL,
	[Fallos de descarga] [int] NULL,
	[Throughput] [float] NULL,
	[Tiempo de subida] [float] NULL,
	[SessionTime] [float] NULL,
	[Throughput Max] [float] NULL,
	[RLC_MAX] [float] NULL,
	[Count_Throughput] [int] null,
	[Count_Throughput_64k] [int] null,
	[ 0-5Mbps] [int] NULL,
    [ 5-10Mbps] [int] NULL,
    [ 10-15Mbps] [int] NULL,
    [ 15-20Mbps] [int] NULL,
    [ 20-25Mbps] [int] NULL,
    [ 25-30Mbps] [int] NULL,
    [ 30-35Mbps] [int] NULL,
    [ 35-40Mbps] [int] NULL,
    [ 40-45Mbps] [int] NULL,
    [ 45-50Mbps] [int] NULL,
    [ >50Mbps] [int] NULL,   

	--20/02/2017 Se incluyen los nuevos rangos para el calculo de los percentiles
	[ 0-0.8Mbps_N ] [int] NULL,
	[ 0.8-1.6Mbps_N ] [int] NULL,
	[ 1.6-2.4Mbps_N ] [int] NULL,
	[ 2.4-3.2Mbps_N ] [int] NULL,
	[ 3.2-4Mbps_N ] [int] NULL,
	[ 4-4.8Mbps_N ] [int] NULL,
	[ 4.8-5.6Mbps_N ] [int] NULL,
	[ 5.6-6.4Mbps_N ] [int] NULL,
	[ 6.4-7.2Mbps_N ] [int] NULL,
	[ 7.2-8Mbps_N ] [int] NULL,
	[ 8-8.8Mbps_N ] [int] NULL,
	[ 8.8-9.6Mbps_N ] [int] NULL,
	[ 9.6-10.4Mbps_N ] [int] NULL,
	[ 10.4-11.2Mbps_N ] [int] NULL,
	[ 11.2-12Mbps_N ] [int] NULL,
	[ 12-12.8Mbps_N ] [int] NULL,
	[ 12.8-13.6Mbps_N ] [int] NULL,
	[ 13.6-14.4Mbps_N ] [int] NULL,
	[ 14.4-15.2Mbps_N ] [int] NULL,
	[ 15.2-16Mbps_N ] [int] NULL,
	[ 16-16.8Mbps_N ] [int] NULL,
	[ 16.8-17.6Mbps_N ] [int] NULL,
	[ 17.6-18.4Mbps_N ] [int] NULL,
	[ 18.4-19.2Mbps_N ] [int] NULL,
	[ 19.2-20Mbps_N ] [int] NULL,
	[ 20-20.8Mbps_N ] [int] NULL,
	[ 20.8-21.6Mbps_N ] [int] NULL,
	[ 21.6-22.4Mbps_N ] [int] NULL,
	[ 22.4-23.2Mbps_N ] [int] NULL,
	[ 23.2-24Mbps_N ] [int] NULL,
	[ 24-24.8Mbps_N ] [int] NULL,
	[ 24.8-25.6Mbps_N ] [int] NULL,
	[ 25.6-26.4Mbps_N ] [int] NULL,
	[ 26.4-27.2Mbps_N ] [int] NULL,
	[ 27.2-28Mbps_N ] [int] NULL,
	[ 28-28.8Mbps_N ] [int] NULL,
	[ 28.8-29.6Mbps_N ] [int] NULL,
	[ 29.6-30.4Mbps_N ] [int] NULL,
	[ 30.4-31.2Mbps_N ] [int] NULL,
	[ 31.2-32Mbps_N ] [int] NULL,
	[ 32-32.8Mbps_N ] [int] NULL,
	[ 32.8-33.6Mbps_N ] [int] NULL,
	[ 33.6-34.4Mbps_N ] [int] NULL,
	[ 34.4-35.2Mbps_N ] [int] NULL,
	[ 35.2-36Mbps_N ] [int] NULL,
	[ 36-36.8Mbps_N ] [int] NULL,
	[ 36.8-37.6Mbps_N ] [int] NULL,
	[ 37.6-38.4Mbps_N ] [int] NULL,
	[ 38.4-39.2Mbps_N ] [int] NULL,
	[ 39.2-40Mbps_N ] [int] NULL,
	[ 40-40.8Mbps_N ] [int] NULL,
	[ 40.8-41.6Mbps_N ] [int] NULL,
	[ 41.6-42.4Mbps_N ] [int] NULL,
	[ 42.4-43.2Mbps_N ] [int] NULL,
	[ 43.2-44Mbps_N ] [int] NULL,
	[ 44-44.8Mbps_N ] [int] NULL,
	[ 44.8-45.6Mbps_N ] [int] NULL,
	[ 45.6-46.4Mbps_N ] [int] NULL,
	[ 46.4-47.2Mbps_N ] [int] NULL,
	[ 47.2-48Mbps_N ] [int] NULL,
	[ 48-48.8Mbps_N ] [int] NULL,
	[ 48.8-49.6Mbps_N ] [int] NULL,
	[ 49.6-50.4Mbps_N ] [int] NULL,
	[ 50.4-51.2Mbps_N ] [int] NULL,
	[ 51.2-52Mbps_N ] [int] NULL,
	[ >52Mbps_N] [int] NULL,

	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF][varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP][varchar](256) NULL, 

	[Count_TransferTime] [int] null,
	[Count_SessionTime] [int] null,
	--20170626:   -@MDM: Nuevo KPI para metología FY1718
	[Count_Throughput_384k] [int] null,
	--20170719:   -CAC: Nuevo KPI para metología FY1718
	[Count_Throughput_1M] [int] null,
	--CAC 10/08/2017: se calcula el thput de test con error en todos los casos posibles (no en todos los errores se rellena info en tablas de sistema)
	[Throughput_ERROR] [float] NULL,
	[Count_Throughput_ERROR] [int] null,
	[Throughput_ALL] [float] NULL,
	[Count_Throughput_ALL] [int] null
)

if @Indoor=0
begin
	insert into @data_ULthputNC_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC') then 1 else 0 end) as 'Subidas',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.TransferTime end) as 'Tiempo de subida',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.sessiontime end) as 'SessionTime',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC') then v.RLC_MAX end) as 'RLC_MAX',
	
		
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>64) then 1 else 0 end) as 'Count_Throughput_64k',
		
		--CAC 03/08/2017: se excluyen los test con thput=0 para igualar criterio percentiles de procesado
		--SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 0 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 0-5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 > 0 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 0-5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 5 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 5-10Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 10 and v.Throughput/1000 < 15) then 1 else 0 end ) as [ 10-15Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 15 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 15-20Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 20 and v.Throughput/1000 < 25) then 1 else 0 end ) as [ 20-25Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 25 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 25-30Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 30 and v.Throughput/1000 < 35) then 1 else 0 end ) as [ 30-35Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 35 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 35-40Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 40 and v.Throughput/1000 < 45) then 1 else 0 end ) as [ 40-45Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 45 and v.Throughput/1000 < 50) then 1 else 0 end ) as [ 45-50Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 50) then 1 else 0 end ) as [ >150Mbps],
		
		--20/02/2017 Se incluyen los nuevos rangos para el calculo de los percentiles
		--CAC 03/08/2017: se excluyen los test con thput=0 para igualar criterio percentiles de procesado
		--SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0 and v.Throughput/1000 < 0.8) then 1 else 0 end ) as [ 0-0.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >0 and v.Throughput/1000 < 0.8) then 1 else 0 end ) as [ 0-0.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0.8 and v.Throughput/1000 < 1.6) then 1 else 0 end ) as [ 0.8-1.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1.6 and v.Throughput/1000 < 2.4) then 1 else 0 end ) as [ 1.6-2.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2.4 and v.Throughput/1000 < 3.2) then 1 else 0 end ) as [ 2.4-3.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3.2 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 3.2-4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4 and v.Throughput/1000 < 4.8) then 1 else 0 end ) as [ 4-4.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4.8 and v.Throughput/1000 < 5.6) then 1 else 0 end ) as [ 4.8-5.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=5.6 and v.Throughput/1000 < 6.4) then 1 else 0 end ) as [ 5.6-6.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=6.4 and v.Throughput/1000 < 7.2) then 1 else 0 end ) as [ 6.4-7.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=7.2 and v.Throughput/1000 < 8) then 1 else 0 end ) as [ 7.2-8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=8 and v.Throughput/1000 < 8.8) then 1 else 0 end ) as [ 8-8.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=8.8 and v.Throughput/1000 < 9.6) then 1 else 0 end ) as [ 8.8-9.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=9.6 and v.Throughput/1000 < 10.4) then 1 else 0 end ) as [ 9.6-10.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=10.4 and v.Throughput/1000 < 11.2) then 1 else 0 end ) as [ 10.4-11.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=11.2 and v.Throughput/1000 < 12) then 1 else 0 end ) as [ 11.2-12Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=12 and v.Throughput/1000 < 12.8) then 1 else 0 end ) as [ 12-12.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=12.8 and v.Throughput/1000 < 13.6) then 1 else 0 end ) as [ 12.8-13.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=13.6 and v.Throughput/1000 < 14.4) then 1 else 0 end ) as [ 13.6-14.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=14.4 and v.Throughput/1000 < 15.2) then 1 else 0 end ) as [ 14.4-15.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=15.2 and v.Throughput/1000 < 16) then 1 else 0 end ) as [ 15.2-16Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=16 and v.Throughput/1000 < 16.8) then 1 else 0 end ) as [ 16-16.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=16.8 and v.Throughput/1000 < 17.6) then 1 else 0 end ) as [ 16.8-17.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=17.6 and v.Throughput/1000 < 18.4) then 1 else 0 end ) as [ 17.6-18.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=18.4 and v.Throughput/1000 < 19.2) then 1 else 0 end ) as [ 18.4-19.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=19.2 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 19.2-20Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=20 and v.Throughput/1000 < 20.8) then 1 else 0 end ) as [ 20-20.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=20.8 and v.Throughput/1000 < 21.6) then 1 else 0 end ) as [ 20.8-21.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=21.6 and v.Throughput/1000 < 22.4) then 1 else 0 end ) as [ 21.6-22.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=22.4 and v.Throughput/1000 < 23.2) then 1 else 0 end ) as [ 22.4-23.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=23.2 and v.Throughput/1000 < 24) then 1 else 0 end ) as [ 23.2-24Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=24 and v.Throughput/1000 < 24.8) then 1 else 0 end ) as [ 24-24.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=24.8 and v.Throughput/1000 < 25.6) then 1 else 0 end ) as [ 24.8-25.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=25.6 and v.Throughput/1000 < 26.4) then 1 else 0 end ) as [ 25.6-26.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=26.4 and v.Throughput/1000 < 27.2) then 1 else 0 end ) as [ 26.4-27.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=27.2 and v.Throughput/1000 < 28) then 1 else 0 end ) as [ 27.2-28Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=28 and v.Throughput/1000 < 28.8) then 1 else 0 end ) as [ 28-28.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=28.8 and v.Throughput/1000 < 29.6) then 1 else 0 end ) as [ 28.8-29.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=29.6 and v.Throughput/1000 < 30.4) then 1 else 0 end ) as [ 29.6-30.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=30.4 and v.Throughput/1000 < 31.2) then 1 else 0 end ) as [ 30.4-31.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=31.2 and v.Throughput/1000 < 32) then 1 else 0 end ) as [ 31.2-32Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=32 and v.Throughput/1000 < 32.8) then 1 else 0 end ) as [ 32-32.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=32.8 and v.Throughput/1000 < 33.6) then 1 else 0 end ) as [ 32.8-33.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=33.6 and v.Throughput/1000 < 34.4) then 1 else 0 end ) as [ 33.6-34.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=34.4 and v.Throughput/1000 < 35.2) then 1 else 0 end ) as [ 34.4-35.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=35.2 and v.Throughput/1000 < 36) then 1 else 0 end ) as [ 35.2-36Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=36 and v.Throughput/1000 < 36.8) then 1 else 0 end ) as [ 36-36.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=36.8 and v.Throughput/1000 < 37.6) then 1 else 0 end ) as [ 36.8-37.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=37.6 and v.Throughput/1000 < 38.4) then 1 else 0 end ) as [ 37.6-38.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=38.4 and v.Throughput/1000 < 39.2) then 1 else 0 end ) as [ 38.4-39.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=39.2 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 39.2-40Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=40 and v.Throughput/1000 < 40.8) then 1 else 0 end ) as [ 40-40.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=40.8 and v.Throughput/1000 < 41.6) then 1 else 0 end ) as [ 40.8-41.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=41.6 and v.Throughput/1000 < 42.4) then 1 else 0 end ) as [ 41.6-42.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=42.4 and v.Throughput/1000 < 43.2) then 1 else 0 end ) as [ 42.4-43.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=43.2 and v.Throughput/1000 < 44) then 1 else 0 end ) as [ 43.2-44Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=44 and v.Throughput/1000 < 44.8) then 1 else 0 end ) as [ 44-44.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=44.8 and v.Throughput/1000 < 45.6) then 1 else 0 end ) as [ 44.8-45.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=45.6 and v.Throughput/1000 < 46.4) then 1 else 0 end ) as [ 45.6-46.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=46.4 and v.Throughput/1000 < 47.2) then 1 else 0 end ) as [ 46.4-47.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=47.2 and v.Throughput/1000 < 48) then 1 else 0 end ) as [ 47.2-48Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=48 and v.Throughput/1000 < 48.8) then 1 else 0 end ) as [ 48-48.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=48.8 and v.Throughput/1000 < 49.6) then 1 else 0 end ) as [ 48.8-49.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=49.6 and v.Throughput/1000 < 50.4) then 1 else 0 end ) as [ 49.6-50.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=50.4 and v.Throughput/1000 < 51.2) then 1 else 0 end ) as [ 50.4-51.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=51.2 and v.Throughput/1000 < 52) then 1 else 0 end ) as [ 51.2-52Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=52) then 1 else 0 end ) as [ >52Mbps_N ],

		
		--'' as [% > Umbral], --PDTE
		--'' as [% > Umbral_sec], --PDTE
		----Para % a partir de un umbral (en ejemplo 3000)
		--case when (SUM (case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 
		--					else 0 
		--				end)) = 0 then 0 
		--	else (1.0*SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)
		--		/SUM (case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end)) 
		--end

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'GRID',
		lp.Region_OSP as Region_OSP,

		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.TransferTime is not null) then 1 else 0 end) as 'Count_TransferTime',
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime',

		--20170626:   -@MDM: Nuevo KPI para metología FY1718
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>384) then 1 else 0 end) as 'Count_Throughput_384k',
		--20170719:   -CAC: Nuevo KPI para metología FY1718
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>1000) then 1 else 0 end) as 'Count_Throughput_1M',
		
		--CAC 10/08/2017: se calcula el thput de test con error en todos los casos posibles (no en todos los errores se rellena info en tablas de sistema)
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.ErrorType is not null and ISNULL(v.ThputApp_nu,0)>0) then v.ThputApp_nu end) as 'Throughput_ERROR',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.ErrorType is not null and ISNULL(v.ThputApp_nu,0)>0) then 1 else 0 end) as 'Count_Throughput_ERROR',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 
			(case when v.ErrorType is null and ISNULL(v.Throughput,0)>0 then v.Throughput
				when v.ErrorType is not null and ISNULL(v.ThputApp_nu,0)>0 then v.ThputApp_nu end)
		end) as 'Throughput_ALL',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC') then 
			(case when (v.ErrorType is null and ISNULL(v.Throughput,0)>0) or (v.ErrorType is not null and ISNULL(v.ThputApp_nu,0)>0) then 1
				else 0 end)
		end) as 'Count_Throughput_ALL'
	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_UL v,
		Agrids.dbo.lcc_parcelas lp
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='UL_NC'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) 
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP
end 
else
begin
	insert into @data_ULthputNC_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC') then 1 else 0 end) as 'Subidas',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.TransferTime end) as 'Tiempo de subida',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.sessiontime end) as 'SessionTime',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC') then v.RLC_MAX end) as 'RLC_MAX',
	
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>64) then 1 else 0 end) as 'Count_Throughput_64k',
		
		--CAC 03/08/2017: se excluyen los test con thput=0 para igualar criterio percentiles de procesado
		--SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 0 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 0-5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 > 0 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 0-5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 5 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 5-10Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 10 and v.Throughput/1000 < 15) then 1 else 0 end ) as [ 10-15Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 15 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 15-20Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 20 and v.Throughput/1000 < 25) then 1 else 0 end ) as [ 20-25Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 25 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 25-30Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 30 and v.Throughput/1000 < 35) then 1 else 0 end ) as [ 30-35Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 35 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 35-40Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 40 and v.Throughput/1000 < 45) then 1 else 0 end ) as [ 40-45Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 45 and v.Throughput/1000 < 50) then 1 else 0 end ) as [ 45-50Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 50) then 1 else 0 end ) as [ >150Mbps],
		
		--20/02/2017 Se incluyen los nuevos rangos para el calculo de los percentiles
		--CAC 03/08/2017: se excluyen los test con thput=0 para igualar criterio percentiles de procesado
		--SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0 and v.Throughput/1000 < 0.8) then 1 else 0 end ) as [ 0-0.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >0 and v.Throughput/1000 < 0.8) then 1 else 0 end ) as [ 0-0.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0.8 and v.Throughput/1000 < 1.6) then 1 else 0 end ) as [ 0.8-1.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1.6 and v.Throughput/1000 < 2.4) then 1 else 0 end ) as [ 1.6-2.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2.4 and v.Throughput/1000 < 3.2) then 1 else 0 end ) as [ 2.4-3.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3.2 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 3.2-4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4 and v.Throughput/1000 < 4.8) then 1 else 0 end ) as [ 4-4.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4.8 and v.Throughput/1000 < 5.6) then 1 else 0 end ) as [ 4.8-5.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=5.6 and v.Throughput/1000 < 6.4) then 1 else 0 end ) as [ 5.6-6.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=6.4 and v.Throughput/1000 < 7.2) then 1 else 0 end ) as [ 6.4-7.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=7.2 and v.Throughput/1000 < 8) then 1 else 0 end ) as [ 7.2-8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=8 and v.Throughput/1000 < 8.8) then 1 else 0 end ) as [ 8-8.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=8.8 and v.Throughput/1000 < 9.6) then 1 else 0 end ) as [ 8.8-9.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=9.6 and v.Throughput/1000 < 10.4) then 1 else 0 end ) as [ 9.6-10.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=10.4 and v.Throughput/1000 < 11.2) then 1 else 0 end ) as [ 10.4-11.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=11.2 and v.Throughput/1000 < 12) then 1 else 0 end ) as [ 11.2-12Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=12 and v.Throughput/1000 < 12.8) then 1 else 0 end ) as [ 12-12.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=12.8 and v.Throughput/1000 < 13.6) then 1 else 0 end ) as [ 12.8-13.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=13.6 and v.Throughput/1000 < 14.4) then 1 else 0 end ) as [ 13.6-14.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=14.4 and v.Throughput/1000 < 15.2) then 1 else 0 end ) as [ 14.4-15.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=15.2 and v.Throughput/1000 < 16) then 1 else 0 end ) as [ 15.2-16Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=16 and v.Throughput/1000 < 16.8) then 1 else 0 end ) as [ 16-16.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=16.8 and v.Throughput/1000 < 17.6) then 1 else 0 end ) as [ 16.8-17.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=17.6 and v.Throughput/1000 < 18.4) then 1 else 0 end ) as [ 17.6-18.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=18.4 and v.Throughput/1000 < 19.2) then 1 else 0 end ) as [ 18.4-19.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=19.2 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 19.2-20Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=20 and v.Throughput/1000 < 20.8) then 1 else 0 end ) as [ 20-20.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=20.8 and v.Throughput/1000 < 21.6) then 1 else 0 end ) as [ 20.8-21.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=21.6 and v.Throughput/1000 < 22.4) then 1 else 0 end ) as [ 21.6-22.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=22.4 and v.Throughput/1000 < 23.2) then 1 else 0 end ) as [ 22.4-23.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=23.2 and v.Throughput/1000 < 24) then 1 else 0 end ) as [ 23.2-24Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=24 and v.Throughput/1000 < 24.8) then 1 else 0 end ) as [ 24-24.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=24.8 and v.Throughput/1000 < 25.6) then 1 else 0 end ) as [ 24.8-25.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=25.6 and v.Throughput/1000 < 26.4) then 1 else 0 end ) as [ 25.6-26.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=26.4 and v.Throughput/1000 < 27.2) then 1 else 0 end ) as [ 26.4-27.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=27.2 and v.Throughput/1000 < 28) then 1 else 0 end ) as [ 27.2-28Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=28 and v.Throughput/1000 < 28.8) then 1 else 0 end ) as [ 28-28.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=28.8 and v.Throughput/1000 < 29.6) then 1 else 0 end ) as [ 28.8-29.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=29.6 and v.Throughput/1000 < 30.4) then 1 else 0 end ) as [ 29.6-30.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=30.4 and v.Throughput/1000 < 31.2) then 1 else 0 end ) as [ 30.4-31.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=31.2 and v.Throughput/1000 < 32) then 1 else 0 end ) as [ 31.2-32Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=32 and v.Throughput/1000 < 32.8) then 1 else 0 end ) as [ 32-32.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=32.8 and v.Throughput/1000 < 33.6) then 1 else 0 end ) as [ 32.8-33.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=33.6 and v.Throughput/1000 < 34.4) then 1 else 0 end ) as [ 33.6-34.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=34.4 and v.Throughput/1000 < 35.2) then 1 else 0 end ) as [ 34.4-35.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=35.2 and v.Throughput/1000 < 36) then 1 else 0 end ) as [ 35.2-36Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=36 and v.Throughput/1000 < 36.8) then 1 else 0 end ) as [ 36-36.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=36.8 and v.Throughput/1000 < 37.6) then 1 else 0 end ) as [ 36.8-37.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=37.6 and v.Throughput/1000 < 38.4) then 1 else 0 end ) as [ 37.6-38.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=38.4 and v.Throughput/1000 < 39.2) then 1 else 0 end ) as [ 38.4-39.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=39.2 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 39.2-40Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=40 and v.Throughput/1000 < 40.8) then 1 else 0 end ) as [ 40-40.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=40.8 and v.Throughput/1000 < 41.6) then 1 else 0 end ) as [ 40.8-41.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=41.6 and v.Throughput/1000 < 42.4) then 1 else 0 end ) as [ 41.6-42.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=42.4 and v.Throughput/1000 < 43.2) then 1 else 0 end ) as [ 42.4-43.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=43.2 and v.Throughput/1000 < 44) then 1 else 0 end ) as [ 43.2-44Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=44 and v.Throughput/1000 < 44.8) then 1 else 0 end ) as [ 44-44.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=44.8 and v.Throughput/1000 < 45.6) then 1 else 0 end ) as [ 44.8-45.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=45.6 and v.Throughput/1000 < 46.4) then 1 else 0 end ) as [ 45.6-46.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=46.4 and v.Throughput/1000 < 47.2) then 1 else 0 end ) as [ 46.4-47.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=47.2 and v.Throughput/1000 < 48) then 1 else 0 end ) as [ 47.2-48Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=48 and v.Throughput/1000 < 48.8) then 1 else 0 end ) as [ 48-48.8Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=48.8 and v.Throughput/1000 < 49.6) then 1 else 0 end ) as [ 48.8-49.6Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=49.6 and v.Throughput/1000 < 50.4) then 1 else 0 end ) as [ 49.6-50.4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=50.4 and v.Throughput/1000 < 51.2) then 1 else 0 end ) as [ 50.4-51.2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=51.2 and v.Throughput/1000 < 52) then 1 else 0 end ) as [ 51.2-52Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=52) then 1 else 0 end ) as [ >52Mbps_N ],

				
		--'' as [% > Umbral], --PDTE
		--'' as [% > Umbral_sec], --PDTE
		----Para % a partir de un umbral (en ejemplo 3000)
		--case when (SUM (case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 
		--					else 0 
		--				end)) = 0 then 0 
		--	else (1.0*SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)
		--		/SUM (case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end)) 
		--end

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'GRID',
		null,

		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.TransferTime is not null) then 1 else 0 end) as 'Count_TransferTime',
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime',
				--20170626:   -@MDM: Nuevo KPI para metología FY1718
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>384) then 1 else 0 end) as 'Count_Throughput_384k',
		--20170719:   -CAC: Nuevo KPI para metología FY1718
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>1000) then 1 else 0 end) as 'Count_Throughput_1M',
		
		--CAC 10/08/2017: se calcula el thput de test con error en todos los casos posibles (no en todos los errores se rellena info en tablas de sistema)
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.ErrorType is not null and ISNULL(v.ThputApp_nu,0)>0) then v.ThputApp_nu end) as 'Throughput_ERROR',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.ErrorType is not null and ISNULL(v.ThputApp_nu,0)>0) then 1 else 0 end) as 'Count_Throughput_ERROR',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 
			(case when v.ErrorType is null and ISNULL(v.Throughput,0)>0 then v.Throughput
				when v.ErrorType is not null and ISNULL(v.ThputApp_nu,0)>0 then v.ThputApp_nu end)
		end) as 'Throughput_ALL',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC') then 
			(case when (v.ErrorType is null and ISNULL(v.Throughput,0)>0) or (v.ErrorType is not null and ISNULL(v.ThputApp_nu,0)>0) then 1
				else 0 end)
		end) as 'Count_Throughput_ALL'
	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_UL v
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='UL_NC'
	group by v.MNC
end


select * from @data_ULthputNC_LTE
