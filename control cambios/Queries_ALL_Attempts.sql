---------------------------------------------------Voz-------------------------------------------------------------

select   
t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '3G' as meas_Tech, 
	'Voz' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(MO_Succeeded + MO_Blocks + MO_Drops + MT_Succeeded + MT_Blocks + MT_Drops) as Num_tests
from [AGGRVoice3G].dbo.lcc_aggr_sp_MDD_Voice_Llamadas t
 , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'alcazardesanjuan'--t.report_type = 'MUN'
group by 
	t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type
order by vf_entity, meas_round, meas_date, meas_week, report_type

select   
t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '3G' as meas_Tech, 
	'Voz' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(MO_Succeeded + MO_Blocks + MO_Drops + MT_Succeeded + MT_Blocks + MT_Drops) as Num_tests
from [AGGRVoice4G_ROAD].dbo.lcc_aggr_sp_MDD_Voice_Llamadas t
 , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad like '%A4-CAD-R2%'--t.report_type = 'MUN'
group by 
	t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type
order by vf_entity, meas_round, meas_date, meas_week, report_type

---------------------------------------------------Test CE---------------------------------------------------------
--3G CE_DL
select   
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '3G' as meas_Tech, 
	'CE_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(navegaciones) as Num_tests
from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_CE] t
 , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'tirajana'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type
	
--4G CE_DL
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '4G' as meas_Tech, 
	'CE_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.navegaciones) as Num_tests
 from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_CE] t
	  , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'tirajana' 
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_Device CE_DL    
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'NoCA_Device' as meas_Tech, 
	'CE_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.navegaciones) as Num_tests
 from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_CE_4GDevice] t
	  , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_ROAD CE_DL 
select  
	p.codigo_ine, 'Roads' vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'CE_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.navegaciones) as Num_tests
 from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_CE] t
	  , agrids.dbo.vlcc_parcelas_osp p
	   where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_Device_ROAD CE_DL   
--select  
--	p.codigo_ine, 'Roads' vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'Road NoCA_Device' as meas_Tech, 
--	'CE_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
--	sum(t.navegaciones) as Num_tests
-- from [AGGRData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_CE_4GDevice] t
--	  , agrids.dbo.vlcc_parcelas_osp p
--where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
--group by 
--	p.codigo_ine,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--3G CE_UL
select   
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '3G' as meas_Tech, 
	'CE_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(Subidas) as Num_tests
 from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_CE] t
 , agrids.dbo.vlcc_parcelas_osp p
	   where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
	group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type
	
--4G CE_UL
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '4G' as meas_Tech, 
	'CE_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.Subidas) as Num_tests
 from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_CE] t
	  , agrids.dbo.vlcc_parcelas_osp p
	   where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
	group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_Device CE_UL
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'NoCA_Device' as meas_Tech, 
	'CE_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.Subidas) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_CE_4GDevice] t
	  , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_ROAD CE_UL
select  
	p.codigo_ine, 'Roads' vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'CE_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.Subidas) as Num_tests
 from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_CE] t
	  , agrids.dbo.vlcc_parcelas_osp p
	   where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
	group by 
	p.codigo_ine,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_ROAD_Device CE_UL
--select  
--	p.codigo_ine, 'Roads' vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'Road NoCA_Device' as meas_Tech, 
--	'CE_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
--	sum(t.Subidas) as Num_tests
-- from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_CE_4GDevice] t
--	  , agrids.dbo.vlcc_parcelas_osp p
--where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
--group by 
--	p.codigo_ine,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


---------------------------------------------------Test NC---------------------------------------------------------
--3G NC_DL
select   
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '3G' as meas_Tech, 
	'NC_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(navegaciones) as Num_tests
 from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_NC] t
 , agrids.dbo.vlcc_parcelas_osp p
	   where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
	group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type
	
--4G NC_DL
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '4G' as meas_Tech, 
	'NC_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(navegaciones) as Num_tests
 from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_NC] t
	  , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_Device NC_DL
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'NoCA_Device' as meas_Tech, 
	'NC_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.navegaciones) as Num_tests
 from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_NC_4GDevice] t
	  , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_ROAD NC_DL
select  
	p.codigo_ine, 'Roads' vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'NC_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.navegaciones) as Num_tests
 from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_NC] t
	  , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_DEVICE_ROAD NC_DL
--select  
--	p.codigo_ine, 'Roads' vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'Road NoCA_Device' as meas_Tech, 
--	'NC_DL' as Test_type, 'Downlink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
--	sum(t.navegaciones) as Num_tests
-- from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_DL_Thput_NC_4GDevice] t
--	  , agrids.dbo.vlcc_parcelas_osp p
--	   where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
--	group by 
--	p.codigo_ine,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--3G NC_UL
select   
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '3G' as meas_Tech, 
	'NC_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(Subidas) as Num_tests
 from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_NC] t
 , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type
	
--4G NC_UL
select  
	case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, '4G' as meas_Tech, 
	'NC_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.Subidas) as Num_tests
 from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_NC] t
	  , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'vilagarcia' 
group by 
	case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_DEVICE NC_UL
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'NoCA_Device' as meas_Tech, 
	'NC_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.Subidas) as Num_tests
 from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_NC_4GDevice] t
	  , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_ROAD NC_UL
select  
	p.codigo_ine, 'Roads' vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'NC_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(t.Subidas) as Num_tests
 from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_NC] t
	  , agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_DEVICE_ROAD NC_UL
--select  
--	p.codigo_ine, 'Roads' vf_environment,t.mnc,t.meas_round,t.Date_Reporting as meas_date,t.Week_Reporting as meas_week, 'Road NoCA_Device' as meas_Tech, 
--	'NC_UL' as Test_type, 'Uplink' as Direction, t.entidad as vf_entity,t.Report_Type,t.Aggr_Type,
--	sum(t.Subidas) as Num_tests
-- from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_UL_Thput_NC_4GDevice] t
--	  , agrids.dbo.vlcc_parcelas_osp p
--where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
--group by 
--	p.codigo_ine,t.mnc,t.meas_round,t.Date_Reporting,t.Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


---------------------------------------------------Test WEB---------------------------------------------------------
--3G WEB HTTP
	select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '3G' as meas_Tech, 
	'WEB HTTP' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Navegaciones) as Num_tests
from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_Web] t, agrids.dbo.vlcc_parcelas_osp p
	   where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'pontevedra'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G WEB HTTP
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '4G' as meas_Tech, 
	'WEB HTTP' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Navegaciones) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Web] t, agrids.dbo.vlcc_parcelas_osp p
	   where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'alcaladehenares'
	group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_DEVICE WEB HTTP
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'NoCA_Device' as meas_Tech, 
	'WEB HTTP' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Navegaciones) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Web_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_ROAD WEB HTTP
select  
	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'WEB HTTP' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Navegaciones) as Num_tests
from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Web] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_DEVICE_ROAD WEB HTTP
--select  
--	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road NoCA_Device' as meas_Tech, 
--	'WEB HTTP' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
--		sum(t.Navegaciones) as Num_tests
--from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Web_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
--	   where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
--group by 
--	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--3G WEB HTTPS
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '3G' as meas_Tech, 
	'WEB HTTPS' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(isnull(t.[Navegaciones HTTPS],0)) as Num_tests
from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_Web] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'santantonideportman'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G WEB HTTPS
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '4G' as meas_Tech, 
	'WEB HTTPS' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(isnull(t.[Navegaciones HTTPS],0)) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Web] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_DEVICE WEB HTTPS
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'NoCA_Device' as meas_Tech, 
	'WEB HTTPS' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(isnull(t.[Navegaciones HTTPS],0)) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Web_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_ROAD WEB HTTPS
select  
	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'WEB HTTPS' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(isnull(t.[Navegaciones HTTPS],0)) as Num_tests
from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Web] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_DEVICE_ROAD WEB HTTPS
--select  
--	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road NoCA_Device' as meas_Tech, 
--	'WEB HTTPS' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
--		sum(isnull(t.Navegaciones,0)) as Num_tests--- FJLA ALERTA HAY que cambiarlo a HTTPS!!!
--from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Web_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
--where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
--group by 
--	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--3G WEB Public
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '3G' as meas_Tech, 
	'WEB Public' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(isnull(t.[Navegaciones Public],0)) as Num_tests
from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_Web] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G WEB Public
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '4G' as meas_Tech, 
	'WEB Public' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(isnull(t.[Navegaciones Public],0)) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Web] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_ROAD WEB Public
	select  
	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'WEB Public' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(isnull(t.[Navegaciones Public],0)) as Num_tests
from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Web] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


---------------------------------------------------Test YTB---------------------------------------------------------
--3G Youtube SD
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '3G' as meas_Tech, 
	'Youtube SD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Reproducciones) as Num_tests
from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_Youtube] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G Youtube SD
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '4G' as meas_Tech, 
	'Youtube SD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Reproducciones) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Youtube] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_DEVICE Youtube SD
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'NoCA_Device' as meas_Tech, 
	'Youtube SD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Reproducciones) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Youtube_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_ROAD Youtube SD
select  
	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'Youtube SD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Reproducciones) as Num_tests
from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Youtube] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_DEVICE_ROAD Youtube SD
--select  
--	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road NoCA_Device' as meas_Tech, 
--	'Youtube SD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
--		sum(t.Reproducciones) as Num_tests
--from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Youtube_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
--where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
--group by 
--	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--3G Youtube HD
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '3G' as meas_Tech, 
	'Youtube HD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Reproducciones) as Num_tests
from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_Youtube_HD] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'almansa'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G Youtube HD
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '4G' as meas_Tech, 
	'Youtube HD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Reproducciones) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Youtube_HD] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'almansa'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

--4G_DEVICE Youtube HD
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'NoCA_Device' as meas_Tech, 
	'Youtube HD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Reproducciones) as Num_tests
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Youtube_HD_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_ROAD Youtube HD
select  
	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'Youtube HD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
		sum(t.Reproducciones) as Num_tests
from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Youtube_HD] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_DEVICE_ROAD Youtube HD
--select  
--	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road NoCA_Device' as meas_Tech, 
--	'Youtube HD' as Test_type, 'Downlink' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
--		sum(t.Reproducciones) as Num_tests
--from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Youtube_HD_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
--where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
--group by 
--	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type

		
---------------------------------------------------Test Ping---------------------------------------------------------
--3G Ping
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '3G' as meas_Tech, 
	'Ping' as Test_type, 'RTT' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(pings) as Latency_Den	
from [AGGRData3G].dbo.[lcc_aggr_sp_MDD_Data_Ping] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G Ping
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, '4G' as meas_Tech, 
	'Ping' as Test_type, 'RTT' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(pings) as Latency_Den
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Ping] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'zaragoza'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_Device Ping
select  
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'NoCA_Device' as meas_Tech, 
	'Ping' as Test_type, 'RTT' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(pings) as Latency_Den
from [AGGRData4G].dbo.[lcc_aggr_sp_MDD_Data_Ping_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'cordoba'
group by 
	p.codigo_ine, case when t.entidad like 'AVE-%' or t.entidad like 'MAD-___-R[0-9]%' then  'AVE' else p.vf_environment end ,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type
			
--4G_ROAD Ping
select  
	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road 4G' as meas_Tech, 
	'Ping' as Test_type, 'RTT' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
	sum(pings) as Latency_Den
from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Ping] t, agrids.dbo.vlcc_parcelas_osp p
where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
group by 
	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type


--4G_Device_ROAD Ping
--select  
--	p.codigo_ine, 'Roads' vf_environment,mnc,meas_round,Date_Reporting as meas_date,Week_Reporting as meas_week, 'Road NoCA_Device' as meas_Tech, 
--	'Ping' as Test_type, 'RTT' as Direction, entidad as vf_entity,t.Report_Type,t.Aggr_Type,
--	sum(pings) as Latency_Den
-- from [aggrData4G_ROAD].dbo.[lcc_aggr_sp_MDD_Data_Ping_4GDevice] t, agrids.dbo.vlcc_parcelas_osp p
--where p.parcela=isnull(t.parcel,'0.00000 Long, 0.00000 Lat') and t.entidad = 'AAAA'
--group by 
--	p.codigo_ine,mnc,meas_round,Date_Reporting,Week_Reporting,t.entidad,t.Report_Type,t.Aggr_Type
		
