USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_DL_Performance_NC_LTE_FY1617_GRID]    Script Date: 31/10/2017 13:53:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_DL_Performance_NC_LTE_FY1617_GRID](
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
--use [FY1617_Data_AVE_Rest_H2]

--declare @ciudad as varchar(256) = 'AVE-Cordoba-Malaga-R4'
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
declare @data_DLperfNC  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[ RBs] [numeric](38, 12) NULL,
	[ RBs MAX] [numeric](13, 0) NULL,
	[ RBs MIN] [numeric](13, 0) NULL,
	[ % TM Invalid] [numeric](38, 12) NULL,
	[ % TM1] [numeric](38, 12) NULL,
	[ % TM2] [numeric](38, 12) NULL,
	[ % TM3] [numeric](38, 12) NULL,
	[ % TM4] [numeric](38, 12) NULL,
	[ % MIMO] [numeric](38, 12) NULL,
	[ % TM6] [numeric](38, 12) NULL,
	[ % TM7] [numeric](38, 12) NULL,
	[ % TM Unknown] [numeric](38, 12) NULL,
	
	[Count_CQI_U2100] [int] null,
	[Count_CQI_U900] [int] null,
	[Count_CQI_L2600] [int] null,
	[Count_CQI_L2100] [int] null,
	[Count_CQI_L1800] [int] null,
	[Count_CQI_L800] [int] null,
	[CQI_U2100] [float] NULL,
	[CQI_U900] [float] NULL,
	[CQI_L2600] [float] NULL,
	[CQI_L2100] [float] NULL,
	[CQI_L1800] [float] NULL,
	[CQI_L800] [float] NULL,
	[Count_HSPA] [int] null,
	[Count_HSPA+] [int] null,
	[Count_HSPA+_DC] [int] null,
	[Count_LTE_5Mhz_SC] [int] null,
	[Count_LTE_10Mhz_SC] [int] null,
	[Count_LTE_15Mhz_SC] [int] null,
	[Count_LTE_20Mhz_SC] [int] null,	
	[Count_LTE_15Mhz_CA] [int] null,
	[Count_LTE_20Mhz_CA] [int] null,
	[Count_LTE_25Mhz_CA] [int] null,
	[Count_LTE_30Mhz_CA] [int] null,
	[Count_LTE_35Mhz_CA] [int] null,
	[Count_LTE_40Mhz_CA] [int] null,
	[HSPA_PCT] [float] NULL,
	[HSPA+_PCT] [float] NULL,
	[HSPA+_DC_PCT] [float] NULL,
	[LTE_5Mhz_SC_PCT] [float] NULL,
	[LTE_10Mhz_SC_PCT] [float] NULL,
	[LTE_15Mhz_SC_PCT] [float] NULL,
	[LTE_20Mhz_SC_PCT] [float] NULL,	
	[LTE_15Mhz_CA_PCT] [float] NULL,
	[LTE_20Mhz_CA_PCT] [float] NULL,
	[LTE_25Mhz_CA_PCT] [float] NULL,
	[LTE_30Mhz_CA_PCT] [float] NULL,
	[LTE_35Mhz_CA_PCT] [float] NULL,
	[LTE_40Mhz_CA_PCT] [float] NULL,

	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF][varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null, 

	--@ERC-20170126: Se añade CQI 4G
	[CQI_4G] [float] NULL,
	[Count_CQI_4G] [int] null,
	[CQI_4G_PCC] [float] NULL,
	[Count_CQI_4G_PCC] [int] null,
	[CQI_4G_SCC1] [float] NULL,
	[Count_CQI_4G_SCC1] [int] null,

	--@ERC-20170206: Se añade contadores TM - los del CQI no valen
	[Count_TM_Invalid] [int] null,
	[Count_TM1] [int] null,
	[Count_TM2] [int] null,
	[Count_TM3] [int] null,
	[Count_TM4] [int] null,
	[Count_TM5] [int] null,
	[Count_TM6] [int] null,
	[Count_TM7] [int] null,
	[Count_TM_Unknown] [int] null,

	[Count_RBs] [int] null,
	[Region_OSP][varchar](256) NULL,

	--@ERC: Se añaden porque en los POC el valor de los generales no se rellena bien
	[%_TM_Invalid_PCC] [float] NULL,
	[%_TM1_PCC] [float] NULL,
	[%_TM2_PCC] [float] NULL,
	[%_TM3_PCC] [float] NULL,
	[%_TM4_PCC] [float] NULL,
	[%_TM5_PCC] [float] NULL,
	[%_TM6_PCC] [float] NULL,
	[%_TM7_PCC] [float] NULL,
	[%_TM_Unknown_PCC] [float] NULL,

	[Count_TM_Invalid_PCC] [int] null,
	[Count_TM1_PCC] [int] null,
	[Count_TM2_PCC] [int] null,
	[Count_TM3_PCC] [int] null,
	[Count_TM4_PCC] [int] null,
	[Count_TM5_PCC] [int] null,
	[Count_TM6_PCC] [int] null,
	[Count_TM7_PCC] [int] null,
	[Count_TM_Unknown_PCC] [int] null,
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL
)

if @Indoor=0
begin
	insert into @data_DLperfNC
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		-----------------
		-- Performance 4G
		-----------------
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[RBs] end)  as [ RBs],
		MAX(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Max RBs] end)  as [ RBs MAX],
		MIN(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Min RBs] end)  as [ RBs MIN],
		--AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 4G] end)  as [ CQI],
		--AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Rank Indicator] end)  as [ Rank Indicator],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM Invalid] end)  as [ % TM Invalid],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 1: Single Antenna Port 0] end)  as [ % TM1],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 2: TD Rank 1] end)  as [ % TM2],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 3: OL SM] end)  as [ % TM3],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 4: CL SM] end)  as [ % TM4],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 5: MU MIMO] end)  as [ % MIMO],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 6: CL RANK1 PC] end)  as [ % TM6],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 7: Single Antenna Port 5] end)  as [ % TM7],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM Unknown] end)  as [ % TM Unknown],
		
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI UMTS2100] is not null) then 1 else 0 end) as 'Count_CQI_U2100',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI UMTS900] is not null) then 1 else 0 end) as 'Count_CQI_U900',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI LTE2600] is not null) then 1 else 0 end) as 'Count_CQI_L2600',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI LTE2100] is not null) then 1 else 0 end) as 'Count_CQI_L2100',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI LTE1800] is not null) then 1 else 0 end) as 'Count_CQI_L1800',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI LTE800] is not null) then 1 else 0 end) as 'Count_CQI_L800',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI UMTS2100] end) as 'CQI_U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI UMTS900] end) as 'CQI_U900',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI LTE2600] end) as 'CQI_L2600',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI LTE2100] end) as 'CQI_L2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI LTE1800] end) as 'CQI_L1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI LTE800] end) as 'CQI_L800',


		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA_PCT] is not null) then 1 else 0 end) as 'Count_HSPA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA+_PCT] is not null) then 1 else 0 end) as 'Count_HSPA+',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA+_DC_PCT] is not null) then 1 else 0 end) as 'Count_HSPA+_DC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_5Mhz_SC_PCT] is not null) then 1 else 0 end) as 'Count_LTE_5Mhz_SC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_10Mhz_SC_PCT] is not null) then 1 else 0 end) as 'Count_LTE_10Mhz_SC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_15Mhz_SC_PCT] is not null) then 1 else 0 end) as 'Count_LTE_15Mhz_SC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_20Mhz_SC_PCT] is not null) then 1 else 0 end) as 'Count_LTE_20Mhz_SC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_15Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_15Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_20Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_20Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_25Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_25Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_30Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_30Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_35Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_35Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_40Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_40Mhz_CA',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA_PCT] end) as '% HSPA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA+_PCT] end) as '% HSPA+',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA+_DC_PCT] end) as '% HSPA+ DC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_5Mhz_SC_PCT] end) as '% LTE 5Mhz SC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_10Mhz_SC_PCT] end) as '% LTE 10Mhz SC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_15Mhz_SC_PCT] end) as '% LTE 15Mhz SC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_20Mhz_SC_PCT] end) as '% LTE 20Mhz SC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_15Mhz_CA_PCT] end) as '% LTE 15Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_20Mhz_CA_PCT] end) as '% LTE 20Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_25Mhz_CA_PCT] end) as '% LTE 25Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_30Mhz_CA_PCT] end) as '% LTE 30Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_35Mhz_CA_PCT] end) as '% LTE 35Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_40Mhz_CA_PCT] end) as '% LTE 40Mhz CA',

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'GRID',

		--@ERC-20170126: Se añade CQI 4G
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 4G] end) as 'CQI_4G',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 4G] is not null) then 1 else 0 end) as 'Count_CQI_4G',
		
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 4G PCC] end) as 'CQI_4G_PCC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 4G PCC] is not null) then 1 else 0 end) as 'Count_CQI_4G_PCC',
		
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 4G SCC1] end) as 'CQI_4G_SCC1',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 4G SCC1] is not null) then 1 else 0 end) as 'Count_CQI_4G_SCC1',

		--@ERC-20170206: Se añade contadores TM - los del CQI no valen
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM Invalid] is not null) then 1 else 0 end)  as [Count_TM_Invalid],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 1: Single Antenna Port 0] is not null) then 1 else 0 end)  as [Count_TM1],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 2: TD Rank 1] is not null) then 1 else 0 end)  as [Count_TM2],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 3: OL SM] is not null) then 1 else 0 end)  as [Count_TM3],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 4: CL SM] is not null) then 1 else 0 end)  as [Count_TM4],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 5: MU MIMO] is not null) then 1 else 0 end)  as [Count_TM5],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 6: CL RANK1 PC] is not null) then 1 else 0 end)  as [Count_TM6],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 7: Single Antenna Port 5] is not null) then 1 else 0 end)  as [Count_TM7],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM Unknown] is not null) then 1 else 0 end)  as [Count_TM_Unknown],
	
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[RBs] is not null) then 1 else 0 end)  as [Count_RBs],
		lp.Region_OSP as Region_OSP,

		--@ERC: Se añaden porque en los POC el valor de los generales no se rellena bien
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM Invalid PCC] end)  as [%_TM_Invalid_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 1: Single Antenna Port 0 PCC] end)  as [%_TM1_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 2: TD Rank 1 PCC] end)  as [%_TM2_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 3: OL SM PCC] end)  as [%_TM3_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 4: CL SM PCC] end)  as [%_TM4_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 5: MU MIMO PCC] end)  as [%_TM5_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 6: CL RANK1 PC PCC] end)  as [%_TM6_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 7: Single Antenna Port 5 PCC] end)  as [%_TM7_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM Unknown PCC] end)  as [%_TM_Unknown_PCC] ,

		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM Invalid PCC] is not null) then 1 else 0 end)  as [Count_TM_Invalid_PCC] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 1: Single Antenna Port 0 PCC] is not null) then 1 else 0 end)  as [Count_TM1_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 2: TD Rank 1 PCC] is not null) then 1 else 0 end)  as [Count_TM2_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 3: OL SM PCC] is not null) then 1 else 0 end)  as [Count_TM3_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 4: CL SM PCC] is not null) then 1 else 0 end)  as [Count_TM4_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 5: MU MIMO PCC] is not null) then 1 else 0 end)  as [Count_TM5_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 6: CL RANK1 PC PCC] is not null) then 1 else 0 end)  as [Count_TM6_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 7: Single Antenna Port 5 PCC] is not null) then 1 else 0 end)  as [Count_TM7_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM Unknown PCC] is not null) then 1 else 0 end)  as [Count_TM_Unknown_PCC],
		v.[ASideDevice],
		v.[BSideDevice],
		v.[SWVersion]
	
	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_DL v,
		Agrids.dbo.lcc_parcelas lp
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='DL_NC'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])	 
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]),v.MNC,lp.Region_VF,lp.Region_OSP, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end
else
begin
	insert into @data_DLperfNC
	select  
		db_name() as 'Database',
		v.mnc,
		null,	
		-----------------
		-- Performance 4G
		-----------------
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[RBs] end)  as [ RBs],
		MAX(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Max RBs] end)  as [ RBs MAX],
		MIN(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Min RBs] end)  as [ RBs MIN],
		--AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 4G] end)  as [ CQI],
		--AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Rank Indicator] end)  as [ Rank Indicator],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM Invalid] end)  as [ % TM Invalid],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 1: Single Antenna Port 0] end)  as [ % TM1],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 2: TD Rank 1] end)  as [ % TM2],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 3: OL SM] end)  as [ % TM3],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 4: CL SM] end)  as [ % TM4],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 5: MU MIMO] end)  as [ % MIMO],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 6: CL RANK1 PC] end)  as [ % TM6],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 7: Single Antenna Port 5] end)  as [ % TM7],
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM Unknown] end)  as [ % TM Unknown],
		
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI UMTS2100] is not null) then 1 else 0 end) as 'Count_CQI_U2100',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI UMTS900] is not null) then 1 else 0 end) as 'Count_CQI_U900',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI LTE2600] is not null) then 1 else 0 end) as 'Count_CQI_L2600',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI LTE2100] is not null) then 1 else 0 end) as 'Count_CQI_L2100',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI LTE1800] is not null) then 1 else 0 end) as 'Count_CQI_L1800',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI LTE800] is not null) then 1 else 0 end) as 'Count_CQI_L800',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI UMTS2100] end) as 'CQI_U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI UMTS900] end) as 'CQI_U900',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI LTE2600] end) as 'CQI_L2600',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI LTE2100] end) as 'CQI_L2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI LTE1800] end) as 'CQI_L1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI LTE800] end) as 'CQI_L800',


		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA_PCT] is not null) then 1 else 0 end) as 'Count_HSPA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA+_PCT] is not null) then 1 else 0 end) as 'Count_HSPA+',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA+_DC_PCT] is not null) then 1 else 0 end) as 'Count_HSPA+_DC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_5Mhz_SC_PCT] is not null) then 1 else 0 end) as 'Count_LTE_5Mhz_SC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_10Mhz_SC_PCT] is not null) then 1 else 0 end) as 'Count_LTE_10Mhz_SC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_15Mhz_SC_PCT] is not null) then 1 else 0 end) as 'Count_LTE_15Mhz_SC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_20Mhz_SC_PCT] is not null) then 1 else 0 end) as 'Count_LTE_20Mhz_SC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_15Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_15Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_20Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_20Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_25Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_25Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_30Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_30Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_35Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_35Mhz_CA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[LTE_40Mhz_CA_PCT] is not null) then 1 else 0 end) as 'Count_LTE_40Mhz_CA',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA_PCT] end) as '% HSPA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA+_PCT] end) as '% HSPA+',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA+_DC_PCT] end) as '% HSPA+ DC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_5Mhz_SC_PCT] end) as '% LTE 5Mhz SC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_10Mhz_SC_PCT] end) as '% LTE 10Mhz SC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_15Mhz_SC_PCT] end) as '% LTE 15Mhz SC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_20Mhz_SC_PCT] end) as '% LTE 20Mhz SC',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_15Mhz_CA_PCT] end) as '% LTE 15Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_20Mhz_CA_PCT] end) as '% LTE 20Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_25Mhz_CA_PCT] end) as '% LTE 25Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_30Mhz_CA_PCT] end) as '% LTE 30Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_35Mhz_CA_PCT] end) as '% LTE 35Mhz CA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[LTE_40Mhz_CA_PCT] end) as '% LTE 40Mhz CA',

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'GRID',

		--@ERC-20170126: Se añade CQI 4G
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 4G] end) as 'CQI_4G',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 4G] is not null) then 1 else 0 end) as 'Count_CQI_4G',
		
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 4G PCC] end) as 'CQI_4G_PCC',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 4G PCC] is not null) then 1 else 0 end) as 'Count_CQI_4G_PCC',
		
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 4G SCC1] end) as 'CQI_4G_SCC1',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 4G SCC1] is not null) then 1 else 0 end) as 'Count_CQI_4G_SCC1',

		--@ERC-20170206: Se añade contadores TM - los del CQI no valen
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM Invalid] is not null) then 1 else 0 end)  as [Count_TM_Invalid],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 1: Single Antenna Port 0] is not null) then 1 else 0 end)  as [Count_TM1],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 2: TD Rank 1] is not null) then 1 else 0 end)  as [Count_TM2],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 3: OL SM] is not null) then 1 else 0 end)  as [Count_TM3],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 4: CL SM] is not null) then 1 else 0 end)  as [Count_TM4],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 5: MU MIMO] is not null) then 1 else 0 end)  as [Count_TM5],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 6: CL RANK1 PC] is not null) then 1 else 0 end)  as [Count_TM6],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 7: Single Antenna Port 5] is not null) then 1 else 0 end)  as [Count_TM7],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM Unknown] is not null) then 1 else 0 end)  as [Count_TM_Unknown],

		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[RBs] is not null) then 1 else 0 end)  as [Count_RBs],
		null,

		--@ERC: Se añaden porque en los POC el valor de los generales no se rellena bien
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM Invalid PCC] end)  as [%_TM_Invalid_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 1: Single Antenna Port 0 PCC] end)  as [%_TM1_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 2: TD Rank 1 PCC] end)  as [%_TM2_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 3: OL SM PCC] end)  as [%_TM3_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 4: CL SM PCC] end)  as [%_TM4_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 5: MU MIMO PCC] end)  as [%_TM5_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 6: CL RANK1 PC PCC] end)  as [%_TM6_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM 7: Single Antenna Port 5 PCC] end)  as [%_TM7_PCC] ,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% TM Unknown PCC] end)  as [%_TM_Unknown_PCC] ,

		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM Invalid PCC] is not null) then 1 else 0 end)  as [Count_TM_Invalid_PCC] ,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 1: Single Antenna Port 0 PCC] is not null) then 1 else 0 end)  as [Count_TM1_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 2: TD Rank 1 PCC] is not null) then 1 else 0 end)  as [Count_TM2_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 3: OL SM PCC] is not null) then 1 else 0 end)  as [Count_TM3_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 4: CL SM PCC] is not null) then 1 else 0 end)  as [Count_TM4_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 5: MU MIMO PCC] is not null) then 1 else 0 end)  as [Count_TM5_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 6: CL RANK1 PC PCC] is not null) then 1 else 0 end)  as [Count_TM6_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM 7: Single Antenna Port 5 PCC] is not null) then 1 else 0 end)  as [Count_TM7_PCC],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[% TM Unknown PCC] is not null) then 1 else 0 end)  as [Count_TM_Unknown_PCC],
		v.[ASideDevice],
		v.[BSideDevice],
		v.[SWVersion]
	
	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_DL v
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='DL_NC'	 
	group by v.MNC, v.[ASideDevice], v.[BSideDevice], v.[SWVersion] 
end

select * from @data_DLperfNC