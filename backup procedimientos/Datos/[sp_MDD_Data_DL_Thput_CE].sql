USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_DL_Thput_CE]    Script Date: 29/05/2017 12:15:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_DL_Thput_CE] (
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


-----------------------------
----- Date Declarations -----
-----------------------------
	
--declare @fecha_ini1 as datetime = @fecha_ini_text1
--declare @fecha_fin1 as datetime = @fecha_fin_text1
--declare @fecha_ini2 as datetime = @fecha_ini_text2
--declare @fecha_fin2 as datetime = @fecha_fin_text2
--declare @fecha_ini3 as datetime = @fecha_ini_text3
--declare @fecha_fin3 as datetime = @fecha_fin_text3
--declare @fecha_ini4 as datetime = @fecha_ini_text4
--declare @fecha_fin4 as datetime = @fecha_fin_text4
--declare @fecha_ini5 as datetime = @fecha_ini_text5
--declare @fecha_fin5 as datetime = @fecha_fin_text5
--declare @fecha_ini6 as datetime = @fecha_ini_text6
--declare @fecha_fin6 as datetime = @fecha_fin_text6
--declare @fecha_ini7 as datetime = @fecha_ini_text7
--declare @fecha_fin7 as datetime = @fecha_fin_text7
--declare @fecha_ini8 as datetime = @fecha_ini_text8
--declare @fecha_fin8 as datetime = @fecha_fin_text8
--declare @fecha_ini9 as datetime = @fecha_ini_text9
--declare @fecha_fin9 as datetime = @fecha_fin_text9
--declare @fecha_ini10 as datetime = @fecha_ini_text10
--declare @fecha_fin10 as datetime = @fecha_fin_text10


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
	case when v.[% CA] >0 then 'CA'
	else 'SC' end as hasCA
from Lcc_Data_HTTPTransfer_DL v
Where v.collectionname like @Date + '%[_]' + @ciudad + '[_]%' + @Tech
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos
	and v.info like @Info	
	--and (v.callStartTimeStamp >=@fecha_ini1 and @fecha_fin1 
	--		 or
	--		 v.callStartTimeStamp >=@fecha_ini2 and @fecha_fin2 
	--		 or
	--		 v.callStartTimeStamp >=@fecha_ini3 and @fecha_fin3 
	--		 or
	--		 v.callStartTimeStamp >=@fecha_ini4 and @fecha_fin4 
	--		 or
	--		 v.callStartTimeStamp >=@fecha_ini5 and @fecha_fin5 
	--		 or
	--		 v.callStartTimeStamp >=@fecha_ini6 and @fecha_fin6
 --			 or
	--		 v.callStartTimeStamp >=@fecha_ini7 and @fecha_fin7 
 --			 or
	--		 v.callStartTimeStamp >=@fecha_ini8 and @fecha_fin8 
 --			 or
	--		 v.callStartTimeStamp >=@fecha_ini9 and @fecha_fin9 
 --			 or
	--		 v.callStartTimeStamp >=@fecha_ini10 and @fecha_fin10 			 
	--		 or
	--		 v.callEndTimeStamp >=@fecha_ini1 and @fecha_fin1 
	--		 or
	--		 v.callEndTimeStamp >=@fecha_ini2 and @fecha_fin2 
	--		 or
	--		 v.callEndTimeStamp >=@fecha_ini3 and @fecha_fin3 
	--		 or
	--		 v.callEndTimeStamp >=@fecha_ini4 and @fecha_fin4 
	--		 or
	--		 v.callEndTimeStamp >=@fecha_ini5 and @fecha_fin5 
	--		 or
	--		 v.callEndTimeStamp >=@fecha_ini6 and @fecha_fin6
 --			 or
	--		 v.callEndTimeStamp >=@fecha_ini7 and @fecha_fin7 
 --			 or
	--		 v.callEndTimeStamp >=@fecha_ini8 and @fecha_fin8 
 --			 or
	--		 v.callEndTimeStamp >=@fecha_ini9 and @fecha_fin9 
 --			 or
	--		 v.callEndTimeStamp >=@fecha_ini10 and @fecha_fin10 			 
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
declare @dateMax datetime2(3)= (select max(c.endTime) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

--declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, endTime)),2) + '_'	 + convert(varchar(256),format(endTime,'MM'))
--	from Lcc_Data_HTTPTransfer_DL where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from Lcc_Data_HTTPTransfer_DL v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max([master].dbo.fn_lcc_getElement(5, v.collectionname,'_')) from Lcc_Data_HTTPTransfer_DL v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId)-- group by [master].dbo.fn_lcc_getElement(5, v.collectionname,'_'))

declare @week as varchar(256)
declare @tmpDateFirst int 
declare @tmpWeek int 

--select @tmpDateFirst = @@DATEFIRST
--if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
--	SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPTransfer_DL 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
--else
--	begin
--		SET DATEFIRST 1;  --Primer dia de la semana lunes
--		SELECT @tmpWeek =DATEPART(week, (select endTime
--						from Lcc_Data_HTTPTransfer_DL 
--						where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)))
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
declare @data_DLthputCE  as table (
      [Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[Navegaciones] [int] NULL,
	[Fallos de Acceso] [int] NULL,
	[Fallos de descarga] [int] NULL,
	[Throughput] [float] NULL,
	[Throughput_Desv] [float] NULL,
	[Tiempo de Descarga] [float] NULL,
	[SessionTime] [float] NULL,
	[Throughput Max] [float] NULL,
	[RLC_MAX] [float] NULL,
	[Count_Throughput] [int] null,
	[Count_Throughput_1M] [int] null,
	[Count_Throughput_3M] [int] null,
	[ 0-1Mbps] [int] NULL,
	[ 1-2Mbps] [int] NULL,
	[ 2-3Mbps] [int] NULL,
	[ 3-4Mbps] [int] NULL,
	[ 4-5Mbps] [int] NULL,
	[ 5-6Mbps] [int] NULL,
	[ 6-7Mbps] [int] NULL,
	[ 7-8Mbps] [int] NULL,
	[ 8-9Mbps] [int] NULL,
	[ 9-10Mbps] [int] NULL,
	[ 10-11Mbps] [int] NULL,
	[ 11-12Mbps] [int] NULL,
	[ 12-13Mbps] [int] NULL,
	[ 13-14Mbps] [int] NULL,
	[ 14-15Mbps] [int] NULL,
	[ 15-16Mbps] [int] NULL,
	[ 16-17Mbps] [int] NULL,
	[ 17-18Mbps] [int] NULL,
	[ 18-19Mbps] [int] NULL,
	[ 19-20Mbps] [int] NULL,
	[ 20-21Mbps] [int] NULL,
	[ 21-22Mbps] [int] NULL,
	[ 22-23Mbps] [int] NULL,
	[ 23-24Mbps] [int] NULL,
	[ 24-25Mbps] [int] NULL,
	[ 25-26Mbps] [int] NULL,
	[ 26-27Mbps] [int] NULL,
	[ 27-28Mbps] [int] NULL,
	[ 28-29Mbps] [int] NULL,
	[ 29-30Mbps] [int] NULL,
	[ 30-31Mbps] [int] NULL,
	[ 31-32Mbps] [int] NULL,
	[ >32Mbps] [int] NULL,
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
	insert into @data_DLthputCE
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		STDEV(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput_Desv',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.TransferTime end) as 'Tiempo de Descarga',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.sessionTime end) as 'SessionTime',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[RLC Thput] end) as 'RLC_MAX',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>1000) then 1 else 0 end)'Count_Throughput_1M',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)'Count_Throughput_3M',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=0 and v.Throughput/1000 < 1) then 1 else 0 end ) as [ 0-1Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=1 and v.Throughput/1000 < 2) then 1 else 0 end ) as [ 1-2Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=2 and v.Throughput/1000 < 3)then 1 else 0 end )  as [ 2-3Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=3 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 3-4Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=4 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 4-5Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=5 and v.Throughput/1000 < 6) then 1 else 0 end ) as [ 5-6Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=6 and v.Throughput/1000 < 7) then 1 else 0 end ) as [ 6-7Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=7 and v.Throughput/1000 < 8) then 1 else 0 end ) as [ 7-8Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=8 and v.Throughput/1000 < 9) then 1 else 0 end ) as [ 8-9Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=9 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 9-10Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=10 and v.Throughput/1000 < 11) then 1 else 0 end ) as [ 10-11Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=11 and v.Throughput/1000 < 12) then 1 else 0 end )  as [ 11-12Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=12 and v.Throughput/1000 < 13) then 1 else 0 end ) as [ 12-13Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=13 and v.Throughput/1000 < 14) then 1 else 0 end ) as [ 13-14Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=14 and v.Throughput/1000 < 15)then 1 else 0 end )  as [ 14-15Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=15 and v.Throughput/1000 < 16) then 1 else 0 end ) as [ 15-16Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=16 and v.Throughput/1000 < 17) then 1 else 0 end ) as [ 16-17Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=17 and v.Throughput/1000 < 18)then 1 else 0 end )  as [ 17-18Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=18 and v.Throughput/1000 < 19)then 1 else 0 end )  as [ 18-19Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=19 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 19-20Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=20 and v.Throughput/1000 < 21) then 1 else 0 end ) as [ 20-21Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=21 and v.Throughput/1000 < 22) then 1 else 0 end ) as [ 21-22Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=22 and v.Throughput/1000 < 23)then 1 else 0 end )  as [ 22-23Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=23 and v.Throughput/1000 < 24) then 1 else 0 end ) as [ 23-24Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=24 and v.Throughput/1000 < 25) then 1 else 0 end ) as [ 24-25Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=25 and v.Throughput/1000 < 26) then 1 else 0 end ) as [ 25-26Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=26 and v.Throughput/1000 < 27) then 1 else 0 end ) as [ 26-27Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=27 and v.Throughput/1000 < 28) then 1 else 0 end ) as [ 27-28Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=28 and v.Throughput/1000 < 29) then 1 else 0 end ) as [ 28-29Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=29 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 29-30Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=30 and v.Throughput/1000 < 31) then 1 else 0 end ) as [ 30-31Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=31 and v.Throughput/1000 < 32) then 1 else 0 end ) as [ 31-32Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=32) then 1 else 0 end ) as [ >32Mbps],
		--'' as [% > Umbral], --PDTE
		--'' as [% > Umbral_sec], --PDTE
		----Para % a partir de un umbral (en ejemplo 3000)
		--case when (SUM (case when (v.direction='uplink' and v.TestType='UL_CE' and ISNULL(v.Throughput,0)>0) then 1 
		--					else 0 
		--				end)) = 0 then 0 
		--	else (1.0*SUM(case when (v.direction='uplink' and v.TestType='UL_CE' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)
		--		/SUM (case when (v.direction='uplink' and v.TestType='UL_CE' and ISNULL(v.Throughput,0)>0) then 1 else 0 end)) 
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

		sum(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.TransferTime is not null) then 1 else 0 end) as 'Count_TransferTime',
		sum(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime'

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_DL v,
		Agrids.dbo.lcc_parcelas lp
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='DL_CE'
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) 
	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]),v.MNC,lp.Region_VF,lp.Region_OSP
end 
else
begin
	insert into @data_DLthputCE
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1 else 0 end) as 'Navegaciones',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.ErrorType='Accessibility') then 1 else 0 end) as 'Fallos de Acceso',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.ErrorType='Retainability') then 1 else 0 end) as 'Fallos de descarga',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput',
		STDEV(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput_Desv',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.TransferTime end) as 'Tiempo de Descarga',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.sessionTime end) as 'SessionTime',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then v.Throughput end) as 'Throughput Max',
		MAX(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[RLC Thput] end) as 'RLC_MAX',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>0) then 1 else 0 end) as 'Count_Throughput',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>1000) then 1 else 0 end)'Count_Throughput_1M',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)'Count_Throughput_3M',
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=0 and v.Throughput/1000 < 1) then 1 else 0 end ) as [ 0-1Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=1 and v.Throughput/1000 < 2) then 1 else 0 end ) as [ 1-2Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=2 and v.Throughput/1000 < 3)then 1 else 0 end )  as [ 2-3Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=3 and v.Throughput/1000 < 4) then 1 else 0 end ) as [ 3-4Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=4 and v.Throughput/1000 < 5) then 1 else 0 end ) as [ 4-5Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=5 and v.Throughput/1000 < 6) then 1 else 0 end ) as [ 5-6Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=6 and v.Throughput/1000 < 7) then 1 else 0 end ) as [ 6-7Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=7 and v.Throughput/1000 < 8) then 1 else 0 end ) as [ 7-8Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=8 and v.Throughput/1000 < 9) then 1 else 0 end ) as [ 8-9Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=9 and v.Throughput/1000 < 10) then 1 else 0 end ) as [ 9-10Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=10 and v.Throughput/1000 < 11) then 1 else 0 end ) as [ 10-11Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=11 and v.Throughput/1000 < 12) then 1 else 0 end )  as [ 11-12Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=12 and v.Throughput/1000 < 13) then 1 else 0 end ) as [ 12-13Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=13 and v.Throughput/1000 < 14) then 1 else 0 end ) as [ 13-14Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=14 and v.Throughput/1000 < 15)then 1 else 0 end )  as [ 14-15Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=15 and v.Throughput/1000 < 16) then 1 else 0 end ) as [ 15-16Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=16 and v.Throughput/1000 < 17) then 1 else 0 end ) as [ 16-17Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=17 and v.Throughput/1000 < 18)then 1 else 0 end )  as [ 17-18Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=18 and v.Throughput/1000 < 19)then 1 else 0 end )  as [ 18-19Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=19 and v.Throughput/1000 < 20) then 1 else 0 end ) as [ 19-20Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=20 and v.Throughput/1000 < 21) then 1 else 0 end ) as [ 20-21Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=21 and v.Throughput/1000 < 22) then 1 else 0 end ) as [ 21-22Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=22 and v.Throughput/1000 < 23)then 1 else 0 end )  as [ 22-23Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=23 and v.Throughput/1000 < 24) then 1 else 0 end ) as [ 23-24Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=24 and v.Throughput/1000 < 25) then 1 else 0 end ) as [ 24-25Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=25 and v.Throughput/1000 < 26) then 1 else 0 end ) as [ 25-26Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=26 and v.Throughput/1000 < 27) then 1 else 0 end ) as [ 26-27Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=27 and v.Throughput/1000 < 28) then 1 else 0 end ) as [ 27-28Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=28 and v.Throughput/1000 < 29) then 1 else 0 end ) as [ 28-29Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=29 and v.Throughput/1000 < 30) then 1 else 0 end ) as [ 29-30Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=30 and v.Throughput/1000 < 31) then 1 else 0 end ) as [ 30-31Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=31 and v.Throughput/1000 < 32) then 1 else 0 end ) as [ 31-32Mbps],
		SUM(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.Throughput/1000 >=32) then 1 else 0 end ) as [ >32Mbps],
		--'' as [% > Umbral], --PDTE
		--'' as [% > Umbral_sec], --PDTE
		----Para % a partir de un umbral (en ejemplo 3000)
		--case when (SUM (case when (v.direction='uplink' and v.TestType='UL_CE' and ISNULL(v.Throughput,0)>0) then 1 
		--					else 0 
		--				end)) = 0 then 0 
		--	else (1.0*SUM(case when (v.direction='uplink' and v.TestType='UL_CE' and ISNULL(v.Throughput,0)>3000) then 1 else 0 end)
		--		/SUM (case when (v.direction='uplink' and v.TestType='UL_CE' and ISNULL(v.Throughput,0)>0) then 1 else 0 end)) 
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

		sum(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.TransferTime is not null) then 1 else 0 end) as 'Count_TransferTime',
		sum(case when (v.direction='Downlink' and v.TestType='DL_CE' and v.sessionTime is not null) then 1 else 0 end) as 'Count_SessionTime'

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_HTTPTransfer_DL v
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.TestType='DL_CE'
	group by v.MNC
end


select * from @data_DLthputCE