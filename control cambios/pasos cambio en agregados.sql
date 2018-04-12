USE [master]

----------------------------
-- Proc GLOBAL de AGREGADOS:
--sp_lcc_create_tables_Data_Aggr_D16
--sp_lcc_create_tables_Voice_Aggr_D16
----------------------------

-- 1) Backup de codigo de agregados:
--		[sp_MDD_Data_NEW_KPIs_UL_LTE_GRID_20170117]
--		[sp_MDD_Data_NEW_KPIs_DL_LTE_GRID_20170117]

-- 2) Modificados ambos con los nuevos KPIs de MIMO y RI1, RI2 (num y den)

-- 3) Procedimientos agregados a ejecutar
select * from [AGRIDS].[dbo].[lcc_procedures_step1_GRID]
where name_proc like '%NEW_KPIs%' and type_info='Data'


-- 4) Listado de entidades agregadas en H2
-- Vista cogida de bbdd de Datos y creada en en [AddedValue]
-- SHARING:
SELECT	[Meas_Round]	,[Database]  ,	[Entidad]	,[Report_Type]      ,[Aggr_Type], [Week_Reporting]
FROM [AddedValue].[dbo].[vlcc_AGGRData4G]
where [Meas_Round] like '%FY1617_H2%'
group by	[Meas_Round]	,[Database]  ,	[Entidad]	,[Report_Type]      ,[Aggr_Type], [Week_Reporting]
order by	[Meas_Round]	,[Database]  ,	[Entidad]	,[Report_Type]      ,[Aggr_Type], [Week_Reporting]

-- OSP:
SELECT	[Meas_Round]	,[Database]  ,	[Entidad]	,[Report_Type]      ,[Aggr_Type],	[Week_Reporting]
FROM [AddedValue].[dbo].[vlcc_AGGRData4G]
where [Database] like '%OSP%'
group by	[Meas_Round]	,[Database]  ,	[Entidad]	,[Report_Type]      ,[Aggr_Type],	[Week_Reporting]
order by	[Week_Reporting], [Meas_Round]	,[Database]  ,	[Entidad]	,[Report_Type]      ,[Aggr_Type] 


-- 5) Se guardan backups de las tablas y se borran las entidades agregadas de H2:
use [AGGRData4G]

drop table #db
select identity(int,1,1) id, name 
into #db
from sys.tables where name like '%new_KPI%' and name not like '%20%'

select * from #db


---
declare @table as varchar(256)
declare @cont as int=1

while @cont<= (select max(id) from  #db)
begin
	set @table=(select name from #db where id=@cont)

	-- a) Primera ejecucion para backup:
	--print('select * into ' +@table+ '_20170117 from ' + @table)

	-- b) Segunda ejecucion para borrado:
	-- Se borra vdf:
	print ('delete ' + @table + ' where [Meas_Round]=''FY1617_H2'' and Report_Type=''VDF'' and entidad in (''A1-IRUN-R6'',	''A2-BCN-R6'',	''A3-VLC-R7'',	''A4-CAD-R6'',	''A5-BAD-R8'',	''A6-COR-R8'',	''A7-ALG-R6'',	''ALCAZARDESANJUAN'',	''ALGECIRAS'',	''ARCOSDELAFRONTERA'',	''AVE-Olmedo-Zamora-R4'',	''AVE-Santiago-Orense-R4'',	''BARAKALDO'',	''BASAURI'',	''CADIZ'',	''CAMARGO'',	''CARMONA'',	''CASTROURDIALES'',	''CIUDADREAL'',	''CORDOBA'',	''CORIADELRIO'',	''DOSHERMANAS'',	''DURANGO'',	''ECIJA'',	''EIBAR'',	''ERRENTERIA'',	''GALDAKAO'',	''GETXO'',	''HUELVA'',	''HUESCA'',	''JACA'',	''JEREZ'',	''LALINEADELACONCEPCION'',	''LARINCONADA'',	''LEPE'',	''LHOSPITALETDELLOBREGAT'',	''MAD-SEV-R4'',	''MAD-VLC-R4'',	''MALAGA'',	''MARTORELL'',	''MIRANDADEEBRO'',	''OSUNA'',	''PORTUGALETE'',	''PUERTOREAL'',	''ROTA'',	''RUBI'',	''SANFERNANDO'',	''SANLUCARDEBARRAMEDA'',	''SANTONA'',	''SANTURTZI'',	''SESTAO'',	''SEVILLA'',	''TOMELLOSO'',	''TORRELAVEGA'',	''VALDEPENAS'',	''VLC-RLW'')')

	-- Se borra mun:
	print ('delete ' + @table + ' where [Meas_Round]=''FY1617_H2'' and Report_Type=''MUN'' and entidad in (''ALCAZARDESANJUAN'',	''ALGECIRAS'',	''ARCOSDELAFRONTERA'',	''BARAKALDO'',	''BASAURI'',	''CADIZ'',	''CAMARGO'',	''CARMONA'',	''CASTROURDIALES'',	''CIUDADREAL'',	''CORDOBA'',	''CORIADELRIO'',	''DOSHERMANAS'',	''DURANGO'',	''ECIJA'',	''EIBAR'',	''ERRENTERIA'',	''GALDAKAO'',	''GETXO'',	''HUELVA'',	''HUESCA'',	''JACA'',	''JEREZ'',	''LALINEADELACONCEPCION'',	''LARINCONADA'',	''LEPE'',	''LHOSPITALETDELLOBREGAT'',	''MALAGA'',	''MARTORELL'',	''MIRANDADEEBRO'',	''OSUNA'',	''PORTUGALETE'',	''PUERTOREAL'',	''ROTA'',	''RUBI'',	''SANFERNANDO'',	''SANLUCARDEBARRAMEDA'',	''SANTONA'',	''SANTURTZI'',	''SESTAO'',	''SEVILLA'',	''TOMELLOSO'',	''TORRELAVEGA'',	''VALDEPENAS'')')

	set @cont=@cont+1
end

-- 6) Se rellena el excel de entidades agregadas y Antonio lanza reagregado
-- 7) Chequeo para verificar que no haya cambios en los reagregados y se rellenen correctamente los nuevos KPIs