USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_Web_FY1617_GRID]    Script Date: 29/05/2017 13:02:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_Web_FY1617_GRID] (
		 --Variables de entrada
		@ciudad as varchar(256),
		@simOperator as int,
		@sheet as varchar(256),				-- all: %%, 4G: 'LTE', 3G: 'WCDMA', CA
		@Date as varchar (256),
		@Tech as varchar (256),				-- Para seleccionar entre 3G, 4G y CA
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
--declare @Methodology as varchar(256) = 'D16' 

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
	from Lcc_Data_HTTPBrowser v, testinfo t, lcc_position_Entity_List_Vodafone c
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
	from Lcc_Data_HTTPBrowser v, testinfo t, lcc_position_Entity_List_Orange c
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
	from Lcc_Data_HTTPBrowser v, testinfo t, lcc_position_Entity_List_Municipio c
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
declare @dateMax datetime2(3)= (select max(c.endTime) from Lcc_Data_HTTPBrowser c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)
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
--	from Lcc_Data_HTTPBrowser where TestId=(select max(c.TestId) from Lcc_Data_HTTPBrowser c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

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
declare @data_webKepler  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Navegaciones] [int] NULL,
	[Fallos de acceso] [int] NULL,
	[Navegaciones fallidas] [int] NULL,
	[Session Time] [float] NULL,
	[IP Service Setup Time] [float] NULL,
	[Transfer Time] [float] NULL,
	[Count_SessionTime] [int] NULL,
	[Count_IPServiceSetupTime] [int] NULL,
	[Count_TransferTime] [int] NULL,
	[Navegaciones HTTPS] [int] NULL,
	[Fallos de acceso HTTPS] [int] NULL,
	[Navegaciones fallidas HTTPS] [int] NULL,
	[Session Time HTTPS] [float] NULL,
	[IP Service Setup Time HTTPS] [float] NULL,
	[Transfer Time HTTPS] [float] NULL,
	[Count_SessionTime HTTPS] [int] NULL,
	[Count_IPServiceSetupTime HTTPS] [int] NULL,
	[Count_TransferTime HTTPS] [int] NULL,
	[Navegaciones Public] [int] NULL,
	[Fallos de acceso Public] [int] NULL,
	[Navegaciones fallidas Public] [int] NULL,
	[Session Time Public] [float] NULL,
	[IP Service Setup Time Public] [float] NULL,
	[Transfer Time Public] [float] NULL,
	[Count_SessionTime Public] [int] NULL,
	[Count_IPServiceSetupTime Public] [int] NULL,
	[Count_TransferTime Public] [int] NULL,
	[NavegacionesKepler0] [int] NULL,
	[Navegaciones_16s] [int] NULL,
	[NavegacionesKepler0_10s] [int] NULL,
	[Throughput] [float] NULL,
	[Throughput Max] [float] NULL,
	[NavegacionesKepler0 Public] [int] NULL,
	[Navegaciones_16s Public] [int] NULL,
	[NavegacionesKepler0_10s Public] [int] NULL,
	[Throughput Public] [float] NULL,
	[Throughput Max Public] [float] NULL,
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
	[SWVersion] [varchar](256) NULL
)

if @Indoor=0
begin
	insert into @data_webKepler
	select  
	db_name() as 'Database',
	v.mnc,
	master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,

	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%') then 1 else 0 end) as 'Navegaciones',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime',

	-- BROWSING HTTPS
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%') then 1 else 0 end) as 'Navegaciones HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas HTTPS',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time HTTPS',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time HTTPS',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime HTTPS',

	-- BROWSING HTTP PUBLIC
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%') then 1 else 0 end) as 'Navegaciones Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas Public',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time Public',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time Public',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime Public',

	NULL as 'NavegacionesKepler0',
	NULL as 'Navegaciones_16s',
	NULL as 'NavegacionesKepler0_10s',
	NULL as 'Throughput',
	NULL as 'Throughput Max',
	
	NULL as 'NavegacionesKepler0 Public',
	NULL as 'Navegaciones_16s Public',
	NULL as 'NavegacionesKepler0_10s Public',
	NULL as 'Throughput Public',
	NULL as 'Throughput Max Public',		

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
	v.[ASideDevice],
	v.[BSideDevice],
	v.[SWVersion]

from 
	TestInfo t,
	@All_Tests a,
	Lcc_Data_HTTPBrowser v,
	Agrids.dbo.lcc_parcelas lp
where	
	a.Sessionid=t.Sessionid and a.TestId=t.TestId
	and t.valid=1
	and a.Sessionid=v.Sessionid and a.TestId=v.TestId
	and v.typeoftest='HTTPBrowser'
	and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])
group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]

end
else
begin
	insert into @data_webKepler
	select  
	db_name() as 'Database',
	v.mnc,
	NULL as Parcel,

	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%') then 1 else 0 end) as 'Navegaciones',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.TestType like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime',

	-- BROWSING HTTPS
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%') then 1 else 0 end) as 'Navegaciones HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas HTTPS',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time HTTPS',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time HTTPS',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime HTTPS',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.TestType like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime HTTPS',

	-- BROWSING HTTP PUBLIC
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%') then 1 else 0 end) as 'Navegaciones Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas Public',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time Public',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time Public',
	AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime Public',
	SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol like 'HTTP%' and v.TestType not like '%Kepler%' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime Public',

	NULL as 'NavegacionesKepler0',
	NULL as 'Navegaciones_16s',
	NULL as 'NavegacionesKepler0_10s',
	NULL as 'Throughput',
	NULL as 'Throughput Max',

	NULL as 'NavegacionesKepler0 Public',
	NULL as 'Navegaciones_16s Public',
	NULL as 'NavegacionesKepler0_10s Public',
	NULL as 'Throughput Public',
	NULL as 'Throughput Max Public',

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
	v.[ASideDevice],
	v.[BSideDevice],
	v.[SWVersion]

from 
	TestInfo t,
	@All_Tests a,
	Lcc_Data_HTTPBrowser v

where	
	a.Sessionid=t.Sessionid and a.TestId=t.TestId
	and t.valid=1
	and a.Sessionid=v.Sessionid and a.TestId=v.TestId
	and v.typeoftest='HTTPBrowser'
group by v.MNC, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end

select * from @data_webKepler