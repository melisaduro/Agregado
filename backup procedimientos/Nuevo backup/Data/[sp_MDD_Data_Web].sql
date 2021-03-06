USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_Web]    Script Date: 31/10/2017 15:40:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_Web] (
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

insert into @All_Tests_Tech  
select v.sessionid, v.testid,
	case when v.[% LTE]=1 then 'LTE'
		 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' 
	end as tech,	
	'SC' hasCA
from Lcc_Data_HTTPBrowser v
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
declare @dateMax datetime2(3)= (select max(c.endTime) from Lcc_Data_HTTPBrowser c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

--declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, endTime)),2) + '_'	 + convert(varchar(256),format(endTime,'MM'))
--	from Lcc_Data_HTTPBrowser where TestId=(select max(c.TestId) from Lcc_Data_HTTPBrowser c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from Lcc_Data_HTTPBrowser v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max([master].dbo.fn_lcc_getElement(5, v.collectionname,'_')) from Lcc_Data_HTTPBrowser v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId)-- group by [master].dbo.fn_lcc_getElement(5, v.collectionname,'_'))

declare @week as varchar(256)
declare @tmpDateFirst int 
declare @tmpWeek int 

--select @tmpDateFirst = @@DATEFIRST
--if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
--	SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPBrowser 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPBrowser c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
--else
--	begin
--		SET DATEFIRST 1;  --Primer dia de la semana lunes
--		SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPBrowser 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPBrowser c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
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
	[NavegacionesKepler0] [int] NULL,
	[Navegaciones_16s] [int] NULL,
	[NavegacionesKepler0_10s] [int] NULL,
	[Throughput] [float] NULL,
	[Throughput Max] [float] NULL,
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

		SUM(case when (v.typeoftest='HTTPBrowser') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',
		AVG(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time',
		AVG(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time',
		AVG(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime',

		-- BROWSING HTTPS
		NULL as 'Navegaciones HTTPS',
		NULL as 'Fallos de acceso HTTPS',
		NULL as 'Navegaciones fallidas HTTPS',
		NULL as 'Session Time HTTPS',
		NULL as 'IP Service Setup Time HTTPS',
		NULL as 'Transfer Time HTTPS',
		NULL as 'Count_SessionTime HTTPS',
		NULL as 'Count_IPServiceSetupTime HTTPS',
		NULL as 'Count_TransferTime HTTPS',

		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType='Kepler 0s Pause') then 1 else 0 end) as 'NavegacionesKepler0',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Session Time (s)],0)>16) then 1 else 0 end) as 'Navegaciones_16s',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Session Time (s)],0)>10 and v.TestType='Kepler 0s Pause') then 1 else 0 end) as 'NavegacionesKepler0_10s',
		AVG(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		MAX(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',		

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'Collection Name',
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
	--else
	--begin
	--	insert into @data_webKepler
	--	select  
	--		db_name() as 'Database',
	--		v.mnc,
	--		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,

	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP') then 1 else 0 end) as 'Navegaciones',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime',

	--		-- BROWSING HTTPS
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS') then 1 else 0 end) as 'Navegaciones HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas HTTPS',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time HTTPS',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time HTTPS',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime HTTPS',

	--		NULL as 'NavegacionesKepler0',
	--		NULL as 'Navegaciones_16s',
	--		NULL as 'NavegacionesKepler0_10s',
	--		NULL as 'Throughput',
	--		NULL as 'Throughput Max',		

	--		@week as Meas_Week,
	--		@Meas_Round as Meas_Round,
	--		@Meas_Date as Meas_Date,
	--		@entidad as Entidad,
	--		lp.region as Region,
	--		null 
	--	from 
	--		TestInfo t,
	--		@All_Tests a,
	--		Lcc_Data_HTTPBrowser v,
	--		Agrids.dbo.lcc_parcelas lp
	--	where	
	--		a.Sessionid=t.Sessionid and a.TestId=t.TestId
	--		and t.valid=1
	--		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
	--		and v.typeoftest='HTTPBrowser'
	--		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])
	--	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.region
	--end
else
begin
	insert into @data_webKepler
	select  
		db_name() as 'Database',
		v.mnc,
		NULL as Parcel,

		SUM(case when (v.typeoftest='HTTPBrowser') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',
		AVG(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time',
		AVG(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time',
		AVG(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime',

		-- BROWSING HTTPS
		NULL as 'Navegaciones HTTPS',
		NULL as 'Fallos de acceso HTTPS',
		NULL as 'Navegaciones fallidas HTTPS',
		NULL as 'Session Time HTTPS',
		NULL as 'IP Service Setup Time HTTPS',
		NULL as 'Transfer Time HTTPS',
		NULL as 'Count_SessionTime HTTPS',
		NULL as 'Count_IPServiceSetupTime HTTPS',
		NULL as 'Count_TransferTime HTTPS',

		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType='Kepler 0s Pause') then 1 else 0 end) as 'NavegacionesKepler0',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Session Time (s)],0)>16) then 1 else 0 end) as 'Navegaciones_16s',
		SUM(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.[Session Time (s)],0)>10 and v.TestType='Kepler 0s Pause') then 1 else 0 end) as 'NavegacionesKepler0_10s',
		AVG(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		MAX(case when (v.typeoftest='HTTPBrowser' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'Collection Name',
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

	--else
	--begin
	--		insert into @data_webKepler
	--		select  
	--		db_name() as 'Database',
	--		v.mnc,
	--		NULL as Parcel,

	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP') then 1 else 0 end) as 'Navegaciones',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTP' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime',

	--		-- BROWSING HTTPS
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS') then 1 else 0 end) as 'Navegaciones HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas HTTPS',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[Session Time (s)],0)>0) then v.[Session Time (s)] end) as 'Session Time HTTPS',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time HTTPS',
	--		AVG(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[Transfer Time (s)] ,0)>0) then v.[Transfer Time (s)] end) as 'Transfer Time HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[Session Time (s)],0)>0) then 1 else 0 end) as 'Count_SessionTime HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[IP Service Setup Time (s)],0)>0) then 1 else 0 end) as 'Count_IPServiceSetupTime HTTPS',
	--		SUM(case when (v.typeoftest='HTTPBrowser' and v.protocol='HTTPS' and ISNULL(v.[Transfer Time (s)] ,0)>0) then 1 else 0 end) as 'Count_TransferTime HTTPS',

	--		NULL as 'NavegacionesKepler0',
	--		NULL as 'Navegaciones_16s',
	--		NULL as 'NavegacionesKepler0_10s',
	--		NULL as 'Throughput',
	--		NULL as 'Throughput Max',	

	--		@week as Meas_Week,
	--		@Meas_Round as Meas_Round,
	--		@Meas_Date as Meas_Date,
	--		@entidad as Entidad,
	--		null,
	--		@medida as 'Num_Medida'
	--	from 
	--		TestInfo t,
	--		@All_Tests a,
	--		Lcc_Data_HTTPBrowser v
	--	where	
	--		a.Sessionid=t.Sessionid and a.TestId=t.TestId
	--		and t.valid=1
	--		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
	--		and v.typeoftest='HTTPBrowser'
	--	group by v.MNC
	--end
end

select * from @data_webKepler