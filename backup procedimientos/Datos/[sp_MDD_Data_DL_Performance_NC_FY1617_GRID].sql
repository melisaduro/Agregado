USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_DL_Performance_NC_FY1617_GRID]    Script Date: 29/05/2017 12:11:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_DL_Performance_NC_FY1617_GRID] (
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
--use [FY1617_Data_Rest_3G_H2]

--declare @ciudad as varchar(256) = 'DONBENITO'
--declare @simOperator as int = 4
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @Info as varchar (256) = 'Completed' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @sheet as varchar(256) = '%%' --%%/LTE/WCDMA
--declare @Tech as varchar (256) = '3G'
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
	[CQI] [numeric](38, 6) NULL,
	[% SCCH] [numeric](38, 12) NULL,
	[Procesos HARQ] [int] NULL,
	[BLER DSCH] [float] NULL,
	[DTX DSCH] [int] NULL,
	[ACKs] [int] NULL,
	[NACKs] [numeric](38, 12) NULL,
	[EcI0 Avg] [float] NULL,
	[BLER RLC] [numeric](38, 17) NULL,
	[Retrx DSCH] [float] NULL,
	[RETRX MAC] [varchar](1) NOT NULL,
	[RLC Thput] [float] NULL,
	[CQI < 21Mbps] [int] NULL,
	[CQI 21] [int] NULL,
	[CQI 22] [int] NULL,
	[CQI 23] [int] NULL,
	[CQI 24] [int] NULL,
	[CQI 25] [int] NULL,
	[CQI 26] [int] NULL,
	[CQI 27] [int] NULL,
	[CQI 28] [int] NULL,

	[Count_CQI_U2100] [int] null,
	[Count_CQI_U900] [int] null,
	[CQI_U2100] [float] NULL,
	[CQI_U900] [float] NULL,
	[Count_HSPA] [int] null,
	[Count_HSPA+] [int] null,
	[Count_HSPA+_DC] [int] null,
	[HSPA_PCT] [float] NULL,
	[HSPA+_PCT] [float] NULL,
	[HSPA+_DC_PCT] [float] NULL,

	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF][varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,

	[UL_Inter] [float] NULL,
	[Count_UL_Inter] [int] null,
	[UL_Inter_Lin] float null,
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
		-- Performance 3G
		-----------------
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 3G] end) as 'CQI',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% SCCH] end) as '% SCCH',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Procesos HARQ] end) as 'Procesos HARQ',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[BLER DSCH] end) as 'BLER DSCH',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[DTX DSCH] end) as 'DTX DSCH',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[ACKs] end) as 'ACKs',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% NACKs] end) as 'NACKs',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.EcI0_avg end) as 'EcI0 Avg',
	
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[BLER RLC] end) as 'BLER RLC',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Retrx DSCH] end) as 'Retrx DSCH',
		'' as 'RETRX MAC', --PDTE !!!
	
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[RLC Thput] end) as 'RLC Thput',

		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] < 21) then 1 else 0 end ) as [CQI < 21Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 21 and 22) then 1 else 0 end ) as [CQI 21],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 22 and 23)then 1 else 0 end )  as [CQI 22],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 23 and 24) then 1 else 0 end ) as [CQI 23],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 24 and 25) then 1 else 0 end ) as [CQI 24],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 25 and 26) then 1 else 0 end ) as [CQI 25],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 26 and 27) then 1 else 0 end ) as [CQI 26],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 27 and 28) then 1 else 0 end ) as [CQI 27],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 28 and 29) then 1 else 0 end ) as [CQI 28],

		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI UMTS2100] is not null) then 1 else 0 end) as 'Count_CQI_U2100',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI UMTS900] is not null) then 1 else 0 end) as 'Count_CQI_U900',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI UMTS2100] end) as 'CQI_U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI UMTS900] end) as 'CQI_U900',

		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA_PCT] is not null) then 1 else 0 end) as 'Count_HSPA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA+_PCT] is not null) then 1 else 0 end) as 'Count_HSPA+',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA+_DC_PCT] is not null) then 1 else 0 end) as 'Count_HSPA+_DC',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA_PCT] end) as '% HSPA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA+_PCT] end) as '% HSPA+',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA+_DC_PCT] end) as '% HSPA+ DC',

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'GRID',
		

		log10(AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then (power(10.0E0,v.[UL_Interference]/10.0E0)) end))*10.0  as 'UL_Inter',
		sum(case when (v.direction='Downlink' and v.TestType='DL_NC' and power(10.0E0,v.[UL_Interference]/10.0E0) is not null) then 1 else 0 end) as 'Count_UL_Inter',		
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then power(10.0E0,v.[UL_Interference]/10.0E0) end) as 'UL_Inter_Lin'	,	
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
		-- Performance 3G
		-----------------
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI 3G] end) as 'CQI',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% SCCH] end) as '% SCCH',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Procesos HARQ] end) as 'Procesos HARQ',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[BLER DSCH] end) as 'BLER DSCH',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[DTX DSCH] end) as 'DTX DSCH',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[ACKs] end) as 'ACKs',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[% NACKs] end) as 'NACKs',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.EcI0_avg end) as 'EcI0 Avg',
	
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[BLER RLC] end) as 'BLER RLC',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[Retrx DSCH] end) as 'Retrx DSCH',
		'' as 'RETRX MAC', --PDTE !!!
	
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[RLC Thput] end) as 'RLC Thput',

		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] < 21) then 1 else 0 end ) as [CQI < 21Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 21 and 22) then 1 else 0 end ) as [CQI 21],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 22 and 23)then 1 else 0 end )  as [CQI 22],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 23 and 24) then 1 else 0 end ) as [CQI 23],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 24 and 25) then 1 else 0 end ) as [CQI 24],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 25 and 26) then 1 else 0 end ) as [CQI 25],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 26 and 27) then 1 else 0 end ) as [CQI 26],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 27 and 28) then 1 else 0 end ) as [CQI 27],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI 3G] between 28 and 29) then 1 else 0 end ) as [CQI 28],

		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI UMTS2100] is not null) then 1 else 0 end) as 'Count_CQI_U2100',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[CQI UMTS900] is not null) then 1 else 0 end) as 'Count_CQI_U900',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI UMTS2100] end) as 'CQI_U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[CQI UMTS900] end) as 'CQI_U900',

		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA_PCT] is not null) then 1 else 0 end) as 'Count_HSPA',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA+_PCT] is not null) then 1 else 0 end) as 'Count_HSPA+',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_NC' and v.[HSPA+_DC_PCT] is not null) then 1 else 0 end) as 'Count_HSPA+_DC',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA_PCT] end) as '% HSPA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA+_PCT] end) as '% HSPA+',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then v.[HSPA+_DC_PCT] end) as '% HSPA+ DC',

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'GRID',

		log10(AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then (power(10.0E0,v.[UL_Interference]/10.0E0)) end))*10.0  as 'UL_Inter',
		sum(case when (v.direction='Downlink' and v.TestType='DL_NC' and power(10.0E0,v.[UL_Interference]/10.0E0) is not null) then 1 else 0 end) as 'Count_UL_Inter',		
		AVG(case when (v.direction='Downlink' and v.TestType='DL_NC') then power(10.0E0,v.[UL_Interference]/10.0E0) end) as 'UL_Inter_Lin',		
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