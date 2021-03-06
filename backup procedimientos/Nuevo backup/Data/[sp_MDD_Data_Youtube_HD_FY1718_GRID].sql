USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_Youtube_HD_FY1718_GRID]    Script Date: 31/10/2017 15:55:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_Youtube_HD_FY1718_GRID] (
	  --Variables de entrada
		@ciudad as varchar(256),
		@simOperator as int,
		@sheet as varchar(256),				-- all: %%, 4G: 'LTE', 3G: 'WCDMA', CA
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
--use FY1718_DATA_WILL_4G_H1_1

--declare @ciudad as varchar(256) = 'ARAFO'
--declare @simOperator as int = 1
--declare @sheet as varchar(256) = '%%' --%%/LTE/WCDMA
--declare @date as varchar(256) = ''
--declare @Tech as varchar (256) = '4G'
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @Info as varchar (256) = 'Completed' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @methodology as varchar (256) = 'D16'
--declare @report as varchar(256) = 'MUN' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests_Tech as table (sessionid bigint, TestId bigint,tech varchar(5), hasCA varchar(2))


declare @YTB_url1 as varchar(256)
declare @YTB_url12 as varchar(256)
declare @YTB_url2 as varchar(256)
declare @YTB_url3 as varchar(256)
declare @YTB_url4 as varchar(256)

--URLs DE LOS 4 VIDEOS REPRODUCIDOS EN LA NUEVA METOLOGIA FY1718. 
--20170720: @MDM: Se modifica la condición, ya que en los FR el protocolo es diferente

if (db_name() like '%Indoor%' or db_name() like '%AVE%')
begin
 set @YTB_url1='http://www.youtube.com/watch?v=6DLcMKN8gI4'
 set @YTB_url12='http://www.youtube.com/watch?v=CuFH08QXNI8'
 set @YTB_url2='http://www.youtube.com/watch?v=QoHDdunfcQ8'
 set @YTB_url3='http://www.youtube.com/watch?v=uyPPAZUq66I'
 set @YTB_url4='http://www.youtube.com/watch?v=p_gv6fRejLM'
end
else
begin 
 set @YTB_url1='https://www.youtube.com/watch?v=6DLcMKN8gI4' 
 set @YTB_url12='https://www.youtube.com/watch?v=CuFH08QXNI8'
 set @YTB_url2='https://www.youtube.com/watch?v=QoHDdunfcQ8'
 set @YTB_url3='https://www.youtube.com/watch?v=uyPPAZUq66I'
 set @YTB_url4='https://www.youtube.com/watch?v=p_gv6fRejLM'
end


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
declare @data_YTB_HD  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Reproducciones] [int] NULL,
	[Fails] [int] NULL,
	[Time To First Image] [float] NULL,
	[Time To First Image max] [float] NULL,
	[Num. Interruptions] [int] NULL,
	[ReproduccionesSinInt] [int] NULL,
	[ReproduccionesHD] [int] NULL,
	[Count_Video_Resolucion] [int] NULL,
	[Count_Video_MOS] [int] NULL,
	[Service success ratio W/o interruptions] [float] NULL,
	[Reproduction ratio W/o interruptions] [float] NULL,
	[Successful video download] [int] NULL,
	[avg video resolution] [varchar](256) NULL,
	[B4] [int] NULL,
	[video mos] [float] NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF] [varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Youtube_Version] [varchar](256) null,
	[Region_OSP] [varchar](256) NULL,

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

	[720p-VideoDuration] [float] NULL,
	[Count 720p-VideoDuration] [int] NULL,
	[720p-VideoMOS] [float] NULL,
	[Count 720p-VideoMOS] [int] NULL,
	[% 720p] [float] NULL,
	[Count % 720p] [int] NULL,

	[1080p-VideoDuration] [float] NULL,
	[Count 1080p-VideoDuration] [int] NULL,
	[1080p-VideoMOS] [float] NULL,
	[Count 1080p-VideoMOS] [int] NULL,
	[% 1080p] [float] NULL,
	[Count % 1080p] [int] NULL,

--20170626 - @MDM: Se agregan nuevos KPIs para metodología FY1718:

--------------------------------------------------------------------------------
-- YOUTUBE HD - Video 1
--------------------------------------------------------------------------------
	[Reproducciones_Video1] [int] NULL,
	[Fails_Video1] [int] NULL,
	[Time To First Image_Video1] [float] NULL,
	[Time To First Image max_Video1] [float] NULL,
	[Num. Interruptions_Video1] [int] NULL,
	[ReproduccionesSinInt_Video1] [int] NULL,
	[ReproduccionesHD_Video1] [int] NULL,
	[Count_Video_Resolucion_Video1] [int] NULL,
	[Count_Video_MOS_Video1] [int] NULL,
	[Service success ratio W/o interruptions_Video1] [float] NULL,
	[Reproduction ratio W/o interruptions_Video1] [float] NULL,
	[Successful video download_Video1] [int] NULL,
	[avg video resolution_Video1] [varchar](256) NULL,
	[B4_Video1] [int] NULL,
	[video mos_Video1] [float] NULL,
	[url_Video1] [varchar](256) NULL,

	[1st Resolution_Video1] [float] NULL,
	[Count 1st Resolution_Video1] [int] NULL,
	[2nd Resolution_Video1] [float] NULL,
	[Count 2nd Resolution_Video1] [int] NULL,
	[FirstChangeFromInit_Video1] [float] NULL,
	[Count FirstChangeFromInit_Video1] [int] NULL,
	[initialResolution_Video1] [float] NULL,
	[Count initialResolution_Video1] [int] NULL,
	[finalResolution_Video1] [float] NULL,
	[Count finalResolution_Video1] [int] NULL,
	[Duration_Video1] [float] NULL,
	[Count Duration_Video1] [int] NULL,

	[144p-VideoDuration_Video1] [float] NULL,
	[Count 144p-VideoDuration_Video1] [int] NULL,
	[144p-VideoMOS_Video1] [float] NULL,
	[Count 144p-VideoMOS_Video1] [int] NULL,
	[% 144p_Video1] [float] NULL,
	[Count % 144p_Video1] [int] NULL,

	[240p-VideoDuration_Video1] [float] NULL,
	[Count 240p-VideoDuration_Video1] [int] NULL,
	[240p-VideoMOS_Video1] [float] NULL,
	[Count 240p-VideoMOS_Video1] [int] NULL,
	[% 240p_Video1] [float] NULL,
	[Count % 240p_Video1] [int] NULL,

	[360p-VideoDuration_Video1] [float] NULL,
	[Count 360p-VideoDuration_Video1] [int] NULL,
	[360p-VideoMOS_Video1] [float] NULL,
	[Count 360p-VideoMOS_Video1] [int] NULL,
	[% 360p_Video1] [float] NULL,
	[Count % 360p_Video1] [int] NULL,

	[480p-VideoDuration_Video1] [float] NULL,
	[Count 480p-VideoDuration_Video1] [int] NULL,
	[480p-VideoMOS_Video1] [float] NULL,
	[Count 480p-VideoMOS_Video1] [int] NULL,
	[% 480p_Video1] [float] NULL,
	[Count % 480p_Video1] [int] NULL,

	[720p-VideoDuration_Video1] [float] NULL,
	[Count 720p-VideoDuration_Video1] [int] NULL,
	[720p-VideoMOS_Video1] [float] NULL,
	[Count 720p-VideoMOS_Video1] [int] NULL,
	[% 720p_Video1] [float] NULL,
	[Count % 720p_Video1] [int] NULL,

	[1080p-VideoDuration_Video1] [float] NULL,
	[Count 1080p-VideoDuration_Video1] [int] NULL,
	[1080p-VideoMOS_Video1] [float] NULL,
	[Count 1080p-VideoMOS_Video1] [int] NULL,
	[% 1080p_Video1] [float] NULL,
	[Count % 1080p_Video1] [int] NULL,
--------------------------------------------------------------------------------
-- YOUTUBE HD - Video 2
--------------------------------------------------------------------------------
	[Reproducciones_Video2] [int] NULL,
	[Fails_Video2] [int] NULL,
	[Time To First Image_Video2] [float] NULL,
	[Time To First Image max_Video2] [float] NULL,
	[Num. Interruptions_Video2] [int] NULL,
	[ReproduccionesSinInt_Video2] [int] NULL,
	[ReproduccionesHD_Video2] [int] NULL,
	[Count_Video_Resolucion_Video2] [int] NULL,
	[Count_Video_MOS_Video2] [int] NULL,
	[Service success ratio W/o interruptions_Video2] [float] NULL,
	[Reproduction ratio W/o interruptions_Video2] [float] NULL,
	[Successful video download_Video2] [int] NULL,
	[avg video resolution_Video2] [varchar](256) NULL,
	[B4_Video2] [int] NULL,
	[video mos_Video2] [float] NULL,
	[url_Video2] [varchar](256) NULL,

	[1st Resolution_Video2] [float] NULL,
	[Count 1st Resolution_Video2] [int] NULL,
	[2nd Resolution_Video2] [float] NULL,
	[Count 2nd Resolution_Video2] [int] NULL,
	[FirstChangeFromInit_Video2] [float] NULL,
	[Count FirstChangeFromInit_Video2] [int] NULL,
	[initialResolution_Video2] [float] NULL,
	[Count initialResolution_Video2] [int] NULL,
	[finalResolution_Video2] [float] NULL,
	[Count finalResolution_Video2] [int] NULL,
	[Duration_Video2] [float] NULL,
	[Count Duration_Video2] [int] NULL,

	[144p-VideoDuration_Video2] [float] NULL,
	[Count 144p-VideoDuration_Video2] [int] NULL,
	[144p-VideoMOS_Video2] [float] NULL,
	[Count 144p-VideoMOS_Video2] [int] NULL,
	[% 144p_Video2] [float] NULL,
	[Count % 144p_Video2] [int] NULL,

	[240p-VideoDuration_Video2] [float] NULL,
	[Count 240p-VideoDuration_Video2] [int] NULL,
	[240p-VideoMOS_Video2] [float] NULL,
	[Count 240p-VideoMOS_Video2] [int] NULL,
	[% 240p_Video2] [float] NULL,
	[Count % 240p_Video2] [int] NULL,

	[360p-VideoDuration_Video2] [float] NULL,
	[Count 360p-VideoDuration_Video2] [int] NULL,
	[360p-VideoMOS_Video2] [float] NULL,
	[Count 360p-VideoMOS_Video2] [int] NULL,
	[% 360p_Video2] [float] NULL,
	[Count % 360p_Video2] [int] NULL,

	[480p-VideoDuration_Video2] [float] NULL,
	[Count 480p-VideoDuration_Video2] [int] NULL,
	[480p-VideoMOS_Video2] [float] NULL,
	[Count 480p-VideoMOS_Video2] [int] NULL,
	[% 480p_Video2] [float] NULL,
	[Count % 480p_Video2] [int] NULL,

	[720p-VideoDuration_Video2] [float] NULL,
	[Count 720p-VideoDuration_Video2] [int] NULL,
	[720p-VideoMOS_Video2] [float] NULL,
	[Count 720p-VideoMOS_Video2] [int] NULL,
	[% 720p_Video2] [float] NULL,
	[Count % 720p_Video2] [int] NULL,

	[1080p-VideoDuration_Video2] [float] NULL,
	[Count 1080p-VideoDuration_Video2] [int] NULL,
	[1080p-VideoMOS_Video2] [float] NULL,
	[Count 1080p-VideoMOS_Video2] [int] NULL,
	[% 1080p_Video2] [float] NULL,
	[Count % 1080p_Video2] [int] NULL,
--------------------------------------------------------------------------------
-- YOUTUBE HD - Video 3
--------------------------------------------------------------------------------
	[Reproducciones_Video3] [int] NULL,
	[Fails_Video3] [int] NULL,
	[Time To First Image_Video3] [float] NULL,
	[Time To First Image max_Video3] [float] NULL,
	[Num. Interruptions_Video3] [int] NULL,
	[ReproduccionesSinInt_Video3] [int] NULL,
	[ReproduccionesHD_Video3] [int] NULL,
	[Count_Video_Resolucion_Video3] [int] NULL,
	[Count_Video_MOS_Video3] [int] NULL,
	[Service success ratio W/o interruptions_Video3] [float] NULL,
	[Reproduction ratio W/o interruptions_Video3] [float] NULL,
	[Successful video download_Video3] [int] NULL,
	[avg video resolution_Video3] [varchar](256) NULL,
	[B4_Video3] [int] NULL,
	[video mos_Video3] [float] NULL,
	[url_Video3] [varchar](256) NULL,

	[1st Resolution_Video3] [float] NULL,
	[Count 1st Resolution_Video3] [int] NULL,
	[2nd Resolution_Video3] [float] NULL,
	[Count 2nd Resolution_Video3] [int] NULL,
	[FirstChangeFromInit_Video3] [float] NULL,
	[Count FirstChangeFromInit_Video3] [int] NULL,
	[initialResolution_Video3] [float] NULL,
	[Count initialResolution_Video3] [int] NULL,
	[finalResolution_Video3] [float] NULL,
	[Count finalResolution_Video3] [int] NULL,
	[Duration_Video3] [float] NULL,
	[Count Duration_Video3] [int] NULL,

	[144p-VideoDuration_Video3] [float] NULL,
	[Count 144p-VideoDuration_Video3] [int] NULL,
	[144p-VideoMOS_Video3] [float] NULL,
	[Count 144p-VideoMOS_Video3] [int] NULL,
	[% 144p_Video3] [float] NULL,
	[Count % 144p_Video3] [int] NULL,

	[240p-VideoDuration_Video3] [float] NULL,
	[Count 240p-VideoDuration_Video3] [int] NULL,
	[240p-VideoMOS_Video3] [float] NULL,
	[Count 240p-VideoMOS_Video3] [int] NULL,
	[% 240p_Video3] [float] NULL,
	[Count % 240p_Video3] [int] NULL,

	[360p-VideoDuration_Video3] [float] NULL,
	[Count 360p-VideoDuration_Video3] [int] NULL,
	[360p-VideoMOS_Video3] [float] NULL,
	[Count 360p-VideoMOS_Video3] [int] NULL,
	[% 360p_Video3] [float] NULL,
	[Count % 360p_Video3] [int] NULL,

	[480p-VideoDuration_Video3] [float] NULL,
	[Count 480p-VideoDuration_Video3] [int] NULL,
	[480p-VideoMOS_Video3] [float] NULL,
	[Count 480p-VideoMOS_Video3] [int] NULL,
	[% 480p_Video3] [float] NULL,
	[Count % 480p_Video3] [int] NULL,

	[720p-VideoDuration_Video3] [float] NULL,
	[Count 720p-VideoDuration_Video3] [int] NULL,
	[720p-VideoMOS_Video3] [float] NULL,
	[Count 720p-VideoMOS_Video3] [int] NULL,
	[% 720p_Video3] [float] NULL,
	[Count % 720p_Video3] [int] NULL,

	[1080p-VideoDuration_Video3] [float] NULL,
	[Count 1080p-VideoDuration_Video3] [int] NULL,
	[1080p-VideoMOS_Video3] [float] NULL,
	[Count 1080p-VideoMOS_Video3] [int] NULL,
	[% 1080p_Video3] [float] NULL,
	[Count % 1080p_Video3] [int] NULL,
--------------------------------------------------------------------------------
-- YOUTUBE HD - Video 4
--------------------------------------------------------------------------------
	[Reproducciones_Video4] [int] NULL,
	[Fails_Video4] [int] NULL,
	[Time To First Image_Video4] [float] NULL,
	[Time To First Image max_Video4] [float] NULL,
	[Num. Interruptions_Video4] [int] NULL,
	[ReproduccionesSinInt_Video4] [int] NULL,
	[ReproduccionesHD_Video4] [int] NULL,
	[Count_Video_Resolucion_Video4] [int] NULL,
	[Count_Video_MOS_Video4] [int] NULL,
	[Service success ratio W/o interruptions_Video4] [float] NULL,
	[Reproduction ratio W/o interruptions_Video4] [float] NULL,
	[Successful video download_Video4] [int] NULL,
	[avg video resolution_Video4] [varchar](256) NULL,
	[B4_Video4] [int] NULL,
	[video mos_Video4] [float] NULL,
	[url_Video4] [varchar](256) NULL,

	[1st Resolution_Video4] [float] NULL,
	[Count 1st Resolution_Video4] [int] NULL,
	[2nd Resolution_Video4] [float] NULL,
	[Count 2nd Resolution_Video4] [int] NULL,
	[FirstChangeFromInit_Video4] [float] NULL,
	[Count FirstChangeFromInit_Video4] [int] NULL,
	[initialResolution_Video4] [float] NULL,
	[Count initialResolution_Video4] [int] NULL,
	[finalResolution_Video4] [float] NULL,
	[Count finalResolution_Video4] [int] NULL,
	[Duration_Video4] [float] NULL,
	[Count Duration_Video4] [int] NULL,

	[144p-VideoDuration_Video4] [float] NULL,
	[Count 144p-VideoDuration_Video4] [int] NULL,
	[144p-VideoMOS_Video4] [float] NULL,
	[Count 144p-VideoMOS_Video4] [int] NULL,
	[% 144p_Video4] [float] NULL,
	[Count % 144p_Video4] [int] NULL,

	[240p-VideoDuration_Video4] [float] NULL,
	[Count 240p-VideoDuration_Video4] [int] NULL,
	[240p-VideoMOS_Video4] [float] NULL,
	[Count 240p-VideoMOS_Video4] [int] NULL,
	[% 240p_Video4] [float] NULL,
	[Count % 240p_Video4] [int] NULL,

	[360p-VideoDuration_Video4] [float] NULL,
	[Count 360p-VideoDuration_Video4] [int] NULL,
	[360p-VideoMOS_Video4] [float] NULL,
	[Count 360p-VideoMOS_Video4] [int] NULL,
	[% 360p_Video4] [float] NULL,
	[Count % 360p_Video4] [int] NULL,

	[480p-VideoDuration_Video4] [float] NULL,
	[Count 480p-VideoDuration_Video4] [int] NULL,
	[480p-VideoMOS_Video4] [float] NULL,
	[Count 480p-VideoMOS_Video4] [int] NULL,
	[% 480p_Video4] [float] NULL,
	[Count % 480p_Video4] [int] NULL,

	[720p-VideoDuration_Video4] [float] NULL,
	[Count 720p-VideoDuration_Video4] [int] NULL,
	[720p-VideoMOS_Video4] [float] NULL,
	[Count 720p-VideoMOS_Video4] [int] NULL,
	[% 720p_Video4] [float] NULL,
	[Count % 720p_Video4] [int] NULL,

	[1080p-VideoDuration_Video4] [float] NULL,
	[Count 1080p-VideoDuration_Video4] [int] NULL,
	[1080p-VideoMOS_Video4] [float] NULL,
	[Count 1080p-VideoMOS_Video4] [int] NULL,
	[% 1080p_Video4] [float] NULL,
	[Count % 1080p_Video4] [int] NULL
)

if @Indoor=0
begin
	insert into @data_YTB_HD
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then 1 else 0 end) as 'Reproducciones',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.Fails = 'Failed') then 1 else 0 end) as 'Fails',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[Time To First Image [s]]] end) as 'Time To First Image',
		MAX(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then 1.0*(v.[Time To First Image [s]]])end) as 'Time To First Image max',	
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[Num. Interruptions] end) as 'Num. Interruptions',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[End Status] ='W/O Interruptions') then 1 else 0 end) as 'ReproduccionesSinInt',
		--SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[Video Resolution]='720p') then 1 else 0 end) as 'ReproduccionesHD', 
		SUM(case when (v.typeoftest like '%YouTube%' /*and ytb.testname like '%HD%'*/ and FLOOR (replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end) as 'ReproduccionesHD',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and ISNULL(FLOOR(replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end) as 'Count_Video_Resolucion',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) as 'Count_Video_MOS',

		case when SUM(case when v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ then 1 else 0 end)>0 then
			(1 - (1.0*(SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.Fails = 'Failed') then 1 else 0 end)) / 
			(SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then 1 else 0 end)))) 
		else null end as 'Service success ratio W/o interruptions',	--B1
	
		case when SUM(case when v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ then 1 else 0 end)>0 then
			1.0*(SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[End Status]='W/O Interruptions') then 1 else 0 end)) 
			/ (SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then 1 else 0 end)) 
		else null end as 'Reproduction ratio W/o interruptions',	-- B2
	
		SUM(case when v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[Succeesful_Video_Download]='Successful' then 1 else 0 end) as 'Successful video download',  --B3


		/*** Metodo antiguo con Youtube v10 en el que solo se obtenía hasta 720p ***/
		--CASE @Methodology WHEN 'D16' THEN cast( avg(cast (left(v.[Video Resolution],3) as int)) as varchar(10)) + 'p' ELSE NULL END as 'avg video resolution', --B5
		/*** Cambio para limitar que las medidas de Youtube v10 no obtengan más de 720p ***/
		--CASE @Methodology WHEN 'D16' THEN cast( avg(case when (cast (left(v.[Video Resolution],3) as int)<= 720 or v.[Video Resolution] is null) then cast (left(v.[Video Resolution],3) as int)
		--												   else 720 end
		--													) as varchar(10)) + 'p' ELSE NULL END as 'avg video resolution', --B5
		/*** Se incluye Youtube v11 que puede superar los 720p, y se mantiene la limitacion para Youtube v10 que no pueda superar los 720p ***/
		CASE @Methodology WHEN 'D16' then 
		
		--Cambio para hacer el redondeo correcto:
		--cast(avg(case when r.Player like '%v11%' then (cast (floor(replace([Video Resolution],'p','')) as int))
		--		else
		--			case when cast (left(v.[Video Resolution],3) as int)<= 720 or v.[Video Resolution] is null then cast (left(v.[Video Resolution],3) as int)
		--			else 720 end 
		--		end) as varchar(10)) + 'p' ELSE NULL END as 'avg video resolution', --B5

		cast(round(avg((case when cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11 then floor(replace(v.[Video Resolution],'p',''))
			else		
				case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then floor(replace(v.[Video Resolution],'p',''))
				else 720 end end)), 16) as varchar(20)) + 'p' ELSE NULL END as 'avg video resolution', --B5 
				

		--SUM(case when (v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' /*and v.testname like '%HD%'*/ and v.[Video Resolution]='720p') then 1 else 0 end) as 'B4', --B4
		SUM(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' 
				and floor(replace(v.[Video Resolution],'p',''))>= 720 then 1 
				else 0 end
			) as 'B4', --B4
		CASE @Methodology WHEN 'D16' THEN avg(v.Video_MOS) ELSE NULL END as 'video mos', --B6

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'GRID',
		--YTBVersion c
		MAX(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.YTBVersion end) as 'Youtube_Version',
		lp.Region_OSP as Region_OSP,

		-- 20170321 - @ERC: Nuevos KPis y parametros:
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[ASideDevice] end as 'ASideDevice',
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[BSideDevice] end as 'BSideDevice',
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[SWVersion] end as 'SWVersion',	
		
		-- 20170707 - @MDM:
		--La url se rellena a nulo en la nueva metodologúa FY1718, ya que podría introducir duplicados
		--si se hiciesen varias pruebas en la misma parcela
		--case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[url] end as 'url',
		NULL as 'url',

		-- 20170417 - @ERC: Nuevos KPis y parametros:
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[1st Resolution] end) as '1st Resolution',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[1st Resolution] is not null) then 1 else 0 end) as 'Count 1st Resolution',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[2nd Resolution] end) as '2nd Resolution',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[2nd Resolution] is not null) then 1 else 0 end) as 'Count 2nd Resolution',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[FirstChangeFromInit] end) as 'FirstChangeFromInit',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[FirstChangeFromInit] is not null) then 1 else 0 end) as 'Count FirstChangeFromInit',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[initialResolution] end) as 'initialResolution',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[initialResolution] is not null) then 1 else 0 end) as 'Count initialResolution',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[finalResolution] end) as 'finalResolution',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[finalResolution] is not null) then 1 else 0 end) as 'Count finalResolution',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[Duration] end) as 'Duration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[Duration] is not null) then 1 else 0 end) as 'Count Duration',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[144p-VideoDuration] end) as '144p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[144p-VideoDuration] is not null) then 1 else 0 end) as 'Count 144p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[144p-VideoMOS] end) as '144p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[144p-VideoMOS] is not null) then 1 else 0 end) as 'Count 144p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 144p] end) as '% 144p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 144p] is not null) then 1 else 0 end) as 'Count % 144p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[240p-VideoDuration] end) as '240p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[240p-VideoDuration] is not null) then 1 else 0 end) as 'Count 240p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[240p-VideoMOS] end) as '240p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[240p-VideoMOS] is not null) then 1 else 0 end) as 'Count 240p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 240p] end) as '% 240p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 240p] is not null) then 1 else 0 end) as 'Count % 240p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[360p-VideoDuration] end) as '360p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[360p-VideoDuration] is not null) then 1 else 0 end) as 'Count 360p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[360p-VideoMOS] end) as '360p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[360p-VideoMOS] is not null) then 1 else 0 end) as 'Count 360p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 360p] end) as '% 360p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 360p] is not null) then 1 else 0 end) as 'Count % 360p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[480p-VideoDuration] end) as '480p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[480p-VideoDuration] is not null) then 1 else 0 end) as 'Count 480p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[480p-VideoMOS] end) as '480p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[480p-VideoMOS] is not null) then 1 else 0 end) as 'Count 480p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 480p] end) as '% 480p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 480p] is not null) then 1 else 0 end) as 'Count % 480p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[720p-VideoDuration] end) as '720p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[720p-VideoDuration] is not null) then 1 else 0 end) as 'Count 720p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[720p-VideoMOS] end) as '720p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[720p-VideoMOS] is not null) then 1 else 0 end) as 'Count 720p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 720p] end) as '% 720p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 720p] is not null) then 1 else 0 end) as 'Count % 720p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[1080p-VideoDuration] end) as '1080p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[1080p-VideoDuration] is not null) then 1 else 0 end) as 'Count 1080p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[1080p-VideoMOS] end) as '1080p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[1080p-VideoMOS] is not null) then 1 else 0 end) as 'Count 1080p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 1080p] end) as '% 1080p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 1080p] is not null) then 1 else 0 end) as 'Count % 1080p',

		--20170626 - @MDM: Se agregan nuevos KPIs para metodología FY1718:

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- YOUTUBE HD - Video 1
------------------------------------------------------------------------------------------------------------------------------------------------------------

		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end ) end) as 'Reproducciones_Video1',
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end) end) as 'Fails_Video1',
		AVG(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%') then v.[Time To First Image [s]]] end)end) as 'Time To First Image_Video1',
		MAX(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%') then 1.0*(v.[Time To First Image [s]]])end)end) as 'Time To First Image max_Video1',	
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%') then v.[Num. Interruptions] end)end ) as 'Num. Interruptions_Video1',
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end)end) as 'ReproduccionesSinInt_Video1', 
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and FLOOR (replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end)end) as 'ReproduccionesHD_Video1',
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and ISNULL(FLOOR (replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end)end) as 'Count_Video_Resolucion_Video1',
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) end )as 'Count_Video_MOS_Video1',

		case when(SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1 - (1.0*(SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end)end)) 
			/ (SUM(case when( v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))))
		else null end as 'Service success ratio W/o interruptions_Video1',	--B1
	
		case when (SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1.0*(SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)end)) 
			/ (SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))) 
		else null end as 'Reproduction ratio W/o interruptions_Video1',	-- B2
	
		SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful') then 1 else 0 end)end) as 'Successful video download_Video1',  --B3		

		
		case @Methodology when 'D16' then cast(round(avg(case when (v.url=@YTB_url1 or v.url=@YTB_url12) 
	    then (case when (cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11) 
					then floor(replace(v.[Video Resolution],'p',''))
			  else (case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then 
						floor(replace(v.[Video Resolution],'p',''))
					else 720 end)
			  end)
		end),16) as varchar(20))+ 'p' ELSE NULL END as 'avg video resolution_Video1', --B5 
				

		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then 
			(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720 then 
			  1 else 0 end)end) as 'B4_Video1', --B4

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then v.Video_MOS ELSE NULL END) as 'video mos_Video1', --B6
		MAX(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then( case when v.typeoftest like '%YouTube%' then v.[url] end) end) as 'url_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[1st Resolution] end)end) as '1st Resolution_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[1st Resolution] is not null) then 1 else 0 end)end) as 'Count 1st Resolution_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[2nd Resolution] end)end) as '2nd Resolution_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[2nd Resolution] is not null) then 1 else 0 end)end) as 'Count 2nd Resolution_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[FirstChangeFromInit] end)end) as 'FirstChangeFromInit_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[FirstChangeFromInit] is not null) then 1 else 0 end)end) as 'Count FirstChangeFromInit_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[initialResolution] end)end) as 'initialResolution_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[initialResolution] is not null) then 1 else 0 end)end) as 'Count initialResolution_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[finalResolution] end)end) as 'finalResolution_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[finalResolution] is not null) then 1 else 0 end)end) as 'Count finalResolution_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[Duration] end)end) as 'Duration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[Duration] is not null) then 1 else 0 end)end) as 'Count Duration_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoDuration] end)end) as '144p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 144p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoMOS] end)end) as '144p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 144p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 144p] end)end) as '% 144p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 144p] is not null) then 1 else 0 end)end) as 'Count % 144p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoDuration] end)end) as '240p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 240p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoMOS] end)end) as '240p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 240p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 240p] end)end) as '% 240p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 240p] is not null) then 1 else 0 end)end) as 'Count % 240p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoDuration] end)end) as '360p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 360p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoMOS] end)end) as '360p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 360p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 360p] end)end) as '% 360p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 360p] is not null) then 1 else 0 end)end) as 'Count % 360p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoDuration] end)end) as '480p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 480p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoMOS] end)end) as '480p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 480p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 480p] end)end) as '% 480p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 480p] is not null) then 1 else 0 end)end) as 'Count % 480p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoDuration] end)end) as '720p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 720p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoMOS] end)end) as '720p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 720p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 720p] end)end) as '% 720p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 720p] is not null) then 1 else 0 end)end) as 'Count % 720p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoDuration] end)end) as '1080p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoMOS] end)end) as '1080p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 1080p] end)end) as '% 1080p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 1080p] is not null) then 1 else 0 end)end) as 'Count % 1080p_Video1',


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- YOUTUBE HD - Video 2
------------------------------------------------------------------------------------------------------------------------------------------------------------

		SUM(case when(v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end ) end) as 'Reproducciones_Video2',
		SUM(case when(v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end) end) as 'Fails_Video2',
		AVG(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%') then v.[Time To First Image [s]]] end)end) as 'Time To First Image_Video2',
		MAX(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%') then 1.0*(v.[Time To First Image [s]]])end)end) as 'Time To First Image max_Video2',	
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%') then v.[Num. Interruptions] end)end ) as 'Num. Interruptions_Video2',
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end)end) as 'ReproduccionesSinInt_Video2', 
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end)end) as 'ReproduccionesHD_Video2',
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and ISNULL(FLOOR (replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end)end) as 'Count_Video_Resolucion_Video2',
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) end )as 'Count_Video_MOS_Video2',

		case when(SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1 - (1.0*(SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end)end)) 
			/ (SUM(case when( v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))))
		else null end as 'Service success ratio W/o interruptions_Video2',	--B1
	
		case when (SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1.0*(SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)end)) 
			/ (SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))) 
		else null end as 'Reproduction ratio W/o interruptions_Video2',	-- B2
	
		SUM(case when (v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful') then 1 else 0 end)end) as 'Successful video download_Video2',  --B3		

		
		case @Methodology when 'D16' then cast(round(avg(case when (v.url=@YTB_url2) 
	    then (case when (cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11) 
					then floor(replace(v.[Video Resolution],'p',''))
			  else (case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then 
						floor(replace(v.[Video Resolution],'p',''))
					else 720 end)
			  end)
		end),16) as varchar(20))+ 'p' ELSE NULL END as 'avg video resolution_Video2', --B5 
				

		SUM(case when (v.url = @YTB_url2) then 
			(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720 then 
			  1 else 0 end)end) as 'B4_Video2', --B4

		AVG(case when v.url = @YTB_url2 then v.Video_MOS ELSE NULL END) as 'video mos_Video2', --B6
		MAX(case when (v.url = @YTB_url2) then( case when v.typeoftest like '%YouTube%' then v.[url] end) end) as 'url_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[1st Resolution] end)end) as '1st Resolution_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[1st Resolution] is not null) then 1 else 0 end)end) as 'Count 1st Resolution_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[2nd Resolution] end)end) as '2nd Resolution_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[2nd Resolution] is not null) then 1 else 0 end)end) as 'Count 2nd Resolution_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[FirstChangeFromInit] end)end) as 'FirstChangeFromInit_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[FirstChangeFromInit] is not null) then 1 else 0 end)end) as 'Count FirstChangeFromInit_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[initialResolution] end)end) as 'initialResolution_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[initialResolution] is not null) then 1 else 0 end)end) as 'Count initialResolution_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[finalResolution] end)end) as 'finalResolution_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[finalResolution] is not null) then 1 else 0 end)end) as 'Count finalResolution_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[Duration] end)end) as 'Duration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[Duration] is not null) then 1 else 0 end)end) as 'Count Duration_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoDuration] end)end) as '144p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 144p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoMOS] end)end) as '144p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 144p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 144p] end)end) as '% 144p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 144p] is not null) then 1 else 0 end)end) as 'Count % 144p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoDuration] end)end) as '240p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 240p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoMOS] end)end) as '240p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 240p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 240p] end)end) as '% 240p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 240p] is not null) then 1 else 0 end)end) as 'Count % 240p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoDuration] end)end) as '360p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 360p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoMOS] end)end) as '360p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 360p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 360p] end)end) as '% 360p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 360p] is not null) then 1 else 0 end)end) as 'Count % 360p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoDuration] end)end) as '480p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 480p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoMOS] end)end) as '480p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 480p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 480p] end)end) as '% 480p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 480p] is not null) then 1 else 0 end)end) as 'Count % 480p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoDuration] end)end) as '720p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 720p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoMOS] end)end) as '720p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 720p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 720p] end)end) as '% 720p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 720p] is not null) then 1 else 0 end)end) as 'Count % 720p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoDuration] end)end) as '1080p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoMOS] end)end) as '1080p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 1080p] end)end) as '% 1080p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 1080p] is not null) then 1 else 0 end)end) as 'Count % 1080p_Video2',


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- YOUTUBE HD - Video 3
------------------------------------------------------------------------------------------------------------------------------------------------------------

		SUM(case when(v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end ) end) as 'Reproducciones_Video3',
		SUM(case when(v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end) end) as 'Fails_Video3',
		AVG(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%') then v.[Time To First Image [s]]] end)end) as 'Time To First Image_Video3',
		MAX(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%') then 1.0*(v.[Time To First Image [s]]])end)end) as 'Time To First Image max_Video3',	
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%') then v.[Num. Interruptions] end)end ) as 'Num. Interruptions_Video3',
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end)end) as 'ReproduccionesSinInt_Video3', 
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end)end) as 'ReproduccionesHD_Video3',
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and ISNULL(FLOOR(replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end)end) as 'Count_Video_Resolucion_Video3',
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) end )as 'Count_Video_MOS_Video3',

		case when(SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1 - (1.0*(SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end)end)) 
			/ (SUM(case when( v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))))
		else null end as 'Service success ratio W/o interruptions_Video3',	--B1
	
		case when (SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1.0*(SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)end)) 
			/ (SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))) 
		else null end as 'Reproduction ratio W/o interruptions_Video3',	-- B2
	
		SUM(case when (v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful') then 1 else 0 end)end) as 'Successful video download_Video3',  --B3		

		
		case @Methodology when 'D16' then cast(round(avg(case when (v.url=@YTB_url3) 
	    then (case when (cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11) 
					then floor(replace(v.[Video Resolution],'p',''))
			  else (case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then 
						floor(replace(v.[Video Resolution],'p',''))
					else 720 end)
			  end)
		end),16) as varchar(20))+ 'p' ELSE NULL END as 'avg video resolution_Video3', --B5 
				

		SUM(case when (v.url = @YTB_url3) then 
			(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720 then 
			  1 else 0 end)end) as 'B4_Video3', --B4

		AVG(case when v.url = @YTB_url3 then v.Video_MOS ELSE NULL END) as 'video mos_Video3', --B6
		MAX(case when (v.url = @YTB_url3) then( case when v.typeoftest like '%YouTube%' then v.[url] end) end) as 'url_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[1st Resolution] end)end) as '1st Resolution_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[1st Resolution] is not null) then 1 else 0 end)end) as 'Count 1st Resolution_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[2nd Resolution] end)end) as '2nd Resolution_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[2nd Resolution] is not null) then 1 else 0 end)end) as 'Count 2nd Resolution_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[FirstChangeFromInit] end)end) as 'FirstChangeFromInit_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[FirstChangeFromInit] is not null) then 1 else 0 end)end) as 'Count FirstChangeFromInit_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[initialResolution] end)end) as 'initialResolution_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[initialResolution] is not null) then 1 else 0 end)end) as 'Count initialResolution_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[finalResolution] end)end) as 'finalResolution_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[finalResolution] is not null) then 1 else 0 end)end) as 'Count finalResolution_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[Duration] end)end) as 'Duration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[Duration] is not null) then 1 else 0 end)end) as 'Count Duration_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoDuration] end)end) as '144p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 144p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoMOS] end)end) as '144p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 144p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 144p] end)end) as '% 144p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 144p] is not null) then 1 else 0 end)end) as 'Count % 144p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoDuration] end)end) as '240p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 240p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoMOS] end)end) as '240p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 240p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 240p] end)end) as '% 240p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 240p] is not null) then 1 else 0 end)end) as 'Count % 240p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoDuration] end)end) as '360p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 360p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoMOS] end)end) as '360p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 360p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 360p] end)end) as '% 360p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 360p] is not null) then 1 else 0 end)end) as 'Count % 360p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoDuration] end)end) as '480p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 480p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoMOS] end)end) as '480p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 480p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 480p] end)end) as '% 480p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 480p] is not null) then 1 else 0 end)end) as 'Count % 480p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoDuration] end)end) as '720p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 720p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoMOS] end)end) as '720p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 720p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 720p] end)end) as '% 720p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 720p] is not null) then 1 else 0 end)end) as 'Count % 720p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoDuration] end)end) as '1080p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoMOS] end)end) as '1080p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 1080p] end)end) as '% 1080p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 1080p] is not null) then 1 else 0 end)end) as 'Count % 1080p_Video3',


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- YOUTUBE HD - Video 4
------------------------------------------------------------------------------------------------------------------------------------------------------------

		SUM(case when(v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end ) end) as 'Reproducciones_Video4',
		SUM(case when(v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end) end) as 'Fails_Video4',
		AVG(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%') then v.[Time To First Image [s]]] end)end) as 'Time To First Image_Video4',
		MAX(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%') then 1.0*(v.[Time To First Image [s]]])end)end) as 'Time To First Image max_Video4',	
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%') then v.[Num. Interruptions] end)end ) as 'Num. Interruptions_Video4',
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end)end) as 'ReproduccionesSinInt_Video4', 
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end)end) as 'ReproduccionesHD_Video4',
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and ISNULL(FLOOR(replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end)end) as 'Count_Video_Resolucion_Video4',
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) end )as 'Count_Video_MOS_Video4',

		case when(SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1 - (1.0*(SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end)end)) 
			/ (SUM(case when( v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))))
		else null end as 'Service success ratio W/o interruptions_Video4',	--B1
	
		case when (SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1.0*(SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)end)) 
			/ (SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))) 
		else null end as 'Reproduction ratio W/o interruptions_Video4',	-- B2
	
		SUM(case when (v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful') then 1 else 0 end)end) as 'Successful video download_Video4',  --B3		

		
		case @Methodology when 'D16' then cast(round(avg(case when (v.url=@YTB_url4) 
	    then (case when (cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11) 
					then floor(replace(v.[Video Resolution],'p',''))
			  else (case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then 
						floor(replace(v.[Video Resolution],'p',''))
					else 720 end)
			  end)
		end),16) as varchar(20))+ 'p' ELSE NULL END as 'avg video resolution_Video4', --B5 
				

		SUM(case when (v.url = @YTB_url4) then 
			(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720 then 
			  1 else 0 end)end) as 'B4_Video4', --B4

		AVG(case when v.url = @YTB_url4 then v.Video_MOS ELSE NULL END) as 'video mos_Video4', --B6
		MAX(case when (v.url = @YTB_url4) then( case when v.typeoftest like '%YouTube%' then v.[url] end) end) as 'url_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[1st Resolution] end)end) as '1st Resolution_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[1st Resolution] is not null) then 1 else 0 end)end) as 'Count 1st Resolution_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[2nd Resolution] end)end) as '2nd Resolution_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[2nd Resolution] is not null) then 1 else 0 end)end) as 'Count 2nd Resolution_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[FirstChangeFromInit] end)end) as 'FirstChangeFromInit_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[FirstChangeFromInit] is not null) then 1 else 0 end)end) as 'Count FirstChangeFromInit_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[initialResolution] end)end) as 'initialResolution_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[initialResolution] is not null) then 1 else 0 end)end) as 'Count initialResolution_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[finalResolution] end)end) as 'finalResolution_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[finalResolution] is not null) then 1 else 0 end)end) as 'Count finalResolution_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[Duration] end)end) as 'Duration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[Duration] is not null) then 1 else 0 end)end) as 'Count Duration_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoDuration] end)end) as '144p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 144p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoMOS] end)end) as '144p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 144p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 144p] end)end) as '% 144p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 144p] is not null) then 1 else 0 end)end) as 'Count % 144p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoDuration] end)end) as '240p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 240p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoMOS] end)end) as '240p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 240p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 240p] end)end) as '% 240p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 240p] is not null) then 1 else 0 end)end) as 'Count % 240p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoDuration] end)end) as '360p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 360p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoMOS] end)end) as '360p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 360p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 360p] end)end) as '% 360p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 360p] is not null) then 1 else 0 end)end) as 'Count % 360p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoDuration] end)end) as '480p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 480p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoMOS] end)end) as '480p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 480p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 480p] end)end) as '% 480p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 480p] is not null) then 1 else 0 end)end) as 'Count % 480p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoDuration] end)end) as '720p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 720p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoMOS] end)end) as '720p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 720p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 720p] end)end) as '% 720p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 720p] is not null) then 1 else 0 end)end) as 'Count % 720p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoDuration] end)end) as '1080p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoMOS] end)end) as '1080p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 1080p] end)end) as '% 1080p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 1080p] is not null) then 1 else 0 end)end) as 'Count % 1080p_Video4'


	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_YOUTUBE v,
		Agrids.dbo.lcc_parcelas lp
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP,
		--case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.YTBVersion end, 
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[ASideDevice] end,
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[BSideDevice] end,
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[SWVersion] end	
		--case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[url] end

end
else
begin
	insert into @data_YTB_HD
	select  
		db_name() as 'Database',
		v.mnc,
		NULL as Parcel,
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then 1 else 0 end) as 'Reproducciones',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.Fails = 'Failed') then 1 else 0 end) as 'Fails',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[Time To First Image [s]]] end) as 'Time To First Image',
		MAX(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then 1.0*(v.[Time To First Image [s]]])end) as 'Time To First Image max',	
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[Num. Interruptions] end) as 'Num. Interruptions',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[End Status] ='W/O Interruptions') then 1 else 0 end) as 'ReproduccionesSinInt',
		--SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[Video Resolution]='720p') then 1 else 0 end) as 'ReproduccionesHD', --B4
		SUM(case when (v.typeoftest like '%YouTube%' /*and ytb.testname like '%HD%'*/ and FLOOR(replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end) as 'ReproduccionesHD', --B4
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and ISNULL(FLOOR(replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end) as 'Count_Video_Resolucion',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) as 'Count_Video_MOS',

		case when SUM(case when v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ then 1 else 0 end)>0 then
			(1 - (1.0*(SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.Fails = 'Failed') then 1 else 0 end)) / 
			(SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then 1 else 0 end)))) 
		else null end as 'Service success ratio W/o interruptions',	--B1
	
		case when SUM(case when v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ then 1 else 0 end)>0 then
			1.0*(SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[End Status]='W/O Interruptions') then 1 else 0 end)) 
			/ (SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then 1 else 0 end)) 
		else null end as 'Reproduction ratio W/o interruptions',	-- B2
	
		SUM(case when v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[Succeesful_Video_Download]='Successful' then 1 else 0 end) as 'Successful video download',  --B3


		/*** Metodo antiguo con Youtube v10 en el que solo se obtenía hasta 720p ***/
		--CASE @Methodology WHEN 'D16' THEN cast( avg(cast (left(v.[Video Resolution],3) as int)) as varchar(10)) + 'p' ELSE NULL END as 'avg video resolution', --B5
		/*** Cambio para limitar que las medidas de Youtube v10 no obtengan más de 720p ***/
		--CASE @Methodology WHEN 'D16' THEN cast( avg(case when (cast (left(v.[Video Resolution],3) as int)<= 720 or v.[Video Resolution] is null) then cast (left(v.[Video Resolution],3) as int)
		--												   else 720 end
		--													) as varchar(10)) + 'p' ELSE NULL END as 'avg video resolution', --B5
		/*** Se incluye Youtube v11 que puede superar los 720p, y se mantiene la limitacion para Youtube v10 que no pueda superar los 720p ***/
		CASE @Methodology WHEN 'D16' then 
		
		--Cambio para hacer el redondeo correcto:
		--cast(avg(case when r.Player like '%v11%' then (cast (floor(replace([Video Resolution],'p','')) as int))
		--		else
		--			case when cast (left(v.[Video Resolution],3) as int)<= 720 or v.[Video Resolution] is null then cast (left(v.[Video Resolution],3) as int)
		--			else 720 end end) as varchar(10)) + 'p' ELSE NULL END as 'avg video resolution', --B5

		cast(round(avg((case when cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11 then floor(replace(v.[Video Resolution],'p',''))
			else		
				case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then floor(replace(v.[Video Resolution],'p',''))
				else 720 end end)), 16) as varchar(20)) + 'p' ELSE NULL END as 'avg video resolution', --B5 


		--SUM(case when (v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' /*and v.testname like '%HD%'*/ and v.[Video Resolution]='720p') then 1 else 0 end) as 'B4', --B4
		SUM(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' 
				and FLOOR(replace(v.[Video Resolution],'p',''))>= 720 then 1 
				else 0 end
			) as 'B4', --B4
		CASE @Methodology WHEN 'D16' THEN avg(v.Video_MOS) ELSE NULL END as 'video mos', --B6
		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'GRID',
		--YTBVersion as 'Youtube_Version',
		MAX(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.YTBVersion end) as 'Youtube_Version',
		null,

		-- 20170321 - @ERC: Nuevos KPis y parametros:
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[ASideDevice] end as 'ASideDevice',
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[BSideDevice] end as 'BSideDevice',
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[SWVersion] end as 'SWVersion',

		-- 20170707 - @MDM:
		--La url se rellena a nulo en la nueva metodologúa FY1718, ya que podría introducir duplicados 
		--si se hiciesen varias pruebas en la misma parcela	
		--case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[url] end as 'url',
		NULL as 'url',

		-- 20170417 - @ERC: Nuevos KPis y parametros:
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[1st Resolution] end) as '1st Resolution',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and  v.[1st Resolution] is not null) then 1 else 0 end) as 'Count 1st Resolution',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[2nd Resolution] end) as '2nd Resolution',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and  v.[2nd Resolution] is not null) then 1 else 0 end) as 'Count 2nd Resolution',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[FirstChangeFromInit] end) as 'FirstChangeFromInit',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[FirstChangeFromInit] is not null) then 1 else 0 end) as 'Count FirstChangeFromInit',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[initialResolution] end) as 'initialResolution',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[initialResolution] is not null) then 1 else 0 end) as 'Count initialResolution',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[finalResolution] end) as 'finalResolution',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[finalResolution] is not null) then 1 else 0 end) as 'Count finalResolution',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[Duration] end) as 'Duration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[Duration] is not null) then 1 else 0 end) as 'Count Duration',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[144p-VideoDuration] end) as '144p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[144p-VideoDuration] is not null) then 1 else 0 end) as 'Count 144p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[144p-VideoMOS] end) as '144p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[144p-VideoMOS] is not null) then 1 else 0 end) as 'Count 144p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 144p] end) as '% 144p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 144p] is not null) then 1 else 0 end) as 'Count % 144p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[240p-VideoDuration] end) as '240p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[240p-VideoDuration] is not null) then 1 else 0 end) as 'Count 240p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[240p-VideoMOS] end) as '240p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[240p-VideoMOS] is not null) then 1 else 0 end) as 'Count 240p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 240p] end) as '% 240p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 240p] is not null) then 1 else 0 end) as 'Count % 240p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[360p-VideoDuration] end) as '360p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[360p-VideoDuration] is not null) then 1 else 0 end) as 'Count 360p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[360p-VideoMOS] end) as '360p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[360p-VideoMOS] is not null) then 1 else 0 end) as 'Count 360p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 360p] end) as '% 360p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 360p] is not null) then 1 else 0 end) as 'Count % 360p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[480p-VideoDuration] end) as '480p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[480p-VideoDuration] is not null) then 1 else 0 end) as 'Count 480p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[480p-VideoMOS] end) as '480p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[480p-VideoMOS] is not null) then 1 else 0 end) as 'Count 480p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 480p] end) as '% 480p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 480p] is not null) then 1 else 0 end) as 'Count % 480p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[720p-VideoDuration] end) as '720p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[720p-VideoDuration] is not null) then 1 else 0 end) as 'Count 720p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[720p-VideoMOS] end) as '720p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[720p-VideoMOS] is not null) then 1 else 0 end) as 'Count 720p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 720p] end) as '% 720p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 720p] is not null) then 1 else 0 end) as 'Count % 720p',

		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[1080p-VideoDuration] end) as '1080p-VideoDuration',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[1080p-VideoDuration] is not null) then 1 else 0 end) as 'Count 1080p-VideoDuration',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[1080p-VideoMOS] end) as '1080p-VideoMOS',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[1080p-VideoMOS] is not null) then 1 else 0 end) as 'Count 1080p-VideoMOS',
		AVG(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[% 1080p] end) as '% 1080p',
		SUM(case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/ and v.[% 1080p] is not null) then 1 else 0 end) as 'Count % 1080p',


		--20170626 - @MDM: Se agregan nuevos KPIs para metodología FY1718:

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- YOUTUBE HD - Video 1
------------------------------------------------------------------------------------------------------------------------------------------------------------

		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end ) end) as 'Reproducciones_Video1',
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end) end) as 'Fails_Video1',
		AVG(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%') then v.[Time To First Image [s]]] end)end) as 'Time To First Image_Video1',
		MAX(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%') then 1.0*(v.[Time To First Image [s]]])end)end) as 'Time To First Image max_Video1',	
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%') then v.[Num. Interruptions] end)end ) as 'Num. Interruptions_Video1',
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end)end) as 'ReproduccionesSinInt_Video1', 
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and FLOOR (replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end)end) as 'ReproduccionesHD_Video1',
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and ISNULL(FLOOR (replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end)end) as 'Count_Video_Resolucion_Video1',
		SUM(case when(v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) end )as 'Count_Video_MOS_Video1',

		case when(SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1 - (1.0*(SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end)end)) 
			/ (SUM(case when( v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))))
		else null end as 'Service success ratio W/o interruptions_Video1',	--B1
	
		case when (SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1.0*(SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)end)) 
			/ (SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))) 
		else null end as 'Reproduction ratio W/o interruptions_Video1',	-- B2
	
		SUM(case when (v.url=@YTB_url1 or v.url=@YTB_url12) then (case when(v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful') then 1 else 0 end)end) as 'Successful video download_Video1',  --B3		

		
		case @Methodology when 'D16' then cast(round(avg(case when (v.url=@YTB_url1 or v.url=@YTB_url12) 
	    then (case when (cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11) 
					then floor(replace(v.[Video Resolution],'p',''))
			  else (case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then 
						floor(replace(v.[Video Resolution],'p',''))
					else 720 end)
			  end)
		end),16) as varchar(20))+ 'p' ELSE NULL END as 'avg video resolution_Video1', --B5 
				

		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then 
			(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720 then 
			  1 else 0 end)end) as 'B4_Video1', --B4

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then v.Video_MOS ELSE NULL END) as 'video mos_Video1', --B6
		MAX(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then( case when v.typeoftest like '%YouTube%' then v.[url] end) end) as 'url_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[1st Resolution] end)end) as '1st Resolution_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[1st Resolution] is not null) then 1 else 0 end)end) as 'Count 1st Resolution_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[2nd Resolution] end)end) as '2nd Resolution_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[2nd Resolution] is not null) then 1 else 0 end)end) as 'Count 2nd Resolution_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[FirstChangeFromInit] end)end) as 'FirstChangeFromInit_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[FirstChangeFromInit] is not null) then 1 else 0 end)end) as 'Count FirstChangeFromInit_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[initialResolution] end)end) as 'initialResolution_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[initialResolution] is not null) then 1 else 0 end)end) as 'Count initialResolution_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[finalResolution] end)end) as 'finalResolution_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[finalResolution] is not null) then 1 else 0 end)end) as 'Count finalResolution_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[Duration] end)end) as 'Duration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[Duration] is not null) then 1 else 0 end)end) as 'Count Duration_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoDuration] end)end) as '144p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 144p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoMOS] end)end) as '144p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 144p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 144p] end)end) as '% 144p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 144p] is not null) then 1 else 0 end)end) as 'Count % 144p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoDuration] end)end) as '240p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 240p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoMOS] end)end) as '240p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 240p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 240p] end)end) as '% 240p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 240p] is not null) then 1 else 0 end)end) as 'Count % 240p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoDuration] end)end) as '360p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 360p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoMOS] end)end) as '360p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 360p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 360p] end)end) as '% 360p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 360p] is not null) then 1 else 0 end)end) as 'Count % 360p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoDuration] end)end) as '480p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 480p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoMOS] end)end) as '480p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 480p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 480p] end)end) as '% 480p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 480p] is not null) then 1 else 0 end)end) as 'Count % 480p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoDuration] end)end) as '720p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 720p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoMOS] end)end) as '720p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 720p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 720p] end)end) as '% 720p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 720p] is not null) then 1 else 0 end)end) as 'Count % 720p_Video1',

		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoDuration] end)end) as '1080p-VideoDuration_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoDuration_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoMOS] end)end) as '1080p-VideoMOS_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoMOS_Video1',
		AVG(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%') then v.[% 1080p] end)end) as '% 1080p_Video1',
		SUM(case when (v.url = @YTB_url1 or v.url=@YTB_url12) then ( case when (v.typeoftest like '%YouTube%' and v.[% 1080p] is not null) then 1 else 0 end)end) as 'Count % 1080p_Video1',


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- YOUTUBE HD - Video 2
------------------------------------------------------------------------------------------------------------------------------------------------------------

		SUM(case when(v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end ) end) as 'Reproducciones_Video2',
		SUM(case when(v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end) end) as 'Fails_Video2',
		AVG(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%') then v.[Time To First Image [s]]] end)end) as 'Time To First Image_Video2',
		MAX(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%') then 1.0*(v.[Time To First Image [s]]])end)end) as 'Time To First Image max_Video2',	
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%') then v.[Num. Interruptions] end)end ) as 'Num. Interruptions_Video2',
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end)end) as 'ReproduccionesSinInt_Video2', 
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end)end) as 'ReproduccionesHD_Video2',
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and ISNULL(FLOOR(replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end)end) as 'Count_Video_Resolucion_Video2',
		SUM(case when(v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) end )as 'Count_Video_MOS_Video2',

		case when(SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1 - (1.0*(SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end)end)) 
			/ (SUM(case when( v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))))
		else null end as 'Service success ratio W/o interruptions_Video2',	--B1
	
		case when (SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1.0*(SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)end)) 
			/ (SUM(case when (v.url=@YTB_url2) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))) 
		else null end as 'Reproduction ratio W/o interruptions_Video2',	-- B2
	
		SUM(case when (v.url=@YTB_url2) then (case when(v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful') then 1 else 0 end)end) as 'Successful video download_Video2',  --B3		

		
		case @Methodology when 'D16' then cast(round(avg(case when (v.url=@YTB_url2) 
	    then (case when (cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11) 
					then floor(replace(v.[Video Resolution],'p',''))
			  else (case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then 
						floor(replace(v.[Video Resolution],'p',''))
					else 720 end)
			  end)
		end),16) as varchar(20))+ 'p' ELSE NULL END as 'avg video resolution_Video2', --B5 
				

		SUM(case when (v.url = @YTB_url2) then 
			(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720 then 
			  1 else 0 end)end) as 'B4_Video2', --B4

		AVG(case when v.url = @YTB_url2 then v.Video_MOS ELSE NULL END) as 'video mos_Video2', --B6
		MAX(case when (v.url = @YTB_url2) then( case when v.typeoftest like '%YouTube%' then v.[url] end) end) as 'url_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[1st Resolution] end)end) as '1st Resolution_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[1st Resolution] is not null) then 1 else 0 end)end) as 'Count 1st Resolution_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[2nd Resolution] end)end) as '2nd Resolution_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[2nd Resolution] is not null) then 1 else 0 end)end) as 'Count 2nd Resolution_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[FirstChangeFromInit] end)end) as 'FirstChangeFromInit_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[FirstChangeFromInit] is not null) then 1 else 0 end)end) as 'Count FirstChangeFromInit_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[initialResolution] end)end) as 'initialResolution_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[initialResolution] is not null) then 1 else 0 end)end) as 'Count initialResolution_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[finalResolution] end)end) as 'finalResolution_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[finalResolution] is not null) then 1 else 0 end)end) as 'Count finalResolution_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[Duration] end)end) as 'Duration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[Duration] is not null) then 1 else 0 end)end) as 'Count Duration_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoDuration] end)end) as '144p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 144p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoMOS] end)end) as '144p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 144p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 144p] end)end) as '% 144p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 144p] is not null) then 1 else 0 end)end) as 'Count % 144p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoDuration] end)end) as '240p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 240p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoMOS] end)end) as '240p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 240p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 240p] end)end) as '% 240p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 240p] is not null) then 1 else 0 end)end) as 'Count % 240p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoDuration] end)end) as '360p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 360p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoMOS] end)end) as '360p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 360p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 360p] end)end) as '% 360p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 360p] is not null) then 1 else 0 end)end) as 'Count % 360p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoDuration] end)end) as '480p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 480p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoMOS] end)end) as '480p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 480p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 480p] end)end) as '% 480p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 480p] is not null) then 1 else 0 end)end) as 'Count % 480p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoDuration] end)end) as '720p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 720p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoMOS] end)end) as '720p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 720p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 720p] end)end) as '% 720p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 720p] is not null) then 1 else 0 end)end) as 'Count % 720p_Video2',

		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoDuration] end)end) as '1080p-VideoDuration_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoDuration_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoMOS] end)end) as '1080p-VideoMOS_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoMOS_Video2',
		AVG(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%') then v.[% 1080p] end)end) as '% 1080p_Video2',
		SUM(case when v.url = @YTB_url2 then ( case when (v.typeoftest like '%YouTube%' and v.[% 1080p] is not null) then 1 else 0 end)end) as 'Count % 1080p_Video2',


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- YOUTUBE HD - Video 3
------------------------------------------------------------------------------------------------------------------------------------------------------------

		SUM(case when(v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end ) end) as 'Reproducciones_Video3',
		SUM(case when(v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end) end) as 'Fails_Video3',
		AVG(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%') then v.[Time To First Image [s]]] end)end) as 'Time To First Image_Video3',
		MAX(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%') then 1.0*(v.[Time To First Image [s]]])end)end) as 'Time To First Image max_Video3',	
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%') then v.[Num. Interruptions] end)end ) as 'Num. Interruptions_Video3',
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end)end) as 'ReproduccionesSinInt_Video3', 
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end)end) as 'ReproduccionesHD_Video3',
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and ISNULL(FLOOR(replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end)end) as 'Count_Video_Resolucion_Video3',
		SUM(case when(v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) end )as 'Count_Video_MOS_Video3',

		case when(SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1 - (1.0*(SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end)end)) 
			/ (SUM(case when( v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))))
		else null end as 'Service success ratio W/o interruptions_Video3',	--B1
	
		case when (SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1.0*(SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)end)) 
			/ (SUM(case when (v.url=@YTB_url3) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))) 
		else null end as 'Reproduction ratio W/o interruptions_Video3',	-- B2
	
		SUM(case when (v.url=@YTB_url3) then (case when(v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful') then 1 else 0 end)end) as 'Successful video download_Video3',  --B3		

		
		case @Methodology when 'D16' then cast(round(avg(case when (v.url=@YTB_url3) 
	    then (case when (cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11) 
					then floor(replace(v.[Video Resolution],'p',''))
			  else (case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then 
						floor(replace(v.[Video Resolution],'p',''))
					else 720 end)
			  end)
		end),16) as varchar(20))+ 'p' ELSE NULL END as 'avg video resolution_Video3', --B5 
				

		SUM(case when (v.url = @YTB_url3) then 
			(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720 then 
			  1 else 0 end)end) as 'B4_Video3', --B4

		AVG(case when v.url = @YTB_url3 then v.Video_MOS ELSE NULL END) as 'video mos_Video3', --B6
		MAX(case when (v.url = @YTB_url3) then( case when v.typeoftest like '%YouTube%' then v.[url] end) end) as 'url_Video3',


		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[1st Resolution] end)end) as '1st Resolution_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[1st Resolution] is not null) then 1 else 0 end)end) as 'Count 1st Resolution_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[2nd Resolution] end)end) as '2nd Resolution_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[2nd Resolution] is not null) then 1 else 0 end)end) as 'Count 2nd Resolution_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[FirstChangeFromInit] end)end) as 'FirstChangeFromInit_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[FirstChangeFromInit] is not null) then 1 else 0 end)end) as 'Count FirstChangeFromInit_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[initialResolution] end)end) as 'initialResolution_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[initialResolution] is not null) then 1 else 0 end)end) as 'Count initialResolution_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[finalResolution] end)end) as 'finalResolution_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[finalResolution] is not null) then 1 else 0 end)end) as 'Count finalResolution_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[Duration] end)end) as 'Duration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[Duration] is not null) then 1 else 0 end)end) as 'Count Duration_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoDuration] end)end) as '144p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 144p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoMOS] end)end) as '144p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 144p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 144p] end)end) as '% 144p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 144p] is not null) then 1 else 0 end)end) as 'Count % 144p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoDuration] end)end) as '240p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 240p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoMOS] end)end) as '240p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 240p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 240p] end)end) as '% 240p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 240p] is not null) then 1 else 0 end)end) as 'Count % 240p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoDuration] end)end) as '360p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 360p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoMOS] end)end) as '360p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 360p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 360p] end)end) as '% 360p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 360p] is not null) then 1 else 0 end)end) as 'Count % 360p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoDuration] end)end) as '480p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 480p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoMOS] end)end) as '480p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 480p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 480p] end)end) as '% 480p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 480p] is not null) then 1 else 0 end)end) as 'Count % 480p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoDuration] end)end) as '720p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 720p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoMOS] end)end) as '720p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 720p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 720p] end)end) as '% 720p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 720p] is not null) then 1 else 0 end)end) as 'Count % 720p_Video3',

		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoDuration] end)end) as '1080p-VideoDuration_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoDuration_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoMOS] end)end) as '1080p-VideoMOS_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoMOS_Video3',
		AVG(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%') then v.[% 1080p] end)end) as '% 1080p_Video3',
		SUM(case when v.url = @YTB_url3 then ( case when (v.typeoftest like '%YouTube%' and v.[% 1080p] is not null) then 1 else 0 end)end) as 'Count % 1080p_Video3',


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- YOUTUBE HD - Video 4
------------------------------------------------------------------------------------------------------------------------------------------------------------

		SUM(case when(v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end ) end) as 'Reproducciones_Video4',
		SUM(case when(v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end) end) as 'Fails_Video4',
		AVG(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%') then v.[Time To First Image [s]]] end)end) as 'Time To First Image_Video4',
		MAX(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%') then 1.0*(v.[Time To First Image [s]]])end)end) as 'Time To First Image max_Video4',	
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%') then v.[Num. Interruptions] end)end ) as 'Num. Interruptions_Video4',
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and v.[End Status] ='W/O Interruptions') then 1 else 0 end)end) as 'ReproduccionesSinInt_Video4', 
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720) then 1 else 0 end)end) as 'ReproduccionesHD_Video4',
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and ISNULL(FLOOR(replace(v.[Video Resolution],'p','')),0)>0) then 1 else 0 end)end) as 'Count_Video_Resolucion_Video4',
		SUM(case when(v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and ISNULL(v.[Video_MOS],0)>0) then 1 else 0 end) end )as 'Count_Video_MOS_Video4',

		case when(SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1 - (1.0*(SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%' and v.Fails = 'Failed') then 1 else 0 end)end)) 
			/ (SUM(case when( v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))))
		else null end as 'Service success ratio W/o interruptions_Video4',	--B1
	
		case when (SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end)>0) then
			(1.0*(SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%' and v.[End Status]='W/O Interruptions') then 1 else 0 end)end)) 
			/ (SUM(case when (v.url=@YTB_url4) then (case when (v.typeoftest like '%YouTube%') then 1 else 0 end)end))) 
		else null end as 'Reproduction ratio W/o interruptions_Video4',	-- B2
	
		SUM(case when (v.url=@YTB_url4) then (case when(v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful') then 1 else 0 end)end) as 'Successful video download_Video4',  --B3		

		
		case @Methodology when 'D16' then cast(round(avg(case when (v.url=@YTB_url4) 
	    then (case when (cast(SUBSTRING(v.YTBVersion,1, (CHARINDEX('.',v.YTBVersion)-1)) as int)=11) 
					then floor(replace(v.[Video Resolution],'p',''))
			  else (case when floor(replace(v.[Video Resolution],'p','')) <= 720 or v.[Video Resolution] is null then 
						floor(replace(v.[Video Resolution],'p',''))
					else 720 end)
			  end)
		end),16) as varchar(20))+ 'p' ELSE NULL END as 'avg video resolution_Video4', --B5 
				

		SUM(case when (v.url = @YTB_url4) then 
			(case when v.typeoftest like '%YouTube%' and v.[Succeesful_Video_Download]='Successful' and FLOOR(replace(v.[Video Resolution],'p',''))>= 720 then 
			  1 else 0 end)end) as 'B4_Video4', --B4

		AVG(case when v.url = @YTB_url4 then v.Video_MOS ELSE NULL END) as 'video mos_Video4', --B6
		MAX(case when (v.url = @YTB_url4) then( case when v.typeoftest like '%YouTube%' then v.[url] end) end) as 'url_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[1st Resolution] end)end) as '1st Resolution_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[1st Resolution] is not null) then 1 else 0 end)end) as 'Count 1st Resolution_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[2nd Resolution] end)end) as '2nd Resolution_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[2nd Resolution] is not null) then 1 else 0 end)end) as 'Count 2nd Resolution_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[FirstChangeFromInit] end)end) as 'FirstChangeFromInit_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[FirstChangeFromInit] is not null) then 1 else 0 end)end) as 'Count FirstChangeFromInit_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[initialResolution] end)end) as 'initialResolution_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[initialResolution] is not null) then 1 else 0 end)end) as 'Count initialResolution_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[finalResolution] end)end) as 'finalResolution_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[finalResolution] is not null) then 1 else 0 end)end) as 'Count finalResolution_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[Duration] end)end) as 'Duration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[Duration] is not null) then 1 else 0 end)end) as 'Count Duration_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoDuration] end)end) as '144p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 144p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[144p-VideoMOS] end)end) as '144p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[144p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 144p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 144p] end)end) as '% 144p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 144p] is not null) then 1 else 0 end)end) as 'Count % 144p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoDuration] end)end) as '240p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 240p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[240p-VideoMOS] end)end) as '240p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[240p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 240p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 240p] end)end) as '% 240p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 240p] is not null) then 1 else 0 end)end) as 'Count % 240p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoDuration] end)end) as '360p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 360p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[360p-VideoMOS] end)end) as '360p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[360p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 360p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 360p] end)end) as '% 360p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 360p] is not null) then 1 else 0 end)end) as 'Count % 360p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoDuration] end)end) as '480p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 480p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[480p-VideoMOS] end)end) as '480p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[480p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 480p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 480p] end)end) as '% 480p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 480p] is not null) then 1 else 0 end)end) as 'Count % 480p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoDuration] end)end) as '720p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 720p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[720p-VideoMOS] end)end) as '720p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[720p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 720p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 720p] end)end) as '% 720p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 720p] is not null) then 1 else 0 end)end) as 'Count % 720p_Video4',

		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoDuration] end)end) as '1080p-VideoDuration_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoDuration] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoDuration_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[1080p-VideoMOS] end)end) as '1080p-VideoMOS_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[1080p-VideoMOS] is not null) then 1 else 0 end)end) as 'Count 1080p-VideoMOS_Video4',
		AVG(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%') then v.[% 1080p] end)end) as '% 1080p_Video4',
		SUM(case when v.url = @YTB_url4 then ( case when (v.typeoftest like '%YouTube%' and v.[% 1080p] is not null) then 1 else 0 end)end) as 'Count % 1080p_Video4'

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_YOUTUBE v
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/
	group by v.MNC,
		--case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.YTBVersion end, 
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[ASideDevice] end,
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[BSideDevice] end,
		case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[SWVersion] end	
		--case when (v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/) then v.[url] end
end

select * from @data_YTB_HD