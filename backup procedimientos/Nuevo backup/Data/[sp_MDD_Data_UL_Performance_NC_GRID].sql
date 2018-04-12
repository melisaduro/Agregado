USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_UL_Performance_NC_GRID]    Script Date: 31/10/2017 15:31:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_UL_Performance_NC_GRID] (
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
--declare @ciudad as varchar(256) = 'rubi'
--declare @simOperator as int = 7
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 1-- O = False, 1 = True
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
declare @data_ULperfNC  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[HappyRate] [float] NULL,
	[Happy Rate MAX] [float] NULL,
	[Coverage] [float] NULL,
	[EcI0 Avg] [float] NULL,
	[Active Set] [varchar](1) NOT NULL,
	[Serving Grant] [float] NULL,
	[DTX] [float] NULL,
	[TBs] [int] NULL,
	[% SHO] [numeric](38, 6) NULL,
	[ReTrx PDU] [varchar](1) NOT NULL,

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
	insert into @data_ULperfNC
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		-----------------
		-- Performance 3G
		-----------------
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.HappyRate end) as 'HappyRate',
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[Happy Rate MAX] end) as 'Happy Rate MAX',
		log10(avg(power(10.0E0,(case when (v.direction='uplink' and v.TestType='uL_NC') then 1.0 * v.RSCP_avg end)/10.0E0)))*10 as 'Coverage',
		log10(avg(power(10.0E0,(case when (v.direction='uplink' and v.TestType='uL_NC') then 1.0 * v.EcI0_avg end)/10.0E0)))*10 as 'EcI0 Avg',
		'' as 'Active Set', --PDTE !!!
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[Serving Grant] else null end) as 'Serving Grant',
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.DTX else null end) as 'DTX',
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[avg TBs size] else null end) as 'TBs',	
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[% SHO] else null end) as '% SHO',
		--AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[ReTrx PDU] else null end) as 'ReTrx PDU',
		'' as 'ReTrx PDU', --PDTE !!!
		
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
		'GRID',
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
		and v.TestType='uL_NC'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])
	 
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP
			, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]

end
else
begin
	insert into @data_ULperfNC
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		-----------------
		-- Performance 3G
		-----------------
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.HappyRate end) as 'HappyRate',
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[Happy Rate MAX] end) as 'Happy Rate MAX',
		log10(avg(power(10.0E0,(case when (v.direction='uplink' and v.TestType='uL_NC') then 1.0 * v.RSCP_avg end)/10.0E0)))*10 as 'Coverage',
		log10(avg(power(10.0E0,(case when (v.direction='uplink' and v.TestType='uL_NC') then 1.0 * v.EcI0_avg end)/10.0E0)))*10 as 'EcI0 Avg',
		'' as 'Active Set', --PDTE !!!
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[Serving Grant] else null end) as 'Serving Grant',
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.DTX else null end) as 'DTX',
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[avg TBs size] else null end) as 'TBs',	
		AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[% SHO] else null end) as '% SHO',
		--AVG(case when (v.direction='uplink' and v.TestType='uL_NC') then v.[ReTrx PDU] else null end) as 'ReTrx PDU',
		'' as 'ReTrx PDU', --PDTE !!!

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
		'GRID',
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
		and v.TestType='uL_NC'
	 
	group by v.MNC, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]	
end

select * from @data_ULperfNC
