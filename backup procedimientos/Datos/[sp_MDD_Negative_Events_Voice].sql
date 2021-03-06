USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Negative_Events_Voice]    Script Date: 29/05/2017 13:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Negative_Events_Voice] 

AS

declare @simOperator as int = 1
		
------------------------------------------------------------------------------------
--	Eventos negativos VOZ:
------------------------------------------------------------------------------------
exec dbo.sp_lcc_DropIfExists '_lcc_Negative_Events_Voice'
	  
select 
	--@reportWeek as 'Week',
	master.dbo.fn_lcc_getElement(4,v.collectionname,'_')  as [Municipio / Entidad], 
	case when db_name() like '%Road%' then '4G'
		 else master.dbo.fn_lcc_getElement(4,db_name(),'_') end as 'Tech DT' ,
	db_name() as 'DDBB', 
	v.Sessionid,
	v.ASideFileName as LogFile,
	v.callStartTimeStamp as StartDate,
	v.longitude_Fin_A as Final_Longitude_A,
	v.latitude_Fin_A as Final_Latitude_A,
	v.calltype,
	v.callDir as CallDirection,
	v.EndTechnology,
	v.[LAC/TAC_Fin] as Final_LAC,
	v.CellId_Fin as Final_CellId,
	case when v.EndTechnology like '%GSM%' then v.BCCH_Ini
		when v.EndTechnology like '%UMTS%' then v.UARFCN_Ini
		when v.EndTechnology like '%LTE%' then v.EARFCN_Ini
		end as Final_BCCH_UARFCN_EARFCN,
	case when v.EndTechnology like '%GSM%' then v.BSIC_Fin
		when v.EndTechnology like '%UMTS%' then v.PSC_Fin
		when v.EndTechnology like '%LTE%' then v.PCI_Fin
		end as Final_BSIC_PSC_PCI,
	v.callstatus,
	'' as 'Cell Name',
	'' as 'RxLev/RSCP', '' as 'RxQual/EcI0', '' as Issue, '' as 'Description', '' as 'Type'

into _lcc_Negative_Events_Voice
from 
		--#All_Tests a,
		lcc_Calls_Detailed v,
		Sessions s

where
		--a.Sessionid=v.Sessionid	and 
		s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and (v.callStatus='Dropped' or v.callStatus='Failed')
		and s.valid=1
		and v.MNC=1

order by v.callEndTimeStamp


----------------------------
-- Añadimos Info de parcelas
exec dbo.sp_lcc_DropIfExists 'lcc_Negative_Events_Voice'

select  f.*,
		lp.provincia as Provincia,
		lp.entorno as Entorno,
		lp.ciudad as Ciudad,
		lp.condado as Condado
	into lcc_Negative_Events_Voice	
	from _lcc_Negative_Events_Voice f
		LEFT OUTER JOIN	Agrids.dbo.lcc_parcelas lp on (lp.Nombre=master.dbo.fn_lcc_getParcel(f.Final_Longitude_A, f.Final_Latitude_A))

--drop table #All_Tests
-- select * from lcc_Negative_Events_Voice


