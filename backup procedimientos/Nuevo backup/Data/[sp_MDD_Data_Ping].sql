USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_Ping]    Script Date: 31/10/2017 14:01:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_Ping] (
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
from Lcc_Data_Latencias v
Where v.collectionname like @Date + '%[_]' + @ciudad + '[_]%' + @Tech
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
declare @dateMax datetime2(3)= (select max(c.endTime) from Lcc_Data_Latencias c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId)

declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from Lcc_Data_Latencias v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max([master].dbo.fn_lcc_getElement(5, v.collectionname,'_')) from Lcc_Data_Latencias v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId)-- group by [master].dbo.fn_lcc_getElement(5, v.collectionname,'_'))

declare @week as varchar(256)
declare @tmpDateFirst int 
declare @tmpWeek int 

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
declare @data_ping  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[pings] [int] NULL,
	[rtt] [float] NULL,
	[ 0-5Ms] [int] NULL,
	[ 5-10Ms] [int] NULL,
	[ 10-15Ms] [int] NULL,
	[ 15-20Ms] [int] NULL,
	[ 20-25Ms] [int] NULL,
	[ 25-30Ms] [int] NULL,
	[ 30-35Ms] [int] NULL,
	[ 35-40Ms] [int] NULL,
	[ 40-45Ms] [int] NULL,
	[ 45-50Ms] [int] NULL,
	[ 50-55Ms] [int] NULL,
	[ 55-60Ms] [int] NULL,
	[ 60-65Ms] [int] NULL,
	[ 65-70Ms] [int] NULL,
	[ 70-75Ms] [int] NULL,
	[ 75-80Ms] [int] NULL,
	[ 80-85Ms] [int] NULL,
	[ 85-90Ms] [int] NULL,
	[ 90-95Ms] [int] NULL,
	[ 95-100Ms] [int] NULL,
	[ 100-105Ms] [int] NULL,
	[ 105-110Ms] [int] NULL,
	[ 110-115Ms] [int] NULL,
	[ 115-120Ms] [int] NULL,
	[ 120-125Ms] [int] NULL,
	[ 125-130Ms] [int] NULL,
	[ 130-135Ms] [int] NULL,
	[ 135-140Ms] [int] NULL,
	[ 140-145Ms] [int] NULL,
	[ 145-150Ms] [int] NULL,
	[ 150-155Ms] [int] NULL,
	[ 155-160Ms] [int] NULL,
	[ 160-165Ms] [int] NULL,
	[ 165-170Ms] [int] NULL,
	[ 170-175Ms] [int] NULL,
	[ 175-180Ms] [int] NULL,
	[ 180-185Ms] [int] NULL,
	[ 185-190Ms] [int] NULL,
	[ 190-195Ms] [int] NULL,
	[ 195-200Ms] [int] NULL,
	[ >200Ms] [int] NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF][varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Methodology] [varchar](50) null,
	[Region_OSP][varchar](256) NULL,

	-- 20170321 - @ERC: Nuevos KPis y parametros:
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL
)

if @Indoor=0
begin
	insert into @data_ping
	select  
			db_name() as 'Database',
			v.mnc,
			master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]) as Parcel,
			COUNT(v.testid) as 'pings',
			AVG(1.0*v.rtt) as 'rtt',

			SUM(case when (rtt >=0 and rtt <5) then 1 else 0 end ) as [ 0-5Ms],
			SUM(case when (rtt >=5 and rtt <10) then 1 else 0 end ) as [ 5-10Ms],
			SUM(case when (rtt >=10 and rtt <15) then 1 else 0 end ) as [ 10-15Ms],
			SUM(case when (rtt >=15 and rtt <20) then 1 else 0 end ) as [ 15-20Ms],
			SUM(case when (rtt >=20 and rtt <25) then 1 else 0 end ) as [ 20-25Ms],
			SUM(case when (rtt >=25 and rtt <30) then 1 else 0 end ) as [ 25-30Ms],
			SUM(case when (rtt >=30 and rtt <35) then 1 else 0 end ) as [ 30-35Ms],
			SUM(case when (rtt >=35 and rtt <40) then 1 else 0 end ) as [ 35-40Ms],
			SUM(case when (rtt >=40 and rtt <45) then 1 else 0 end ) as [ 40-45Ms],
			SUM(case when (rtt >=45 and rtt <50) then 1 else 0 end ) as [ 45-50Ms],
			SUM(case when (rtt >=50 and rtt <55) then 1 else 0 end ) as [ 50-55Ms],
			SUM(case when (rtt >=55 and rtt <60) then 1 else 0 end ) as [ 55-60Ms],
			SUM(case when (rtt >=60 and rtt <65) then 1 else 0 end ) as [ 60-65Ms],
			SUM(case when (rtt >=65 and rtt <70) then 1 else 0 end ) as [ 65-70Ms],
			SUM(case when (rtt >=70 and rtt <75) then 1 else 0 end ) as [ 70-75Ms],
			SUM(case when (rtt >=75 and rtt <80) then 1 else 0 end ) as [ 75-80Ms],
			SUM(case when (rtt >=80 and rtt <85) then 1 else 0 end ) as [ 80-85Ms],
			SUM(case when (rtt >=85 and rtt <90) then 1 else 0 end ) as [ 85-90Ms],
			SUM(case when (rtt >=90 and rtt <95) then 1 else 0 end ) as [ 90-95Ms],
			SUM(case when (rtt >=95 and rtt <100) then 1 else 0 end ) as [ 95-100Ms],
			SUM(case when (rtt >=100 and rtt <105) then 1 else 0 end ) as [ 100-105Ms],
			SUM(case when (rtt >=105 and rtt <110) then 1 else 0 end ) as [ 105-110Ms],
			SUM(case when (rtt >=110 and rtt <115) then 1 else 0 end ) as [ 110-115Ms],
			SUM(case when (rtt >=115 and rtt <120) then 1 else 0 end ) as [ 115-120Ms],
			SUM(case when (rtt >=120 and rtt <125) then 1 else 0 end ) as [ 120-125Ms],

			SUM(case when (rtt >=125 and rtt <130) then 1 else 0 end ) as [ 125-130Ms],
			SUM(case when (rtt >=130 and rtt <135) then 1 else 0 end ) as [ 130-135Ms],
			SUM(case when (rtt >=135 and rtt <140) then 1 else 0 end ) as [ 135-140Ms],
			SUM(case when (rtt >=140 and rtt <145) then 1 else 0 end ) as [ 140-145Ms],
			SUM(case when (rtt >=145 and rtt <150) then 1 else 0 end ) as [ 145-150Ms],
			SUM(case when (rtt >=150 and rtt <155) then 1 else 0 end ) as [ 150-155Ms],
			SUM(case when (rtt >=155 and rtt <160) then 1 else 0 end ) as [ 155-160Ms],
			SUM(case when (rtt >=160 and rtt <165) then 1 else 0 end ) as [ 160-165Ms],
			SUM(case when (rtt >=165 and rtt <170) then 1 else 0 end ) as [ 165-170Ms],
			SUM(case when (rtt >=170 and rtt <175) then 1 else 0 end ) as [ 170-175Ms],
			SUM(case when (rtt >=175 and rtt <180) then 1 else 0 end ) as [ 175-180Ms],
			SUM(case when (rtt >=180 and rtt <185) then 1 else 0 end ) as [ 180-185Ms],
			SUM(case when (rtt >=185 and rtt <190) then 1 else 0 end ) as [ 185-190Ms],
			SUM(case when (rtt >=190 and rtt <195) then 1 else 0 end ) as [ 190-195Ms],
			SUM(case when (rtt >=195 and rtt <200) then 1 else 0 end ) as [ 195-200Ms],
			SUM(case when (rtt >=200) then 1 else 0 end ) as [ >200Ms],

			@week as Meas_Week,
			@Meas_Round as Meas_Round,
			@Meas_Date as Meas_Date,
			@entidad as Entidad,
			lp.Region_VF as Region_VF,
			null,
			@Report,
			'Collection Name',
			@Methodology,
			lp.Region_OSP as Region_OSP,

			-- 20170321 - @ERC: Nuevos KPis y parametros:
			v.[ASideDevice],
			v.[BSideDevice],
			v.[SWVersion]

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_Latencias v,
		Agrids.dbo.lcc_parcelas lp

	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final])

	group by master.dbo.fn_lcc_getParcel(v.[Longitud Final],v.[Latitud Final]), v.MNC,lp.Region_VF,lp.Region_OSP, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end
else
begin
	insert into @data_ping
	select  
			db_name() as 'Database',
			v.mnc,
			null,
			COUNT(v.testid) as 'pings',
			AVG(1.0*v.rtt) as 'rtt',

			SUM(case when (rtt >=0 and rtt <5) then 1 else 0 end ) as [ 0-5Ms],
			SUM(case when (rtt >=5 and rtt <10) then 1 else 0 end ) as [ 5-10Ms],
			SUM(case when (rtt >=10 and rtt <15) then 1 else 0 end ) as [ 10-15Ms],
			SUM(case when (rtt >=15 and rtt <20) then 1 else 0 end ) as [ 15-20Ms],
			SUM(case when (rtt >=20 and rtt <25) then 1 else 0 end ) as [ 20-25Ms],
			SUM(case when (rtt >=25 and rtt <30) then 1 else 0 end ) as [ 25-30Ms],
			SUM(case when (rtt >=30 and rtt <35) then 1 else 0 end ) as [ 30-35Ms],
			SUM(case when (rtt >=35 and rtt <40) then 1 else 0 end ) as [ 35-40Ms],
			SUM(case when (rtt >=40 and rtt <45) then 1 else 0 end ) as [ 40-45Ms],
			SUM(case when (rtt >=45 and rtt <50) then 1 else 0 end ) as [ 45-50Ms],
			SUM(case when (rtt >=50 and rtt <55) then 1 else 0 end ) as [ 50-55Ms],
			SUM(case when (rtt >=55 and rtt <60) then 1 else 0 end ) as [ 55-60Ms],
			SUM(case when (rtt >=60 and rtt <65) then 1 else 0 end ) as [ 60-65Ms],
			SUM(case when (rtt >=65 and rtt <70) then 1 else 0 end ) as [ 65-70Ms],
			SUM(case when (rtt >=70 and rtt <75) then 1 else 0 end ) as [ 70-75Ms],
			SUM(case when (rtt >=75 and rtt <80) then 1 else 0 end ) as [ 75-80Ms],
			SUM(case when (rtt >=80 and rtt <85) then 1 else 0 end ) as [ 80-85Ms],
			SUM(case when (rtt >=85 and rtt <90) then 1 else 0 end ) as [ 85-90Ms],
			SUM(case when (rtt >=90 and rtt <95) then 1 else 0 end ) as [ 90-95Ms],
			SUM(case when (rtt >=95 and rtt <100) then 1 else 0 end ) as [ 95-100Ms],
			SUM(case when (rtt >=100 and rtt <105) then 1 else 0 end ) as [ 100-105Ms],
			SUM(case when (rtt >=105 and rtt <110) then 1 else 0 end ) as [ 105-110Ms],
			SUM(case when (rtt >=110 and rtt <115) then 1 else 0 end ) as [ 110-115Ms],
			SUM(case when (rtt >=115 and rtt <120) then 1 else 0 end ) as [ 115-120Ms],
			SUM(case when (rtt >=120 and rtt <125) then 1 else 0 end ) as [ 120-125Ms],
			SUM(case when (rtt >=125 and rtt <130) then 1 else 0 end ) as [ 125-130Ms],
			SUM(case when (rtt >=130 and rtt <135) then 1 else 0 end ) as [ 130-135Ms],
			SUM(case when (rtt >=135 and rtt <140) then 1 else 0 end ) as [ 135-140Ms],
			SUM(case when (rtt >=140 and rtt <145) then 1 else 0 end ) as [ 140-145Ms],
			SUM(case when (rtt >=145 and rtt <150) then 1 else 0 end ) as [ 145-150Ms],
			SUM(case when (rtt >=150 and rtt <155) then 1 else 0 end ) as [ 150-155Ms],
			SUM(case when (rtt >=155 and rtt <160) then 1 else 0 end ) as [ 155-160Ms],
			SUM(case when (rtt >=160 and rtt <165) then 1 else 0 end ) as [ 160-165Ms],
			SUM(case when (rtt >=165 and rtt <170) then 1 else 0 end ) as [ 165-170Ms],
			SUM(case when (rtt >=170 and rtt <175) then 1 else 0 end ) as [ 170-175Ms],
			SUM(case when (rtt >=175 and rtt <180) then 1 else 0 end ) as [ 175-180Ms],
			SUM(case when (rtt >=180 and rtt <185) then 1 else 0 end ) as [ 180-185Ms],
			SUM(case when (rtt >=185 and rtt <190) then 1 else 0 end ) as [ 185-190Ms],
			SUM(case when (rtt >=190 and rtt <195) then 1 else 0 end ) as [ 190-195Ms],
			SUM(case when (rtt >=195 and rtt <200) then 1 else 0 end ) as [ 195-200Ms],
			SUM(case when (rtt >=200) then 1 else 0 end ) as [ >200Ms],

			@week as Meas_Week,
			@Meas_Round as Meas_Round,
			@Meas_Date as Meas_Date,
			@entidad as Entidad,
			null,
			@medida as 'Num_Medida',
			@Report,
			'Collection Name',
			@Methodology,
			null,

			-- 20170321 - @ERC: Nuevos KPis y parametros:
			v.[ASideDevice],
			v.[BSideDevice],
			v.[SWVersion]

	from 
		TestInfo t,
		@All_Tests a,
		Lcc_Data_Latencias v

	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and a.Sessionid=v.Sessionid and a.TestId=v.TestId

	group by v.MNC, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end

select * from @data_ping
