USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_DL_Thput_CE_LTE_GRID]    Script Date: 29/05/2017 12:16:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_DL_Thput_CE_LTE_GRID] (
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
--use FY1617_Data_Rest_3G_H1_4

--declare @ciudad as varchar(256) = 'AMPOSTA'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @Info as varchar (256) = 'Completed' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @sheet as varchar(256) = '%%' --%%/LTE/WCDMA
--declare @Tech as varchar (256) = '4G'
--declare @methodology as varchar (256) = 'D16'
--declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

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
		case when v.[% CA] >0 then 'CA'
		else 'SC' end as hasCA
	from Lcc_Data_HTTPTransfer_DL v, testinfo t, lcc_position_Entity_List_Vodafone c
	Where t.testid=v.testid
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
		v.[Longitud Final], v.[Latitud Final],
		case when v.[% CA] >0 then 'CA'
		else 'SC' end
end

If @Report='OSP'
begin
	insert into @All_Tests_Tech 
	select v.sessionid, v.testid,
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
			else 'Mixed' 
		end as tech,	
		case when v.[% CA] >0 then 'CA'
		else 'SC' end as hasCA
	from Lcc_Data_HTTPTransfer_DL v, testinfo t, lcc_position_Entity_List_Orange c
	Where t.testid=v.testid
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
		v.[Longitud Final], v.[Latitud Final],
		case when v.[% CA] >0 then 'CA'
		else 'SC' end
end

If @Report='MUN'
begin
	insert into @All_Tests_Tech 
	select v.sessionid, v.testid,
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
			else 'Mixed' 
		end as tech,	
		case when v.[% CA] >0 then 'CA'
		else 'SC' end as hasCA
	from Lcc_Data_HTTPTransfer_DL v, testinfo t, lcc_position_Entity_List_Municipio c
	Where t.testid=v.testid
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
		v.[Longitud Final], v.[Latitud Final],
		case when v.[% CA] >0 then 'CA'
		else 'SC' end
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
declare @dateMax datetime2(3)= (select max(c.endTime) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)
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
--	from Lcc_Data_HTTPTransfer_DL where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

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
declare @data_DLthputCE_LTE  as table (
    [Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Navegaciones] [int] NULL,
	[Fallos de Acceso] [int] NULL,
	[Fallos de descarga] [int] NULL,
	[Throughput] [float] NULL,
	[Tiempo de Descarga] [float] NULL,
	[SessionTime] [float] NULL,
	[Throughput Max] [float] NULL,
	[RLC_MAX] [float] NULL,
	[Count_Throughput] [int] null,
	[Count_Throughput_1M] [int] null,
	[Count_Throughput_3M] [int] null,
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
    [ 50-55Mbps] [int] NULL,
    [ 55-60Mbps] [int] NULL,
    [ 60-65Mbps] [int] NULL,
    [ 65-70Mbps] [int] NULL,
    [ 70-75Mbps] [int] NULL,
    [ 75-80Mbps] [int] NULL,
    [ 80-85Mbps] [int] NULL,
    [ 85-90Mbps] [int] NULL,
    [ 90-95Mbps] [int] NULL,
    [ 95-100Mbps] [int] NULL,
    [ 100-105Mbps] [int] NULL,
    [ 105-110Mbps] [int] NULL,
    [ 110-115Mbps] [int] NULL,
    [ 115-120Mbps] [int] NULL,
    [ 120-125Mbps] [int] NULL,
    [ 125-130Mbps] [int] NULL,
    [ 130-135Mbps] [int] NULL,
    [ 135-140Mbps] [int] NULL,
    [ 140-145Mbps] [int] NULL,
    [ 145-150Mbps] [int] NULL,
	[ >150Mbps] [int] NULL,

	--20/02/2017 Se incluyen los nuevos rangos para el calculo de los percentiles
	[ 0-2Mbps_N ] [int] NULL,
	[ 2-4Mbps_N ] [int] NULL,
	[ 4-6Mbps_N ] [int] NULL,
	[ 6-8Mbps_N ] [int] NULL,
	[ 8-10Mbps_N ] [int] NULL,
	[ 10-12Mbps_N ] [int] NULL,
	[ 12-14Mbps_N ] [int] NULL,
	[ 14-16Mbps_N ] [int] NULL,
	[ 16-18Mbps_N ] [int] NULL,
	[ 18-20Mbps_N ] [int] NULL,
	[ 20-22Mbps_N ] [int] NULL,
	[ 22-24Mbps_N ] [int] NULL,
	[ 24-26Mbps_N ] [int] NULL,
	[ 26-28Mbps_N ] [int] NULL,
	[ 28-30Mbps_N ] [int] NULL,
	[ 30-32Mbps_N ] [int] NULL,
	[ 32-34Mbps_N ] [int] NULL,
	[ 34-36Mbps_N ] [int] NULL,
	[ 36-38Mbps_N ] [int] NULL,
	[ 38-40Mbps_N ] [int] NULL,
	[ 40-42Mbps_N ] [int] NULL,
	[ 42-44Mbps_N ] [int] NULL,
	[ 44-46Mbps_N ] [int] NULL,
	[ 46-48Mbps_N ] [int] NULL,
	[ 48-50Mbps_N ] [int] NULL,
	[ 50-52Mbps_N ] [int] NULL,
	[ 52-54Mbps_N ] [int] NULL,
	[ 54-56Mbps_N ] [int] NULL,
	[ 56-58Mbps_N ] [int] NULL,
	[ 58-60Mbps_N ] [int] NULL,
	[ 60-62Mbps_N ] [int] NULL,
	[ 62-64Mbps_N ] [int] NULL,
	[ 64-66Mbps_N ] [int] NULL,
	[ 66-68Mbps_N ] [int] NULL,
	[ 68-70Mbps_N ] [int] NULL,
	[ 70-72Mbps_N ] [int] NULL,
	[ 72-74Mbps_N ] [int] NULL,
	[ 74-76Mbps_N ] [int] NULL,
	[ 76-78Mbps_N ] [int] NULL,
	[ 78-80Mbps_N ] [int] NULL,
	[ 80-82Mbps_N ] [int] NULL,
	[ 82-84Mbps_N ] [int] NULL,
	[ 84-86Mbps_N ] [int] NULL,
	[ 86-88Mbps_N ] [int] NULL,
	[ 88-90Mbps_N ] [int] NULL,
	[ 90-92Mbps_N ] [int] NULL,
	[ 92-94Mbps_N ] [int] NULL,
	[ 94-96Mbps_N ] [int] NULL,
	[ 96-98Mbps_N ] [int] NULL,
	[ 98-100Mbps_N ] [int] NULL,
	[ >100Mbps_N] [int] NULL,

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
	[Count_SessionTime] [int] null

)

if @Indoor=0
begin
	insert into @data_DLthputCE_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.TransferTime end) as 'Tiempo de Descarga',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.sessionTime end) as 'SessionTime',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[RLC Thput] end) as 'RLC_MAX',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>1000) then 1 else 0 end)'Count_Throughput_1M',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)'Count_Throughput_3M',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=0 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 0-5Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=5 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 5-10Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=10 and v.Throughput/1000 < 15) then 1 else 0 end ) as [ 10-15Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=15 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 15-20Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=20 and v.Throughput/1000 < 25) then 1 else 0 end ) as [ 20-25Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=25 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 25-30Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=30 and v.Throughput/1000 < 35) then 1 else 0 end ) as [ 30-35Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=35 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 35-40Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=40 and v.Throughput/1000 < 45) then 1 else 0 end ) as [ 40-45Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=45 and v.Throughput/1000 < 50) then 1 else 0 end ) as [ 45-50Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=50 and v.Throughput/1000 < 55) then 1 else 0 end ) as [ 50-55Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=55 and v.Throughput/1000 < 60) then 1 else 0 end ) as [ 55-60Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=60 and v.Throughput/1000 < 65) then 1 else 0 end ) as [ 60-65Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=65 and v.Throughput/1000 < 70) then 1 else 0 end ) as [ 65-70Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=70 and v.Throughput/1000 < 75) then 1 else 0 end ) as [ 70-75Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=75 and v.Throughput/1000 < 80) then 1 else 0 end ) as [ 75-80Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=80 and v.Throughput/1000 < 85) then 1 else 0 end ) as [ 80-85Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=85 and v.Throughput/1000 < 90) then 1 else 0 end ) as [ 85-90Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=90 and v.Throughput/1000 < 95) then 1 else 0 end ) as [ 90-95Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=95 and v.Throughput/1000 < 100) then 1 else 0 end ) as [ 95-100Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=100 and v.Throughput/1000 < 105) then 1 else 0 end ) as [ 100-105Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=105 and v.Throughput/1000 < 110) then 1 else 0 end ) as [ 105-110Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=110 and v.Throughput/1000 < 115) then 1 else 0 end ) as [ 110-115Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=115 and v.Throughput/1000 < 120) then 1 else 0 end ) as [ 115-120Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=120 and v.Throughput/1000 < 125) then 1 else 0 end ) as [ 120-125Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=125 and v.Throughput/1000 < 130) then 1 else 0 end ) as [ 125-130Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=130 and v.Throughput/1000 < 135) then 1 else 0 end ) as [ 130-135Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=135 and v.Throughput/1000 < 140) then 1 else 0 end ) as [ 135-140Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=140 and v.Throughput/1000 < 145) then 1 else 0 end ) as [ 140-145Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=145 and v.Throughput/1000 < 150) then 1 else 0 end ) as [ 145-150Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >= 150) then 1 else 0 end ) as [ >150Mbps],
		
		--20/02/2017 Se incluyen los nuevos rangos para el calculo de los percentiles
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=0 and v.Throughput/1000 < 2) then 1 else 0 end ) as [ 0-2Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=2 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 2-4Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=4 and v.Throughput/1000 < 6) then 1 else 0 end ) as [ 4-6Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=6 and v.Throughput/1000 < 8) then 1 else 0 end ) as [ 6-8Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=8 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 8-10Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=10 and v.Throughput/1000 < 12) then 1 else 0 end ) as [ 10-12Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=12 and v.Throughput/1000 < 14) then 1 else 0 end ) as [ 12-14Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=14 and v.Throughput/1000 < 16) then 1 else 0 end ) as [ 14-16Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=16 and v.Throughput/1000 < 18) then 1 else 0 end ) as [ 16-18Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=18 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 18-20Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=20 and v.Throughput/1000 < 22) then 1 else 0 end ) as [ 20-22Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=22 and v.Throughput/1000 < 24) then 1 else 0 end ) as [ 22-24Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=24 and v.Throughput/1000 < 26) then 1 else 0 end ) as [ 24-26Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=26 and v.Throughput/1000 < 28) then 1 else 0 end ) as [ 26-28Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=28 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 28-30Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=30 and v.Throughput/1000 < 32) then 1 else 0 end ) as [ 30-32Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=32 and v.Throughput/1000 < 34) then 1 else 0 end ) as [ 32-34Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=34 and v.Throughput/1000 < 36) then 1 else 0 end ) as [ 34-36Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=36 and v.Throughput/1000 < 38) then 1 else 0 end ) as [ 36-38Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=38 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 38-40Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=40 and v.Throughput/1000 < 42) then 1 else 0 end ) as [ 40-42Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=42 and v.Throughput/1000 < 44) then 1 else 0 end ) as [ 42-44Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=44 and v.Throughput/1000 < 46) then 1 else 0 end ) as [ 44-46Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=46 and v.Throughput/1000 < 48) then 1 else 0 end ) as [ 46-48Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=48 and v.Throughput/1000 < 50) then 1 else 0 end ) as [ 48-50Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=50 and v.Throughput/1000 < 52) then 1 else 0 end ) as [ 50-52Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=52 and v.Throughput/1000 < 54) then 1 else 0 end ) as [ 52-54Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=54 and v.Throughput/1000 < 56) then 1 else 0 end ) as [ 54-56Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=56 and v.Throughput/1000 < 58) then 1 else 0 end ) as [ 56-58Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=58 and v.Throughput/1000 < 60) then 1 else 0 end ) as [ 58-60Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=60 and v.Throughput/1000 < 62) then 1 else 0 end ) as [ 60-62Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=62 and v.Throughput/1000 < 64) then 1 else 0 end ) as [ 62-64Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=64 and v.Throughput/1000 < 66) then 1 else 0 end ) as [ 64-66Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=66 and v.Throughput/1000 < 68) then 1 else 0 end ) as [ 66-68Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=68 and v.Throughput/1000 < 70) then 1 else 0 end ) as [ 68-70Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=70 and v.Throughput/1000 < 72) then 1 else 0 end ) as [ 70-72Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=72 and v.Throughput/1000 < 74) then 1 else 0 end ) as [ 72-74Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=74 and v.Throughput/1000 < 76) then 1 else 0 end ) as [ 74-76Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=76 and v.Throughput/1000 < 78) then 1 else 0 end ) as [ 76-78Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=78 and v.Throughput/1000 < 80) then 1 else 0 end ) as [ 78-80Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=80 and v.Throughput/1000 < 82) then 1 else 0 end ) as [ 80-82Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=82 and v.Throughput/1000 < 84) then 1 else 0 end ) as [ 82-84Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=84 and v.Throughput/1000 < 86) then 1 else 0 end ) as [ 84-86Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=86 and v.Throughput/1000 < 88) then 1 else 0 end ) as [ 86-88Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=88 and v.Throughput/1000 < 90) then 1 else 0 end ) as [ 88-90Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=90 and v.Throughput/1000 < 92) then 1 else 0 end ) as [ 90-92Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=92 and v.Throughput/1000 < 94) then 1 else 0 end ) as [ 92-94Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=94 and v.Throughput/1000 < 96) then 1 else 0 end ) as [ 94-96Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=96 and v.Throughput/1000 < 98) then 1 else 0 end ) as [ 96-98Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=98 and v.Throughput/1000 < 100) then 1 else 0 end ) as [ 98-100Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=100) then 1 else 0 end ) as [ >100Mbps_N ] ,

		
		--'' as [% > Umbral], --PDTE
		--'' as [% > Umbral_sec], --PDTE
		----Para % a partir de un umbral (en ejemplo 3000)
		--case when (SUM (case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then 1 
		--					else 0 
		--				end)) = 0 then 0 
		--	else (1.0*SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)
		--		/SUM (case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then 1 else 0 end)) 
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

		sum(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.TransferTime is not null) then 1 else 0 end) as 'Count_TransferTime',
		sum(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime'

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_DL v,
		Agrids.dbo.lcc_parcelas lp
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='DL_CE'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) 
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]),v.MNC,lp.Region_VF,lp.Region_OSP
end 
else
begin
	insert into @data_DLthputCE_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.TransferTime end) as 'Tiempo de Descarga',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.sessionTime end) as 'SessionTime',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[RLC Thput] end) as 'RLC_MAX',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>1000) then 1 else 0 end)'Count_Throughput_1M',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)'Count_Throughput_3M',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=0 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 0-5Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=5 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 5-10Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=10 and v.Throughput/1000 < 15) then 1 else 0 end ) as [ 10-15Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=15 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 15-20Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=20 and v.Throughput/1000 < 25) then 1 else 0 end ) as [ 20-25Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=25 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 25-30Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=30 and v.Throughput/1000 < 35) then 1 else 0 end ) as [ 30-35Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=35 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 35-40Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=40 and v.Throughput/1000 < 45) then 1 else 0 end ) as [ 40-45Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=45 and v.Throughput/1000 < 50) then 1 else 0 end ) as [ 45-50Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=50 and v.Throughput/1000 < 55) then 1 else 0 end ) as [ 50-55Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=55 and v.Throughput/1000 < 60) then 1 else 0 end ) as [ 55-60Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=60 and v.Throughput/1000 < 65) then 1 else 0 end ) as [ 60-65Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=65 and v.Throughput/1000 < 70) then 1 else 0 end ) as [ 65-70Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=70 and v.Throughput/1000 < 75) then 1 else 0 end ) as [ 70-75Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=75 and v.Throughput/1000 < 80) then 1 else 0 end ) as [ 75-80Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=80 and v.Throughput/1000 < 85) then 1 else 0 end ) as [ 80-85Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=85 and v.Throughput/1000 < 90) then 1 else 0 end ) as [ 85-90Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=90 and v.Throughput/1000 < 95) then 1 else 0 end ) as [ 90-95Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=95 and v.Throughput/1000 < 100) then 1 else 0 end ) as [ 95-100Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=100 and v.Throughput/1000 < 105) then 1 else 0 end ) as [ 100-105Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=105 and v.Throughput/1000 < 110) then 1 else 0 end ) as [ 105-110Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=110 and v.Throughput/1000 < 115) then 1 else 0 end ) as [ 110-115Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=115 and v.Throughput/1000 < 120) then 1 else 0 end ) as [ 115-120Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=120 and v.Throughput/1000 < 125) then 1 else 0 end ) as [ 120-125Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=125 and v.Throughput/1000 < 130) then 1 else 0 end ) as [ 125-130Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=130 and v.Throughput/1000 < 135) then 1 else 0 end ) as [ 130-135Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=135 and v.Throughput/1000 < 140) then 1 else 0 end ) as [ 135-140Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=140 and v.Throughput/1000 < 145) then 1 else 0 end ) as [ 140-145Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=145 and v.Throughput/1000 < 150) then 1 else 0 end ) as [ 145-150Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >= 150) then 1 else 0 end ) as [ >150Mbps],
		
		--20/02/2017 Se incluyen los nuevos rangos para el calculo de los percentiles
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=0 and v.Throughput/1000 < 2) then 1 else 0 end ) as [ 0-2Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=2 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 2-4Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=4 and v.Throughput/1000 < 6) then 1 else 0 end ) as [ 4-6Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=6 and v.Throughput/1000 < 8) then 1 else 0 end ) as [ 6-8Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=8 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 8-10Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=10 and v.Throughput/1000 < 12) then 1 else 0 end ) as [ 10-12Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=12 and v.Throughput/1000 < 14) then 1 else 0 end ) as [ 12-14Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=14 and v.Throughput/1000 < 16) then 1 else 0 end ) as [ 14-16Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=16 and v.Throughput/1000 < 18) then 1 else 0 end ) as [ 16-18Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=18 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 18-20Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=20 and v.Throughput/1000 < 22) then 1 else 0 end ) as [ 20-22Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=22 and v.Throughput/1000 < 24) then 1 else 0 end ) as [ 22-24Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=24 and v.Throughput/1000 < 26) then 1 else 0 end ) as [ 24-26Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=26 and v.Throughput/1000 < 28) then 1 else 0 end ) as [ 26-28Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=28 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 28-30Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=30 and v.Throughput/1000 < 32) then 1 else 0 end ) as [ 30-32Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=32 and v.Throughput/1000 < 34) then 1 else 0 end ) as [ 32-34Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=34 and v.Throughput/1000 < 36) then 1 else 0 end ) as [ 34-36Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=36 and v.Throughput/1000 < 38) then 1 else 0 end ) as [ 36-38Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=38 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 38-40Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=40 and v.Throughput/1000 < 42) then 1 else 0 end ) as [ 40-42Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=42 and v.Throughput/1000 < 44) then 1 else 0 end ) as [ 42-44Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=44 and v.Throughput/1000 < 46) then 1 else 0 end ) as [ 44-46Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=46 and v.Throughput/1000 < 48) then 1 else 0 end ) as [ 46-48Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=48 and v.Throughput/1000 < 50) then 1 else 0 end ) as [ 48-50Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=50 and v.Throughput/1000 < 52) then 1 else 0 end ) as [ 50-52Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=52 and v.Throughput/1000 < 54) then 1 else 0 end ) as [ 52-54Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=54 and v.Throughput/1000 < 56) then 1 else 0 end ) as [ 54-56Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=56 and v.Throughput/1000 < 58) then 1 else 0 end ) as [ 56-58Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=58 and v.Throughput/1000 < 60) then 1 else 0 end ) as [ 58-60Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=60 and v.Throughput/1000 < 62) then 1 else 0 end ) as [ 60-62Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=62 and v.Throughput/1000 < 64) then 1 else 0 end ) as [ 62-64Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=64 and v.Throughput/1000 < 66) then 1 else 0 end ) as [ 64-66Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=66 and v.Throughput/1000 < 68) then 1 else 0 end ) as [ 66-68Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=68 and v.Throughput/1000 < 70) then 1 else 0 end ) as [ 68-70Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=70 and v.Throughput/1000 < 72) then 1 else 0 end ) as [ 70-72Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=72 and v.Throughput/1000 < 74) then 1 else 0 end ) as [ 72-74Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=74 and v.Throughput/1000 < 76) then 1 else 0 end ) as [ 74-76Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=76 and v.Throughput/1000 < 78) then 1 else 0 end ) as [ 76-78Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=78 and v.Throughput/1000 < 80) then 1 else 0 end ) as [ 78-80Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=80 and v.Throughput/1000 < 82) then 1 else 0 end ) as [ 80-82Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=82 and v.Throughput/1000 < 84) then 1 else 0 end ) as [ 82-84Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=84 and v.Throughput/1000 < 86) then 1 else 0 end ) as [ 84-86Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=86 and v.Throughput/1000 < 88) then 1 else 0 end ) as [ 86-88Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=88 and v.Throughput/1000 < 90) then 1 else 0 end ) as [ 88-90Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=90 and v.Throughput/1000 < 92) then 1 else 0 end ) as [ 90-92Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=92 and v.Throughput/1000 < 94) then 1 else 0 end ) as [ 92-94Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=94 and v.Throughput/1000 < 96) then 1 else 0 end ) as [ 94-96Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=96 and v.Throughput/1000 < 98) then 1 else 0 end ) as [ 96-98Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=98 and v.Throughput/1000 < 100) then 1 else 0 end ) as [ 98-100Mbps_N ] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=100) then 1 else 0 end ) as [ >100Mbps_N ] ,
	
		
		--'' as [% > Umbral], --PDTE
		--'' as [% > Umbral_sec], --PDTE
		----Para % a partir de un umbral (en ejemplo 3000)
		--case when (SUM (case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then 1 
		--					else 0 
		--				end)) = 0 then 0 
		--	else (1.0*SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)
		--		/SUM (case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then 1 else 0 end)) 
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

		sum(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.TransferTime is not null) then 1 else 0 end) as 'Count_TransferTime',
		sum(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime'

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_DL v
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='DL_CE'
	group by v.MNC
end


select * from @data_DLthputCE_LTE