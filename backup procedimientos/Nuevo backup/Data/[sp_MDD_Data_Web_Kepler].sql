USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_Web_Kepler]    Script Date: 31/10/2017 15:41:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_Web_Kepler] (
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
Where v.collectionname like @Date + '%[_]' + @ciudad + '[_]%' + @Tech
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos	
	and v.info like @Info
	--and (v.callStartTimeStamp between @fecha_ini1 and @fecha_fin1 
	--		 or
	--		 v.callStartTimeStamp between @fecha_ini2 and @fecha_fin2 
	--		 or
	--		 v.callStartTimeStamp between @fecha_ini3 and @fecha_fin3 
	--		 or
	--		 v.callStartTimeStamp between @fecha_ini4 and @fecha_fin4 
	--		 or
	--		 v.callStartTimeStamp between @fecha_ini5 and @fecha_fin5 
	--		 or
	--		 v.callStartTimeStamp between @fecha_ini6 and @fecha_fin6
 --			 or
	--		 v.callStartTimeStamp between @fecha_ini7 and @fecha_fin7 
 --			 or
	--		 v.callStartTimeStamp between @fecha_ini8 and @fecha_fin8 
 --			 or
	--		 v.callStartTimeStamp between @fecha_ini9 and @fecha_fin9 
 --			 or
	--		 v.callStartTimeStamp between @fecha_ini10 and @fecha_fin10 			 
	--		 or
	--		 v.callEndTimeStamp between @fecha_ini1 and @fecha_fin1 
	--		 or
	--		 v.callEndTimeStamp between @fecha_ini2 and @fecha_fin2 
	--		 or
	--		 v.callEndTimeStamp between @fecha_ini3 and @fecha_fin3 
	--		 or
	--		 v.callEndTimeStamp between @fecha_ini4 and @fecha_fin4 
	--		 or
	--		 v.callEndTimeStamp between @fecha_ini5 and @fecha_fin5 
	--		 or
	--		 v.callEndTimeStamp between @fecha_ini6 and @fecha_fin6
 --			 or
	--		 v.callEndTimeStamp between @fecha_ini7 and @fecha_fin7 
 --			 or
	--		 v.callEndTimeStamp between @fecha_ini8 and @fecha_fin8 
 --			 or
	--		 v.callEndTimeStamp between @fecha_ini9 and @fecha_fin9 
 --			 or
	--		 v.callEndTimeStamp between @fecha_ini10 and @fecha_fin10 			 
	--     )  

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
	[Throughput] [float] NULL,
	[Tiempo de Navegación] [float] NULL,
	[Throughput Max] [float] NULL,
	[ 0-128Kbps] [int] NULL,
	[ 128Kbps-256Kbps] [int] NULL,
	[ 256Kbps-384Kbps] [int] NULL,
	[ 384Kbps-512Kbps] [int] NULL,
	[ 512Kbps-640Kbps] [int] NULL,
	[ 640Kbps-768Kbps] [int] NULL,
	[ 768Kbps-896Kbps] [int] NULL,
	[ 896Kbps-1Mbps] [int] NULL,
	[ 1Mbps-1128Kbps] [int] NULL,
	[ 1128Kbps-1256Kbps] [int] NULL,
	[ 1256Kbps-1384Kbps] [int] NULL,
	[ 1384Kbps-1512Kbps] [int] NULL,
	[ 1512Kbps-1640Kbps] [int] NULL,
	[ 1640Kbps-1768Kbps] [int] NULL,
	[ 1768Kbps-1896Kbps] [int] NULL,
	[ 1896Kbps-2Mbps] [int] NULL,
	[ > 2Mbps] [int] NULL,
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
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',	
	
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.Throughput end) as 'Throughput',
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.[Transfer Time (s)] end) as 'Tiempo de Navegación',
		MAX(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.Throughput end) as 'Throughput Max',
	
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 0 and 128) then 1 else 0 end) as [ 0-128Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 128 and 256) then 1 else 0 end)  as [ 128Kbps-256Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 256 and 384) then 1 else 0 end)  as [ 256Kbps-384Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 384 and 512) then 1 else 0 end)  as [ 384Kbps-512Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 512 and 640) then 1 else 0 end)  as [ 512Kbps-640Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 640 and 768) then 1 else 0 end)  as [ 640Kbps-768Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 768 and 896) then 1 else 0 end)  as [ 768Kbps-896Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 896 and 1000) then 1 else 0 end)  as [ 896Kbps-1Mbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1000 and 1128) then 1 else 0 end)  as [ 1Mbps-1128Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1128 and 1256) then 1 else 0 end)  as [ 1128Kbps-1256Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1256 and 1384) then 1 else 0 end)  as [ 1256Kbps-1384Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1384 and 1512) then 1 else 0 end)  as [ 1384Kbps-1512Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1512 and 1640) then 1 else 0 end)  as [ 1512Kbps-1640Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1640 and 1768) then 1 else 0 end)  as [ 1640Kbps-1768Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1768 and 1896) then 1 else 0 end)  as [ 1768Kbps-1896Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1896 and 2000) then 1 else 0 end)  as [ 1896Kbps-2Mbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput > 2000) then 1 else 0 end)  as [ > 2Mbps],

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF ,
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
		and v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end
else
begin
	insert into @data_webKepler
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',	
	
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.Throughput end) as 'Throughput',
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.[Transfer Time (s)] end) as 'Tiempo de Navegación',
		MAX(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.Throughput end) as 'Throughput Max',
	
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 0 and 128) then 1 else 0 end) as [ 0-128Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 128 and 256) then 1 else 0 end)  as [ 128Kbps-256Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 256 and 384) then 1 else 0 end)  as [ 256Kbps-384Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 384 and 512) then 1 else 0 end)  as [ 384Kbps-512Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 512 and 640) then 1 else 0 end)  as [ 512Kbps-640Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 640 and 768) then 1 else 0 end)  as [ 640Kbps-768Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 768 and 896) then 1 else 0 end)  as [ 768Kbps-896Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 896 and 1000) then 1 else 0 end)  as [ 896Kbps-1Mbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1000 and 1128) then 1 else 0 end)  as [ 1Mbps-1128Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1128 and 1256) then 1 else 0 end)  as [ 1128Kbps-1256Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1256 and 1384) then 1 else 0 end)  as [ 1256Kbps-1384Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1384 and 1512) then 1 else 0 end)  as [ 1384Kbps-1512Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1512 and 1640) then 1 else 0 end)  as [ 1512Kbps-1640Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1640 and 1768) then 1 else 0 end)  as [ 1640Kbps-1768Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1768 and 1896) then 1 else 0 end)  as [ 1768Kbps-1896Kbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput between 1896 and 2000) then 1 else 0 end)  as [ 1896Kbps-2Mbps],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.Throughput > 2000) then 1 else 0 end)  as [ > 2Mbps],
		
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
		and v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%'
	group by v.MNC, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end

select * from @data_webKepler