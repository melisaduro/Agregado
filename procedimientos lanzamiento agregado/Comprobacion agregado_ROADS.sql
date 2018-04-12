declare @entidad as varchar (256)='A1-IRUN-R2'


select entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type,meas_round,count(distinct(mnc)) as MNC
from [AGGRVoice4G_ROAD].dbo.lcc_aggr_sp_MDD_Voice_Llamadas
where entidad = @entidad
and meas_round like '%1718%'
group by entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type,meas_round
order by 2

select entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type,meas_round,count(distinct(mnc)) as MNC
from [AGGRVOLTE_ROAD].dbo.lcc_aggr_sp_MDD_Voice_Llamadas
where entidad= @entidad
and meas_round like '%1718%'
group by entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type,meas_round
order by 2

select entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type,meas_round,count(distinct(mnc)) as MNC
from [AGGRData4G_ROAD].dbo.lcc_aggr_sp_MDD_Data_DL_Thput_CE
where entidad= @entidad
and meas_round like '%1718%'
group by entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type,meas_round
order by 2

select entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type,meas_round,count(distinct(mnc)) as MNC
from [AGGRCoverage_ROAD].DBO.lcc_aggr_sp_MDD_Coverage_All_Indoor a
where a.entidad=@entidad
and meas_round like '%1718%'
group by entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type,meas_round
order by 2				
	