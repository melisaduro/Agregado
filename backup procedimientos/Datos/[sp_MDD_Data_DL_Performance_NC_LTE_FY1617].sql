USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_DL_Performance_NC_LTE_FY1617]    Script Date: 29/05/2017 12:13:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_DL_Performance_NC_LTE_FY1617] (
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
--declare @ciudad as varchar(256) = 'INDOOR_A1-IRUN-R1'
--declare @simOperator as int = 4
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 1 -- O = False, 1 = True
--declare @Info as varchar (256) = '%%' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @sheet as varchar(256) = 'WCDMA' --%%/LTE/WCDMA
--declare @Tech as varchar (256) = '4G'
-----------------------------
----- Date Declarations -----
-----------------------------
	
--declare @fecha_ini1 as datetime = @fecha_ini_text1
--declare @fecha_fin1 as datetime = @fecha_fin_text1
--declare @fecha_ini2 as datetime = @fecha_ini_text2
--declare @fecha_fin2 as datetime = @fecha_fin_text2
--declare @fecha_ini3 as datetime = @fecha_ini_text3
--declare @fecha_fin3 as datetime = @fecha_fin_text3
--declare @fecha_ini4 as datetime = @fecha_ini_text4
--declare @fecha_fin4 as datetime = @fecha_fin_text4
--declare @fecha_ini5 as datetime = @fecha_ini_text5
--declare @fecha_fin5 as datetime = @fecha_fin_text5
--declare @fecha_ini6 as datetime = @fecha_ini_text6
--declare @fecha_fin6 as datetime = @fecha_fin_text6
--declare @fecha_ini7 as datetime = @fecha_ini_text7
--declare @fecha_fin7 as datetime = @fecha_fin_text7
--declare @fecha_ini8 as datetime = @fecha_ini_text8
--declare @fecha_fin8 as datetime = @fecha_fin_text8
--declare @fecha_ini9 as datetime = @fecha_ini_text9
--declare @fecha_fin9 as datetime = @fecha_fin_text9
--declare @fecha_ini10 as datetime = @fecha_ini_text10
--declare @fecha_fin10 as datetime = @fecha_fin_text10


-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests_Tech as table (sessionid bigint, TestId bigint,tech varchar(5), hasCA varchar(2))

insert into @All_Tests_Tech 
select v.sessionid, v.testid,
	case when v.[% LTE]=1 then 'LTE'
		 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' 
	end as tech,	
	case when v.[% CA] >0 then 'CA'
	else 'SC' end as hasCA
from Lcc_Data_HTTPTransfer_DL v
Where v.collectionname like @Date + '%' + @ciudad + '%' + @Tech
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos	
	and v.info like @Info
 

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

declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

--declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, endTime)),2) + '_'	 + convert(varchar(256),format(endTime,'MM'))
--	from Lcc_Data_HTTPTransfer_DL where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from Lcc_Data_HTTPTransfer_DL v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max([master].dbo.fn_lcc_getElement(5, v.collectionname,'_')) from Lcc_Data_HTTPTransfer_DL v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId)-- group by [master].dbo.fn_lcc_getElement(5, v.collectionname,'_'))

declare @week as varchar(256)
declare @tmpDateFirst int 
declare @tmpWeek int 

--select @tmpDateFirst = @@DATEFIRST
--if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
--	SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPTransfer_DL 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
--else
--	begin
--		SET DATEFIRST 1;  --Primer dia de la semana lunes
--		SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPTransfer_DL 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
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
	[Region_OSP][varchar](256) NULL,
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
		'Collection Name',
		lp.Region_OSP as Region_OSP,
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
		'Collection Name',
		null,
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
	group by v.MNC , v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end

select * from @data_DLperfNC