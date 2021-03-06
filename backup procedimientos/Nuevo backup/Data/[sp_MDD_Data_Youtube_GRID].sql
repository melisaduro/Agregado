USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_Youtube_GRID]    Script Date: 31/10/2017 15:54:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_Youtube_GRID] (
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
--use FY1617_Data_Rest_4G_H2
--declare @ciudad as varchar(256) = 'ALCAZARDESANJUAN'
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
	from Lcc_Data_YOUTUBE v, testinfo t, lcc_position_Entity_List_Vodafone c
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
	from Lcc_Data_YOUTUBE v, testinfo t, lcc_position_Entity_List_Orange c
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
	from Lcc_Data_YOUTUBE v, testinfo t, lcc_position_Entity_List_Municipio c
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
declare @dateMax datetime2(3)= (select max(c.endTime) from Lcc_Data_YOUTUBE c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)
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
--	from Lcc_Data_YOUTUBE where TestId=(select max(c.TestId) from Lcc_Data_YOUTUBE c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

declare @entidad as varchar(256) = @ciudad

declare @medida as varchar(256) 
if @Indoor=1 and @entidad not like '%RLW%' and @entidad not like '%APT%' and @entidad not like '%STD%'
begin
	SET @medida = right(@ciudad,1)
end
  
declare @week as varchar(256)
set @week = 'W' +convert(varchar,DATEPART(iso_week, @dateMax))

-------------------------------------------------------------------------------
--	GENERAL SELECT		-------------------	  select * from Lcc_Data_YOUTUBE
-------------------------------------------------------------------------------
declare @data_YTB  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Reproducciones] [int] NULL,
	[Fails] [int] NULL,
	[Time To First Image] [float] NULL,
	[Time To First Image max] [float] NULL,
	[Num. Interruptions] [int] NULL,
	[ReproduccionesSinInt] [int] NULL,
	[Service success ratio W/o interruptions] [float] NULL,
	[Reproduction ratio W/o interruptions] [float] NULL,
	[Successful video download] [int] NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF][varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP][varchar](256) NULL,

	-- 20170321 - @ERC: Nuevos KPis y parametros:
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL,
	[url] [varchar](256) NULL,

	-- 20170417 - @ERC: Nuevos KPis y parametros:
	[1st Resolution] [float] NULL,
	[Count 1st Resolution] [int] NULL,

	[2nd Resolution] [float] NULL,
	[Count 2nd Resolution] [int] NULL,

	[FirstChangeFromInit] [float] NULL,
	[Count FirstChangeFromInit] [int] NULL,

	[initialResolution] [float] NULL,
	[Count initialResolution] [int] NULL,

	[finalResolution] [float] NULL,
	[Count finalResolution] [int] NULL,

	[Duration] [float] NULL,
	[Count Duration] [int] NULL,

	[144p-VideoDuration] [float] NULL,
	[Count 144p-VideoDuration] [int] NULL,
	[144p-VideoMOS] [float] NULL,
	[Count 144p-VideoMOS] [int] NULL,
	[% 144p] [float] NULL,
	[Count % 144p] [int] NULL,

	[240p-VideoDuration] [float] NULL,
	[Count 240p-VideoDuration] [int] NULL,
	[240p-VideoMOS] [float] NULL,
	[Count 240p-VideoMOS] [int] NULL,
	[% 240p] [float] NULL,
	[Count % 240p] [int] NULL,

	[360p-VideoDuration] [float] NULL,
	[Count 360p-VideoDuration] [int] NULL,
	[360p-VideoMOS] [float] NULL,
	[Count 360p-VideoMOS] [int] NULL,
	[% 360p] [float] NULL,
	[Count % 360p] [int] NULL,

	[480p-VideoDuration] [float] NULL,
	[Count 480p-VideoDuration] [int] NULL,
	[480p-VideoMOS] [float] NULL,
	[Count 480p-VideoMOS] [int] NULL,
	[% 480p] [float] NULL,
	[Count % 480p] [int] NULL,

	[1080p-VideoDuration] [float] NULL,
	[Count 1080p-VideoDuration] [int] NULL,
	[1080p-VideoMOS] [float] NULL,
	[Count 1080p-VideoMOS] [int] NULL,
	[% 1080p] [float] NULL,
	[Count % 1080p] [int] NULL
)

if @Indoor=0
begin
	insert into @data_YTB
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Reproducciones',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.Fails = 'Failed') then 1 else 0 end) as 'Fails',
	
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[Time To First Image [s]]] end) as 'Time To First Image',
		MAX(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1.0*(v.[Time To First Image [s]]])end) as 'Time To First Image max',	
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[Num. Interruptions] end) as 'Num. Interruptions',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end) as 'ReproduccionesSinInt',

		case when SUM(case when v.typeoftest like '%YouTube%' and v.testname like '%SD%' then 1 else 0 end)>0 then
			(1 - (1.0*(SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.Fails = 'Failed') then 1 else 0 end)) / 
			(SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end)))) 
		else null end as 'Service success ratio W/o interruptions',	--B1
	
		case when SUM(case when v.typeoftest like '%YouTube%' and v.testname like '%SD%' then 1 else 0 end)>0 then
			1.0*(SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)) 
			/ (SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end)) 
		else null end as 'Reproduction ratio W/o interruptions',	-- B2
	
		SUM(case when v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.[Succeesful_Video_Download]='Successful' then 1 else 0 end) as 'Successful video download',  --B3
		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'GRID',
		lp.Region_OSP as Region_OSP,

		-- 20170321 - @ERC: Nuevos KPis y parametros:
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[ASideDevice] end as 'ASideDevice',
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[BSideDevice] end as 'BSideDevice',
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[SWVersion] end as 'SWVersion',	
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[url] end as 'url',

		-- 20170417 - @ERC: Nuevos KPis y parametros:
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[1st Resolution] end) as '1st Resolution',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 1st Resolution',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[2nd Resolution] end) as '2nd Resolution',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 2nd Resolution',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[FirstChangeFromInit] end) as 'FirstChangeFromInit',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count FirstChangeFromInit',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[initialResolution] end) as 'initialResolution',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count initialResolution',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[finalResolution] end) as 'finalResolution',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count finalResolution',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[Duration] end) as 'Duration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count Duration',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[144p-VideoDuration] end) as '144p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 144p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[144p-VideoMOS] end) as '144p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 144p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 144p] end) as '% 144p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 144p',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[240p-VideoDuration] end) as '240p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 240p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[240p-VideoMOS] end) as '240p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 240p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 240p] end) as '% 240p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 240p',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[360p-VideoDuration] end) as '360p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 360p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[360p-VideoMOS] end) as '360p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 360p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 360p] end) as '% 360p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 360p',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[480p-VideoDuration] end) as '480p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 480p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[480p-VideoMOS] end) as '480p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 480p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 480p] end) as '% 480p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 480p',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[1080p-VideoDuration] end) as '1080p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 1080p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[1080p-VideoMOS] end) as '1080p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 1080p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 1080p] end) as '% 1080p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 1080p'

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_YOUTUBE v,
		Agrids.dbo.lcc_parcelas lp
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.typeoftest like '%YouTube%' and v.testname like '%SD%'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP, 
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[ASideDevice] end,
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[BSideDevice] end,
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[SWVersion] end,	
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[url] end
end
else
begin
	insert into @data_YTB
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Reproducciones',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.Fails = 'Failed') then 1 else 0 end) as 'Fails',
	
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[Time To First Image [s]]] end) as 'Time To First Image',
		MAX(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1.0*(v.[Time To First Image [s]]])end) as 'Time To First Image max',	
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[Num. Interruptions] end) as 'Num. Interruptions',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end) as 'ReproduccionesSinInt',

		case when SUM(case when v.typeoftest like '%YouTube%' and v.testname like '%SD%' then 1 else 0 end)>0 then
			(1 - (1.0*(SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.Fails = 'Failed') then 1 else 0 end)) / 
			(SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end)))) 
		else null end as 'Service success ratio W/o interruptions',	--B1
	
		case when SUM(case when v.typeoftest like '%YouTube%' and v.testname like '%SD%' then 1 else 0 end)>0 then
			1.0*(SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)) 
			/ (SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end)) 
		else null end as 'Reproduction ratio W/o interruptions',	-- B2
	
		SUM(case when v.typeoftest like '%YouTube%' and v.testname like '%SD%' and v.[Succeesful_Video_Download]='Successful' then 1 else 0 end) as 'Successful video download',  --B3
		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'GRID',
		null,

		-- 20170321 - @ERC: Nuevos KPis y parametros:
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[ASideDevice] end as 'ASideDevice',
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[BSideDevice] end as 'BSideDevice',
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[SWVersion] end as 'SWVersion',	
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[url] end as 'url',

		-- 20170417 - @ERC: Nuevos KPis y parametros:
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[1st Resolution] end) as '1st Resolution',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 1st Resolution',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[2nd Resolution] end) as '2nd Resolution',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 2nd Resolution',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[FirstChangeFromInit] end) as 'FirstChangeFromInit',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count FirstChangeFromInit',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[initialResolution] end) as 'initialResolution',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count initialResolution',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[finalResolution] end) as 'finalResolution',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count finalResolution',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[Duration] end) as 'Duration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count Duration',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[144p-VideoDuration] end) as '144p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 144p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[144p-VideoMOS] end) as '144p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 144p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 144p] end) as '% 144p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 144p',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[240p-VideoDuration] end) as '240p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 240p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[240p-VideoMOS] end) as '240p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 240p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 240p] end) as '% 240p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 240p',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[360p-VideoDuration] end) as '360p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 360p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[360p-VideoMOS] end) as '360p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 360p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 360p] end) as '% 360p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 360p',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[480p-VideoDuration] end) as '480p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 480p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[480p-VideoMOS] end) as '480p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 480p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 480p] end) as '% 480p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 480p',

		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[1080p-VideoDuration] end) as '1080p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 1080p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[1080p-VideoMOS] end) as '1080p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count 1080p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[% 1080p] end) as '% 1080p',
		SUM(case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then 1 else 0 end) as 'Count % 1080p'

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_YOUTUBE v
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.typeoftest like '%YouTube%' and v.testname like '%SD%'
	group by v.MNC, 
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[ASideDevice] end,
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[BSideDevice] end,
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[SWVersion] end,	
		case when (v.typeoftest like '%YouTube%' and v.testname like '%SD%') then v.[url] end
end

select * from @data_YTB