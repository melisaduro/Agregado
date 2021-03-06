USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_Negative_Events_UL]    Script Date: 29/05/2017 12:55:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_MDD_Data_Negative_Events_UL] (
	 --Variables de entrada
				@provincia as varchar(256),			-- si NED: '%%',	si paso1: valor
				@ciudad as varchar(256),			-- si NED: valor,	si paso1: '%%'				
				@simOperator as int,
				@Date as varchar (256),
				@Tech as varchar (256)  -- Para seleccionar entre 3G, 4G y CA
				)
AS

--use FY1516_DATA_Main_3G_H1_2

------------------------------------------------------------------------------
-- Los eventos negativos en datos son:
	--HTTP DL (3 Mbytes) – Timeout: 62.5 sec [384 kbps]
	--HTTP UL (1 Mbytes) - Timeout: 20.8 sec [384 kbps]
	--HTTP DL FDTT (500 Mbytes) – Timeout: 10 sec 
	--		- Minimum Throughput in order to consider a session as successful: 128 Kbps for downlink
	--HTTP UL FDTT (500 Mbytes) - Timeout: 10 sec 
	--		- Minimum Throughput in order to consider a session as successful: 64 Kbps for uplink

-- 20150924 - Solicitan:
--				- En el mismo kml todos los tipos de eventos, es decir, 
--				  todo lo que está por debajo de 3Mbps en el caso de DL para CE 
--				  y al mismo tiempo los fallos porque están por debajo de 384kbps. 
--				- Ambos se usan para distintas campañas de P3 y todos son importantes. 
------------------------------------------------------------------------------

-----------------------------
----- Testing Variables -----
-----------------------------
--declare @provincia as varchar(256) = '%%'
--declare @ciudad as varchar(256) = '%BARCELONA%'
--declare @sheet as varchar(256) = '%%'
--declare @date as varchar(256) = '%%'
--declare @Tech as varchar(256) = '3G'

--declare @simOperator as int = 1

------select * from Lcc_Data_HTTPTransfer_UL
	

-------------------------------------------------------------------------------
--	FILTRO GLOBAL		-------------------
-------------------------------------------------------------------------------		
--- UL - #All_Tests_UL
select v.sessionid, v.testid, 
	case when v.[% LTE]=1 then 'LTE'
		 when v.[% WCDMA]=1 then 'WCDMA'
	else 'Mixed' end as tech,
	v.[Longitud Final], v.[Latitud Final]
into #All_Tests_UL
from Lcc_Data_HTTPTransfer_UL v
Where v.collectionname like @Date + '%' + @ciudad + '%' + @Tech
	and v.info='completed' --DGP 17/09/2015: Filtramos solo los tests marcados como completados
	and v.MNC = @simOperator	--MNC
	and v.MCC= 214						--MCC - Descartamos los valores erróneos	


-------------------------------------------------------------------------------
--	GENERAL SELECT		-------------------	  
-------------------------------------------------------------------------------
select  
	v.IMEI,
	v.testid,
	v.CollectionName as LogFile,
	'Packet Switched data call' as TipoMedidas,
	v.MCC as Pais,
	v.MNC as Operador,
	v.startDate as Fecha,
	v.startTime as InicioDescarga,
	v.endTime as FinDescarga,
	v.[Longitud Final] as Longitud,
	v.[Latitud Final] as Latitud,
	v.DataTransferred_nu as 'DataTransferred',
	v.[ThputApp_nu]*1000.0 as 'Throughput',	-- salia en bps
	v.ErrorCause as Cause,
	v.[ErrorType]  as ErrorType,
	case when v.Testtype='UL_CE' then 'Customer Experience'
		 when v.Testtype='UL_NC' then 'Network Capability'
	else null end as TestType,
	v.ServiceType,
	v.[IPAccessTime_sec_nu] as [IP Access Time (ms)],
	v.[% LTE] as DatamodeUL_LTE,
	v.[% WCDMA] as DatamodeUL_HSUPA, 
	v.[% GSM] as DatamodeUL_GSM,
	v.TransferTime_nu as TransferTime,
	v.[Longitud Inicial],
	v.[Latitud Inicial],

	-- Inicial:
    v.[Tech_Ini],
	case when v.[Tech_Ini] in ('GSM', 'DCS', 'EGSM') then v.BSIC_Ini
			when v.[Tech_Ini] like '%UMTS%' then v.PSC_Ini
			when v.[Tech_Ini] like '%LTE%' then v.PCI_Ini
			end as Initial_BSIC_PSC_PCI,
	case when v.[Tech_Ini] in ('GSM', 'DCS', 'EGSM') then v.BCCH_Ini
			when v.[Tech_Ini] like '%UMTS%' then v.UARFCN_Ini
			when v.[Tech_Ini] like '%LTE%' then v.EARFCN_Ini
			end as Initial_BCCH_UARFCN_EARFCN,
	v.RNC_Ini as Initial_RNC,
	case when v.[Tech_Ini] in ('GSM', 'DCS', 'EGSM') then v.RxLev_Ini
			when v.[Tech_Ini] like '%UMTS%' then v.RSCP_Ini
			when v.[Tech_Ini] like '%LTE%' then v.RSRP_Ini
			end as Initial_SS,
	case when v.[Tech_Ini] in ('GSM', 'DCS', 'EGSM') then v.RxQual_Ini
			when v.[Tech_Ini] like '%UMTS%' then v.EcIo_Ini
			when v.[Tech_Ini] like '%LTE%' then v.RSRQ_Ini
			end as Initial_SQ,
	v.[SINR_Ini] as 'SINR Inicial',

	-- Final:
	v.[Tech_Fin],
	case when v.[Tech_Fin] in ('GSM', 'DCS', 'EGSM') then v.BSIC_Fin
			when v.[Tech_Fin] like '%UMTS%' then v.PSC_Fin
			when v.[Tech_Fin] like '%LTE%' then v.PCI_Fin
			end as Final_BSIC_PSC_PCI,
	case when v.[Tech_Fin] in ('GSM', 'DCS', 'EGSM') then v.BCCH_Ini
			when v.[Tech_Fin] like '%UMTS%' then v.UARFCN_Ini
			when v.[Tech_Fin] like '%LTE%' then v.EARFCN_Ini
			end as Final_BCCH_UARFCN_EARFCN,
	v.RNC_Fin as Final_RNC,
	case when v.[Tech_Fin] in ('GSM', 'DCS', 'EGSM') then v.RxLev_Fin
			when v.[Tech_Fin] like '%UMTS%' then v.RSCP_Fin
			when v.[Tech_Fin] like '%LTE%' then v.RSRP_Fin
			end as Final_SS,
	case when v.[Tech_Fin] in ('GSM', 'DCS', 'EGSM') then v.RxQual_Fin
			when v.[Tech_Fin] like '%UMTS%' then v.EcIo_Fin
			when v.[Tech_Fin] like '%LTE%' then v.RSRQ_Fin
			end as Final_SQ,
	v.[SINR_Fin] as 'SINR Final',

	-- Both:
	v.[CellId_Ini] as 'CellID Inicial',
	v.[CellId_Fin] as 'CellID Final',
	v.[LAC/TAC_Ini] as 'LAC Inicial',
	v.[LAC/TAC_Fin] as 'LAC Final',
	DB_name() as DDBB

into #final	
from 
	TestInfo t,
	#All_Tests_UL a,
	Lcc_Data_HTTPTransfer_UL v

where	
	a.SessionId=t.SessionId and a.TestId=t.TestId
	and t.valid=1
	and t.Sessionid=v.Sessionid and t.TestId=v.TestId
	--and v.Testtype='UL_CE'
	--and v.[ThputApp_nu]*1000.0 < 384000
	--and v.[ThputApp_nu] < 1000		-- son kilo bits no bytes
	and ((v.Testtype='UL_CE' and v.[ThputApp_nu] < 1000) or v.ErrorCause is not null)
	--and (v.[ThputApp_nu] < 1000 or v.ErrorCause is not null)

	 

--union all
--select  
--	v.IMEI,
--	v.testid,
--	v.CollectionName as LogFile,
--	'Packet Switched data call' as TipoMedidas,
--	v.MCC as Pais,
--	v.MNC as Operador,
--	v.startDate as Fecha,
--	v.startTime as InicioDescarga,
--	v.endTime as FinDescarga,
--	v.[Longitud Final] as Longitud,
--	v.[Latitud Final] as Latitud,
--	v.DataTransferred_nu as 'DataTransferred',
--	v.[ThputApp_nu]*1000.0 as 'Throughput',	-- salia en bps
--	v.ErrorCause as Cause,
--	v.[ErrorType]  as ErrorType,
--	case when v.Testtype='UL_CE' then 'Customer Experience'
--		 when v.Testtype='UL_NC' then 'Network Capability'
--	else null end as TestType,
--	v.ServiceType,
--	v.[IPAccessTime_sec_nu] as [IP Access Time (ms)],
--	v.[% LTE] as DatamodeUL_LTE,
--	v.[% WCDMA] as DatamodeUL_HSUPA, 
--	v.[% GSM] as DatamodeUL_GSM,
--	v.TransferTime_nu as TransferTime,
--	v.[Longitud Inicial],
--	v.[Latitud Inicial],

--	-- Inicial:
--    v.[Tech_Ini],
--	case when v.[Tech_Ini] in ('GSM', 'DCS', 'EGSM') then v.BSIC_Ini
--			when v.[Tech_Ini] like '%UMTS%' then v.PSC_Ini
--			when v.[Tech_Ini] like '%LTE%' then v.PCI_Ini
--			end as Initial_BSIC_PSC_PCI,
--	case when v.[Tech_Ini] in ('GSM', 'DCS', 'EGSM') then v.BCCH_Ini
--			when v.[Tech_Ini] like '%UMTS%' then v.UARFCN_Ini
--			when v.[Tech_Ini] like '%LTE%' then v.EARFCN_Ini
--			end as Initial_BCCH_UARFCN_EARFCN,
--	v.RNC_Ini as Initial_RNC,
--	case when v.[Tech_Ini] in ('GSM', 'DCS', 'EGSM') then v.RxLev_Ini
--			when v.[Tech_Ini] like '%UMTS%' then v.RSCP_Ini
--			when v.[Tech_Ini] like '%LTE%' then v.RSRP_Ini
--			end as Initial_SS,
--	case when v.[Tech_Ini] in ('GSM', 'DCS', 'EGSM') then v.RxQual_Ini
--			when v.[Tech_Ini] like '%UMTS%' then v.EcIo_Ini
--			when v.[Tech_Ini] like '%LTE%' then v.RSRQ_Ini
--			end as Initial_SQ,
--	v.[SINR_Ini] as 'SINR Inicial',

--	-- Final:
--    v.[Tech_Fin],
--	case when v.[Tech_Fin] in ('GSM', 'DCS', 'EGSM') then v.BSIC_Fin
--			when v.[Tech_Fin] like '%UMTS%' then v.PSC_Fin
--			when v.[Tech_Fin] like '%LTE%' then v.PCI_Fin
--			end as Final_BSIC_PSC_PCI,
--	case when v.[Tech_Fin] in ('GSM', 'DCS', 'EGSM') then v.BCCH_Ini
--			when v.[Tech_Fin] like '%UMTS%' then v.UARFCN_Ini
--			when v.[Tech_Fin] like '%LTE%' then v.EARFCN_Ini
--			end as Final_BCCH_UARFCN_EARFCN,
--	v.RNC_Fin as Final_RNC,
--	case when v.[Tech_Fin] in ('GSM', 'DCS', 'EGSM') then v.RxLev_Fin
--			when v.[Tech_Fin] like '%UMTS%' then v.RSCP_Fin
--			when v.[Tech_Fin] like '%LTE%' then v.RSRP_Fin
--			end as Final_SS,
--	case when v.[Tech_Fin] in ('GSM', 'DCS', 'EGSM') then v.RxQual_Fin
--			when v.[Tech_Fin] like '%UMTS%' then v.EcIo_Fin
--			when v.[Tech_Fin] like '%LTE%' then v.RSRQ_Fin
--			end as Final_SQ,
--	v.[SINR_Fin] as 'SINR Final',

--	-- Both:
--	v.[CellId_Ini] as 'CellID Inicial',
--	v.[CellId_Fin] as 'CellID Final',
--	v.[LAC/TAC_Ini] as 'LAC Inicial',
--	v.[LAC/TAC_Fin] as 'LAC Final',
--	DB_name() as DDBB
--from 
--	TestInfo t,
--	#All_Tests_UL a,
--	Lcc_Data_HTTPTransfer_UL v

--where	
--	a.SessionId=t.SessionId and a.TestId=t.TestId
--	and t.valid=1
--	and t.Sessionid=v.Sessionid and t.TestId=v.TestId
--	and v.Testtype='UL_NC'
--	--and v.[ThputApp_nu]*1000.0 < 64000
--	and v.[ThputApp_nu] < 1000	-- son kilo bits no bytes

--order by v.endTime

----------------------------
-- Añadimos Info de parcelas
select  f.*,
		lp.nombre as Parcela,
		lp.provincia as Provincia,
		lp.entorno as Entorno,
		--lp.entorno_TLT as Entorno_TLT,
		lp.ciudad as Ciudad,
		lp.condado as Condado
	into #V	
	from #final f
		LEFT OUTER JOIN Agrids.dbo.lcc_parcelas lp on lp.Nombre=master.dbo.fn_lcc_getParcel(f.Longitud, f.Latitud)
		

select * from #V 
order by FinDescarga


-------------------------------------------------------------------------------
--	Borrado Tablas		-------------------	  
-------------------------------------------------------------------------------
drop table #All_Tests_UL, #V, #final

