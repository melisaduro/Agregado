USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_UL_Performance_CE_LTE]    Script Date: 31/10/2017 14:03:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_UL_Performance_CE_LTE] (
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
--use [FY1617_Data_REST_4G_H2_2]

--declare @ciudad as varchar(256) = 'MERIDA'
--declare @simOperator as int = 3
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @Info as varchar (256) = 'Completed' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @sheet as varchar(256) = '%%' --%%/LTE/WCDMA
--declare @Tech as varchar (256) = '4G'
--declare @methodology as varchar (256) = 'D16'
--declare @report as varchar(256) = 'vdf' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)



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
	'SC' hasCA
from Lcc_Data_HTTPTransfer_UL v
Where v.collectionname like @Date + '%[_]' + @ciudad + '[_]%' + @Tech
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
declare @dateMax datetime2(3)= (select max(c.endTime) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

--declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, endTime)),2) + '_'	 + convert(varchar(256),format(endTime,'MM'))
--	from Lcc_Data_HTTPTransfer_UL where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from Lcc_Data_HTTPTransfer_UL v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max([master].dbo.fn_lcc_getElement(5, v.collectionname,'_')) from Lcc_Data_HTTPTransfer_UL v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId)-- group by [master].dbo.fn_lcc_getElement(5, v.collectionname,'_'))

declare @week as varchar(256)
declare @tmpDateFirst int 
declare @tmpWeek int 

--select @tmpDateFirst = @@DATEFIRST
--if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
--	SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPTransfer_UL 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
--else
--	begin
--		SET DATEFIRST 1;  --Primer dia de la semana lunes
--		SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPTransfer_UL 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
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
declare @data_ULperfCE  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,	
	[ RBs] [numeric](38, 12) NULL,
	[ RBs MAX] [numeric](13, 0) NULL,
	[ RBs MIN] [numeric](13, 0) NULL,
	[ CQI] [float] NULL,
	[ Rank Indicator] [int] NULL,
	[ % TM Invalid] [numeric](38, 12) NULL,
	[ % TM1] [numeric](38, 12) NULL,
	[ % TM2] [numeric](38, 12) NULL,
	[ % TM3] [numeric](38, 12) NULL,
	[ % TM4] [numeric](38, 12) NULL,
	[ % MIMO] [numeric](38, 12) NULL,
	[ % TM6] [numeric](38, 12) NULL,
	[ % TM7] [numeric](38, 12) NULL,
	[ % TM8] [numeric](38, 12) NULL,
	[ % TM9] [numeric](38, 12) NULL,
	[ CQI 1] [int] NULL,
	[ CQI 2] [int] NULL,
	[ CQI 3] [int] NULL,
	[ CQI 4] [int] NULL,
	[ CQI 5] [int] NULL,
	[ CQI 6] [int] NULL,
	[ CQI 7] [int] NULL,
	[ CQI 8] [int] NULL,
	[ CQI 9] [int] NULL,
	[ CQI 10] [int] NULL,
	[ CQI 11] [int] NULL,
	[ CQI 12] [int] NULL,
	[ CQI 13] [int] NULL,
	[ CQI 14] [int] NULL,
	[ CQI 15] [int] NULL,

	[Count_CQI_L2600] [int] null,
	[Count_CQI_L2100] [int] null,
	[Count_CQI_L1800] [int] null,
	[Count_CQI_L800] [int] null,
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
	[HSPA_PCT] [float] NULL,
	[HSPA+_PCT] [float] NULL,
	[HSPA+_DC_PCT] [float] NULL,
	[LTE_5Mhz_SC_PCT] [float] NULL,
	[LTE_10Mhz_SC_PCT] [float] NULL,
	[LTE_15Mhz_SC_PCT] [float] NULL,
	[LTE_20Mhz_SC_PCT] [float] NULL,	

	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF] [varchar] (256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP] [varchar] (256) NULL,
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL

)

if @Indoor=0
begin
	insert into @data_ULperfCE
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		-----------------
		-- Performance 4G
		-----------------
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[RBs] end)  as [ RBs],
		MAX(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[Max RBs] end)  as [ RBs MAX],
		MIN(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[Min RBs] end)  as [ RBs MIN],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[CQI 4G] end)  as [ CQI],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[Rank Indicator] end)  as [ Rank Indicator],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM Invalid] end)  as [ % TM Invalid],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 1: Single Antenna Port 0] end)  as [ % TM1],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 2: TD Rank 1] end)  as [ % TM2],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 3: OL SM] end)  as [ % TM3],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 4: CL SM] end)  as [ % TM4],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 5: MU MIMO] end)  as [ % MIMO],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 6: CL RANK1 PC] end)  as [ % TM6],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 7: Single Antenna Port 5] end)  as [ % TM7],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 8] end)  as [ % TM8],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 9] end)  as [ % TM9],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] < 1.5) then 1 else 0 end ) as [ CQI 1],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 1.5 and 2.5) then 1 else 0 end) as [ CQI 2],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 2.5 and 3.5) then 1 else 0 end)  as [ CQI 3],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 3.5 and 4.5) then 1 else 0 end)  as [ CQI 4],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 4.5 and 5.5) then 1 else 0 end)  as [ CQI 5],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 5.5 and 6.5) then 1 else 0 end)  as [ CQI 6],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 6.5 and 7.5) then 1 else 0 end)  as [ CQI 7],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 7.5 and 8.5) then 1 else 0 end)  as [ CQI 8],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 8.5 and 9.5) then 1 else 0 end)  as [ CQI 9],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 9.5 and 10.5) then 1 else 0 end)  as [ CQI 10],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 10.5 and 11.5) then 1 else 0 end)  as [ CQI 11],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 11.5 and 12.5) then 1 else 0 end)  as [ CQI 12],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 12.5 and 13.5) then 1 else 0 end)  as [ CQI 13],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 13.5 and 14.5) then 1 else 0 end)  as [ CQI 14],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] > 14.5) then 1 else 0 end)  as [ CQI 15],

		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,


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
		Lcc_Data_HTTPTransfer_UL v,
		Agrids.dbo.lcc_parcelas lp

	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='uL_CE'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])
	 
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end
else
begin
	insert into @data_ULperfCE
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		-----------------
		-- Performance 4G
		-----------------
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[RBs] end)  as [ RBs],
		MAX(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[Max RBs] end)  as [ RBs MAX],
		MIN(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[Min RBs] end)  as [ RBs MIN],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[CQI 4G] end)  as [ CQI],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[Rank Indicator] end)  as [ Rank Indicator],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM Invalid] end)  as [ % TM Invalid],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 1: Single Antenna Port 0] end)  as [ % TM1],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 2: TD Rank 1] end)  as [ % TM2],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 3: OL SM] end)  as [ % TM3],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 4: CL SM] end)  as [ % TM4],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 5: MU MIMO] end)  as [ % MIMO],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 6: CL RANK1 PC] end)  as [ % TM6],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 7: Single Antenna Port 5] end)  as [ % TM7],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 8] end)  as [ % TM8],
		AVG(case when (v.direction='uplink' and v.TestType='uL_CE') then v.[% TM 9] end)  as [ % TM9],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] < 1.5) then 1 else 0 end ) as [ CQI 1],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 1.5 and 2.5) then 1 else 0 end) as [ CQI 2],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 2.5 and 3.5) then 1 else 0 end)  as [ CQI 3],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 3.5 and 4.5) then 1 else 0 end)  as [ CQI 4],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 4.5 and 5.5) then 1 else 0 end)  as [ CQI 5],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 5.5 and 6.5) then 1 else 0 end)  as [ CQI 6],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 6.5 and 7.5) then 1 else 0 end)  as [ CQI 7],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 7.5 and 8.5) then 1 else 0 end)  as [ CQI 8],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 8.5 and 9.5) then 1 else 0 end)  as [ CQI 9],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 9.5 and 10.5) then 1 else 0 end)  as [ CQI 10],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 10.5 and 11.5) then 1 else 0 end)  as [ CQI 11],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 11.5 and 12.5) then 1 else 0 end)  as [ CQI 12],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 12.5 and 13.5) then 1 else 0 end)  as [ CQI 13],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] between 13.5 and 14.5) then 1 else 0 end)  as [ CQI 14],
		SUM(case when (v.direction='uplink' and v.TestType='uL_CE' and v.[CQI 4G] > 14.5) then 1 else 0 end)  as [ CQI 15],

		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,

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
		Lcc_Data_HTTPTransfer_UL v

	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='uL_CE'
	 
	group by v.MNC
, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end

select * from @data_ULperfCE
