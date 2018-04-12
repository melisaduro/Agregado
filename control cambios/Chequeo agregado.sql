from [AGGRVoice4G].dbo.lcc_aggr_sp_MDD_Voice_Llamadas
where entidad= 'bilbao'
group by [database],date_reporting,week_reporting
order by 1

select [database],date_reporting,week_reporting
from [AGGRData4G].dbo.lcc_aggr_sp_MDD_Data_DL_Thput_NC
where entidad= 'cordoba'
group by [database],date_reporting,week_reporting
order by 1

select [database],date_reporting,week_reporting
from [AGGRData4G].dbo.lcc_aggr_sp_MDD_Data_DL_Thput_NC_4GDevice
where entidad= 'CANGAS'
group by [database],date_reporting,week_reporting
order by 1

------------------------------------------------------------------------

select [database],date_reporting,week_reporting
from [AGGRVoice3G].dbo.lcc_aggr_sp_MDD_Voice_Llamadas
where entidad= 'bilbao'
group by [database],date_reporting,week_reporting
order by 1

select [database],date_reporting,week_reporting
from [AGGRData3G].dbo.lcc_aggr_sp_MDD_Data_DL_Thput_NC
where entidad= 'tirajana'
group by [database],date_reporting,week_reporting
order by 1
