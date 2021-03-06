USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_All_Test_FY1617]    Script Date: 29/05/2017 12:09:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Data_All_Test_FY1617] (
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
--use [FY1617_Data_Smaller_3G_H2_2]

--declare @ciudad as varchar(256) = 'oviedo'
--declare @simOperator as int = 1
--declare @sheet as varchar(256) = '%%' --%%/LTE/WCDMA
--declare @date as varchar(256) = ''
--declare @Tech as varchar (256) = '3G'
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @Info as varchar (256) = 'Completed' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @methodology as varchar (256) = 'D16'
--declare @report as varchar(256) = 'MUN' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests_Tech_DL as table (sessionid bigint, TestId bigint,tech varchar(5), hasCA varchar(2),Longitud_Final float,Latitud_Final float,MNC varchar(2))

insert into @All_Tests_Tech_DL 
select v.sessionid, v.testid,
	case when v.[% LTE]=1 then 'LTE'
		 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' 
	end as tech,	
	case when v.[% CA] >0 then 'CA'
	else 'SC' end as hasCA,
	[Longitud Final],
	[Latitud Final],
	MNC
from Lcc_Data_HTTPTransfer_DL v
Where v.collectionname like @Date + '%' + @ciudad + '%' + @Tech
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos
	and v.info like @Info
OPTION (RECOMPILE)

declare @All_Tests_Tech_UL as table (sessionid bigint, TestId bigint,tech varchar(5), hasCA varchar(2),Longitud_Final float,Latitud_Final float,MNC varchar(2))

insert into @All_Tests_Tech_UL
select v.sessionid, v.testid,
	case when v.[% LTE]=1 then 'LTE'
		 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' 
	end as tech,	
	'SC' hasCA,
	[Longitud Final],
	[Latitud Final],
	MNC
from Lcc_Data_HTTPTransfer_UL v
Where v.collectionname like @Date + '%' + @ciudad + '%' + @Tech
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos
	and v.info like @Info	
 OPTION (RECOMPILE)

declare @All_Tests_Tech_WEB as table (sessionid bigint, TestId bigint,tech varchar(5), hasCA varchar(2),Longitud_Final float,Latitud_Final float,MNC varchar(2))

insert into @All_Tests_Tech_WEB 
select v.sessionid, v.testid,
	case when v.[% LTE]=1 then 'LTE'
		 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' 
	end as tech,	
	'SC' hasCA,
	[Longitud Final],
	[Latitud Final],
	MNC
from Lcc_Data_HTTPBrowser v
Where v.collectionname like @Date + '%' + @ciudad + '%' + @Tech
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos	
	and v.info like @Info
OPTION (RECOMPILE)

declare @All_Tests_Tech_YTB as table (sessionid bigint, TestId bigint,tech varchar(5), hasCA varchar(2),Longitud_Final float,Latitud_Final float,MNC varchar(2))

insert into @All_Tests_Tech_YTB
select v.sessionid, v.testid,
	case when v.[% LTE]=1 then 'LTE'
		 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' 
	end as tech,	
	'SC' hasCA,
	[Longitud Final],
	[Latitud Final],
	MNC
from Lcc_Data_YOUTUBE v
Where v.collectionname like @Date + '%' + @ciudad + '%' + @Tech
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos
	and v.info like @Info
OPTION (RECOMPILE)


declare @All_Tests as table (sessionid bigint, TestId bigint,Longitud_Final float,Latitud_Final float,MNC varchar(2))
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
select sessionid, testid,Longitud_Final,Latitud_Final,MNC
from @All_Tests_Tech_DL 
where tech like @sheet1 
	and hasCA like @CA
union all
select sessionid, testid,Longitud_Final,Latitud_Final,MNC
from @All_Tests_Tech_UL 
where tech like @sheet1 
	and hasCA like @CA
union all
select sessionid, testid,Longitud_Final,Latitud_Final,MNC
from @All_Tests_Tech_WEB 
where tech like @sheet1 
	and hasCA like @CA
union all
select sessionid, testid,Longitud_Final,Latitud_Final,MNC
from @All_Tests_Tech_YTB 
where tech like @sheet1 
	and hasCA like @CA
OPTION (RECOMPILE)
--select * from @All_Tests
------ Metemos en variables algunos campos calculados ----------------
declare @tests_Info as table (dateMax datetime2(3), medida varchar(256))
insert into @tests_Info
select max(c.endTime),max([master].dbo.fn_lcc_getElement(5, c.collectionname,'_')) from Lcc_Data_HTTPTransfer_DL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId
union all
select max(c.endTime),max([master].dbo.fn_lcc_getElement(5, c.collectionname,'_')) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId
union all
select max(c.endTime),max([master].dbo.fn_lcc_getElement(5, c.collectionname,'_')) from Lcc_Data_HTTPBrowser c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId
union all
select max(c.endTime),max([master].dbo.fn_lcc_getElement(5, c.collectionname,'_')) from Lcc_Data_YOUTUBE c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId
OPTION (RECOMPILE)

declare @dateMax datetime2(3)= (select max(dateMax) from @tests_Info)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))
declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

--declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, endTime)),2) + '_'	 + convert(varchar(256),format(endTime,'MM'))
--	from Lcc_Data_HTTPTransfer_UL where TestId=(select max(c.TestId) from Lcc_Data_HTTPTransfer_UL c, @All_Tests a where a.sessionid=c.sessionid and a.TestId=c.TestId))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from Lcc_Data_HTTPTransfer_DL v, @All_Tests s where s.sessionid=v.sessionid and s.TestId=v.TestId group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max(medida) from @tests_Info)

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
declare @data_All_TCP_LTE  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,	
	[TCP_HandShake_Average_DL] [float] null,
	[TCP_HandShake_Average_UL] [float] null,
	[TCP_HandShake_Average_WEB] [float] null,
	[TCP_HandShake_Average_YTB] [float] null,
	[TCP_HandShake_Average_Count_DL] [bigint] null,
	[TCP_HandShake_Average_Count_UL] [bigint] null,
	[TCP_HandShake_Average_Count_WEB] [bigint] null,
	[TCP_HandShake_Average_Count_YTB] [bigint] null,
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
	insert into @data_All_TCP_LTE
	select  
		db_name() as 'Database',
		a.mnc,
		master.dbo.fn_lcc_getParcel(a.[Longitud_Final],a.[Latitud_Final]) as Parcel,
		
		sum(dl.TCP_HandShake_Average) as [TCP_HandShake_Average_DL],
		sum(ul.TCP_HandShake_Average) as [TCP_HandShake_Average_UL],
		sum(web.TCP_HandShake_Average) as [TCP_HandShake_Average_WEB],
		sum(ytb.TCP_HandShake_Average) as [TCP_HandShake_Average_YTB],
		sum(case when dl.TCP_HandShake_Average is not null then 1 else 0 end) as [TCP_HandShake_Average_Count_DL],
		sum(case when ul.TCP_HandShake_Average is not null then 1 else 0 end) as [TCP_HandShake_Average_Count_UL],
		sum(case when web.TCP_HandShake_Average is not null then 1 else 0 end) as [TCP_HandShake_Average_Count_WEB],
		sum(case when ytb.TCP_HandShake_Average is not null then 1 else 0 end) as [TCP_HandShake_Average_Count_YTB],
		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'Collection Name',
		lp.Region_OSP as Region_OSP

	from 
		TestInfo t,
		@All_Tests a
		LEFT OUTER JOIN Lcc_Data_HTTPTransfer_DL dl		on dl.sessionid=a.sessionid and dl.testid=a.testid
		LEFT OUTER JOIN Lcc_Data_HTTPTransfer_UL ul		on ul.sessionid=a.sessionid and ul.testid=a.testid
		LEFT OUTER JOIN Lcc_Data_HTTPBrowser web	on web.sessionid=a.sessionid and web.testid=a.testid		
		LEFT OUTER JOIN Lcc_Data_YOUTUBE ytb	on ytb.sessionid=a.sessionid and ytb.testid=a.testid,
		Agrids.dbo.lcc_parcelas lp
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
		and lp.Nombre= master.dbo.fn_lcc_getParcel(a.[Longitud_Final],a.[Latitud_Final]) 
	group by master.dbo.fn_lcc_getParcel(a.[Longitud_Final],a.[Latitud_Final]), a.MNC,lp.Region_VF,lp.Region_OSP
	OPTION (RECOMPILE)
end 
else
begin
	insert into @data_All_TCP_LTE
	select  
		db_name() as 'Database',
		a.mnc,
		null as Parcel,

		sum(dl.TCP_HandShake_Average) as [TCP_HandShake_Average_DL],
		sum(ul.TCP_HandShake_Average) as [TCP_HandShake_Average_UL],
		sum(web.TCP_HandShake_Average) as [TCP_HandShake_Average_WEB],
		sum(ytb.TCP_HandShake_Average) as [TCP_HandShake_Average_YTB],
		sum(case when dl.TCP_HandShake_Average is not null then 1 else 0 end) as [TCP_HandShake_Average_Count_DL],
		sum(case when ul.TCP_HandShake_Average is not null then 1 else 0 end) as [TCP_HandShake_Average_Count_UL],
		sum(case when web.TCP_HandShake_Average is not null then 1 else 0 end) as [TCP_HandShake_Average_Count_WEB],
		sum(case when ytb.TCP_HandShake_Average is not null then 1 else 0 end) as [TCP_HandShake_Average_Count_YTB],

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
		@All_Tests a
		LEFT OUTER JOIN Lcc_Data_HTTPTransfer_DL dl		on dl.sessionid=a.sessionid and dl.testid=a.testid
		LEFT OUTER JOIN Lcc_Data_HTTPTransfer_UL ul		on ul.sessionid=a.sessionid and ul.testid=a.testid
		LEFT OUTER JOIN Lcc_Data_HTTPBrowser web	on web.sessionid=a.sessionid and web.testid=a.testid		
		LEFT OUTER JOIN Lcc_Data_YOUTUBE ytb	on ytb.sessionid=a.sessionid and ytb.testid=a.testid
	where	
		a.Sessionid=t.Sessionid and a.TestId=t.TestId
		and t.valid=1
	group by a.MNC
	OPTION (RECOMPILE)
end


select * from @data_All_TCP_LTE

