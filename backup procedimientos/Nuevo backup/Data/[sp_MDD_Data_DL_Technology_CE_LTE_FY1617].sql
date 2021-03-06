USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_DL_Technology_CE_LTE_FY1617]    Script Date: 31/10/2017 13:55:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_DL_Technology_CE_LTE_FY1617] (
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
--declare @mob1 as varchar(256) = '354720054741835'
--declare @mob2 as varchar(256) = 'Ninguna'
--declare @mob3 as varchar(256) = 'Ninguna'

--declare @fecha_ini_text1 as varchar (256) = '2015-05-27 09:10:00.000'
--declare @fecha_fin_text1 as varchar (256) = '2015-05-27 14:30:00.000'
--declare @fecha_ini_text2 as varchar (256) = '2015-05-27 15:15:00.000'
--declare @fecha_fin_text2 as varchar (256) = '2015-05-27 22:00:00.000'
--declare @fecha_ini_text3 as varchar (256) = '2015-05-28 08:20:00.000'
--declare @fecha_fin_text3 as varchar (256) = '2015-05-28 15:40:00.000'
--declare @fecha_ini_text4 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_fin_text4 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_ini_text5 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_fin_text5 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_ini_text6 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_fin_text6 as varchar (256) = '2014-06-23 18:30:00:000'
--declare @fecha_ini_text7 as varchar (256) = '2014-08-07 10:40:00:000'
--declare @fecha_fin_text7 as varchar (256) = '2014-08-07 10:40:00:000'
--declare @fecha_ini_text8 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_fin_text8 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_ini_text9 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_fin_text9 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_ini_text10 as varchar (256) = '2014-08-12 09:40:00:000'
--declare @fecha_fin_text10 as varchar (256) = '2014-08-12 09:40:00:000'


--declare @ciudad as varchar(256) = 'po_ogrove'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 1 -- O = False, 1 = True
--declare @Info as varchar (256) = '%%' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @sheet as varchar(256) = '%%'
--declare @Tech as varchar (256) = '4G'
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
Where v.collectionname like @Date + '%' + @ciudad + '%' + @Tech
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
declare @data_DLtechCE_LTE  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[% LTE] [numeric](38, 12) NULL,
	[% WCDMA] [numeric](38, 12) NULL,
	[% GSM] [numeric](38, 12) NULL,
	[QPSK] [numeric](38, 6) NULL,
	[16QAM] [numeric](38, 6) NULL,
	[64QAM] [numeric](38, 6) NULL,
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
	[% LTE800] [numeric](24, 12) NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF][varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP][varchar](256) NULL
	
)

if @Indoor=0
begin
	insert into @data_DLtechCE_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% LTE] end) as '% LTE',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% WCDMA] end) as '% WCDMA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% GSM] end) as '% GSM',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% QPSK 4G] end) as 'QPSK',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% 16QAM 4G] end) as '16QAM',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% 64QAM 4G] end) as '64QAM',

		log10(avg(power(10.0E0,(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1.0 * v.RSRP_avg end)/10.0E0)))*10 as 'RSRP Avg',	
		log10(avg(power(10.0E0,(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1.0 * v.RSRQ_avg end)/10.0E0)))*10 as 'RSRQ Avg',
		log10(avg(power(10.0E0,(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1.0 * v.SINR_avg end)/10.0E0)))*10 as 'SINR Avg',

		null as '10Mhz Bandwidth %',
		null as '15Mhz Bandwidth %',
		null as '20Mhz Bandwidth %',
				
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 U2100] else null end) as '% F1 U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F2 U2100] else null end) as '% F2 U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F3 U2100] else null end) as '% F3 U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 U900] else null end) as '% F1 U900',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F2 U900] else null end) as '% F2 U900',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 L2600] else null end) as '% F1 L2600',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 L2100] else null end) as '% F1 L2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F2 L2100] else null end) as '% F2 L2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 L1800] else null end) as '% F1 L1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F2 L1800] else null end) as '% F2 L1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F3 L1800] else null end) as '% F3 L1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 L800] else null end) as '% F1 L800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% U2100] else null end) as '% U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% U900] else null end) as '% U900',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% LTE1800] else null end) as '% LTE1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% LTE2600] else null end) as '% LTE2600',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% LTE800] else null end) as '% LTE800',
		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null as 'Num_Medida',
		@Report,
		'Collection Name',
		lp.Region_OSP as Region_OSP

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
	insert into @data_DLtechCE_LTE
	select  
		db_name() as 'Database',
		v.mnc,
		null as Parcel,
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% LTE] end) as '% LTE',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% WCDMA] end) as '% WCDMA',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% GSM] end) as '% GSM',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% QPSK 4G] end) as 'QPSK',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% 16QAM 4G] end) as '16QAM',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% 64QAM 4G] end) as '64QAM',

		log10(avg(power(10.0E0,(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1.0 * v.RSRP_avg end)/10.0E0)))*10 as 'RSRP Avg',	
		log10(avg(power(10.0E0,(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1.0 * v.RSRQ_avg end)/10.0E0)))*10 as 'RSRQ Avg',
		log10(avg(power(10.0E0,(case when (v.direction='Downlink' and v.TestType='DL_CE') then 1.0 * v.SINR_avg end)/10.0E0)))*10 as 'SINR Avg',

		null as '10Mhz Bandwidth %',
		null as '15Mhz Bandwidth %',
		null as '20Mhz Bandwidth %',

		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 U2100] else null end) as '% F1 U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F2 U2100] else null end) as '% F2 U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F3 U2100] else null end) as '% F3 U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 U900] else null end) as '% F1 U900',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F2 U900] else null end) as '% F2 U900',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 L2600] else null end) as '% F1 L2600',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 L2100] else null end) as '% F1 L2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F2 L2100] else null end) as '% F2 L2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 L1800] else null end) as '% F1 L1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F2 L1800] else null end) as '% F2 L1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F3 L1800] else null end) as '% F3 L1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% F1 L800] else null end) as '% F1 L800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% U2100] else null end) as '% U2100',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% U900] else null end) as '% U900',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% LTE1800] else null end) as '% LTE1800',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% LTE2600] else null end) as '% LTE2600',
		AVG(case when (v.direction='Downlink' and v.TestType='DL_CE') then v.[% LTE800] else null end) as '% LTE800',
		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'Collection Name',
		null
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

select * from @data_DLtechCE_LTE