USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Negative_Events_Data]    Script Date: 29/05/2017 13:08:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Negative_Events_Data] 

AS

declare @simOperator as int = 1
		
-------------------------------------------------------------------------------
--	Eventos negativos DATOS:
-------------------------------------------------------------------------------	
exec dbo.sp_lcc_DropIfExists '_test_thput_bajo_384'

select 
	--'' as 'Week',
	master.dbo.fn_lcc_getElement(4,collectionname,'_')  as 'Municipio / Entidad',
	[ddbb] as DDBB
	,[Fecha]
	,[CollectionName]
	,[SessionId]
	,[testid]
	,[TestType]
	,[Throughput_app]
	, case 
		when [TestType]='DL_CE' and [Throughput_app]<384 then 'DL_CE < 384 Kbps'
		when [TestType]='UL_CE' and [Throughput_app]<384 then 'UL_CE < 384 Kbps'

		when [TestType]='DL_NC' and [Throughput_app]<128 then 'DL_NC < 128 Kbps'
		when [TestType]='UL_NC' and [Throughput_app]<64 then 'UL_NC < 64 Kbps'
	end as Thput_bajo
	,[TestStatus]
	,[ErrorCause]
	,[Operador]
	,[Tecn Inicio]
	,[Tecn Inicio Thput]
	,[Tecn Fin Thput]

into _test_thput_bajo_384

from dbo.Lcc_Data_HTTPTransfer_DL_Estudio
where 
	Operador=@simOperator
	--and ddbb like '%' + @scope + '%' + @Tech + '%' 
	and  [Throughput_app]<384		--es el general, los NC tiene limites menores
	and valid=1

---------------------------------------------------------------------------------
union all
select 
	--'' as 'Week',
	master.dbo.fn_lcc_getElement(4,collectionname,'_')  as 'Municipio / Entidad',
	[ddbb] as DDBB
	,[Fecha]
	,[CollectionName]
	,[SessionId]
	,[testid]
	,[TestType]
	,[Throughput_app]
	, case 
		when [TestType]='DL_CE' and [Throughput_app]<384 then 'DL_CE < 384 Kbps'
		when [TestType]='UL_CE' and [Throughput_app]<384 then 'UL_CE < 384 Kbps'

		when [TestType]='DL_NC' and [Throughput_app]<128 then 'DL_NC < 128 Kbps'
		when [TestType]='UL_NC' and [Throughput_app]<64 then 'UL_NC < 64 Kbps'
	end as Thput_bajo
	,[TestStatus]
	,[ErrorCause]
	,[Operador]
	,[Tecn Inicio]
	,[Tecn Inicio Thput]
	,[Tecn Fin Thput]

from dbo.Lcc_Data_HTTPTransfer_UL_Estudio
where 
		Operador=@simOperator
	--and ddbb like '%' + @scope + '%' + @Tech + '%' 
	and  [Throughput_app]<384		--es el general, los NC tiene limites menores
	and valid=1


-------------------------------------------------------------------------------------
-- Nos quedamos solo con los que cumplen la condiciones en funcion del tipo de test
exec dbo.sp_lcc_DropIfExists '_test_thput_bajo'

select * 
into _test_thput_bajo
from _test_thput_bajo_384 
where thput_bajo is not null

-- select * from #test_thput_bajo order by [Throughput_app]
-- drop table #test_thput_bajo, #test_thput_bajo_384


-------------------------------------------------------------------------------------
-- Se le añade info radio correspondiente a los test seleccionados
exec dbo.sp_lcc_DropIfExists '_lcc_Negative_Events_Data'

select th.* 
	, case when th.TestType like 'DL_%' then dl.[BCCH_Fin] 
		   when th.TestType like 'UL_%' then ul.[BCCH_Fin] end as [BCCH_Fin]

	, case when th.TestType like 'DL_%' then dl.[BSIC_Fin]
		   when th.TestType like 'UL_%' then ul.[BSIC_Fin] end as [BSIC_Fin]	

	, case when th.TestType like 'DL_%' then dl.[PSC_Fin]
		   when th.TestType like 'UL_%' then ul.[PSC_Fin] end as [PSC_Fin]

	, case when th.TestType like 'DL_%' then dl.[UARFCN_Fin]
		   when th.TestType like 'UL_%' then ul.[UARFCN_Fin] end as [UARFCN_Fin]

	, case when th.TestType like 'DL_%' then dl.[PCI_Fin]
		   when th.TestType like 'UL_%' then ul.[PCI_Fin] end as [PCI_Fin]
		   	
	, case when th.TestType like 'DL_%' then dl.[EARFCN_Fin]
		   when th.TestType like 'UL_%' then ul.[EARFCN_Fin] end as [EARFCN_Fin]
		   	
	, case when th.TestType like 'DL_%' then dl.[CellId_Fin]
		   when th.TestType like 'UL_%' then ul.[CellId_Fin] end as [CellId_Fin]

	, case when th.TestType like 'DL_%' then dl.[LAC/TAC_Fin]
		   when th.TestType like 'UL_%' then ul.[LAC/TAC_Fin] end as [LAC/TAC_Fin]

	, case when th.TestType like 'DL_%' then dl.[RNC_Fin]
		   when th.TestType like 'UL_%' then ul.[RNC_Fin] end as [RNC_Fin]
		   	
	, case when th.TestType like 'DL_%' then dl.[Longitud Final]
		   when th.TestType like 'UL_%' then ul.[Longitud Final] end as [Longitud Final]

	, case when th.TestType like 'DL_%' then dl.[Latitud Final]
		   when th.TestType like 'UL_%' then ul.[Latitud Final] end as [Latitud Final]

	,'' as 'Cell Name','' as 'Issue','' as 'Description','' as 'Type'

into _lcc_Negative_Events_Data
from _test_thput_bajo th
	left outer join [Lcc_Data_HTTPTransfer_DL] dl on (dl.testid=th.testid and th.TestType like 'DL_%')
	left outer join [Lcc_Data_HTTPTransfer_UL] ul on (ul.testid=th.testid and th.TestType like 'UL_%')

order by testid

----------------------------
-- Añadimos Info de parcelas
exec dbo.sp_lcc_DropIfExists 'lcc_Negative_Events_Data'

select  f.*,
		lp.provincia as Provincia,
		lp.entorno as Entorno,
		lp.ciudad as Ciudad,
		lp.condado as Condado
	into lcc_Negative_Events_Data	
	from _lcc_Negative_Events_Data f
		LEFT OUTER JOIN	Agrids.dbo.lcc_parcelas lp on (lp.Nombre=master.dbo.fn_lcc_getParcel(f.[Longitud Final], f.[Latitud Final]))


drop table _test_thput_bajo, _test_thput_bajo_384, _lcc_Negative_Events_Data

