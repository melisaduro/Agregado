USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Libro_Dropped_Calls_OSP]    Script Date: 29/05/2017 13:15:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_Libro_Dropped_Calls_OSP] (
	 --Variables de entrada
				@ciudad as varchar(256),
				@simOperator as int,
				@type as varchar (256),
				@Date as varchar (256),
				@TechF as varchar (256),
				@Environ as varchar (256)
				)
AS

-----------------------------
----- Testing Variables -----
-----------------------------
---- use OSP1617_EVENTOS
 
----declare @ciudad as varchar(256) = 'huelva'
----declare @simOperator as int = 3
----declare @type as varchar(256) = 'M2F'
----declare @Date as varchar(256) = ''
----declare @TechF as varchar(256) = '4G'
----declare @Environ as varchar(256) = '%%'

		
-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------		  
select v.sessionid

into #All_Tests
from lcc_Calls_Detailed v
Where v.collectionname like @Date + '%' + @ciudad + '%' + @TechF
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos	
	and v.calltype = 'M2F'	--@type


------------------------------------------------------------------------------------
------------------------------- GENERAL SELECT
-------------------- Drop Calls Disaggregated Info Book
------------------------------------------------------------------------------------
	  
select  v.Sessionid,
		v.ASideFileName as LogFile,
		--v.imei,
		v.callDir as CallDirection,
		v.calltype,
		v.MCC as Country,
		v.MNC as Operator,
		convert(varchar(10),datepart(dd, v.callStartTimeStamp))+'/'+convert(varchar(10),datepart(mm, v.callStartTimeStamp)) as LogDate,
		v.callStartTimeStamp as StartDate,
		convert(varchar(10),datepart(hh, v.callStartTimeStamp))+':'+
		convert(varchar(10), case 
								when datepart(mi, v.callStartTimeStamp) >= 0  and datepart(mi, v.callStartTimeStamp)<15 then '00'
								when datepart(mi, v.callStartTimeStamp) >= 15 and datepart(mi, v.callStartTimeStamp)<30 then '15'
								when datepart(mi, v.callStartTimeStamp) >= 30 and datepart(mi, v.callStartTimeStamp)<45 then '30'
								when datepart(mi, v.callStartTimeStamp) >= 45 and datepart(mi, v.callStartTimeStamp)<=59 then '45'
							end) + '.00' as ROP_Inicio,

		v.callEndTimeStamp as DropDate,
		convert(varchar(10),datepart(hh, callEndTimeStamp))+':'+
		convert(varchar(10), case 
								when datepart(mi, callEndTimeStamp) >= 0  and datepart(mi, callEndTimeStamp)<15 then '00'
								when datepart(mi, callEndTimeStamp) >= 15 and datepart(mi, callEndTimeStamp)<30 then '15'
								when datepart(mi, callEndTimeStamp) >= 30 and datepart(mi, callEndTimeStamp)<45 then '30'
								when datepart(mi, callEndTimeStamp) >= 45 and datepart(mi, callEndTimeStamp)<=59 then '45'
							end) + '.00' as ROP_final,
		v.callDuration as Duration,
		v.codeDescription as Cause,

		m.ExtendedSR_Time_A_DLEARFCN as Initial_DL_EARFCN, 
		--m.ExtendedSR_Time_A_PCI as Initial_PCI_, 
		case when v.StartTechnology like '%LTE%' then v.PCI_Ini end as Initial_PCI,
		--case when v.StartTechnology like '%LTE%' then v.EARFCN_Ini end as Initial_EARFCN,

		v.is_CSFB as Is_CSFB_Call,

		--case when v.StartTechnology like '%UMTS%' then v.UARFCN_Ini end as Initial_UARFCN,
		--case when v.StartTechnology like '%UMTS%' then v.PSC_ini end as Initial_SC,
		m.CMService_Request_DLARFCN as Initial_UARFCN,
		m.CMService_Request_SC as Initial_SC,

		--v.is_CSFB as Is_CSFB_Call,
		--v.CMService_UARFCN,
		--v.CMService_Band,
		--v.Alerting_UARFCN,
		--v.Alerting_Band,
		--v.Connect_UARFCN,
		--v.Connect_Band,
		--v.Disconnect_UARFCN,
		--v.Disconnect_Band,
		--v.technology as Technology,
		--v.Hopping,
		--v.StartTechnology,
		--v.[LAC/TAC_Ini] as Initial_LAC,
		--v.CellId_Ini as Initial_CellId,
		--case when v.StartTechnology like '%GSM%' then v.BSIC_Ini
		--	 when v.StartTechnology like '%UMTS%' then v.PSC_Ini
		--	 when v.StartTechnology like '%LTE%' then v.PCI_Ini
		--	 end as Initial_BSIC_PSC_PCI,
		--case when v.StartTechnology like '%GSM%' then v.BCCH_Ini
		--	 when v.StartTechnology like '%UMTS%' then v.UARFCN_Ini
		--	 when v.StartTechnology like '%LTE%' then v.EARFCN_Ini
		--	 end as Initial_BCCH_UARFCN_EARFCN,
		----v.UARFCN_Ini as Initial_UARFCN,
		--v.RNC_Ini as Initial_RNC,
		case when v.StartTechnology like '%GSM%' then v.RxLev_Ini
			 when v.StartTechnology like '%UMTS%' then v.RSCP_Ini
			 when v.StartTechnology like '%LTE%' then v.RSRP_Ini
			 end as Initial_SS,
		case when v.StartTechnology like '%GSM%' then v.RxQual_Ini
			 when v.StartTechnology like '%UMTS%' then v.EcIo_Ini
			 when v.StartTechnology like '%LTE%' then v.RSRQ_Ini
			 end as Initial_SQ,
		--case when v.StartTechnology like '%LTE%' then v.SINR_Aside_ini end as SINR_Ini,
		--v.EndTechnology,
		--v.[LAC/TAC_Fin] as Final_LAC,
		--v.CellId_Fin as Final_CellId,
		--case when v.EndTechnology like '%GSM%' then v.BSIC_Fin
		--	 when v.EndTechnology like '%UMTS%' then v.PSC_Fin
		--	 when v.EndTechnology like '%LTE%' then v.PCI_Fin
		--	 end as Final_BSIC_PSC_PCI,
		--case when v.EndTechnology like '%GSM%' then v.BCCH_Ini
		--	 when v.EndTechnology like '%UMTS%' then v.UARFCN_Ini
		--	 when v.EndTechnology like '%LTE%' then v.EARFCN_Ini
		--	 end as Final_BCCH_UARFCN_EARFCN,
		----v.UARFCN_Fin as Final_UARFCN,
		--v.RNC_Fin as Final_RNC,
		case when v.EndTechnology like '%GSM%' then v.RxLev_Fin
			 when v.EndTechnology like '%UMTS%' then v.RSCP_Fin
			 when v.StartTechnology like '%LTE%' then v.RSRP_Fin
			 end as Final_SS,
		case when v.EndTechnology like '%GSM%' then v.RxQual_Fin
			 when v.EndTechnology like '%UMTS%' then v.EcIo_Fin
			 when v.EndTechnology like '%LTE%' then v.RSRQ_Fin
			 end as Final_SQ,
		--case when v.EndTechnology like '%LTE%' then v.SINR_Aside_fin end as SINR_Fin,
		--v.average_technology as Average_Technology,
		case when v.average_technology like '%GSM%' then v.RxLev
			 when v.average_technology like '%UMTS%' then v.RSCP
			 when v.average_technology like '%LTE%' then v.RSRP
			 end as Average_SS,
		case when v.average_technology like '%GSM%' then v.RxQual
			 when v.average_technology like '%UMTS%' then v.EcIo
			 when v.average_technology like '%LTE%' then v.RSRQ
			 end as Average_SQ,
		--case when v.average_technology like '%LTE%' then v.SINR_Aside end as Average_SINR,
		--case when v.average_technology like '%GSM%' then v.N1_RxLev
		--	 when v.average_technology like '%UMTS%' then v.N1_RSCP
		--	-- when v.average_technology like '%LTE%' then v.N1_RSRP
		--	 end as Neighbor1_SS,
		--case when v.average_technology like '%GSM%' then v.RxLev_min
		--	 when v.average_technology like '%UMTS%' then v.RSCP_Min
		--	-- when v.average_technology like '%LTE%' then v.RSRP_Min
		--	 end as Min_SS,
		--case when v.average_technology like '%GSM%' then v.RxQual_min
		--	 when v.average_technology like '%UMTS%' then v.EcIo_min
		--	-- when v.average_technology like '%LTE%' then v.RSRQ_Min
		--	 end as Worst_SQ,
		--v.Fast_Return_Duration,
		--v.Fast_Return_Freq_Dest,
		--v.longitude_Ini_A as Initial_Longitude_A,
		--v.latitude_Ini_A as Initial_Latitude_A,
		--v.longitude_Ini_B as Initial_Longitude_B,
		--v.latitude_Ini_B as Initial_Latitude_B,
		v.longitude_Fin_A as Final_Longitude_A,
		v.latitude_Fin_A as Final_Latitude_A,
		--v.longitude_Fin_B as Final_Longitude_B,
		--v.latitude_Fin_B as Final_Latitude_B,

		case when v.[PCI_Ini]=[PCI_fin] then 'Completa'
	else 'Parcial' end as Status,

		DB_name() as DDBB
		
		--,		
		--v.is_VoLTE as Volte,
		--v.Speech_Delay as [Volte Speech Delay],
		--v.is_SRVCC as SRVCC,
		--v.technology_BSide,
		--v.CMService_UARFCN_B,
		--v.CMService_Band_B,
		--v.Alerting_UARFCN_B,
		--v.Alerting_Band_B,
		--v.Connect_UARFCN_B,
		--v.Connect_Band_B,
		--v.Disconnect_UARFCN_B,
		--v.Disconnect_Band_B,
		--v.Hopping_BSide,
		--v.StartTechnology_BSide,
		--v.[LAC/TAC_Ini_BSide] as Initial_LAC_BSide,
		--v.CellId_Ini_BSide as Initial_CellId_BSide,
		--case when v.StartTechnology_BSide like '%GSM%' then v.BSIC_Ini_BSide
		--	 when v.StartTechnology_BSide like '%UMTS%' then v.PSC_Ini_BSide
		--	 when v.StartTechnology_BSide like '%LTE%' then v.PCI_Ini_BSide
		--	 end as Initial_BSIC_PSC_PCI_BSide,
		--case when v.StartTechnology_BSide like '%GSM%' then v.BCCH_Ini_BSide
		--	 when v.StartTechnology_BSide like '%UMTS%' then v.UARFCN_Ini_BSide
		--	 when v.StartTechnology_BSide like '%LTE%' then v.EARFCN_Ini_BSide
		--	 end as Initial_BCCH_UARFCN_EARFCN_BSide,
		----v.UARFCN_Ini as Initial_UARFCN,
		--v.RNC_Ini_BSide as Initial_RNC_BSide,
		--case when v.StartTechnology_BSide like '%GSM%' then v.RxLev_Ini_BSide
		--	 when v.StartTechnology_BSide like '%UMTS%' then v.RSCP_Ini_BSide
		--	 when v.StartTechnology_BSide like '%LTE%' then v.RSRP_Ini_BSide
		--	 end as Initial_SS_BSide,
		--case when v.StartTechnology_BSide like '%GSM%' then v.RxQual_Ini_BSide
		--	 when v.StartTechnology_BSide like '%UMTS%' then v.EcIo_Ini_BSide
		--	 when v.StartTechnology_BSide like '%LTE%' then v.RSRQ_Ini_BSide
		--	 end as Initial_SQ_BSide,
		--case when v.StartTechnology_BSide like '%LTE%' then v.SINR_Bside_ini end as SINR_Ini_BSide,
		--v.EndTechnology_BSide,
		--v.[LAC/TAC_Fin_BSide] as Final_LAC_BSide,
		--v.CellId_Fin_BSide as Final_CellId_BSide,
		--case when v.EndTechnology_BSide like '%GSM%' then v.BSIC_Fin_BSide
		--	 when v.EndTechnology_BSide like '%UMTS%' then v.PSC_Fin_BSide
		--	 when v.EndTechnology_BSide like '%LTE%' then v.PCI_Fin_BSide
		--	 end as Final_BSIC_PSC_PCI_BSide,
		--case when v.EndTechnology_BSide like '%GSM%' then v.BCCH_Ini_BSide
		--	 when v.EndTechnology_BSide like '%UMTS%' then v.UARFCN_Ini_BSide
		--	 when v.EndTechnology_BSide like '%LTE%' then v.EARFCN_Ini_BSide
		--	 end as Final_BCCH_UARFCN_EARFCN_BSide,
		----v.UARFCN_Fin as Final_UARFCN,
		--v.RNC_Fin as Final_RNC_BSide,
		--case when v.EndTechnology_BSide like '%GSM%' then v.RxLev_Fin_BSide
		--	 when v.EndTechnology_BSide like '%UMTS%' then v.RSCP_Fin_BSide
		--	 when v.StartTechnology_BSide like '%LTE%' then v.RSRP_Fin_BSide
		--	 end as Final_SS_BSide,
		--case when v.EndTechnology_BSide like '%GSM%' then v.RxQual_Fin_BSide
		--	 when v.EndTechnology_BSide like '%UMTS%' then v.EcIo_Fin_BSide
		--	 when v.EndTechnology_BSide like '%LTE%' then v.RSRQ_Fin_BSide
		--	 end as Final_SQ_BSide,
		--case when v.EndTechnology_BSide like '%LTE%' then v.SINR_Bside_fin end as SINR_Fin_BSide,
		--v.average_technology_B as Average_Technology_B,
		--case when v.average_technology_B like '%GSM%' then v.RxLev_BSide
		--	 when v.average_technology_B like '%UMTS%' then v.RSCP_BSide
		--	 when v.average_technology_B like '%LTE%' then v.RSRP_BSide
		--	 end as Average_SS_BSide,
		--case when v.average_technology_B like '%GSM%' then v.RxQual_BSide
		--	 when v.average_technology_B like '%UMTS%' then v.EcIo_BSide
		--	 when v.average_technology_B like '%LTE%' then v.RSRQ_BSide
		--	 end as Average_SQ_BSide,
		--case when v.average_technology_B like '%LTE%' then v.SINR_Bside end as Average_SINR_BSide,
		--v.CSFB_Device,
		--v.RTP_Jitter_DL,
		--v.RTP_Jitter_UL,
		--v.RTP_Delay_DL,
		--v.RTP_Delay_UL,
		--v.RTP_Jitter_DL_BSide,
		--v.RTP_Jitter_UL_BSide,
		--v.RTP_Delay_DL_BSide,
		--v.RTP_Delay_UL_BSide,
		--v.Paging_Success_Ratio,
		--v.Paging_Success_Ratio_BSide,
		--v.PDP_Activate_Ratio,
		--v.PDP_Activate_Ratio_BSide,
		--v.EARFCN_N1,
		--v.PCI_N1,
		--v.RSRP_N1,
		--v.RSRQ_N1,
		--v.EARFCN_N1_BSide,
		--v.PCI_N1_BSide,
		--v.RSRP_N1_BSide,
		--v.RSRQ_N1_BSide,
		--v.SRVCC_SR,
		--v.SRVCC_SR_BSide,
		--v.IRAT_HO2G3G_Ratio,
		--v.IRAT_HO2G3G_Ratio_BSide,
		--v.num_HO_S1X2,
		--v.duration_S1X2_avg,
		--v.S1X2HO_SR,
		--v.num_HO_S1X2_BSide,
		--v.duration_S1X2_avg_BSide,
		--v.S1X2HO_SR_BSide

into #final
from 
		#All_Tests a
			LEFT OUTER JOIN lcc_markers_time m on m.sessionid=a.sessionid		-- select * from lcc_markers_time
			LEFT OUTER JOIN lcc_status_OSP st on st.sessionid=a.sessionid
		,
		lcc_Calls_Detailed v,
		Sessions s

where
		a.Sessionid=v.Sessionid
		and s.SessionId=v.Sessionid
		and v.callDir <> 'SO'
		and v.callStatus='Dropped'
		and s.valid=1

order by v.callEndTimeStamp

-- DGP 20/11/2015:
-- Separamos los resultados por tipo de scope:
-- BenchMarkers: Sólo se muestran los tests con GPS
-- FreeRiders: Se muestran todos los tests, y se añade la info de GPS a los que tengan

if (db_name() like '%Indoor%' or db_name() like '%AVE%')
begin
	select  f.*,
			lp.nombre as Parcela,
			lp.Region,
			lp.provincia as Provincia,
			lp.entorno as Entorno,
			lp.entorno_TLT as Entorno_TLT,
			lp.ciudad as Ciudad,
			lp.condado as Condado
		into #DI	
		from #final f
			LEFT OUTER JOIN	Agrids.dbo.lcc_parcelas lp on (lp.Nombre=master.dbo.fn_lcc_getParcel(f.Final_Longitude_A, f.Final_Latitude_A))

select * from #DI 
order by DropDate

drop table #All_Tests,#final,#DI
end

else
begin
	select  f.*,
			lp.nombre as Parcela,
			lp.Region,
			lp.provincia as Provincia,
			lp.entorno as Entorno,
			--lp.entorno_TLT as Entorno_TLT,
			lp.ciudad as Ciudad,
			lp.condado as Condado
		into #D	
		from #final f, Agrids.dbo.lcc_parcelas lp 
		where lp.Nombre=master.dbo.fn_lcc_getParcel(f.Final_Longitude_A, f.Final_Latitude_A)
		and lp.entorno like @Environ

select * from #D 
order by DropDate

drop table #All_Tests,#final,#D
end
