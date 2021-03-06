USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Causas_Caidas]    Script Date: 29/05/2017 13:12:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_Causas_Caidas] (
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


--declare @ciudad as varchar(256) = 'A_ELCHE'
--declare @simOperator as int = 1
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 1 -- O = False, 1 = True
--declare @sheet as varchar(256) ='WCDMA'

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
declare @All_Tests as table (sessionid bigint)
declare @filtroTech as varchar(1024)  
declare @operator as varchar(256)

if @sheet = '%%'
	set @filtroTech = ''

else if @sheet = 'LTE'
	--set @filtroTech = 'and (v.technology = ''LTE'' or v.is_csfb=1)'
	if @Indoor = 0
		set @filtroTech = 'and ((v.is_csfb=2 or (v.is_VOLTE > 0 and v.is_CSFB<2))
		                   or (v.callstatus=''Failed'' and (((v.is_csfb in (0,1) and v.is_volte in (0,1)) and ((v.csfb_device=''A'' and v.technology_Bside=''LTE'') or (v.csfb_device=''B'' and v.technology=''LTE''))) or (v.is_csfb=0 and v.is_volte=0 and v.technology_Bside=''LTE'' and v.technology=''LTE''))))'
		--set @filtroTech = 'and (v.is_csfb=2 or (v.is_VOLTE > 0 and v.is_CSFB<2))'
	
	else
		set @filtroTech = 'and ((v.is_csfb>0 or v.is_VOLTE>0)
							or (v.callstatus=''Failed'' and (v.is_csfb=0 and v.is_VOLTE=0) and v.technology=''LTE''))'
		--set @filtroTech = 'and (v.is_csfb>0 or v.is_VOLTE>0)'
		
else if @sheet = 'WCDMA'
	--set @filtroTech = 'and v.technology <> ''LTE'' and v.is_csfb=0'
	if @Indoor = 0
		set @filtroTech = 'and (v.is_CSFB=0 and (v.technology <> ''LTE'' and v.technology_BSide <> ''LTE'') and v.is_VOLTE = 0)'
	else 
		set @filtroTech = 'and (v.is_CSFB=0 and (v.technology <> ''LTE'') and v.is_VOLTE = 0)'

set @operator = convert(varchar,@simOperator)

insert into @All_Tests
exec ('select v.sessionid
from lcc_Calls_Detailed v
Where v.collectionname like '''+ @Date + '%' + @ciudad + '%' +'''
	and v.MNC = '+ @operator +'	--MNC
	and v.MCC= 214				--MCC - Descartamos los valores erróneos
	and callStatus in (''Completed'',''Failed'',''Dropped'')
	'+	@filtroTech)


------ Metemos en variables algunos campos calculados ----------------

declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

declare @dateMax datetime2(3)= (select max(c.callEndTimeStamp) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)
declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, @dateMax)),2) + '_'	 + convert(varchar(256),format(@dateMax,'MM')))

--declare @Meas_Date as varchar(256)= (select max(right(convert(varchar(256),datepart(yy, callendtimestamp)),2) + '_'	 + convert(varchar(256),format(callendtimestamp,'MM')))
--	from lcc_Calls_Detailed where sessionid=(select max(c.sessionid) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid))

declare @entidad as varchar(256) = (select [master].dbo.fn_lcc_getElement(4, v.collectionname,'_') from lcc_calls_detailed v, @All_Tests s where s.sessionid=v.sessionid group by [master].dbo.fn_lcc_getElement(4, v.collectionname,'_'))
declare @medida as varchar(256) = (select max([master].dbo.fn_lcc_getElement(5, v.collectionname,'_')) from lcc_calls_detailed v, @All_Tests s where s.sessionid=v.sessionid)-- group by [master].dbo.fn_lcc_getElement(5, v.collectionname,'_'))

declare @week as varchar(256)
declare @tmpDateFirst int 
declare @tmpWeek int 

--select @tmpDateFirst = @@DATEFIRST
--if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
--	SELECT @tmpWeek =DATEPART(week, (select callendtimestamp
--						from lcc_Calls_Detailed 
--						where sessionid=(select max(c.sessionid) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)))
--else
--	begin
--		SET DATEFIRST 1;  --Primer dia de la semana lunes
--		SELECT @tmpWeek =DATEPART(week, (select callendtimestamp
--						from lcc_Calls_Detailed 
--						where sessionid=(select max(c.sessionid) from lcc_Calls_Detailed c, @All_Tests a where a.sessionid=c.sessionid)))
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
------------------------------------------------------------------------------------
------------------------------- GENERAL SELECT
-------------------- Drop Calls Disaggregated by drop type
------------------------------------------------------------------------------------
declare @voice_causeDrop  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[MO_Dropped, Call Re-Establishment attempt] [int] NULL,
	[MO_Dropped, Disconnect received] [int] NULL,
	[MO_Dropped, Disconnect sent] [int] NULL,
	[MO_Dropped, Failed Handover] [int] NULL,
	[MO_Dropped, Handover uncompleted] [int] NULL,
	[MO_Dropped, High BLER] [int] NULL,
	[MO_Dropped, High RxQual] [int] NULL,
	[MO_Dropped, Low Total Ec/Io] [int] NULL,
	[MO_Dropped, Low RxLev] [int] NULL,
	[MO_Dropped, Low UE Rx Power] [int] NULL,
	[MO_Dropped, others] [int] NULL,
	[MO_Dropped, Radio Link Timeout] [int] NULL,
	[MO_Dropped, RRCConnectionRelease received] [int] NULL,
	[MT_Dropped, Call Re-Establishment attempt] [int] NULL,
	[MT_Dropped, Disconnect received] [int] NULL,
	[MT_Dropped, Disconnect sent] [int] NULL,
	[MT_Dropped, Failed Handover] [int] NULL,
	[MT_Dropped, Handover uncompleted] [int] NULL,
	[MT_Dropped, High BLER] [int] NULL,
	[MT_Dropped, High RxQual] [int] NULL,
	[MT_Dropped, Low Total Ec/Io] [int] NULL,
	[MT_Dropped, Low RxLev] [int] NULL,
	[MT_Dropped, Low UE Rx Power] [int] NULL,
	[MT_Dropped, others] [int] NULL,
	[MT_Dropped, Radio Link Timeout] [int] NULL,
	[MT_Dropped, RRCConnectionRelease received] [int] NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF] [varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP] [varchar](256) NULL
)

if (@Indoor=0 OR @Indoor=2)
begin
	insert into @voice_causeDrop 
	select 
		db_name() as 'Database',
		v.mnc,
		[master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A) as Parcel,
		sum (case when (v.callDir='MO'and v.callStatus like '%Call%Re-Establishment%') then 1 else 0 end) as 'MO_Dropped, Call Re-Establishment attempt',
		SUM (case when (v.callDir='MO'and v.callStatus like '%Disconnect%received%') then 1 else 0 end) as 'MO_Dropped, Disconnect received',
		SUM (case when (v.callDir='MO'and v.callStatus like '%Disconnect%sent%') then 1 else 0 end) as 'MO_Dropped, Disconnect sent',
		sum (case when (v.callDir='MO'and v.callStatus like '%Failed%Handover%') then 1 else 0 end) as 'MO_Dropped, Failed Handover',
		sum (case when (v.callDir='MO'and v.callStatus like '%Handover%uncompleted%') then 1 else 0 end) as 'MO_Dropped, Handover uncompleted',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, High BLER%') then 1 else 0 end) as 'MO_Dropped, High BLER',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, High RxQual%') then 1 else 0 end) as 'MO_Dropped, High RxQual',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low Total Ec/Io%') then 1 else 0 end) as 'MO_Dropped, Low Total Ec/Io',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low RxLev%') then 1 else 0 end) as 'MO_Dropped, Low RxLev',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low UE Rx Power%') then 1 else 0 end) as 'MO_Dropped, Low UE Rx Power',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, others%') then 1 else 0 end) as 'MO_Dropped, others',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Radio Link Timeout%') then 1 else 0 end) as 'MO_Dropped, Radio Link Timeout',
		sum (case when (v.callDir='MO'and v.callStatus like 'RRCConnectionRelease%received%') then 1 else 0 end) as 'MO_Dropped, RRCConnectionRelease received',
		sum (case when (v.callDir='MT'and v.callStatus like '%Call%Re-Establishment%') then 1 else 0 end) as 'MT_Dropped, Call Re-Establishment attempt',
		SUM (case when (v.callDir='MT'and v.callStatus like '%Disconnect%received%') then 1 else 0 end) as 'MT_Dropped, Disconnect received',
		SUM (case when (v.callDir='MT'and v.callStatus like '%Disconnect%sent%') then 1 else 0 end) as 'MT_Dropped, Disconnect sent',
		sum (case when (v.callDir='MT'and v.callStatus like '%Failed%Handover%') then 1 else 0 end) as 'MT_Dropped, Failed Handover',
		sum (case when (v.callDir='MT'and v.callStatus like '%Handover%uncompleted%') then 1 else 0 end) as 'MT_Dropped, Handover uncompleted',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, High BLER%') then 1 else 0 end) as 'MT_Dropped, High BLER',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, High RxQual%') then 1 else 0 end) as 'MT_Dropped, High RxQual',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low Total Ec/Io%') then 1 else 0 end) as 'MT_Dropped, Low Total Ec/Io',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low RxLev%') then 1 else 0 end) as 'MT_Dropped, Low RxLev',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low UE Rx Power%') then 1 else 0 end) as 'MT_Dropped, Low UE Rx Power',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, others%') then 1 else 0 end) as 'MT_Dropped, others',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Radio Link Timeout%') then 1 else 0 end) as 'MT_Dropped, Radio Link Timeout',
		sum (case when (v.callDir='MT'and v.callStatus like 'RRCConnectionRelease%received%') then 1 else 0 end) as 'MT_Dropped, RRCConnectionRelease received',
		
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
		@All_Tests a,
		lcc_Calls_Detailed v,
		Sessions s,
		Agrids.dbo.lcc_parcelas lp

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus = 'Dropped' -- Only Drop Calls
		and s.valid=1
		and lp.Nombre= [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A)
	group by [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A), v.mnc,lp.Region_VF,lp.Region_OSP

end
else
begin
	insert into @voice_causeDrop 
	select 
		db_name() as 'Database',
		v.mnc,
		null,
		sum (case when (v.callDir='MO'and v.callStatus like '%Call%Re-Establishment%') then 1 else 0 end) as 'MO_Dropped, Call Re-Establishment attempt',
		SUM (case when (v.callDir='MO'and v.callStatus like '%Disconnect%received%') then 1 else 0 end) as 'MO_Dropped, Disconnect received',
		SUM (case when (v.callDir='MO'and v.callStatus like '%Disconnect%sent%') then 1 else 0 end) as 'MO_Dropped, Disconnect sent',
		sum (case when (v.callDir='MO'and v.callStatus like '%Failed%Handover%') then 1 else 0 end) as 'MO_Dropped, Failed Handover',
		sum (case when (v.callDir='MO'and v.callStatus like '%Handover%uncompleted%') then 1 else 0 end) as 'MO_Dropped, Handover uncompleted',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, High BLER%') then 1 else 0 end) as 'MO_Dropped, High BLER',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, High RxQual%') then 1 else 0 end) as 'MO_Dropped, High RxQual',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low Total Ec/Io%') then 1 else 0 end) as 'MO_Dropped, Low Total Ec/Io',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low RxLev%') then 1 else 0 end) as 'MO_Dropped, Low RxLev',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, Low UE Rx Power%') then 1 else 0 end) as 'MO_Dropped, Low UE Rx Power',
		SUM (case when (v.callDir='MO'and v.callStatus like 'Dropped, others%') then 1 else 0 end) as 'MO_Dropped, others',
		sum (case when (v.callDir='MO'and v.callStatus like 'Dropped, Radio Link Timeout%') then 1 else 0 end) as 'MO_Dropped, Radio Link Timeout',
		sum (case when (v.callDir='MO'and v.callStatus like 'RRCConnectionRelease%received%') then 1 else 0 end) as 'MO_Dropped, RRCConnectionRelease received',
		sum (case when (v.callDir='MT'and v.callStatus like '%Call%Re-Establishment%') then 1 else 0 end) as 'MT_Dropped, Call Re-Establishment attempt',
		SUM (case when (v.callDir='MT'and v.callStatus like '%Disconnect%received%') then 1 else 0 end) as 'MT_Dropped, Disconnect received',
		SUM (case when (v.callDir='MT'and v.callStatus like '%Disconnect%sent%') then 1 else 0 end) as 'MT_Dropped, Disconnect sent',
		sum (case when (v.callDir='MT'and v.callStatus like '%Failed%Handover%') then 1 else 0 end) as 'MT_Dropped, Failed Handover',
		sum (case when (v.callDir='MT'and v.callStatus like '%Handover%uncompleted%') then 1 else 0 end) as 'MT_Dropped, Handover uncompleted',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, High BLER%') then 1 else 0 end) as 'MT_Dropped, High BLER',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, High RxQual%') then 1 else 0 end) as 'MT_Dropped, High RxQual',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low Total Ec/Io%') then 1 else 0 end) as 'MT_Dropped, Low Total Ec/Io',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low RxLev%') then 1 else 0 end) as 'MT_Dropped, Low RxLev',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, Low UE Rx Power%') then 1 else 0 end) as 'MT_Dropped, Low UE Rx Power',
		SUM (case when (v.callDir='MT'and v.callStatus like 'Dropped, others%') then 1 else 0 end) as 'MT_Dropped, others',
		sum (case when (v.callDir='MT'and v.callStatus like 'Dropped, Radio Link Timeout%') then 1 else 0 end) as 'MT_Dropped, Radio Link Timeout',
		sum (case when (v.callDir='MT'and v.callStatus like 'RRCConnectionRelease%received%') then 1 else 0 end) as 'MT_Dropped, RRCConnectionRelease received',
		
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
		@All_Tests a,
		lcc_Calls_Detailed v,
		Sessions s

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus = 'Dropped' -- Only Drop Calls
		and s.valid=1

	group by v.mnc
end


select * from @voice_causeDrop
