USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_UL_Thput_NC_LTE]    Script Date: 29/05/2017 12:56:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_UL_Thput_NC_LTE] (
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
--use FY1617_Data_Rest_3G_H1_4

--declare @ciudad as varchar(256) = 'AMPOSTA'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @Info as varchar (256) = 'Completed' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @sheet as varchar(256) = '%%' --%%/LTE/WCDMA
--declare @Tech as varchar (256) = '4G'
--declare @methodology as varchar (256) = 'D16'
--declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)


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
from Lcc_Data_HTTPTransfer_UL v
Where v.collectionname like @Date + '%[_]' + @ciudad + '[_]%' + @Tech
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos
	and v.info like @Info	
	--and (v.callStartTimeStamp >= @fecha_ini1 and @fecha_fin1 
	--		 or
	--		 v.callStartTimeStamp >= @fecha_ini2 and @fecha_fin2 
	--		 or
	--		 v.callStartTimeStamp >= @fecha_ini3 and @fecha_fin3 
	--		 or
	--		 v.callStartTimeStamp >= @fecha_ini4 and @fecha_fin4 
	--		 or
	--		 v.callStartTimeStamp >= @fecha_ini5 and @fecha_fin5 
	--		 or
	--		 v.callStartTimeStamp >= @fecha_ini6 and @fecha_fin6
 --			 or
	--		 v.callStartTimeStamp >= @fecha_ini7 and @fecha_fin7 
 --			 or
	--		 v.callStartTimeStamp >= @fecha_ini8 and @fecha_fin8 
 --			 or
	--		 v.callStartTimeStamp >= @fecha_ini9 and @fecha_fin9 
 --			 or
	--		 v.callStartTimeStamp >= @fecha_ini10 and @fecha_fin10 			 
	--		 or
	--		 v.callEndTimeStamp >= @fecha_ini1 and @fecha_fin1 
	--		 or
	--		 v.callEndTimeStamp >= @fecha_ini2 and @fecha_fin2 
	--		 or
	--		 v.callEndTimeStamp >= @fecha_ini3 and @fecha_fin3 
	--		 or
	--		 v.callEndTimeStamp >= @fecha_ini4 and @fecha_fin4 
	--		 or
	--		 v.callEndTimeStamp >= @fecha_ini5 and @fecha_fin5 
	--		 or
	--		 v.callEndTimeStamp >= @fecha_ini6 and @fecha_fin6
 --			 or
	--		 v.callEndTimeStamp >= @fecha_ini7 and @fecha_fin7 
 --			 or
	--		 v.callEndTimeStamp >= @fecha_ini8 and @fecha_fin8 
 --			 or
	--		 v.callEndTimeStamp >= @fecha_ini9 and @fecha_fin9 
 --			 or
	--		 v.callEndTimeStamp >= @fecha_ini10 and @fecha_fin10 			 
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
declare @dateMax datetime2(3)= (select max(c.endTime) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

--declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, endTime)),2) + '_'	 + convert(varchar(256),format(endTime,'MM'))
--	from Lcc_Data_HTTPTransfer_UL where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from Lcc_Data_HTTPTransfer_UL v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max([master].dbo.fn_lcc_getElement(5, v.collectionname,'_')) from Lcc_Data_HTTPTransfer_UL v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId)-- group by [master].dbo.fn_lcc_getElement(5, v.collectionname,'_'))

declare @week as varchar(256)
declare @tmpDateFirst int 
declare @tmpWeek int 

--select @tmpDateFirst = @@DATEFIRST
--if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
--	SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPTransfer_UL 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
--else
--	begin
--		SET DATEFIRST 1;  --Primer dia de la semana lunes
--		SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPTransfer_UL 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
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
declare @data_ULthputNC_LTE  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Subidas] [int] NULL,
	[Fallos de Acceso] [int] NULL,
	[Fallos de descarga] [int] NULL,
	[Throughput] [float] NULL,
	[Tiempo de subida] [float] NULL,
	[SessionTime] [float] NULL,
	[Throughput Max] [float] NULL,
	[RLC_MAX] [float] NULL,
	[Count_Throughput] [int] null,
	[Count_Throughput_64k] [int] null,
	[ 0-5Mbps] [int] NULL,
    [ 5-10Mbps] [int] NULL,
    [ 10-15Mbps] [int] NULL,
    [ 15-20Mbps] [int] NULL,
    [ 20-25Mbps] [int] NULL,
    [ 25-30Mbps] [int] NULL,
    [ 30-35Mbps] [int] NULL,
    [ 35-40Mbps] [int] NULL,
    [ 40-45Mbps] [int] NULL,
    [ 45-50Mbps] [int] NULL,
    [ >50Mbps] [int] NULL,   
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF][varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP][varchar](256) NULL, 

	[Count_TransferTime] [int] null,
	[Count_SessionTime] [int] null
)

if @Indoor=0
begin
	insert into @data_ULthputNC_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC') then 1 else 0 end) as 'Subidas',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.TransferTime end) as 'Tiempo de subida',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.sessiontime end) as 'SessionTime',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC') then v.RLC_MAX end) as 'RLC_MAX',
	
		
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>64) then 1 else 0 end) as 'Count_Throughput_64k',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 0 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 0-5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 5 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 5-10Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 10 and v.Throughput/1000 < 15) then 1 else 0 end ) as [ 10-15Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 15 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 15-20Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 20 and v.Throughput/1000 < 25) then 1 else 0 end ) as [ 20-25Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 25 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 25-30Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 30 and v.Throughput/1000 < 35) then 1 else 0 end ) as [ 30-35Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 35 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 35-40Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 40 and v.Throughput/1000 < 45) then 1 else 0 end ) as [ 40-45Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 45 and v.Throughput/1000 < 50) then 1 else 0 end ) as [ 45-50Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 50) then 1 else 0 end ) as [ >150Mbps],
		--'' as [% > Umbral], --PDTE
		--'' as [% > Umbral_sec], --PDTE
		----Para % a partir de un umbral (en ejemplo 3000)
		--case when (SUM (case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 
		--					else 0 
		--				end)) = 0 then 0 
		--	else (1.0*SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)
		--		/SUM (case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end)) 
		--end

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'Collection Name',
		lp.Region_OSP as Region_OSP,

		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.TransferTime is not null) then 1 else 0 end) as 'Count_TransferTime',
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime'

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_UL v,
		Agrids.dbo.lcc_parcelas lp
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='UL_NC'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) 
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP
end 
else
begin
	insert into @data_ULthputNC_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC') then 1 else 0 end) as 'Subidas',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.TransferTime end) as 'Tiempo de subida',
		AVG(case when (v.direction='uplink' and v.TestType='UL_NC') then v.sessiontime end) as 'SessionTime',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='uplink' and v.TestType='UL_NC') then v.RLC_MAX end) as 'RLC_MAX',
	
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>64) then 1 else 0 end) as 'Count_Throughput_64k',
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 0 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 0-5Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 5 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 5-10Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 10 and v.Throughput/1000 < 15) then 1 else 0 end ) as [ 10-15Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 15 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 15-20Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 20 and v.Throughput/1000 < 25) then 1 else 0 end ) as [ 20-25Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 25 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 25-30Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 30 and v.Throughput/1000 < 35) then 1 else 0 end ) as [ 30-35Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 35 and v.Throughput/1000 < 40) then 1 else 0 end ) as [ 35-40Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 40 and v.Throughput/1000 < 45) then 1 else 0 end ) as [ 40-45Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 45 and v.Throughput/1000 < 50) then 1 else 0 end ) as [ 45-50Mbps],
		SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and v.Throughput/1000 >= 50) then 1 else 0 end ) as [ >150Mbps],
		--'' as [% > Umbral], --PDTE
		--'' as [% > Umbral_sec], --PDTE
		----Para % a partir de un umbral (en ejemplo 3000)
		--case when (SUM (case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 
		--					else 0 
		--				end)) = 0 then 0 
		--	else (1.0*SUM(case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)
		--		/SUM (case when (v.direction='uplink' and v.TestType='UL_NC' and ISNULL(v.Throughput,0)>0) then 1 else 0 end)) 
		--end

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'Collection Name',
		null,

		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.TransferTime is not null) then 1 else 0 end) as 'Count_TransferTime',
		sum(case when (v.direction='Uplink' and v.TestType='UL_NC' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime'

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_UL v
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='UL_NC'
	group by v.MNC
end


select * from @data_ULthputNC_LTE
