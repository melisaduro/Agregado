USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_UL_Technology_CE_LTE_GRID]    Script Date: 31/10/2017 15:34:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_UL_Technology_CE_LTE_GRID] (
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
--declare @ciudad as varchar(256) = 'arona'
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
declare @data_ULtechCE_LTE  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[% LTE] [numeric](38, 12) NULL,
	[% WCDMA] [numeric](38, 12) NULL,
	[% GSM] [numeric](38, 12) NULL,
	[BPSK] [numeric](38, 6) NULL,
	[QPSK] [numeric](38, 6) NULL,
	[16QAM] [numeric](38, 6) NULL,
	[RSRP Avg] [float] NULL,
	[RSRQ Avg] [float] NULL,
	[SINR Avg] [float] NULL,
	[10Mhz Bandwidth %] [numeric](38, 12) NULL,
	[15Mhz Bandwidth %] [numeric](38, 12) NULL,
	[20Mhz Bandwidth %] [numeric](38, 12) NULL,
	[% F1 U2100] [numeric](38, 12) NULL,
	[% F2 U2100] [numeric](38, 12) NULL,
	[% F3 U2100] [numeric](38, 12) NULL,
	[% F1 U900] [numeric](38, 12) NULL,
	[% F2 U900] [numeric](38, 12) NULL,
	[% F1 L2600] [numeric](38, 12) NULL,
	[% F1 L2100] [numeric](38, 12) NULL,
	[% F2 L2100] [numeric](38, 12) NULL,
	[% F1 L1800] [numeric](38, 12) NULL,
	[% F2 L1800] [numeric](38, 12) NULL,
	[% F3 L1800] [numeric](38, 12) NULL,
	[% F1 L800] [numeric](38, 12) NULL,
	[% U2100] [numeric](38, 12) NULL,
	[% U900] [numeric](38, 12) NULL,
	[% LTE1800] [numeric](38, 12) NULL,
	[% LTE2600] [numeric](38, 12) NULL,
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

if @Indoor=0
begin
	insert into @data_ULtechCE_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,

		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% LTE] end) as '% LTE',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% WCDMA] end) as '% WCDMA',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% GSM] end) as '% GSM',

		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% BPSK 4G] end) as 'BPSK',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% QPSK 4G] end) as 'QPSK',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% 16QAM 4G] end) as '16QAM',
		
		log10(avg(power(10.0E0,(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0 * v.RSRP_avg end)/10.0E0)))*10 as 'RSRP Avg',	
		log10(avg(power(10.0E0,(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0 * v.RSRQ_avg end)/10.0E0)))*10 as 'RSRQ Avg',
		log10(avg(power(10.0E0,(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0 * v.SINR_avg end)/10.0E0)))*10 as 'SINR Avg',

		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[10Mhz Bandwidth %] else null end) as '10Mhz Bandwidth %',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[15Mhz Bandwidth %] else null end) as '15Mhz Bandwidth %',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[20Mhz Bandwidth %] else null end) as '20Mhz Bandwidth %',

		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 U2100] else null end) as '% F1 U2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F2 U2100] else null end) as '% F2 U2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F3 U2100] else null end) as '% F3 U2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 U900] else null end) as '% F1 U900',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F2 U900] else null end) as '% F2 U900',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 L2600] else null end) as '% F1 L2600',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 L2100] else null end) as '% F1 L2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F2 L2100] else null end) as '% F2 L2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 L1800] else null end) as '% F1 L1800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F2 L1800] else null end) as '% F2 L1800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F3 L1800] else null end) as '% F3 L1800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 L800] else null end) as '% F1 L800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% U2100] else null end) as '% U2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% U900] else null end) as '% U900',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% LTE1800] else null end) as '% LTE1800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% LTE2600] else null end) as '% LTE2600',
		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null as 'Num_Medida',
		@Report,
		'GRID',
		lp.Region_OSP as Region_OSP
	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_UL v,
		Agrids.dbo.lcc_parcelas lp
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='UL_CE'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])	 
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP
end
else
begin
	insert into @data_ULtechCE_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
				AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% LTE] end) as '% LTE',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% WCDMA] end) as '% WCDMA',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% GSM] end) as '% GSM',

		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% BPSK 4G] end) as 'BPSK',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% QPSK 4G] end) as 'QPSK',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% 16QAM 4G] end) as '16QAM',
		
		log10(avg(power(10.0E0,(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0 * v.RSRP_avg end)/10.0E0)))*10 as 'RSRP Avg',	
		log10(avg(power(10.0E0,(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0 * v.RSRQ_avg end)/10.0E0)))*10 as 'RSRQ Avg',
		log10(avg(power(10.0E0,(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0 * v.SINR_avg end)/10.0E0)))*10 as 'SINR Avg',

		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[10Mhz Bandwidth %] else null end) as '10Mhz Bandwidth %',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[15Mhz Bandwidth %] else null end) as '15Mhz Bandwidth %',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[20Mhz Bandwidth %] else null end) as '20Mhz Bandwidth %',

		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 U2100] else null end) as '% F1 U2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F2 U2100] else null end) as '% F2 U2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F3 U2100] else null end) as '% F3 U2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 U900] else null end) as '% F1 U900',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F2 U900] else null end) as '% F2 U900',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 L2600] else null end) as '% F1 L2600',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 L2100] else null end) as '% F1 L2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F2 L2100] else null end) as '% F2 L2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 L1800] else null end) as '% F1 L1800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F2 L1800] else null end) as '% F2 L1800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F3 L1800] else null end) as '% F3 L1800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% F1 L800] else null end) as '% F1 L800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% U2100] else null end) as '% U2100',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% U900] else null end) as '% U900',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% LTE1800] else null end) as '% LTE1800',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[% LTE2600] else null end) as '% LTE2600',
		
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
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_UL v
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='UL_CE'	 
	group by v.MNC
end

select * from @data_ULtechCE_LTE
