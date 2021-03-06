USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_Web_Time_Kepler]    Script Date: 29/05/2017 13:06:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_Web_Time_Kepler] (
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
declare @data_webKeplerTime  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Navegaciones] [int] NULL,
	[Fallos de acceso] [int] NULL,
	[Navegaciones fallidas] [int] NULL,
	[Throughput] [float] NULL,
	[Session Time] [float] NULL,
	[Transfer Time] [float] NULL,
	[IP Service Setup Time] [float] NULL,
	[Throughput Max] [float] NULL,
	[0-1s] [int] NULL,
	[ 1-1.5s] [int] NULL,
	[ 1.5-3s] [int] NULL,
	[ 2-3.5s] [int] NULL,
	[ 2.5-3s] [int] NULL,
	[ 3-3.5s] [int] NULL,
	[ 3.5-4s] [int] NULL,
	[ 4-4.5s] [int] NULL,
	[ 4.5-5s] [int] NULL,
	[ 5-5.5s] [int] NULL,
	[ 5.5-6s] [int] NULL,
	[ 6-6.5s] [int] NULL,
	[ 6.5-7s] [int] NULL,
	[ 7-7.5s] [int] NULL,
	[ 7.5-8s] [int] NULL,
	[ 8-8.5s] [int] NULL,
	[ 8.5-9s] [int] NULL,
	[ 9-9.5s] [int] NULL,
	[ 9.5-10s] [int] NULL,
	[ 10-16s] [int] NULL,
	[ 16-20s] [int] NULL,
	[ 20-25s] [int] NULL,
	[ 25-30s] [int] NULL,
	[ > 30s] [int] NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF] [varchar] (256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP] [varchar] (256) NULL,

	-- 20170321 - @ERC: Nuevos KPis y parametros:
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL
)

if @Indoor=0
begin
	insert into @data_webKeplerTime
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',	
	
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.Throughput end) as 'Throughput',
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.[Session Time (s)] end) as 'Session Time',
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.[Transfer Time (s)] end) as 'Transfer Time',
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time',
		MAX(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.Throughput end) as 'Throughput Max',	
	
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 0 and 1) then 1 else 0 end) as [0-1s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 1 and 1.5) then 1 else 0 end)  as [ 1-1.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 1.5 and 2) then 1 else 0 end)  as [ 1.5-3s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 2 and 2.5) then 1 else 0 end)  as [ 2-3.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 2.5 and 3) then 1 else 0 end)  as [ 2.5-3s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 3 and 3.5) then 1 else 0 end)  as [ 3-3.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 3.5 and 4) then 1 else 0 end)  as [ 3.5-4s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 4 and 4.5) then 1 else 0 end)  as [ 4-4.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 4.5 and 5) then 1 else 0 end)  as [ 4.5-5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 5 and 5.5) then 1 else 0 end)  as [ 5-5.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 5.5 and 6) then 1 else 0 end)  as [ 5.5-6s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 6 and 6.5) then 1 else 0 end)  as [ 6-6.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 6.5 and 7) then 1 else 0 end)  as [ 6.5-7s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 7 and 7.5) then 1 else 0 end)  as [ 7-7.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 7.5 and 8) then 1 else 0 end)  as [ 7.5-8s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 8 and 8.5) then 1 else 0 end)  as [ 8-8.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 8.5 and 9) then 1 else 0 end)  as [ 8.5-9s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 9 and 9.5) then 1 else 0 end)  as [ 9-9.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 9.5 and 10) then 1 else 0 end)  as [ 9.5-10s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 10 and 16) then 1 else 0 end)  as [ 10-16s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 16 and 20) then 1 else 0 end)  as [ 16-20s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 20 and 25) then 1 else 0 end)  as [ 20-25s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 25 and 30) then 1 else 0 end)  as [ 25-30s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] > 30) then 1 else 0 end)  as [ > 30s],

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null as 'Num_Medida',
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
	insert into @data_webKeplerTime
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de acceso',
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.ErrorType='Retainability') then 1 else 0 end) as 'Navegaciones fallidas',	
	
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.Throughput end) as 'Throughput',
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.[Session Time (s)] end) as 'Session Time',
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.[Transfer Time (s)] end) as 'Transfer Time',
		AVG(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.[IP Service Setup Time (s)] end) as 'IP Service Setup Time',
		MAX(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%') then v.Throughput end) as 'Throughput Max',	
	
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 0 and 1) then 1 else 0 end) as [0-1s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 1 and 1.5) then 1 else 0 end)  as [ 1-1.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 1.5 and 2) then 1 else 0 end)  as [ 1.5-3s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 2 and 2.5) then 1 else 0 end)  as [ 2-3.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 2.5 and 3) then 1 else 0 end)  as [ 2.5-3s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 3 and 3.5) then 1 else 0 end)  as [ 3-3.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 3.5 and 4) then 1 else 0 end)  as [ 3.5-4s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 4 and 4.5) then 1 else 0 end)  as [ 4-4.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 4.5 and 5) then 1 else 0 end)  as [ 4.5-5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 5 and 5.5) then 1 else 0 end)  as [ 5-5.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 5.5 and 6) then 1 else 0 end)  as [ 5.5-6s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 6 and 6.5) then 1 else 0 end)  as [ 6-6.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 6.5 and 7) then 1 else 0 end)  as [ 6.5-7s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 7 and 7.5) then 1 else 0 end)  as [ 7-7.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 7.5 and 8) then 1 else 0 end)  as [ 7.5-8s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 8 and 8.5) then 1 else 0 end)  as [ 8-8.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 8.5 and 9) then 1 else 0 end)  as [ 8.5-9s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 9 and 9.5) then 1 else 0 end)  as [ 9-9.5s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 9.5 and 10) then 1 else 0 end)  as [ 9.5-10s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 10 and 16) then 1 else 0 end)  as [ 10-16s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 16 and 20) then 1 else 0 end)  as [ 16-20s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 20 and 25) then 1 else 0 end)  as [ 20-25s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] between 25 and 30) then 1 else 0 end)  as [ 25-30s],
		SUM(case when (v.typeoftest='HTTPBrowser' and v.TestType not like '%Mobile%' and v.[Session Time (s)] > 30) then 1 else 0 end)  as [ > 30s],

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
select * from @data_webKeplerTime