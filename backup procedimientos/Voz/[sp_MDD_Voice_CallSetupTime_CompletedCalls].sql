USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_CallSetupTime_CompletedCalls]    Script Date: 29/05/2017 13:10:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_CallSetupTime_CompletedCalls] (
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


--declare @ciudad as varchar(256) = 'laredo'
--declare @simOperator as int = 4
--declare @date as varchar(256) = ''
--declare @Indoor as bit = 1 -- O = False, 1 = True
--declare @sheet as varchar(256) ='%%'

---------------------------
--- Date Declarations -----
---------------------------
	
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
declare @All_Tests as table (sessionid bigint, is_VoLTE int, is_SRVCC int)
declare @filtroTech as varchar(1024)  
declare @operator as varchar(256)

if @sheet = '%%'
	set @filtroTech = ''

else if @sheet = 'LTE' or @sheet = 'VOLTE'
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
exec ('select v.sessionid, v.is_VOLTE, v.is_SRVCC
from lcc_Calls_Detailed v
Where v.collectionname like '''+ @Date + '%' + @ciudad + '%' +'''
	and v.MNC = '+ @operator +'	--MNC
	and v.MCC= 214				--MCC - Descartamos los valores erróneos
	and callStatus <> ''System Release''
	and callStatus in (''Completed'',''Failed'',''Dropped'')
	'+	@filtroTech+'
	group by v.sessionid, v.is_VOLTE, v.is_SRVCC')


if @sheet = 'VOLTE'
begin
	delete from @All_Tests where (is_VoLTE is NULL or is_VoLTE<>2 or (is_volte=2 and is_SRVCC>0))
end

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
---------------------- Call Setup Time Disaggregated Info
------------------------------------------------------------------------------------
declare @voice_cst  as table (
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](2) NULL,
	[Parcel] [varchar](50) NULL,
	[MO_CallType] [int] NULL,
	[MT_CallType] [int] NULL,
	[Calls_AVG_ALERT_MO] [int] NULL,
	[Calls_AVG_ALERT_MT] [int] NULL,
	[Calls_AVG_CONNECT_MO] [int] NULL,
	[Calls_AVG_CONNECT_MT] [int] NULL,
	[CST_MO_Alerting] [float] NULL,
	[CST_MT_Alerting] [float] NULL,
	[CST_MOMT_Alerting] [float] NULL,
	[CST_MO_Connect] [float] NULL,
	[CST_MT_Connect] [float] NULL,
	[CST_MOMT_Connect] [float] NULL,
	[ 0-0.5 MO_Alert] [int] NULL,
	[ 0.5-1 MO_Alert] [int] NULL,
	[ 1-1.5 MO_Alert] [int] NULL,
	[ 1.5-2 MO_Alert] [int] NULL,
	[ 2-2.5 MO_Alert] [int] NULL,
	[ 2.5-3 MO_Alert] [int] NULL,
	[ 3-3.5 MO_Alert] [int] NULL,
	[ 3.5-4 MO_Alert] [int] NULL,
	[ 4-4.5 MO_Alert] [int] NULL,
	[ 4.5-5 MO_Alert] [int] NULL,
	[ 5-5.5 MO_Alert] [int] NULL,
	[ 5.5-6 MO_Alert] [int] NULL,
	[ 6-6.5 MO_Alert] [int] NULL,
	[ 6.5-7 MO_Alert] [int] NULL,
	[ 7-7.5 MO_Alert] [int] NULL,
	[ 7.5-8 MO_Alert] [int] NULL,
	[ 8-8.5 MO_Alert] [int] NULL,
	[ 8.5-9 MO_Alert] [int] NULL,
	[ 9-9.5 MO_Alert] [int] NULL,
	[ 9.5-10 MO_Alert] [int] NULL,
	[ 10-10.5 MO_Alert] [int] NULL,
	[ 10.5-11 MO_Alert] [int] NULL,
	[ 11-11.5 MO_Alert] [int] NULL,
	[ 11.5-12 MO_Alert] [int] NULL,
	[ 12-12.5 MO_Alert] [int] NULL,
	[ 12.5-13 MO_Alert] [int] NULL,
	[ 13-13.5 MO_Alert] [int] NULL,
	[ 13.5-14 MO_Alert] [int] NULL,
	[ 14-14.5 MO_Alert] [int] NULL,
	[ 14.5-15 MO_Alert] [int] NULL,
	[ 15-15.5 MO_Alert] [int] NULL,
	[ 15.5-16 MO_Alert] [int] NULL,
	[ 16-16.5 MO_Alert] [int] NULL,
	[ 16.5-17 MO_Alert] [int] NULL,
	[ 17-17.5 MO_Alert] [int] NULL,
	[ 17.5-18 MO_Alert] [int] NULL,
	[ 18-18.5 MO_Alert] [int] NULL,
	[ 18.5-19 MO_Alert] [int] NULL,
	[ 19-19.5 MO_Alert] [int] NULL,
	[ 19.5-20 MO_Alert] [int] NULL,
	[ >20 MO_Alert] [int] NULL,
	[ 0-0.5 MT_Alert] [int] NULL,
	[ 0.5-1 MT_Alert] [int] NULL,
	[ 1-1.5 MT_Alert] [int] NULL,
	[ 1.5-2 MT_Alert] [int] NULL,
	[ 2-2.5 MT_Alert] [int] NULL,
	[ 2.5-3 MT_Alert] [int] NULL,
	[ 3-3.5 MT_Alert] [int] NULL,
	[ 3.5-4 MT_Alert] [int] NULL,
	[ 4-4.5 MT_Alert] [int] NULL,
	[ 4.5-5 MT_Alert] [int] NULL,
	[ 5-5.5 MT_Alert] [int] NULL,
	[ 5.5-6 MT_Alert] [int] NULL,
	[ 6-6.5 MT_Alert] [int] NULL,
	[ 6.5-7 MT_Alert] [int] NULL,
	[ 7-7.5 MT_Alert] [int] NULL,
	[ 7.5-8 MT_Alert] [int] NULL,
	[ 8-8.5 MT_Alert] [int] NULL,
	[ 8.5-9 MT_Alert] [int] NULL,
	[ 9-9.5 MT_Alert] [int] NULL,
	[ 9.5-10 MT_Alert] [int] NULL,
	[ 10-10.5 MT_Alert] [int] NULL,
	[ 10.5-11 MT_Alert] [int] NULL,
	[ 11-11.5 MT_Alert] [int] NULL,
	[ 11.5-12 MT_Alert] [int] NULL,
	[ 12-12.5 MT_Alert] [int] NULL,
	[ 12.5-13 MT_Alert] [int] NULL,
	[ 13-13.5 MT_Alert] [int] NULL,
	[ 13.5-14 MT_Alert] [int] NULL,
	[ 14-14.5 MT_Alert] [int] NULL,
	[ 14.5-15 MT_Alert] [int] NULL,		
	[ 15-15.5 MT_Alert] [int] NULL,	
	[ 15.5-16 MT_Alert] [int] NULL,	
	[ 16-16.5 MT_Alert] [int] NULL,	
	[ 16.5-17 MT_Alert] [int] NULL,	
	[ 17-17.5 MT_Alert] [int] NULL,	
	[ 17.5-18 MT_Alert] [int] NULL,	
	[ 18-18.5 MT_Alert] [int] NULL,	
	[ 18.5-19 MT_Alert] [int] NULL,	
	[ 19-19.5 MT_Alert] [int] NULL,	
	[ 19.5-20 MT_Alert] [int] NULL,	
	[ >20 MT_Alert] [int] NULL,
	[ 0-0.5 MOMT_Alert] [int] NULL,
	[ 0.5-1 MOMT_Alert] [int] NULL,
	[ 1-1.5 MOMT_Alert] [int] NULL,
	[ 1.5-2 MOMT_Alert] [int] NULL,
	[ 2-2.5 MOMT_Alert] [int] NULL,
	[ 2.5-3 MOMT_Alert] [int] NULL,
	[ 3-3.5 MOMT_Alert] [int] NULL,
	[ 3.5-4 MOMT_Alert] [int] NULL,
	[ 4-4.5 MOMT_Alert] [int] NULL,
	[ 4.5-5 MOMT_Alert] [int] NULL,
	[ 5-5.5 MOMT_Alert] [int] NULL,
	[ 5.5-6 MOMT_Alert] [int] NULL,
	[ 6-6.5 MOMT_Alert] [int] NULL,
	[ 6.5-7 MOMT_Alert] [int] NULL,
	[ 7-7.5 MOMT_Alert] [int] NULL,
	[ 7.5-8 MOMT_Alert] [int] NULL,
	[ 8-8.5 MOMT_Alert] [int] NULL,
	[ 8.5-9 MOMT_Alert] [int] NULL,
	[ 9-9.5 MOMT_Alert] [int] NULL,
	[ 9.5-10 MOMT_Alert] [int] NULL,
	[ 10-10.5 MOMT_Alert] [int] NULL,
	[ 10.5-11 MOMT_Alert] [int] NULL,
	[ 11-11.5 MOMT_Alert] [int] NULL,
	[ 11.5-12 MOMT_Alert] [int] NULL,
	[ 12-12.5 MOMT_Alert] [int] NULL,
	[ 12.5-13 MOMT_Alert] [int] NULL,
	[ 13-13.5 MOMT_Alert] [int] NULL,
	[ 13.5-14 MOMT_Alert] [int] NULL,
	[ 14-14.5 MOMT_Alert] [int] NULL,
	[ 14.5-15 MOMT_Alert] [int] NULL,
	[ 15-15.5 MOMT_Alert] [int] NULL,
	[ 15.5-16 MOMT_Alert] [int] NULL,
	[ 16-16.5 MOMT_Alert] [int] NULL,
	[ 16.5-17 MOMT_Alert] [int] NULL,
	[ 17-17.5 MOMT_Alert] [int] NULL,
	[ 17.5-18 MOMT_Alert] [int] NULL,
	[ 18-18.5 MOMT_Alert] [int] NULL,
	[ 18.5-19 MOMT_Alert] [int] NULL,
	[ 19-19.5 MOMT_Alert] [int] NULL,
	[ 19.5-20 MOMT_Alert] [int] NULL,
	[ >20 MOMT_Alert] [int] NULL,
	[ 0-0.5 MO_Conn] [int] NULL,
	[ 0.5-1 MO_Conn] [int] NULL,
	[ 1-1.5 MO_Conn] [int] NULL,
	[ 1.5-2 MO_Conn] [int] NULL,
	[ 2-2.5 MO_Conn] [int] NULL,
	[ 2.5-3 MO_Conn] [int] NULL,
	[ 3-3.5 MO_Conn] [int] NULL,
	[ 3.5-4 MO_Conn] [int] NULL,
	[ 4-4.5 MO_Conn] [int] NULL,
	[ 4.5-5 MO_Conn] [int] NULL,
	[ 5-5.5 MO_Conn] [int] NULL,
	[ 5.5-6 MO_Conn] [int] NULL,
	[ 6-6.5 MO_Conn] [int] NULL,
	[ 6.5-7 MO_Conn] [int] NULL,
	[ 7-7.5 MO_Conn] [int] NULL,
	[ 7.5-8 MO_Conn] [int] NULL,
	[ 8-8.5 MO_Conn] [int] NULL,
	[ 8.5-9 MO_Conn] [int] NULL,
	[ 9-9.5 MO_Conn] [int] NULL,
	[ 9.5-10 MO_Conn] [int] NULL,
	[ 10-10.5 MO_Conn] [int] NULL,
	[ 10.5-11 MO_Conn] [int] NULL,
	[ 11-11.5 MO_Conn] [int] NULL,
	[ 11.5-12 MO_Conn] [int] NULL,
	[ 12-12.5 MO_Conn] [int] NULL,
	[ 12.5-13 MO_Conn] [int] NULL,
	[ 13-13.5 MO_Conn] [int] NULL,
	[ 13.5-14 MO_Conn] [int] NULL,
	[ 14-14.5 MO_Conn] [int] NULL,
	[ 14.5-15 MO_Conn] [int] NULL,	
	[ 15-15.5 MO_Conn] [int] NULL,
	[ 15.5-16 MO_Conn] [int] NULL,
	[ 16-16.5 MO_Conn] [int] NULL,
	[ 16.5-17 MO_Conn] [int] NULL,
	[ 17-17.5 MO_Conn] [int] NULL,
	[ 17.5-18 MO_Conn] [int] NULL,
	[ 18-18.5 MO_Conn] [int] NULL,
	[ 18.5-19 MO_Conn] [int] NULL,
	[ 19-19.5 MO_Conn] [int] NULL,
	[ 19.5-20 MO_Conn] [int] NULL,
	[ >20 MO_Conn] [int] NULL,
	[ 0-0.5 MT_Conn] [int] NULL,
	[ 0.5-1 MT_Conn] [int] NULL,
	[ 1-1.5 MT_Conn] [int] NULL,
	[ 1.5-2 MT_Conn] [int] NULL,
	[ 2-2.5 MT_Conn] [int] NULL,
	[ 2.5-3 MT_Conn] [int] NULL,
	[ 3-3.5 MT_Conn] [int] NULL,
	[ 3.5-4 MT_Conn] [int] NULL,
	[ 4-4.5 MT_Conn] [int] NULL,
	[ 4.5-5 MT_Conn] [int] NULL,
	[ 5-5.5 MT_Conn] [int] NULL,
	[ 5.5-6 MT_Conn] [int] NULL,
	[ 6-6.5 MT_Conn] [int] NULL,
	[ 6.5-7 MT_Conn] [int] NULL,
	[ 7-7.5 MT_Conn] [int] NULL,
	[ 7.5-8 MT_Conn] [int] NULL,
	[ 8-8.5 MT_Conn] [int] NULL,
	[ 8.5-9 MT_Conn] [int] NULL,
	[ 9-9.5 MT_Conn] [int] NULL,
	[ 9.5-10 MT_Conn] [int] NULL,
	[ 10-10.5 MT_Conn] [int] NULL,
	[ 10.5-11 MT_Conn] [int] NULL,
	[ 11-11.5 MT_Conn] [int] NULL,
	[ 11.5-12 MT_Conn] [int] NULL,
	[ 12-12.5 MT_Conn] [int] NULL,
	[ 12.5-13 MT_Conn] [int] NULL,
	[ 13-13.5 MT_Conn] [int] NULL,
	[ 13.5-14 MT_Conn] [int] NULL,
	[ 14-14.5 MT_Conn] [int] NULL,
	[ 14.5-15 MT_Conn] [int] NULL,	
	[ 15-15.5 MT_Conn] [int] NULL,	
	[ 15.5-16 MT_Conn] [int] NULL,	
	[ 16-16.5 MT_Conn] [int] NULL,	
	[ 16.5-17 MT_Conn] [int] NULL,	
	[ 17-17.5 MT_Conn] [int] NULL,	
	[ 17.5-18 MT_Conn] [int] NULL,	
	[ 18-18.5 MT_Conn] [int] NULL,	
	[ 18.5-19 MT_Conn] [int] NULL,	
	[ 19-19.5 MT_Conn] [int] NULL,	
	[ 19.5-20 MT_Conn] [int] NULL,	
	[ >20 MT_Conn] [int] NULL,
	[ 0-0.5 MOMT_Conn] [int] NULL,
	[ 0.5-1 MOMT_Conn] [int] NULL,
	[ 1-1.5 MOMT_Conn] [int] NULL,
	[ 1.5-2 MOMT_Conn] [int] NULL,
	[ 2-2.5 MOMT_Conn] [int] NULL,
	[ 2.5-3 MOMT_Conn] [int] NULL,
	[ 3-3.5 MOMT_Conn] [int] NULL,
	[ 3.5-4 MOMT_Conn] [int] NULL,
	[ 4-4.5 MOMT_Conn] [int] NULL,
	[ 4.5-5 MOMT_Conn] [int] NULL,
	[ 5-5.5 MOMT_Conn] [int] NULL,
	[ 5.5-6 MOMT_Conn] [int] NULL,
	[ 6-6.5 MOMT_Conn] [int] NULL,
	[ 6.5-7 MOMT_Conn] [int] NULL,
	[ 7-7.5 MOMT_Conn] [int] NULL,
	[ 7.5-8 MOMT_Conn] [int] NULL,
	[ 8-8.5 MOMT_Conn] [int] NULL,
	[ 8.5-9 MOMT_Conn] [int] NULL,
	[ 9-9.5 MOMT_Conn] [int] NULL,
	[ 9.5-10 MOMT_Conn] [int] NULL,
	[ 10-10.5 MOMT_Conn] [int] NULL,
	[ 10.5-11 MOMT_Conn] [int] NULL,
	[ 11-11.5 MOMT_Conn] [int] NULL,
	[ 11.5-12 MOMT_Conn] [int] NULL,
	[ 12-12.5 MOMT_Conn] [int] NULL,
	[ 12.5-13 MOMT_Conn] [int] NULL,
	[ 13-13.5 MOMT_Conn] [int] NULL,
	[ 13.5-14 MOMT_Conn] [int] NULL,
	[ 14-14.5 MOMT_Conn] [int] NULL,
	[ 14.5-15 MOMT_Conn] [int] NULL,
	[ 15-15.5 MOMT_Conn] [int] NULL,
	[ 15.5-16 MOMT_Conn] [int] NULL,
	[ 16-16.5 MOMT_Conn] [int] NULL,
	[ 16.5-17 MOMT_Conn] [int] NULL,
	[ 17-17.5 MOMT_Conn] [int] NULL,
	[ 17.5-18 MOMT_Conn] [int] NULL,
	[ 18-18.5 MOMT_Conn] [int] NULL,
	[ 18.5-19 MOMT_Conn] [int] NULL,
	[ 19-19.5 MOMT_Conn] [int] NULL,
	[ 19.5-20 MOMT_Conn] [int] NULL,
	[ >20 MOMT_Conn] [int] NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Region_VF] [varchar](256) NULL,
	[Num_Medida] [int] NULL,
	[Report_Type] [varchar](256) null,
	[Aggr_Type] [varchar](256) null,
	[Region_OSP] [varchar](256) NULL,
	[Calltype] [varchar](256) null,
	[ASideDevice] [varchar](256) NULL,
	[BSideDevice] [varchar](256) NULL,
	[SWVersion] [varchar](256) NULL
)

if (@Indoor=0 OR @Indoor=2)
begin
	insert into @voice_cst
	select
		db_name() as 'Database',
		v.mnc,
		[master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A) as Parcel,
		sum (case when v.callDir='MO' then 1 else 0 end) as MO_CallType,
		sum (case when v.callDir='MT' then 1 else 0 end) as MT_CallType,
		
		sum (case when v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) [Calls_AVG_ALERT_MO],
		sum (case when v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) [Calls_AVG_ALERT_MT],
		sum (case when v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) [Calls_AVG_CONNECT_MO],
		sum (case when v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) [Calls_AVG_CONNECT_MT],
		
		AVG(case when v.callDir = 'MO' then 1.0* v.cst_till_alerting end)/1000.0 as CST_MO_Alerting,
		AVG(case when v.callDir = 'MT' then 1.0* v.cst_till_alerting end)/1000.0 as CST_MT_Alerting,
		AVG(v.cst_till_alerting/1000.0) as CST_MOMT_Alerting,
		AVG(case when v.callDir = 'MO' then 1.0* v.cst_till_connAck end)/1000.0 as CST_MO_Connect,
		AVG(case when v.callDir = 'MT' then 1.0* v.cst_till_connAck end)/1000.0 as CST_MT_Connect,
		AVG(v.cst_till_connAck/1000.0) as CST_MOMT_Connect,

		--Rangos Alerting MO
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 0 and v.cst_till_alerting/1000.0 < 0.5) then 1 else 0 end ) as [ 0-0.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 0.5 and v.cst_till_alerting/1000.0 < 1) then 1 else 0 end ) as [ 0.5-1 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 1 and v.cst_till_alerting/1000.0 < 1.5) then 1 else 0 end ) as [ 1-1.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 1.5 and v.cst_till_alerting/1000.0 < 2) then 1 else 0 end ) as [ 1.5-2 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 2 and v.cst_till_alerting/1000.0 < 2.5) then 1 else 0 end ) as [ 2-2.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 2.5 and v.cst_till_alerting/1000.0 < 3) then 1 else 0 end ) as [ 2.5-3 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 3 and v.cst_till_alerting/1000.0 < 3.5) then 1 else 0 end ) as [ 3-3.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 3.5 and v.cst_till_alerting/1000.0 < 4) then 1 else 0 end ) as [ 3.5-4 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 4 and v.cst_till_alerting/1000.0 < 4.5) then 1 else 0 end ) as [ 4-4.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 4.5 and v.cst_till_alerting/1000.0 < 5) then 1 else 0 end ) as [ 4.5-5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 5 and v.cst_till_alerting/1000.0 < 5.5) then 1 else 0 end ) as [ 5-5.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 5.5 and v.cst_till_alerting/1000.0 < 6) then 1 else 0 end ) as [ 5.5-6 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 6 and v.cst_till_alerting/1000.0 < 6.5) then 1 else 0 end ) as [ 6-6.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 6.5 and v.cst_till_alerting/1000.0 < 7) then 1 else 0 end ) as [ 6.5-7 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 7 and v.cst_till_alerting/1000.0 < 7.5) then 1 else 0 end ) as [ 7-7.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 7.5 and v.cst_till_alerting/1000.0 < 8) then 1 else 0 end ) as [ 7.5-8 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 8 and v.cst_till_alerting/1000.0 < 8.5) then 1 else 0 end ) as [ 8-8.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 8.5 and v.cst_till_alerting/1000.0 < 9) then 1 else 0 end ) as [ 8.5-9 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 9 and v.cst_till_alerting/1000.0 < 9.5) then 1 else 0 end ) as [ 9-9.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 9.5 and v.cst_till_alerting/1000.0 < 10) then 1 else 0 end ) as [ 9.5-10 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 10 and v.cst_till_alerting/1000.0 < 10.5) then 1 else 0 end ) as [ 10-10.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 10.5 and v.cst_till_alerting/1000.0 < 11) then 1 else 0 end ) as [ 10.5-11 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 11 and v.cst_till_alerting/1000.0 < 11.5) then 1 else 0 end ) as [ 11-11.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 11.5 and v.cst_till_alerting/1000.0 < 12) then 1 else 0 end ) as [ 11.5-12 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 12 and v.cst_till_alerting/1000.0 < 12.5) then 1 else 0 end ) as [ 12-12.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 12.5 and v.cst_till_alerting/1000.0 < 13) then 1 else 0 end ) as [ 12.5-13 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 13 and v.cst_till_alerting/1000.0 < 13.5) then 1 else 0 end ) as [ 13-13.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 13.5 and v.cst_till_alerting/1000.0 < 14) then 1 else 0 end ) as [ 13.5-14 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 14 and v.cst_till_alerting/1000.0 < 14.5) then 1 else 0 end ) as [ 14-14.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 14.5 and v.cst_till_alerting/1000.0 < 15) then 1 else 0 end ) as [ 14.5-15 MO_Alert],		
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 15 and v.cst_till_alerting/1000.0 < 15.5) then 1 else 0 end ) as [ 15-15.5 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 15.5 and v.cst_till_alerting/1000.0 < 16) then 1 else 0 end ) as [ 15.5-16 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 16 and v.cst_till_alerting/1000.0 < 16.5) then 1 else 0 end ) as [ 16-16.5 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 16.5 and v.cst_till_alerting/1000.0 < 17) then 1 else 0 end ) as [ 16.5-17 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 17 and v.cst_till_alerting/1000.0 < 17.5) then 1 else 0 end ) as [ 17-17.5 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 17.5 and v.cst_till_alerting/1000.0 < 18) then 1 else 0 end ) as [ 17.5-18 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 18 and v.cst_till_alerting/1000.0 < 18.5) then 1 else 0 end ) as [ 18-18.5 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 18.5 and v.cst_till_alerting/1000.0 < 19) then 1 else 0 end ) as [ 18.5-19 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 19 and v.cst_till_alerting/1000.0 < 19.5) then 1 else 0 end ) as [ 19-19.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 19.5 and v.cst_till_alerting/1000.0 < 20) then 1 else 0 end ) as [ 19.5-20 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 20) then 1 else 0 end ) as [ >20 MO_Alert],
		--Rangos Alerting MT
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 0 and v.cst_till_alerting/1000.0 < 0.5) then 1 else 0 end ) as [ 0-0.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 0.5 and v.cst_till_alerting/1000.0 < 1) then 1 else 0 end ) as [ 0.5-1 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 1 and v.cst_till_alerting/1000.0 < 1.5) then 1 else 0 end ) as [ 1-1.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 1.5 and v.cst_till_alerting/1000.0 < 2) then 1 else 0 end ) as [ 1.5-2 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 2 and v.cst_till_alerting/1000.0 < 2.5) then 1 else 0 end ) as [ 2-2.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 2.5 and v.cst_till_alerting/1000.0 < 3) then 1 else 0 end ) as [ 2.5-3 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 3 and v.cst_till_alerting/1000.0 < 3.5) then 1 else 0 end ) as [ 3-3.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 3.5 and v.cst_till_alerting/1000.0 < 4) then 1 else 0 end ) as [ 3.5-4 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 4 and v.cst_till_alerting/1000.0 < 4.5) then 1 else 0 end ) as [ 4-4.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 4.5 and v.cst_till_alerting/1000.0 < 5) then 1 else 0 end ) as [ 4.5-5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 5 and v.cst_till_alerting/1000.0 < 5.5) then 1 else 0 end ) as [ 5-5.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 5.5 and v.cst_till_alerting/1000.0 < 6) then 1 else 0 end ) as [ 5.5-6 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 6 and v.cst_till_alerting/1000.0 < 6.5) then 1 else 0 end ) as [ 6-6.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 6.5 and v.cst_till_alerting/1000.0 < 7) then 1 else 0 end ) as [ 6.5-7 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 7 and v.cst_till_alerting/1000.0 < 7.5) then 1 else 0 end ) as [ 7-7.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 7.5 and v.cst_till_alerting/1000.0 < 8) then 1 else 0 end ) as [ 7.5-8 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 8 and v.cst_till_alerting/1000.0 < 8.5) then 1 else 0 end ) as [ 8-8.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 8.5 and v.cst_till_alerting/1000.0 < 9) then 1 else 0 end ) as [ 8.5-9 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 9 and v.cst_till_alerting/1000.0 < 9.5) then 1 else 0 end ) as [ 9-9.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 9.5 and v.cst_till_alerting/1000.0 < 10) then 1 else 0 end ) as [ 9.5-10 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 10 and v.cst_till_alerting/1000.0 < 10.5) then 1 else 0 end ) as [ 10-10.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 10.5 and v.cst_till_alerting/1000.0 < 11) then 1 else 0 end ) as [ 10.5-11 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 11 and v.cst_till_alerting/1000.0 < 11.5) then 1 else 0 end ) as [ 11-11.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 11.5 and v.cst_till_alerting/1000.0 < 12) then 1 else 0 end ) as [ 11.5-12 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 12 and v.cst_till_alerting/1000.0 < 12.5) then 1 else 0 end ) as [ 12-12.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 12.5 and v.cst_till_alerting/1000.0 < 13) then 1 else 0 end ) as [ 12.5-13 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 13 and v.cst_till_alerting/1000.0 < 13.5) then 1 else 0 end ) as [ 13-13.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 13.5 and v.cst_till_alerting/1000.0 < 14) then 1 else 0 end ) as [ 13.5-14 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 14 and v.cst_till_alerting/1000.0 < 14.5) then 1 else 0 end ) as [ 14-14.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 14.5 and v.cst_till_alerting/1000.0 < 15) then 1 else 0 end ) as [ 14.5-15 MT_Alert],	
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 15 and v.cst_till_alerting/1000.0 < 15.5) then 1 else 0 end ) as [ 15-15.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 15.5 and v.cst_till_alerting/1000.0 < 16) then 1 else 0 end ) as [ 15.5-16 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 16 and v.cst_till_alerting/1000.0 < 16.5) then 1 else 0 end ) as [ 16-16.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 16.5 and v.cst_till_alerting/1000.0 < 17) then 1 else 0 end ) as [ 16.5-17 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 17 and v.cst_till_alerting/1000.0 < 17.5) then 1 else 0 end ) as [ 17-17.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 17.5 and v.cst_till_alerting/1000.0 < 18) then 1 else 0 end ) as [ 17.5-18 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 18 and v.cst_till_alerting/1000.0 < 18.5) then 1 else 0 end ) as [ 18-18.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 18.5 and v.cst_till_alerting/1000.0 < 19) then 1 else 0 end ) as [ 18.5-19 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 19 and v.cst_till_alerting/1000.0 < 19.5) then 1 else 0 end ) as [ 19-19.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 19.5 and v.cst_till_alerting/1000.0 < 20) then 1 else 0 end ) as [ 19.5-20 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 20) then 1 else 0 end ) as [ >20 MT_Alert],
		--Rangos Alerting MOMT
		SUM(case when v.cst_till_alerting/1000.0 >= 0 and v.cst_till_alerting/1000.0 < 0.5 then 1 else 0 end ) as [ 0-0.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 0.5 and v.cst_till_alerting/1000.0 < 1 then 1 else 0 end ) as [ 0.5-1 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 1 and v.cst_till_alerting/1000.0 < 1.5 then 1 else 0 end ) as [ 1-1.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 1.5 and v.cst_till_alerting/1000.0 < 2 then 1 else 0 end ) as [ 1.5-2 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 2 and v.cst_till_alerting/1000.0 < 2.5 then 1 else 0 end ) as [ 2-2.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 2.5 and v.cst_till_alerting/1000.0 < 3 then 1 else 0 end ) as [ 2.5-3 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 3 and v.cst_till_alerting/1000.0 < 3.5 then 1 else 0 end ) as [ 3-3.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 3.5 and v.cst_till_alerting/1000.0 < 4 then 1 else 0 end ) as [ 3.5-4 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 4 and v.cst_till_alerting/1000.0 < 4.5 then 1 else 0 end ) as [ 4-4.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 4.5 and v.cst_till_alerting/1000.0 < 5 then 1 else 0 end ) as [ 4.5-5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 5 and v.cst_till_alerting/1000.0 < 5.5 then 1 else 0 end ) as [ 5-5.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 5.5 and v.cst_till_alerting/1000.0 < 6 then 1 else 0 end ) as [ 5.5-6 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 6 and v.cst_till_alerting/1000.0 < 6.5 then 1 else 0 end ) as [ 6-6.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 6.5 and v.cst_till_alerting/1000.0 < 7 then 1 else 0 end ) as [ 6.5-7 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 7 and v.cst_till_alerting/1000.0 < 7.5 then 1 else 0 end ) as [ 7-7.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 7.5 and v.cst_till_alerting/1000.0 < 8 then 1 else 0 end ) as [ 7.5-8 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 8 and v.cst_till_alerting/1000.0 < 8.5 then 1 else 0 end ) as [ 8-8.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 8.5 and v.cst_till_alerting/1000.0 < 9 then 1 else 0 end ) as [ 8.5-9 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 9 and v.cst_till_alerting/1000.0 < 9.5 then 1 else 0 end ) as [ 9-9.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 9.5 and v.cst_till_alerting/1000.0 < 10 then 1 else 0 end ) as [ 9.5-10 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 10 and v.cst_till_alerting/1000.0 < 10.5 then 1 else 0 end ) as [ 10-10.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 10.5 and v.cst_till_alerting/1000.0 < 11 then 1 else 0 end ) as [ 10.5-11 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 11 and v.cst_till_alerting/1000.0 < 11.5 then 1 else 0 end ) as [ 11-11.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 11.5 and v.cst_till_alerting/1000.0 < 12 then 1 else 0 end ) as [ 11.5-12 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 12 and v.cst_till_alerting/1000.0 < 12.5 then 1 else 0 end ) as [ 12-12.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 12.5 and v.cst_till_alerting/1000.0 < 13 then 1 else 0 end ) as [ 12.5-13 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 13 and v.cst_till_alerting/1000.0 < 13.5 then 1 else 0 end ) as [ 13-13.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 13.5 and v.cst_till_alerting/1000.0 < 14 then 1 else 0 end ) as [ 13.5-14 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 14 and v.cst_till_alerting/1000.0 < 14.5 then 1 else 0 end ) as [ 14-14.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 14.5 and v.cst_till_alerting/1000.0 < 15 then 1 else 0 end ) as [ 14.5-15 MOMT_Alert],	
		SUM(case when v.cst_till_alerting/1000.0 >= 15 and v.cst_till_alerting/1000.0 < 15.5 then 1 else 0 end ) as [ 15-15.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 15.5 and v.cst_till_alerting/1000.0 < 16 then 1 else 0 end ) as [ 15.5-16 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 16 and v.cst_till_alerting/1000.0 < 16.5 then 1 else 0 end ) as [ 16-16.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 16.5 and v.cst_till_alerting/1000.0 < 17 then 1 else 0 end ) as [ 16.5-17 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 17 and v.cst_till_alerting/1000.0 < 17.5 then 1 else 0 end ) as [ 17-17.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 17.5 and v.cst_till_alerting/1000.0 < 18 then 1 else 0 end ) as [ 17.5-18 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 18 and v.cst_till_alerting/1000.0 < 18.5 then 1 else 0 end ) as [ 18-18.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 18.5 and v.cst_till_alerting/1000.0 < 19 then 1 else 0 end ) as [ 18.5-19 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 19 and v.cst_till_alerting/1000.0 < 19.5 then 1 else 0 end ) as [ 19-19.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 19.5 and v.cst_till_alerting/1000.0 < 20 then 1 else 0 end ) as [ 19.5-20 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 20 then 1 else 0 end ) as [ >20 MOMT_Alert],
		--Rangos Connect MO
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 0 and v.cst_till_connAck/1000.0 < 0.5) then 1 else 0 end ) as [ 0-0.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 0.5 and v.cst_till_connAck/1000.0 < 1) then 1 else 0 end ) as [ 0.5-1 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 1 and v.cst_till_connAck/1000.0 < 1.5) then 1 else 0 end ) as [ 1-1.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 1.5 and v.cst_till_connAck/1000.0 < 2) then 1 else 0 end ) as [ 1.5-2 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 2 and v.cst_till_connAck/1000.0 < 2.5) then 1 else 0 end ) as [ 2-2.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 2.5 and v.cst_till_connAck/1000.0 < 3) then 1 else 0 end ) as [ 2.5-3 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 3 and v.cst_till_connAck/1000.0 < 3.5) then 1 else 0 end ) as [ 3-3.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 3.5 and v.cst_till_connAck/1000.0 < 4) then 1 else 0 end ) as [ 3.5-4 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 4 and v.cst_till_connAck/1000.0 < 4.5) then 1 else 0 end ) as [ 4-4.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 4.5 and v.cst_till_connAck/1000.0 < 5) then 1 else 0 end ) as [ 4.5-5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 5 and v.cst_till_connAck/1000.0 < 5.5) then 1 else 0 end ) as [ 5-5.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 5.5 and v.cst_till_connAck/1000.0 < 6) then 1 else 0 end ) as [ 5.5-6 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 6 and v.cst_till_connAck/1000.0 < 6.5) then 1 else 0 end ) as [ 6-6.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 6.5 and v.cst_till_connAck/1000.0 < 7) then 1 else 0 end ) as [ 6.5-7 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 7 and v.cst_till_connAck/1000.0 < 7.5) then 1 else 0 end ) as [ 7-7.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 7.5 and v.cst_till_connAck/1000.0 < 8) then 1 else 0 end ) as [ 7.5-8 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 8 and v.cst_till_connAck/1000.0 < 8.5) then 1 else 0 end ) as [ 8-8.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 8.5 and v.cst_till_connAck/1000.0 < 9) then 1 else 0 end ) as [ 8.5-9 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 9 and v.cst_till_connAck/1000.0 < 9.5) then 1 else 0 end ) as [ 9-9.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 9.5 and v.cst_till_connAck/1000.0 < 10) then 1 else 0 end ) as [ 9.5-10 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 10 and v.cst_till_connAck/1000.0 < 10.5) then 1 else 0 end ) as [ 10-10.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 10.5 and v.cst_till_connAck/1000.0 < 11) then 1 else 0 end ) as [ 10.5-11 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 11 and v.cst_till_connAck/1000.0 < 11.5) then 1 else 0 end ) as [ 11-11.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 11.5 and v.cst_till_connAck/1000.0 < 12) then 1 else 0 end ) as [ 11.5-12 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 12 and v.cst_till_connAck/1000.0 < 12.5) then 1 else 0 end ) as [ 12-12.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 12.5 and v.cst_till_connAck/1000.0 < 13) then 1 else 0 end ) as [ 12.5-13 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 13 and v.cst_till_connAck/1000.0 < 13.5) then 1 else 0 end ) as [ 13-13.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 13.5 and v.cst_till_connAck/1000.0 < 14) then 1 else 0 end ) as [ 13.5-14 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 14 and v.cst_till_connAck/1000.0 < 14.5) then 1 else 0 end ) as [ 14-14.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 14.5 and v.cst_till_connAck/1000.0 < 15) then 1 else 0 end ) as [ 14.5-15 MO_Conn],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 15 and v.cst_till_connAck/1000.0 < 15.5) then 1 else 0 end ) as [ 15-15.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 15.5 and v.cst_till_connAck/1000.0 < 16) then 1 else 0 end ) as [ 15.5-16 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 16 and v.cst_till_connAck/1000.0 < 16.5) then 1 else 0 end ) as [ 16-16.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 16.5 and v.cst_till_connAck/1000.0 < 17) then 1 else 0 end ) as [ 16.5-17 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 17 and v.cst_till_connAck/1000.0 < 17.5) then 1 else 0 end ) as [ 17-17.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 17.5 and v.cst_till_connAck/1000.0 < 18) then 1 else 0 end ) as [ 17.5-18 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 18 and v.cst_till_connAck/1000.0 < 18.5) then 1 else 0 end ) as [ 18-18.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 18.5 and v.cst_till_connAck/1000.0 < 19) then 1 else 0 end ) as [ 18.5-19 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 19 and v.cst_till_connAck/1000.0 < 19.5) then 1 else 0 end ) as [ 19-19.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 19.5 and v.cst_till_connAck/1000.0 < 20) then 1 else 0 end ) as [ 19.5-20 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 20) then 1 else 0 end ) as [ >20 MO_Conn],
		--Rangos Connect MT
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 0 and v.cst_till_connAck/1000.0 < 0.5) then 1 else 0 end ) as [ 0-0.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 0.5 and v.cst_till_connAck/1000.0 < 1) then 1 else 0 end ) as [ 0.5-1 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 1 and v.cst_till_connAck/1000.0 < 1.5) then 1 else 0 end ) as [ 1-1.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 1.5 and v.cst_till_connAck/1000.0 < 2) then 1 else 0 end ) as [ 1.5-2 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 2 and v.cst_till_connAck/1000.0 < 2.5) then 1 else 0 end ) as [ 2-2.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 2.5 and v.cst_till_connAck/1000.0 < 3) then 1 else 0 end ) as [ 2.5-3 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 3 and v.cst_till_connAck/1000.0 < 3.5) then 1 else 0 end ) as [ 3-3.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 3.5 and v.cst_till_connAck/1000.0 < 4) then 1 else 0 end ) as [ 3.5-4 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 4 and v.cst_till_connAck/1000.0 < 4.5) then 1 else 0 end ) as [ 4-4.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 4.5 and v.cst_till_connAck/1000.0 < 5) then 1 else 0 end ) as [ 4.5-5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 5 and v.cst_till_connAck/1000.0 < 5.5) then 1 else 0 end ) as [ 5-5.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 5.5 and v.cst_till_connAck/1000.0 < 6) then 1 else 0 end ) as [ 5.5-6 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 6 and v.cst_till_connAck/1000.0 < 6.5) then 1 else 0 end ) as [ 6-6.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 6.5 and v.cst_till_connAck/1000.0 < 7) then 1 else 0 end ) as [ 6.5-7 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 7 and v.cst_till_connAck/1000.0 < 7.5) then 1 else 0 end ) as [ 7-7.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 7.5 and v.cst_till_connAck/1000.0 < 8) then 1 else 0 end ) as [ 7.5-8 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 8 and v.cst_till_connAck/1000.0 < 8.5) then 1 else 0 end ) as [ 8-8.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 8.5 and v.cst_till_connAck/1000.0 < 9) then 1 else 0 end ) as [ 8.5-9 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 9 and v.cst_till_connAck/1000.0 < 9.5) then 1 else 0 end ) as [ 9-9.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 9.5 and v.cst_till_connAck/1000.0 < 10) then 1 else 0 end ) as [ 9.5-10 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 10 and v.cst_till_connAck/1000.0 < 10.5) then 1 else 0 end ) as [ 10-10.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 10.5 and v.cst_till_connAck/1000.0 < 11) then 1 else 0 end ) as [ 10.5-11 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 11 and v.cst_till_connAck/1000.0 < 11.5) then 1 else 0 end ) as [ 11-11.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 11.5 and v.cst_till_connAck/1000.0 < 12) then 1 else 0 end ) as [ 11.5-12 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 12 and v.cst_till_connAck/1000.0 < 12.5) then 1 else 0 end ) as [ 12-12.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 12.5 and v.cst_till_connAck/1000.0 < 13) then 1 else 0 end ) as [ 12.5-13 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 13 and v.cst_till_connAck/1000.0 < 13.5) then 1 else 0 end ) as [ 13-13.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 13.5 and v.cst_till_connAck/1000.0 < 14) then 1 else 0 end ) as [ 13.5-14 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 14 and v.cst_till_connAck/1000.0 < 14.5) then 1 else 0 end ) as [ 14-14.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 14.5 and v.cst_till_connAck/1000.0 < 15) then 1 else 0 end ) as [ 14.5-15 MT_Conn],	
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 15 and v.cst_till_connAck/1000.0 < 15.5) then 1 else 0 end ) as [ 15-15.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 15.5 and v.cst_till_connAck/1000.0 < 16) then 1 else 0 end ) as [ 15.5-16 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 16 and v.cst_till_connAck/1000.0 < 16.5) then 1 else 0 end ) as [ 16-16.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 16.5 and v.cst_till_connAck/1000.0 < 17) then 1 else 0 end ) as [ 16.5-17 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 17 and v.cst_till_connAck/1000.0 < 17.5) then 1 else 0 end ) as [ 17-17.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 17.5 and v.cst_till_connAck/1000.0 < 18) then 1 else 0 end ) as [ 17.5-18 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 18 and v.cst_till_connAck/1000.0 < 18.5) then 1 else 0 end ) as [ 18-18.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 18.5 and v.cst_till_connAck/1000.0 < 19) then 1 else 0 end ) as [ 18.5-19 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 19 and v.cst_till_connAck/1000.0 < 19.5) then 1 else 0 end ) as [ 19-19.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 19.5 and v.cst_till_connAck/1000.0 < 20) then 1 else 0 end ) as [ 19.5-20 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 20) then 1 else 0 end ) as [ >20 MT_Conn],
		--Rangos Connect MOMT
		SUM(case when v.cst_till_connAck/1000.0 >= 0 and v.cst_till_connAck/1000.0 < 0.5 then 1 else 0 end ) as [ 0-0.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 0.5 and v.cst_till_connAck/1000.0 < 1 then 1 else 0 end ) as [ 0.5-1 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 1 and v.cst_till_connAck/1000.0 < 1.5 then 1 else 0 end ) as [ 1-1.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 1.5 and v.cst_till_connAck/1000.0 < 2 then 1 else 0 end ) as [ 1.5-2 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 2 and v.cst_till_connAck/1000.0 < 2.5 then 1 else 0 end ) as [ 2-2.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 2.5 and v.cst_till_connAck/1000.0 < 3 then 1 else 0 end ) as [ 2.5-3 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 3 and v.cst_till_connAck/1000.0 < 3.5 then 1 else 0 end ) as [ 3-3.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 3.5 and v.cst_till_connAck/1000.0 < 4 then 1 else 0 end ) as [ 3.5-4 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 4 and v.cst_till_connAck/1000.0 < 4.5 then 1 else 0 end ) as [ 4-4.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 4.5 and v.cst_till_connAck/1000.0 < 5 then 1 else 0 end ) as [ 4.5-5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 5 and v.cst_till_connAck/1000.0 < 5.5 then 1 else 0 end ) as [ 5-5.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 5.5 and v.cst_till_connAck/1000.0 < 6 then 1 else 0 end ) as [ 5.5-6 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 6 and v.cst_till_connAck/1000.0 < 6.5 then 1 else 0 end ) as [ 6-6.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 6.5 and v.cst_till_connAck/1000.0 < 7 then 1 else 0 end ) as [ 6.5-7 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 7 and v.cst_till_connAck/1000.0 < 7.5 then 1 else 0 end ) as [ 7-7.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 7.5 and v.cst_till_connAck/1000.0 < 8 then 1 else 0 end ) as [ 7.5-8 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 8 and v.cst_till_connAck/1000.0 < 8.5 then 1 else 0 end ) as [ 8-8.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 8.5 and v.cst_till_connAck/1000.0 < 9 then 1 else 0 end ) as [ 8.5-9 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 9 and v.cst_till_connAck/1000.0 < 9.5 then 1 else 0 end ) as [ 9-9.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 9.5 and v.cst_till_connAck/1000.0 < 10 then 1 else 0 end ) as [ 9.5-10 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 10 and v.cst_till_connAck/1000.0 < 10.5 then 1 else 0 end ) as [ 10-10.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 10.5 and v.cst_till_connAck/1000.0 < 11 then 1 else 0 end ) as [ 10.5-11 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 11 and v.cst_till_connAck/1000.0 < 11.5 then 1 else 0 end ) as [ 11-11.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 11.5 and v.cst_till_connAck/1000.0 < 12 then 1 else 0 end ) as [ 11.5-12 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 12 and v.cst_till_connAck/1000.0 < 12.5 then 1 else 0 end ) as [ 12-12.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 12.5 and v.cst_till_connAck/1000.0 < 13 then 1 else 0 end ) as [ 12.5-13 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 13 and v.cst_till_connAck/1000.0 < 13.5 then 1 else 0 end ) as [ 13-13.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 13.5 and v.cst_till_connAck/1000.0 < 14 then 1 else 0 end ) as [ 13.5-14 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 14 and v.cst_till_connAck/1000.0 < 14.5 then 1 else 0 end ) as [ 14-14.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 14.5 and v.cst_till_connAck/1000.0 < 15 then 1 else 0 end ) as [ 14.5-15 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 15 and v.cst_till_connAck/1000.0 < 15.5 then 1 else 0 end ) as [ 15-15.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 15.5 and v.cst_till_connAck/1000.0 < 16 then 1 else 0 end ) as [ 15.5-16 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 16 and v.cst_till_connAck/1000.0 < 16.5 then 1 else 0 end ) as [ 16-16.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 16.5 and v.cst_till_connAck/1000.0 < 17 then 1 else 0 end ) as [ 16.5-17 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 17 and v.cst_till_connAck/1000.0 < 17.5 then 1 else 0 end ) as [ 17-17.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 17.5 and v.cst_till_connAck/1000.0 < 18 then 1 else 0 end ) as [ 17.5-18 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 18 and v.cst_till_connAck/1000.0 < 18.5 then 1 else 0 end ) as [ 18-18.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 18.5 and v.cst_till_connAck/1000.0 < 19 then 1 else 0 end ) as [ 18.5-19 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 19 and v.cst_till_connAck/1000.0 < 19.5 then 1 else 0 end ) as [ 19-19.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 19.5 and v.cst_till_connAck/1000.0 < 20 then 1 else 0 end ) as [ 19.5-20 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 20 then 1 else 0 end ) as [ >20 MOMT_Conn],
		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		lp.Region_VF as Region_VF,
		null,
		@Report,
		'Collection Name',
		lp.Region_OSP as Region_OSP,
		calltype,
		v.[ASideDevice],
		v.[BSideDevice],
		v.[SWVersion]

	from 
		@All_Tests a,
		lcc_Calls_Detailed v,
		Sessions s,
		Agrids.dbo.lcc_parcelas lp

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus = 'Completed'
		and s.valid=1
		and lp.Nombre= [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A)
	group by [master].[dbo].[fn_lcc_getParcel](v.longitude_fin_A, v.latitude_fin_A), v.mnc,lp.Region_VF,lp.Region_OSP,
		calltype, v.[ASideDevice], v.[BSideDevice], v.[SWVersion]
end
else
begin
	insert into @voice_cst
	select
		db_name() as 'Database',
		v.mnc,
		null,
		sum (case when v.callDir='MO' then 1 else 0 end) as MO_CallType,
		sum (case when v.callDir='MT' then 1 else 0 end) as MT_CallType,

		sum (case when v.callDir='MO' and v.cst_till_alerting is not null then 1 else 0 end) [Calls_AVG_ALERT_MO],
		sum (case when v.callDir='MT' and v.cst_till_alerting is not null then 1 else 0 end) [Calls_AVG_ALERT_MT],
		sum (case when v.callDir='MO' and v.cst_till_connAck is not null then 1 else 0 end) [Calls_AVG_CONNECT_MO],
		sum (case when v.callDir='MT' and v.cst_till_connAck is not null then 1 else 0 end) [Calls_AVG_CONNECT_MT],

		AVG(case when v.callDir = 'MO' then 1.0*v.cst_till_alerting end)/1000.0 as CST_MO_Alerting,
		AVG(case when v.callDir = 'MT' then 1.0*v.cst_till_alerting end)/1000.0 as CST_MT_Alerting,
		AVG(v.cst_till_alerting/1000.0) as CST_MOMT_Alerting,
		AVG(case when v.callDir = 'MO' then 1.0*v.cst_till_connAck end)/1000.0 as CST_MO_Connect,
		AVG(case when v.callDir = 'MT' then 1.0*v.cst_till_connAck end)/1000.0 as CST_MT_Connect,
		AVG(v.cst_till_connAck/1000.0) as CST_MOMT_Connect,

		--Rangos Alerting MO
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 0 and v.cst_till_alerting/1000.0 < 0.5) then 1 else 0 end ) as [ 0-0.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 0.5 and v.cst_till_alerting/1000.0 < 1) then 1 else 0 end ) as [ 0.5-1 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 1 and v.cst_till_alerting/1000.0 < 1.5) then 1 else 0 end ) as [ 1-1.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 1.5 and v.cst_till_alerting/1000.0 < 2) then 1 else 0 end ) as [ 1.5-2 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 2 and v.cst_till_alerting/1000.0 < 2.5) then 1 else 0 end ) as [ 2-2.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 2.5 and v.cst_till_alerting/1000.0 < 3) then 1 else 0 end ) as [ 2.5-3 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 3 and v.cst_till_alerting/1000.0 < 3.5) then 1 else 0 end ) as [ 3-3.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 3.5 and v.cst_till_alerting/1000.0 < 4) then 1 else 0 end ) as [ 3.5-4 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 4 and v.cst_till_alerting/1000.0 < 4.5) then 1 else 0 end ) as [ 4-4.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 4.5 and v.cst_till_alerting/1000.0 < 5) then 1 else 0 end ) as [ 4.5-5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 5 and v.cst_till_alerting/1000.0 < 5.5) then 1 else 0 end ) as [ 5-5.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 5.5 and v.cst_till_alerting/1000.0 < 6) then 1 else 0 end ) as [ 5.5-6 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 6 and v.cst_till_alerting/1000.0 < 6.5) then 1 else 0 end ) as [ 6-6.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 6.5 and v.cst_till_alerting/1000.0 < 7) then 1 else 0 end ) as [ 6.5-7 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 7 and v.cst_till_alerting/1000.0 < 7.5) then 1 else 0 end ) as [ 7-7.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 7.5 and v.cst_till_alerting/1000.0 < 8) then 1 else 0 end ) as [ 7.5-8 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 8 and v.cst_till_alerting/1000.0 < 8.5) then 1 else 0 end ) as [ 8-8.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 8.5 and v.cst_till_alerting/1000.0 < 9) then 1 else 0 end ) as [ 8.5-9 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 9 and v.cst_till_alerting/1000.0 < 9.5) then 1 else 0 end ) as [ 9-9.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 9.5 and v.cst_till_alerting/1000.0 < 10) then 1 else 0 end ) as [ 9.5-10 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 10 and v.cst_till_alerting/1000.0 < 10.5) then 1 else 0 end ) as [ 10-10.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 10.5 and v.cst_till_alerting/1000.0 < 11) then 1 else 0 end ) as [ 10.5-11 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 11 and v.cst_till_alerting/1000.0 < 11.5) then 1 else 0 end ) as [ 11-11.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 11.5 and v.cst_till_alerting/1000.0 < 12) then 1 else 0 end ) as [ 11.5-12 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 12 and v.cst_till_alerting/1000.0 < 12.5) then 1 else 0 end ) as [ 12-12.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 12.5 and v.cst_till_alerting/1000.0 < 13) then 1 else 0 end ) as [ 12.5-13 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 13 and v.cst_till_alerting/1000.0 < 13.5) then 1 else 0 end ) as [ 13-13.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 13.5 and v.cst_till_alerting/1000.0 < 14) then 1 else 0 end ) as [ 13.5-14 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 14 and v.cst_till_alerting/1000.0 < 14.5) then 1 else 0 end ) as [ 14-14.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 14.5 and v.cst_till_alerting/1000.0 < 15) then 1 else 0 end ) as [ 14.5-15 MO_Alert],		
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 15 and v.cst_till_alerting/1000.0 < 15.5) then 1 else 0 end ) as [ 15-15.5 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 15.5 and v.cst_till_alerting/1000.0 < 16) then 1 else 0 end ) as [ 15.5-16 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 16 and v.cst_till_alerting/1000.0 < 16.5) then 1 else 0 end ) as [ 16-16.5 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 16.5 and v.cst_till_alerting/1000.0 < 17) then 1 else 0 end ) as [ 16.5-17 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 17 and v.cst_till_alerting/1000.0 < 17.5) then 1 else 0 end ) as [ 17-17.5 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 17.5 and v.cst_till_alerting/1000.0 < 18) then 1 else 0 end ) as [ 17.5-18 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 18 and v.cst_till_alerting/1000.0 < 18.5) then 1 else 0 end ) as [ 18-18.5 MO_Alert],	
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 18.5 and v.cst_till_alerting/1000.0 < 19) then 1 else 0 end ) as [ 18.5-19 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 19 and v.cst_till_alerting/1000.0 < 19.5) then 1 else 0 end ) as [ 19-19.5 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 19.5 and v.cst_till_alerting/1000.0 < 20) then 1 else 0 end ) as [ 19.5-20 MO_Alert],
		SUM(case when (v.callDir = 'MO' and v.cst_till_alerting/1000.0 >= 20) then 1 else 0 end ) as [ >20 MO_Alert],
		--Rangos Alerting MT
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 0 and v.cst_till_alerting/1000.0 < 0.5) then 1 else 0 end ) as [ 0-0.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 0.5 and v.cst_till_alerting/1000.0 < 1) then 1 else 0 end ) as [ 0.5-1 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 1 and v.cst_till_alerting/1000.0 < 1.5) then 1 else 0 end ) as [ 1-1.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 1.5 and v.cst_till_alerting/1000.0 < 2) then 1 else 0 end ) as [ 1.5-2 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 2 and v.cst_till_alerting/1000.0 < 2.5) then 1 else 0 end ) as [ 2-2.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 2.5 and v.cst_till_alerting/1000.0 < 3) then 1 else 0 end ) as [ 2.5-3 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 3 and v.cst_till_alerting/1000.0 < 3.5) then 1 else 0 end ) as [ 3-3.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 3.5 and v.cst_till_alerting/1000.0 < 4) then 1 else 0 end ) as [ 3.5-4 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 4 and v.cst_till_alerting/1000.0 < 4.5) then 1 else 0 end ) as [ 4-4.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 4.5 and v.cst_till_alerting/1000.0 < 5) then 1 else 0 end ) as [ 4.5-5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 5 and v.cst_till_alerting/1000.0 < 5.5) then 1 else 0 end ) as [ 5-5.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 5.5 and v.cst_till_alerting/1000.0 < 6) then 1 else 0 end ) as [ 5.5-6 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 6 and v.cst_till_alerting/1000.0 < 6.5) then 1 else 0 end ) as [ 6-6.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 6.5 and v.cst_till_alerting/1000.0 < 7) then 1 else 0 end ) as [ 6.5-7 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 7 and v.cst_till_alerting/1000.0 < 7.5) then 1 else 0 end ) as [ 7-7.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 7.5 and v.cst_till_alerting/1000.0 < 8) then 1 else 0 end ) as [ 7.5-8 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 8 and v.cst_till_alerting/1000.0 < 8.5) then 1 else 0 end ) as [ 8-8.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 8.5 and v.cst_till_alerting/1000.0 < 9) then 1 else 0 end ) as [ 8.5-9 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 9 and v.cst_till_alerting/1000.0 < 9.5) then 1 else 0 end ) as [ 9-9.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 9.5 and v.cst_till_alerting/1000.0 < 10) then 1 else 0 end ) as [ 9.5-10 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 10 and v.cst_till_alerting/1000.0 < 10.5) then 1 else 0 end ) as [ 10-10.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 10.5 and v.cst_till_alerting/1000.0 < 11) then 1 else 0 end ) as [ 10.5-11 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 11 and v.cst_till_alerting/1000.0 < 11.5) then 1 else 0 end ) as [ 11-11.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 11.5 and v.cst_till_alerting/1000.0 < 12) then 1 else 0 end ) as [ 11.5-12 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 12 and v.cst_till_alerting/1000.0 < 12.5) then 1 else 0 end ) as [ 12-12.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 12.5 and v.cst_till_alerting/1000.0 < 13) then 1 else 0 end ) as [ 12.5-13 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 13 and v.cst_till_alerting/1000.0 < 13.5) then 1 else 0 end ) as [ 13-13.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 13.5 and v.cst_till_alerting/1000.0 < 14) then 1 else 0 end ) as [ 13.5-14 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 14 and v.cst_till_alerting/1000.0 < 14.5) then 1 else 0 end ) as [ 14-14.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 14.5 and v.cst_till_alerting/1000.0 < 15) then 1 else 0 end ) as [ 14.5-15 MT_Alert],		
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 15 and v.cst_till_alerting/1000.0 < 15.5) then 1 else 0 end ) as [ 15-15.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 15.5 and v.cst_till_alerting/1000.0 < 16) then 1 else 0 end ) as [ 15.5-16 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 16 and v.cst_till_alerting/1000.0 < 16.5) then 1 else 0 end ) as [ 16-16.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 16.5 and v.cst_till_alerting/1000.0 < 17) then 1 else 0 end ) as [ 16.5-17 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 17 and v.cst_till_alerting/1000.0 < 17.5) then 1 else 0 end ) as [ 17-17.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 17.5 and v.cst_till_alerting/1000.0 < 18) then 1 else 0 end ) as [ 17.5-18 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 18 and v.cst_till_alerting/1000.0 < 18.5) then 1 else 0 end ) as [ 18-18.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 18.5 and v.cst_till_alerting/1000.0 < 19) then 1 else 0 end ) as [ 18.5-19 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 19 and v.cst_till_alerting/1000.0 < 19.5) then 1 else 0 end ) as [ 19-19.5 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 19.5 and v.cst_till_alerting/1000.0 < 20) then 1 else 0 end ) as [ 19.5-20 MT_Alert],
		SUM(case when (v.callDir = 'MT' and v.cst_till_alerting/1000.0 >= 20) then 1 else 0 end ) as [ >20 MT_Alert],
		--Rangos Alerting MOMT
		SUM(case when v.cst_till_alerting/1000.0 >= 0 and v.cst_till_alerting/1000.0 < 0.5 then 1 else 0 end ) as [ 0-0.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 0.5 and v.cst_till_alerting/1000.0 < 1 then 1 else 0 end ) as [ 0.5-1 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 1 and v.cst_till_alerting/1000.0 < 1.5 then 1 else 0 end ) as [ 1-1.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 1.5 and v.cst_till_alerting/1000.0 < 2 then 1 else 0 end ) as [ 1.5-2 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 2 and v.cst_till_alerting/1000.0 < 2.5 then 1 else 0 end ) as [ 2-2.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 2.5 and v.cst_till_alerting/1000.0 < 3 then 1 else 0 end ) as [ 2.5-3 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 3 and v.cst_till_alerting/1000.0 < 3.5 then 1 else 0 end ) as [ 3-3.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 3.5 and v.cst_till_alerting/1000.0 < 4 then 1 else 0 end ) as [ 3.5-4 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 4 and v.cst_till_alerting/1000.0 < 4.5 then 1 else 0 end ) as [ 4-4.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 4.5 and v.cst_till_alerting/1000.0 < 5 then 1 else 0 end ) as [ 4.5-5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 5 and v.cst_till_alerting/1000.0 < 5.5 then 1 else 0 end ) as [ 5-5.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 5.5 and v.cst_till_alerting/1000.0 < 6 then 1 else 0 end ) as [ 5.5-6 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 6 and v.cst_till_alerting/1000.0 < 6.5 then 1 else 0 end ) as [ 6-6.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 6.5 and v.cst_till_alerting/1000.0 < 7 then 1 else 0 end ) as [ 6.5-7 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 7 and v.cst_till_alerting/1000.0 < 7.5 then 1 else 0 end ) as [ 7-7.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 7.5 and v.cst_till_alerting/1000.0 < 8 then 1 else 0 end ) as [ 7.5-8 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 8 and v.cst_till_alerting/1000.0 < 8.5 then 1 else 0 end ) as [ 8-8.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 8.5 and v.cst_till_alerting/1000.0 < 9 then 1 else 0 end ) as [ 8.5-9 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 9 and v.cst_till_alerting/1000.0 < 9.5 then 1 else 0 end ) as [ 9-9.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 9.5 and v.cst_till_alerting/1000.0 < 10 then 1 else 0 end ) as [ 9.5-10 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 10 and v.cst_till_alerting/1000.0 < 10.5 then 1 else 0 end ) as [ 10-10.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 10.5 and v.cst_till_alerting/1000.0 < 11 then 1 else 0 end ) as [ 10.5-11 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 11 and v.cst_till_alerting/1000.0 < 11.5 then 1 else 0 end ) as [ 11-11.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 11.5 and v.cst_till_alerting/1000.0 < 12 then 1 else 0 end ) as [ 11.5-12 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 12 and v.cst_till_alerting/1000.0 < 12.5 then 1 else 0 end ) as [ 12-12.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 12.5 and v.cst_till_alerting/1000.0 < 13 then 1 else 0 end ) as [ 12.5-13 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 13 and v.cst_till_alerting/1000.0 < 13.5 then 1 else 0 end ) as [ 13-13.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 13.5 and v.cst_till_alerting/1000.0 < 14 then 1 else 0 end ) as [ 13.5-14 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 14 and v.cst_till_alerting/1000.0 < 14.5 then 1 else 0 end ) as [ 14-14.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 14.5 and v.cst_till_alerting/1000.0 < 15 then 1 else 0 end ) as [ 14.5-15 MOMT_Alert],	
		SUM(case when v.cst_till_alerting/1000.0 >= 15 and v.cst_till_alerting/1000.0 < 15.5 then 1 else 0 end ) as [ 15-15.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 15.5 and v.cst_till_alerting/1000.0 < 16 then 1 else 0 end ) as [ 15.5-16 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 16 and v.cst_till_alerting/1000.0 < 16.5 then 1 else 0 end ) as [ 16-16.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 16.5 and v.cst_till_alerting/1000.0 < 17 then 1 else 0 end ) as [ 16.5-17 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 17 and v.cst_till_alerting/1000.0 < 17.5 then 1 else 0 end ) as [ 17-17.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 17.5 and v.cst_till_alerting/1000.0 < 18 then 1 else 0 end ) as [ 17.5-18 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 18 and v.cst_till_alerting/1000.0 < 18.5 then 1 else 0 end ) as [ 18-18.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 18.5 and v.cst_till_alerting/1000.0 < 19 then 1 else 0 end ) as [ 18.5-19 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 19 and v.cst_till_alerting/1000.0 < 19.5 then 1 else 0 end ) as [ 19-19.5 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 19.5 and v.cst_till_alerting/1000.0 < 20 then 1 else 0 end ) as [ 19.5-20 MOMT_Alert],
		SUM(case when v.cst_till_alerting/1000.0 >= 20 then 1 else 0 end ) as [ >20 MOMT_Alert],
		--Rangos Connect MO
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 0 and v.cst_till_connAck/1000.0 < 0.5) then 1 else 0 end ) as [ 0-0.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 0.5 and v.cst_till_connAck/1000.0 < 1) then 1 else 0 end ) as [ 0.5-1 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 1 and v.cst_till_connAck/1000.0 < 1.5) then 1 else 0 end ) as [ 1-1.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 1.5 and v.cst_till_connAck/1000.0 < 2) then 1 else 0 end ) as [ 1.5-2 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 2 and v.cst_till_connAck/1000.0 < 2.5) then 1 else 0 end ) as [ 2-2.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 2.5 and v.cst_till_connAck/1000.0 < 3) then 1 else 0 end ) as [ 2.5-3 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 3 and v.cst_till_connAck/1000.0 < 3.5) then 1 else 0 end ) as [ 3-3.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 3.5 and v.cst_till_connAck/1000.0 < 4) then 1 else 0 end ) as [ 3.5-4 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 4 and v.cst_till_connAck/1000.0 < 4.5) then 1 else 0 end ) as [ 4-4.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 4.5 and v.cst_till_connAck/1000.0 < 5) then 1 else 0 end ) as [ 4.5-5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 5 and v.cst_till_connAck/1000.0 < 5.5) then 1 else 0 end ) as [ 5-5.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 5.5 and v.cst_till_connAck/1000.0 < 6) then 1 else 0 end ) as [ 5.5-6 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 6 and v.cst_till_connAck/1000.0 < 6.5) then 1 else 0 end ) as [ 6-6.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 6.5 and v.cst_till_connAck/1000.0 < 7) then 1 else 0 end ) as [ 6.5-7 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 7 and v.cst_till_connAck/1000.0 < 7.5) then 1 else 0 end ) as [ 7-7.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 7.5 and v.cst_till_connAck/1000.0 < 8) then 1 else 0 end ) as [ 7.5-8 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 8 and v.cst_till_connAck/1000.0 < 8.5) then 1 else 0 end ) as [ 8-8.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 8.5 and v.cst_till_connAck/1000.0 < 9) then 1 else 0 end ) as [ 8.5-9 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 9 and v.cst_till_connAck/1000.0 < 9.5) then 1 else 0 end ) as [ 9-9.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 9.5 and v.cst_till_connAck/1000.0 < 10) then 1 else 0 end ) as [ 9.5-10 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 10 and v.cst_till_connAck/1000.0 < 10.5) then 1 else 0 end ) as [ 10-10.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 10.5 and v.cst_till_connAck/1000.0 < 11) then 1 else 0 end ) as [ 10.5-11 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 11 and v.cst_till_connAck/1000.0 < 11.5) then 1 else 0 end ) as [ 11-11.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 11.5 and v.cst_till_connAck/1000.0 < 12) then 1 else 0 end ) as [ 11.5-12 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 12 and v.cst_till_connAck/1000.0 < 12.5) then 1 else 0 end ) as [ 12-12.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 12.5 and v.cst_till_connAck/1000.0 < 13) then 1 else 0 end ) as [ 12.5-13 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 13 and v.cst_till_connAck/1000.0 < 13.5) then 1 else 0 end ) as [ 13-13.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 13.5 and v.cst_till_connAck/1000.0 < 14) then 1 else 0 end ) as [ 13.5-14 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 14 and v.cst_till_connAck/1000.0 < 14.5) then 1 else 0 end ) as [ 14-14.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 14.5 and v.cst_till_connAck/1000.0 < 15) then 1 else 0 end ) as [ 14.5-15 MO_Conn],		
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 15 and v.cst_till_connAck/1000.0 < 15.5) then 1 else 0 end ) as [ 15-15.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 15.5 and v.cst_till_connAck/1000.0 < 16) then 1 else 0 end ) as [ 15.5-16 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 16 and v.cst_till_connAck/1000.0 < 16.5) then 1 else 0 end ) as [ 16-16.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 16.5 and v.cst_till_connAck/1000.0 < 17) then 1 else 0 end ) as [ 16.5-17 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 17 and v.cst_till_connAck/1000.0 < 17.5) then 1 else 0 end ) as [ 17-17.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 17.5 and v.cst_till_connAck/1000.0 < 18) then 1 else 0 end ) as [ 17.5-18 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 18 and v.cst_till_connAck/1000.0 < 18.5) then 1 else 0 end ) as [ 18-18.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 18.5 and v.cst_till_connAck/1000.0 < 19) then 1 else 0 end ) as [ 18.5-19 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 19 and v.cst_till_connAck/1000.0 < 19.5) then 1 else 0 end ) as [ 19-19.5 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 19.5 and v.cst_till_connAck/1000.0 < 20) then 1 else 0 end ) as [ 19.5-20 MO_Conn],
		SUM(case when (v.callDir = 'MO' and v.cst_till_connAck/1000.0 >= 20) then 1 else 0 end ) as [ >20 MO_Conn],
		--Rangos Connect MT
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 0 and v.cst_till_connAck/1000.0 < 0.5) then 1 else 0 end ) as [ 0-0.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 0.5 and v.cst_till_connAck/1000.0 < 1) then 1 else 0 end ) as [ 0.5-1 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 1 and v.cst_till_connAck/1000.0 < 1.5) then 1 else 0 end ) as [ 1-1.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 1.5 and v.cst_till_connAck/1000.0 < 2) then 1 else 0 end ) as [ 1.5-2 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 2 and v.cst_till_connAck/1000.0 < 2.5) then 1 else 0 end ) as [ 2-2.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 2.5 and v.cst_till_connAck/1000.0 < 3) then 1 else 0 end ) as [ 2.5-3 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 3 and v.cst_till_connAck/1000.0 < 3.5) then 1 else 0 end ) as [ 3-3.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 3.5 and v.cst_till_connAck/1000.0 < 4) then 1 else 0 end ) as [ 3.5-4 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 4 and v.cst_till_connAck/1000.0 < 4.5) then 1 else 0 end ) as [ 4-4.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 4.5 and v.cst_till_connAck/1000.0 < 5) then 1 else 0 end ) as [ 4.5-5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 5 and v.cst_till_connAck/1000.0 < 5.5) then 1 else 0 end ) as [ 5-5.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 5.5 and v.cst_till_connAck/1000.0 < 6) then 1 else 0 end ) as [ 5.5-6 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 6 and v.cst_till_connAck/1000.0 < 6.5) then 1 else 0 end ) as [ 6-6.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 6.5 and v.cst_till_connAck/1000.0 < 7) then 1 else 0 end ) as [ 6.5-7 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 7 and v.cst_till_connAck/1000.0 < 7.5) then 1 else 0 end ) as [ 7-7.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 7.5 and v.cst_till_connAck/1000.0 < 8) then 1 else 0 end ) as [ 7.5-8 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 8 and v.cst_till_connAck/1000.0 < 8.5) then 1 else 0 end ) as [ 8-8.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 8.5 and v.cst_till_connAck/1000.0 < 9) then 1 else 0 end ) as [ 8.5-9 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 9 and v.cst_till_connAck/1000.0 < 9.5) then 1 else 0 end ) as [ 9-9.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 9.5 and v.cst_till_connAck/1000.0 < 10) then 1 else 0 end ) as [ 9.5-10 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 10 and v.cst_till_connAck/1000.0 < 10.5) then 1 else 0 end ) as [ 10-10.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 10.5 and v.cst_till_connAck/1000.0 < 11) then 1 else 0 end ) as [ 10.5-11 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 11 and v.cst_till_connAck/1000.0 < 11.5) then 1 else 0 end ) as [ 11-11.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 11.5 and v.cst_till_connAck/1000.0 < 12) then 1 else 0 end ) as [ 11.5-12 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 12 and v.cst_till_connAck/1000.0 < 12.5) then 1 else 0 end ) as [ 12-12.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 12.5 and v.cst_till_connAck/1000.0 < 13) then 1 else 0 end ) as [ 12.5-13 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 13 and v.cst_till_connAck/1000.0 < 13.5) then 1 else 0 end ) as [ 13-13.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 13.5 and v.cst_till_connAck/1000.0 < 14) then 1 else 0 end ) as [ 13.5-14 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 14 and v.cst_till_connAck/1000.0 < 14.5) then 1 else 0 end ) as [ 14-14.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 14.5 and v.cst_till_connAck/1000.0 < 15) then 1 else 0 end ) as [ 14.5-15 MT_Conn],		
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 15 and v.cst_till_connAck/1000.0 < 15.5) then 1 else 0 end ) as [ 15-15.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 15.5 and v.cst_till_connAck/1000.0 < 16) then 1 else 0 end ) as [ 15.5-16 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 16 and v.cst_till_connAck/1000.0 < 16.5) then 1 else 0 end ) as [ 16-16.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 16.5 and v.cst_till_connAck/1000.0 < 17) then 1 else 0 end ) as [ 16.5-17 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 17 and v.cst_till_connAck/1000.0 < 17.5) then 1 else 0 end ) as [ 17-17.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 17.5 and v.cst_till_connAck/1000.0 < 18) then 1 else 0 end ) as [ 17.5-18 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 18 and v.cst_till_connAck/1000.0 < 18.5) then 1 else 0 end ) as [ 18-18.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 18.5 and v.cst_till_connAck/1000.0 < 19) then 1 else 0 end ) as [ 18.5-19 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 19 and v.cst_till_connAck/1000.0 < 19.5) then 1 else 0 end ) as [ 19-19.5 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 19.5 and v.cst_till_connAck/1000.0 < 20) then 1 else 0 end ) as [ 19.5-20 MT_Conn],
		SUM(case when (v.callDir = 'MT' and v.cst_till_connAck/1000.0 >= 20) then 1 else 0 end ) as [ >20 MT_Conn],
		--Rangos Connect MOMT
		SUM(case when v.cst_till_connAck/1000.0 >= 0 and v.cst_till_connAck/1000.0 < 0.5 then 1 else 0 end ) as [ 0-0.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 0.5 and v.cst_till_connAck/1000.0 < 1 then 1 else 0 end ) as [ 0.5-1 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 1 and v.cst_till_connAck/1000.0 < 1.5 then 1 else 0 end ) as [ 1-1.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 1.5 and v.cst_till_connAck/1000.0 < 2 then 1 else 0 end ) as [ 1.5-2 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 2 and v.cst_till_connAck/1000.0 < 2.5 then 1 else 0 end ) as [ 2-2.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 2.5 and v.cst_till_connAck/1000.0 < 3 then 1 else 0 end ) as [ 2.5-3 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 3 and v.cst_till_connAck/1000.0 < 3.5 then 1 else 0 end ) as [ 3-3.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 3.5 and v.cst_till_connAck/1000.0 < 4 then 1 else 0 end ) as [ 3.5-4 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 4 and v.cst_till_connAck/1000.0 < 4.5 then 1 else 0 end ) as [ 4-4.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 4.5 and v.cst_till_connAck/1000.0 < 5 then 1 else 0 end ) as [ 4.5-5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 5 and v.cst_till_connAck/1000.0 < 5.5 then 1 else 0 end ) as [ 5-5.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 5.5 and v.cst_till_connAck/1000.0 < 6 then 1 else 0 end ) as [ 5.5-6 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 6 and v.cst_till_connAck/1000.0 < 6.5 then 1 else 0 end ) as [ 6-6.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 6.5 and v.cst_till_connAck/1000.0 < 7 then 1 else 0 end ) as [ 6.5-7 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 7 and v.cst_till_connAck/1000.0 < 7.5 then 1 else 0 end ) as [ 7-7.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 7.5 and v.cst_till_connAck/1000.0 < 8 then 1 else 0 end ) as [ 7.5-8 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 8 and v.cst_till_connAck/1000.0 < 8.5 then 1 else 0 end ) as [ 8-8.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 8.5 and v.cst_till_connAck/1000.0 < 9 then 1 else 0 end ) as [ 8.5-9 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 9 and v.cst_till_connAck/1000.0 < 9.5 then 1 else 0 end ) as [ 9-9.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 9.5 and v.cst_till_connAck/1000.0 < 10 then 1 else 0 end ) as [ 9.5-10 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 10 and v.cst_till_connAck/1000.0 < 10.5 then 1 else 0 end ) as [ 10-10.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 10.5 and v.cst_till_connAck/1000.0 < 11 then 1 else 0 end ) as [ 10.5-11 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 11 and v.cst_till_connAck/1000.0 < 11.5 then 1 else 0 end ) as [ 11-11.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 11.5 and v.cst_till_connAck/1000.0 < 12 then 1 else 0 end ) as [ 11.5-12 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 12 and v.cst_till_connAck/1000.0 < 12.5 then 1 else 0 end ) as [ 12-12.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 12.5 and v.cst_till_connAck/1000.0 < 13 then 1 else 0 end ) as [ 12.5-13 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 13 and v.cst_till_connAck/1000.0 < 13.5 then 1 else 0 end ) as [ 13-13.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 13.5 and v.cst_till_connAck/1000.0 < 14 then 1 else 0 end ) as [ 13.5-14 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 14 and v.cst_till_connAck/1000.0 < 14.5 then 1 else 0 end ) as [ 14-14.5 MOMT_Conn],
		SUM(case when v.cst_till_connAck/1000.0 >= 14.5 and v.cst_till_connAck/1000.0 < 15 then 1 else 0 end ) as [ 14.5-15 MOMT_Conn],		
		SUM(case when v.cst_till_connAck/1000.0 >= 15 and v.cst_till_connAck/1000.0 < 15.5 then 1 else 0 end ) as [ 15-15.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 15.5 and v.cst_till_connAck/1000.0 < 16 then 1 else 0 end ) as [ 15.5-16 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 16 and v.cst_till_connAck/1000.0 < 16.5 then 1 else 0 end ) as [ 16-16.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 16.5 and v.cst_till_connAck/1000.0 < 17 then 1 else 0 end ) as [ 16.5-17 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 17 and v.cst_till_connAck/1000.0 < 17.5 then 1 else 0 end ) as [ 17-17.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 17.5 and v.cst_till_connAck/1000.0 < 18 then 1 else 0 end ) as [ 17.5-18 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 18 and v.cst_till_connAck/1000.0 < 18.5 then 1 else 0 end ) as [ 18-18.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 18.5 and v.cst_till_connAck/1000.0 < 19 then 1 else 0 end ) as [ 18.5-19 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 19 and v.cst_till_connAck/1000.0 < 19.5 then 1 else 0 end ) as [ 19-19.5 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 19.5 and v.cst_till_connAck/1000.0 < 20 then 1 else 0 end ) as [ 19.5-20 MOMT_Conn],	
		SUM(case when v.cst_till_connAck/1000.0 >= 20 then 1 else 0 end ) as [ >20 MOMT_Conn],

		@week as Meas_Week,
		@Meas_Round as Meas_Round,
		@Meas_Date as Meas_Date,
		@entidad as Entidad,
		null,
		@medida as 'Num_Medida',
		@Report,
		'Collection Name',
		null,
		calltype,
		v.[ASideDevice],
		'Fixed' as 'BSideDevice',
		v.[SWVersion]

	from 
		@All_Tests a,
		lcc_Calls_Detailed v,
		Sessions s

	where
		a.sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus = 'Completed'
		and s.valid=1
	group by v.mnc, calltype, v.[ASideDevice], v.[SWVersion]
end


select * from @voice_cst
