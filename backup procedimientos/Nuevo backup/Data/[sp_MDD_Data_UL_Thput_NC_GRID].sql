USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_UL_Thput_NC_GRID]    Script Date: 31/10/2017 15:38:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_UL_Thput_NC_GRID] (
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
declare @data_ULthputNC  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Subidas] [int] NULL,
	[Fallos de Acceso] [int] NULL,
	[Fallos de descarga] [int] NULL,
	[Throughput] [float] NULL,
	[Throughput_Desv] [float] NULL,
	[Tiempo de subida] [float] NULL,
	[SessionTime] [float] NULL,
	[Throughput Max] [float] NULL,
	[RLC_MAX] [float] NULL,
	[Count_Throughput] [int] null,
	[Count_Throughput_64k] [int] null,
	[ 0-0.5Mbps] [int] NULL,
	[ 0.5-1Mbps] [int] NULL,
	[ 1-1.5Mbps] [int] NULL,
	[ 1.5-2Mbps] [int] NULL,
	[ 2-2.5Mbps] [int] NULL,
	[ 2.5-3Mbps] [int] NULL,
	[ 3-3.5Mbps] [int] NULL,
	[ 3.5-4Mbps] [int] NULL,
	[ 4-4.5Mbps] [int] NULL,
	[ 4.5-5Mbps] [int] NULL,
	[ >5Mbps] [int] NULL,

	--20/02/2017 Se incluyen los nuevos rangos para el calculo de los percentiles
	[ 0-0.25Mbps_N ] [int] NULL,
	[ 0.25-0.5Mbps_N ] [int] NULL,
	[ 0.5-0.75Mbps_N ] [int] NULL,
	[ 0.75-1Mbps_N ] [int] NULL,
	[ 1-1.25Mbps_N ] [int] NULL,
	[ 1.25-1.5Mbps_N ] [int] NULL,
	[ 1.5-1.75Mbps_N ] [int] NULL,
	[ 1.75-2Mbps_N ] [int] NULL,
	[ 2-2.25Mbps_N ] [int] NULL,
	[ 2.25-2.5Mbps_N ] [int] NULL,
	[ 2.5-2.75Mbps_N ] [int] NULL,
	[ 2.75-3Mbps_N ] [int] NULL,
	[ 3-3.25Mbps_N ] [int] NULL,
	[ 3.25-3.5Mbps_N ] [int] NULL,
	[ 3.5-3.75Mbps_N ] [int] NULL,
	[ 3.75-4Mbps_N ] [int] NULL,
	[ 4-4.25Mbps_N ] [int] NULL,
	[ 4.25-4.5Mbps_N ] [int] NULL,
	[ 4.5-4.75Mbps_N ] [int] NULL,
	[ 4.75-5Mbps_N ] [int] NULL,
	[ >5Mbps_N ] [int] NULL,

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
	insert into @data_ULthputNC
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC') then 1 else 0 end) as 'Subidas',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		STDEV(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput_Desv',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.TransferTime end) as 'Tiempo de subida',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.sessiontime end) as 'SessionTime',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC') then v.RLC_MAX end) as 'RLC_MAX',
	
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>64) then 1 else 0 end) as 'Count_Throughput_64k',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 0 and v.Throughput/1000 < 0.5) then 1 else 0 end ) as [ 0-0.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 0.5 and v.Throughput/1000 < 1) then 1 else 0 end ) as [ 0.5-1Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 1 and v.Throughput/1000 < 1.5)then 1 else 0 end )  as [ 1-1.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 1.5 and v.Throughput/1000 < 2) then 1 else 0 end ) as [ 1.5-2Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 2 and v.Throughput/1000 < 2.5) then 1 else 0 end ) as [ 2-2.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 2.5 and v.Throughput/1000 < 3) then 1 else 0 end ) as [ 2.5-3Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 3 and v.Throughput/1000 < 3.5) then 1 else 0 end ) as [ 3-3.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 3.5 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 3.5-4Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 4 and v.Throughput/1000 < 4.5) then 1 else 0 end ) as [ 4-4.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 4.5 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 4.5-5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 5) then 1 else 0 end ) as [ >5Mbps],
		
		--20/02/2017 Se incluyen los nuevos rangos para el calculo de los percentiles
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0 and v.Throughput/1000 < 0.25) then 1 else 0 end ) as [ 0-0.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0.25 and v.Throughput/1000 < 0.5) then 1 else 0 end ) as [ 0.25-0.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0.5 and v.Throughput/1000 < 0.75) then 1 else 0 end ) as [ 0.5-0.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0.75 and v.Throughput/1000 < 1) then 1 else 0 end ) as [ 0.75-1Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1 and v.Throughput/1000 < 1.25) then 1 else 0 end ) as [ 1-1.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1.25 and v.Throughput/1000 < 1.5) then 1 else 0 end ) as [ 1.25-1.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1.5 and v.Throughput/1000 < 1.75) then 1 else 0 end ) as [ 1.5-1.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1.75 and v.Throughput/1000 < 2) then 1 else 0 end ) as [ 1.75-2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2 and v.Throughput/1000 < 2.25) then 1 else 0 end ) as [ 2-2.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2.25 and v.Throughput/1000 < 2.5) then 1 else 0 end ) as [ 2.25-2.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2.5 and v.Throughput/1000 < 2.75) then 1 else 0 end ) as [ 2.5-2.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2.75 and v.Throughput/1000 < 3) then 1 else 0 end ) as [ 2.75-3Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3 and v.Throughput/1000 < 3.25) then 1 else 0 end ) as [ 3-3.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3.25 and v.Throughput/1000 < 3.5) then 1 else 0 end ) as [ 3.25-3.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3.5 and v.Throughput/1000 < 3.75) then 1 else 0 end ) as [ 3.5-3.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3.75 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 3.75-4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4 and v.Throughput/1000 < 4.25) then 1 else 0 end ) as [ 4-4.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4.25 and v.Throughput/1000 < 4.5) then 1 else 0 end ) as [ 4.25-4.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4.5 and v.Throughput/1000 < 4.75) then 1 else 0 end ) as [ 4.5-4.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4.75 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 4.75-5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=5) then 1 else 0 end ) as [ >5Mbps_N ],

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
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime'

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
	insert into @data_ULthputNC
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC') then 1 else 0 end) as 'Subidas',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		STDEV(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput_Desv',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.TransferTime end) as 'Tiempo de subida',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.sessiontime end) as 'SessionTime',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC') then v.RLC_MAX end) as 'RLC_MAX',
	
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>64) then 1 else 0 end) as 'Count_Throughput_64k',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 0 and v.Throughput/1000 < 0.5) then 1 else 0 end ) as [ 0-0.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 0.5 and v.Throughput/1000 < 1) then 1 else 0 end ) as [ 0.5-1Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 1 and v.Throughput/1000 < 1.5)then 1 else 0 end )  as [ 1-1.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 1.5 and v.Throughput/1000 < 2) then 1 else 0 end ) as [ 1.5-2Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 2 and v.Throughput/1000 < 2.5) then 1 else 0 end ) as [ 2-2.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 2.5 and v.Throughput/1000 < 3) then 1 else 0 end ) as [ 2.5-3Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 3 and v.Throughput/1000 < 3.5) then 1 else 0 end ) as [ 3-3.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 3.5 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 3.5-4Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 4 and v.Throughput/1000 < 4.5) then 1 else 0 end ) as [ 4-4.5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 4.5 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 4.5-5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 5) then 1 else 0 end ) as [ >5Mbps],
		
		--20/02/2017 Se incluyen los nuevos rangos para el calculo de los percentiles
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0 and v.Throughput/1000 < 0.25) then 1 else 0 end ) as [ 0-0.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0.25 and v.Throughput/1000 < 0.5) then 1 else 0 end ) as [ 0.25-0.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0.5 and v.Throughput/1000 < 0.75) then 1 else 0 end ) as [ 0.5-0.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=0.75 and v.Throughput/1000 < 1) then 1 else 0 end ) as [ 0.75-1Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1 and v.Throughput/1000 < 1.25) then 1 else 0 end ) as [ 1-1.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1.25 and v.Throughput/1000 < 1.5) then 1 else 0 end ) as [ 1.25-1.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1.5 and v.Throughput/1000 < 1.75) then 1 else 0 end ) as [ 1.5-1.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=1.75 and v.Throughput/1000 < 2) then 1 else 0 end ) as [ 1.75-2Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2 and v.Throughput/1000 < 2.25) then 1 else 0 end ) as [ 2-2.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2.25 and v.Throughput/1000 < 2.5) then 1 else 0 end ) as [ 2.25-2.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2.5 and v.Throughput/1000 < 2.75) then 1 else 0 end ) as [ 2.5-2.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=2.75 and v.Throughput/1000 < 3) then 1 else 0 end ) as [ 2.75-3Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3 and v.Throughput/1000 < 3.25) then 1 else 0 end ) as [ 3-3.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3.25 and v.Throughput/1000 < 3.5) then 1 else 0 end ) as [ 3.25-3.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3.5 and v.Throughput/1000 < 3.75) then 1 else 0 end ) as [ 3.5-3.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=3.75 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 3.75-4Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4 and v.Throughput/1000 < 4.25) then 1 else 0 end ) as [ 4-4.25Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4.25 and v.Throughput/1000 < 4.5) then 1 else 0 end ) as [ 4.25-4.5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4.5 and v.Throughput/1000 < 4.75) then 1 else 0 end ) as [ 4.5-4.75Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=4.75 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 4.75-5Mbps_N ],
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.Throughput/1000 >=5) then 1 else 0 end ) as [ >5Mbps_N ],

		
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
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime'

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


select * from @data_ULthputNC



