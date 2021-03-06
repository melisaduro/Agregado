USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_NEW_KPIs_UL_LTE_GRID]    Script Date: 29/05/2017 12:17:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_NEW_KPIs_UL_LTE_GRID] (
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
--use [FY1617_Data_Malaga_4G_H2]
--declare @ciudad as varchar(256) = 'MALAGA'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @Info as varchar (256) = 'Completed' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @sheet as varchar(256) = '%%' --%%/LTE/WCDMA
--declare @Tech as varchar (256) = '%%'
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
declare @data_ULthput  as table (
    [Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,	
	[Navegaciones_CE] [int] NULL,
	[Navegaciones_NC] [int] NULL,
	[Count_RI_CE] [int] NULL,
	[Count_RI_NC] [int] NULL,
	[Count_RBs_CE] [int] NULL,
	[Count_RBs_NC] [int] NULL,
	[RI CE] [float] NULL,
	[RI NC] [float] NULL,
	[RBs CE] [float] NULL,
	[Max RBs CE] [float] NULL,
	[RBs NC] [float] NULL,
	[Max RBs NC] [float] NULL,		
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF] [varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,

	--@ERC-20170117: Se añadens nuevos KPIS de MIMO y RI
	[MIMO_CE_num] [float] NULL,		
	[RI1_CE_num] [float] NULL,		
	[RI2_CE_num] [float] NULL,		
	[MIMO_NC_num] [float] NULL,		
	[RI1_NC_num] [float] NULL,		
	[RI2_NC_num] [float] NULL,		

	[MIMO_CE_den] [float] NULL,		
	[RI1_CE_den] [float] NULL,		
	[RI2_CE_den] [float] NULL,		
	[MIMO_NC_den] [float] NULL,		
	[RI1_NC_den] [float] NULL,		
	[RI2_NC_den] [float] NULL,
	[Region_OSP] [varchar](256) NULL,

	-- 20170321 - @ERC: Nuevos KPis y parametros:
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL
)

if @Indoor=0
begin
	insert into @data_ULthput
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		SUM(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1 else 0 end) as 'Navegaciones_CE',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1 else 0 end) as 'Navegaciones_NC',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[Rank Indicator] is not null) then 1 else 0 end) as 'Count_RI_CE',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[Rank Indicator] is not null) then 1 else 0 end) as 'Count_RI_NC',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[RBs When Allocated] is not null) then 1 else 0 end) as 'Count_RBs_CE',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[RBs When Allocated] is not null) then 1 else 0 end) as 'Count_RBs_NC',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0*v.[Rank Indicator] end)  as 'RI CE',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1.0*v.[Rank Indicator] end)  as 'RI NC',		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[RBs When Allocated] end) as 'RBs CE',
		MAX(case when (v.direction='Uplink' and v.TestType='UL_CE') then abs(ceiling(v.[RBs When Allocated])) end) as 'Max RBs CE',		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then v.[RBs When Allocated] end) as 'RBs NC',
		MAX(case when (v.direction='Uplink' and v.TestType='UL_NC') then abs(ceiling(v.[RBs When Allocated])) end) as 'Max RBs NC',

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'GRID',

		--@ERC-20170117: Se añadens nuevos KPIS de MIMO y RI
		-- DL_CE:		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0*v.[% MIMO] end)
			* sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and 1.0*v.[% MIMO] is not null) then 1.0 else 0 end) as  'MIMO_CE_num',

		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0*v.[% RI1] end) 
			* sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and 1.0*v.[% RI1] is not null) then 1.0 else 0 end) as 'RI1_CE_num',
		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0*v.[% RI2] end)
			* sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and 1.0*v.[% RI2] is not null) then 1.0 else 0 end) as 'RI2_CE_num',
		
		-- UL_NC:
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1.0*v.[% MIMO] end) 
			* sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and 1.0*v.[% MIMO] is not null) then 1.0 else 0 end) as 'MIMO_NC_num',
				
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1.0*v.[% RI1] end)
			* sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and 1.0*v.[% RI1] is not null) then 1.0 else 0 end) as 'RI1_NC_num',
		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1.0*v.[% RI2] end) 
			* sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and 1.0*v.[% RI2] is not null) then 1.0 else 0 end) as 'RI2_NC_num',

		-- Ponderaciones
		sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[% MIMO] is not null) then 1.0 else 0 end)  as 'MIMO_CE_den',		
		sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[% RI1] is not null) then 1.0 else 0 end)  as 'RI1_CE_den',
		sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[% RI2] is not null) then 1.0 else 0 end)  as 'RI2_CE_den',

		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[% MIMO] is not null) then 1.0 else 0 end)  as 'MIMO_NC_den',		
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[% RI1] is not null) then 1.0 else 0 end)  as 'RI1_NC_den',
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[% RI2] is not null) then 1.0 else 0 end)  as 'RI2_NC_den',
		lp.Region_OSP as Region_OSP,

		-- 20170321 - @ERC: Nuevos KPis y parametros:
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
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) 
	group by 
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]),v.MNC,lp.Region_VF,lp.Region_OSP, 
		v.[ASideDevice], v.[BSideDevice], v.[SWVersion]	
end 
else
begin
	insert into @data_ULthput
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		SUM(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1 else 0 end) as 'Navegaciones_CE',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1 else 0 end) as 'Navegaciones_NC',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[Rank Indicator] is not null) then 1 else 0 end) as 'Count_RI_CE',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[Rank Indicator] is not null) then 1 else 0 end) as 'Count_RI_NC',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[RBs When Allocated] is not null) then 1 else 0 end) as 'Count_RBs_CE',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[RBs When Allocated] is not null) then 1 else 0 end) as 'Count_RBs_NC',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0*v.[Rank Indicator] end)  as 'RI CE',
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1.0*v.[Rank Indicator] end)  as 'RI NC',		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then v.[RBs When Allocated] end) as 'RBs CE',
		MAX(case when (v.direction='Uplink' and v.TestType='UL_CE') then abs(ceiling(v.[RBs When Allocated])) end) as 'Max RBs CE',		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then v.[RBs When Allocated] end) as 'RBs NC',
		MAX(case when (v.direction='Uplink' and v.TestType='UL_NC') then abs(ceiling(v.[RBs When Allocated])) end) as 'Max RBs NC',

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'GRID',

		--@ERC-20170117: Se añadens nuevos KPIS de MIMO y RI
		-- DL_CE:		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0*v.[% MIMO] end)
			* sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and 1.0*v.[% MIMO] is not null) then 1.0 else 0 end) as  'MIMO_CE_num',

		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0*v.[% RI1] end) 
			* sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and 1.0*v.[% RI1] is not null) then 1.0 else 0 end) as 'RI1_CE_num',
		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_CE') then 1.0*v.[% RI2] end)
			* sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and 1.0*v.[% RI2] is not null) then 1.0 else 0 end) as 'RI2_CE_num',
		
		-- UL_NC:
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1.0*v.[% MIMO] end) 
			* sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and 1.0*v.[% MIMO] is not null) then 1.0 else 0 end) as 'MIMO_NC_num',
				
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1.0*v.[% RI1] end)
			* sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and 1.0*v.[% RI1] is not null) then 1.0 else 0 end) as 'RI1_NC_num',
		
		AVG(case when (v.direction='Uplink' and v.TestType='UL_NC') then 1.0*v.[% RI2] end) 
			* sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and 1.0*v.[% RI2] is not null) then 1.0 else 0 end) as 'RI2_NC_num',

		-- Ponderaciones
		sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[% MIMO] is not null) then 1.0 else 0 end)  as 'MIMO_CE_den',		
		sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[% RI1] is not null) then 1.0 else 0 end)  as 'RI1_CE_den',
		sum(case when (v.direction='Uplink' and v.TestType='UL_CE' and v.[% RI2] is not null) then 1.0 else 0 end)  as 'RI2_CE_den',

		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[% MIMO] is not null) then 1.0 else 0 end)  as 'MIMO_NC_den',		
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[% RI1] is not null) then 1.0 else 0 end)  as 'RI1_NC_den',
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.[% RI2] is not null) then 1.0 else 0 end)  as 'RI2_NC_den',
		null,

		-- 20170321 - @ERC: Nuevos KPis y parametros:
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
	group by v.MNC,	v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end


select * from @data_ULthput