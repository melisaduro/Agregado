USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Libro_MOS]    Script Date: 29/05/2017 13:16:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_Libro_MOS] (
	 --Variables de entrada
				@mob1 as varchar(256),
				@mob2 as varchar(256),
				@mob3 as varchar(256),
				@ciudad as varchar(256),
				@simOperator as int,
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
				@fecha_fin_text10 as varchar (256)	
				)
AS

-----------------------------
----- Testing Variables -----
-----------------------------
--declare @mob1 as varchar(256) = '355828061803206'
--declare @mob2 as varchar(256) = '355828061804360'
--declare @mob3 as varchar(256) = 'Ninguna'

--declare @fecha_ini_text1 as varchar (256) = '2015-02-15 00:00:00:000'
--declare @fecha_fin_text1 as varchar (256) = '2015-02-28 23:59:59:000'
--declare @fecha_ini_text2 as varchar (256) = '2015-01-13 20:11:00:000'
--declare @fecha_fin_text2 as varchar (256) = '2015-01-13 20:11:00:000'
--declare @fecha_ini_text3 as varchar (256) = '2014-08-20 13:33:00:000'
--declare @fecha_fin_text3 as varchar (256) = '2014-08-20 13:33:00:000'
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


--declare @ciudad as varchar(256) = 'Madrid'
--declare @simOperator as int = 1

-------------------------------------------------------------------------------
-- Declaramos las fechas	
declare @fecha_ini1 as datetime = @fecha_ini_text1
declare @fecha_fin1 as datetime = @fecha_fin_text1
declare @fecha_ini2 as datetime = @fecha_ini_text2
declare @fecha_fin2 as datetime = @fecha_fin_text2
declare @fecha_ini3 as datetime = @fecha_ini_text3
declare @fecha_fin3 as datetime = @fecha_fin_text3
declare @fecha_ini4 as datetime = @fecha_ini_text4
declare @fecha_fin4 as datetime = @fecha_fin_text4
declare @fecha_ini5 as datetime = @fecha_ini_text5
declare @fecha_fin5 as datetime = @fecha_fin_text5
declare @fecha_ini6 as datetime = @fecha_ini_text6
declare @fecha_fin6 as datetime = @fecha_fin_text6
declare @fecha_ini7 as datetime = @fecha_ini_text7
declare @fecha_fin7 as datetime = @fecha_fin_text7
declare @fecha_ini8 as datetime = @fecha_ini_text8
declare @fecha_fin8 as datetime = @fecha_fin_text8
declare @fecha_ini9 as datetime = @fecha_ini_text9
declare @fecha_fin9 as datetime = @fecha_fin_text9
declare @fecha_ini10 as datetime = @fecha_ini_text10
declare @fecha_fin10 as datetime = @fecha_fin_text10


-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------		  
select v.sessionid

into #All_Tests
from lcc_Calls_Detailed v
Where v.collectionname like '%' + @ciudad + '%'
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos	
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



------------------------------------------------------------------------------------
------------------------------- GENERAL SELECT
----------------- MOS and Codec External Book Info per Endcall
------------------------------------------------------------------------------------

select 
		v.MTU,
		v.ASideFileName as LogFile,
		v.callDir as CallDirection,
		v.MCC as Country,
		v.MNC as Operator,
		v.callStartTimeStamp as LogDate,
		v.callStartTimeStamp as StartDate,
		v.callEndTimeStamp as EndDate,
		v.callDuration as Duration,
		v.SQNS,
		v.is_CSFB as Is_CSFB_Call,
		v.MOS_NB as MOS_AVG, -- At this moment we only use NarrowBand
		v.MOS_NB_DL as MOS_DL, -- At this moment we only use NarrowBand
		v.MOS_NB_UL as MOS_UL, -- At this moment we only use NarrowBand
		1.0 * v.EFR_Count/v.Codec_Registers as '% EFR',
		1.0 * v.HR_Count/v.Codec_Registers as '% HR',
		1.0 * v.FR_Count/v.Codec_Registers as '% FR',
		1.0 * v.AMR_HR_Count/v.Codec_Registers as '% AMR HR',
		1.0 * v.AMR_FR_Count/v.Codec_Registers as '% AMR FR',
		1.0 * v.AMR_WB_Count/v.Codec_Registers as '% AMR WB'

from 
		#All_Tests a,
		lcc_Calls_Detailed v

where	
		a.Sessionid=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus='Completed' -- Only in Endcalls

drop table #all_Tests
