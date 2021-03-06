USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_mallado_4G]    Script Date: 31/10/2017 10:30:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_mallado_4G] (
	 --Variables de entrada
		@mob1 as varchar(256),
		@mob2 as varchar(256),
		@mob3 as varchar(256),
		@ciudad as varchar(256),
		@simOperator as int,
		@sheet as varchar(256),				-- all: %%, 4G: 'LTE', 3G: 'WCDMA'
		@fecha_ini_text1 as varchar(256),
		@fecha_fin_text1 as varchar (256),
		@fecha_ini_text2 as varchar(256),
		@fecha_fin_text2 as varchar (256),
		@fecha_ini_text3 as varchar(256),
		@fecha_fin_text3 as varchar (256),
		@fecha_ini_text4 as varchar(256),
		@fecha_fin_text4 as varchar (256),
		@fecha_ini_text5 as varchar(256),
		@fecha_fin_text5 as varchar (256),
		@fecha_ini_text6 as varchar(256),
		@fecha_fin_text6 as varchar (256),
		@fecha_ini_text7 as varchar(256),
		@fecha_fin_text7 as varchar (256),
		@fecha_ini_text8 as varchar(256),
		@fecha_fin_text8 as varchar (256),
		@fecha_ini_text9 as varchar(256),
		@fecha_fin_text9 as varchar (256),
		@fecha_ini_text10 as varchar(256),
		@fecha_fin_text10 as varchar (256),
		@Date as varchar (256),
		@Indoor as int,
		@Report as varchar (256)
)
AS

-----------------------------
----- Testing Variables -----
-----------------------------
--declare @ciudad as varchar(256) = 'RUBI'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @sheet as varchar(256) ='%%'
--declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)

-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests as table (sessionid bigint)
declare @operator as varchar(256)

set @operator = convert(varchar,@simOperator)

insert into @All_Tests
exec ('select v.sessionid
from lcc_Calls_Detailed v
Where v.collectionname like '''+ @Date + '%' + @ciudad + '%' +'''
	and v.MNC = '+ @operator +'	--MNC
	and v.MCC= 214				--MCC - Descartamos los valores erróneos
	and callStatus in (''Completed'',''Failed'',''Dropped'')
	')

------ Metemos en variables algunos campos calculados ----------------

declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

declare @dateMax datetime2(3)= (select max(c.callEndTimeStamp) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from lcc_calls_detailed v, @All_Tests s where s.sessionid=v.sessionid group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max([master].dbo.fn_lcc_getElement(5, v.collectionname,'_')) from lcc_calls_detailed v, @All_Tests s where s.sessionid=v.sessionid)-- group by [master].dbo.fn_lcc_getElement(5, v.collectionname,'_'))

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
------------------------------------------------------------------------------------
------------------------------- GENERAL SELECT
------------- Calls Related Main Info, Samples per Tech and Codec
------------------------------------------------------------------------------------
declare @voice_calls  as table (
	[Database] nvarchar(128)
	, Parcel varchar(50) 
	, mnc varchar(2)
	, position_count int
	, [Meas_Week] [varchar](3) NULL
	, Meas_Round varchar(256)
	, Meas_Date varchar(256)
	, Entidad varchar(256)
	, Region varchar(256)
	, Num_Medida varchar(256)
	,[Report_Type] [varchar](256) null
	,[Aggr_Type] [varchar](256) null
)

if @Indoor=0
begin
	insert into @voice_calls 
	select 
		db_name() as 'Database',
		master.dbo.fn_lcc_getParcel(v.longitude, v.latitude) as Parcel,
		@operator,
		count(v.sessionid),
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.region as Region,
		null,
		@Report,
		'Collection Name'
	from 
		@All_Tests a,
		lcc_position v,
		Sessions s,
		Agrids.dbo.lcc_parcelas lp

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and s.valid=1
		and lp.Nombre= master.dbo.fn_lcc_getParcel(v.longitude, v.latitude)

	group by master.dbo.fn_lcc_getParcel(v.longitude, v.latitude), lp.region	
end
else
begin
	insert into @voice_calls
	select distinct
		db_name() as 'Database',
		null,
		@operator,
		null,		
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'Collection Name'
	from 
		@All_Tests a,
		lcc_position v,
		Sessions s

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and s.valid=1

end

select * from @voice_calls

