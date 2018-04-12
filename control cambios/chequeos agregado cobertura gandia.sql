select meas_round, meas_date, [database],entidad, aggr_type, report_type 
from lcc_aggr_sp_MDD_Coverage_All_Curves 
where entidad like '%gramenet%' 
group by meas_round, meas_date, [database],entidad, aggr_type, report_type

select meas_round, meas_date, [database],entidad, aggr_type, report_type 
from lcc_aggr_sp_MDD_Coverage_All_Indoor
where entidad like '%gandia%' 
group by meas_round, meas_date, [database],entidad, aggr_type, report_type

select meas_round, meas_date, [database],entidad, aggr_type, report_type 
from lcc_aggr_sp_MDD_Coverage_3G
where entidad like '%gandia%' 
group by meas_round, meas_date, [database],entidad, aggr_type, report_type


select concat('select ''AGGRCoverage.dbo.',name,'''',' select *
from AGGRCoverage.dbo.',name,' where entidad=''GANDIA''')
from AGGRCoverage.sys.tables 


select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Curves_old' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Curves_old where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_2G' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_2G where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Indoor_old' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Indoor_old where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_3G' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_3G where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_4G' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_4G where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Curves_NEW_20161018' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Curves_NEW_20161018 where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Indoor_NEW_20161018' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Indoor_NEW_20161018 where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Outdoor_old' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Outdoor_old where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Indoor_20161021' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Indoor_20161021 where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Curves' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Curves where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Indoor' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Indoor where entidad='GANDIA'
select 'AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Outdoor' select *
from AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Outdoor where entidad='GANDIA'

select *--parcel, entidad, count (parcel)
from lcc_aggr_sp_MDD_Coverage_All_Indoor
where entidad= 'GANDIA' and report_type= 'MUN'
group by parcel, entidad



BEGIN TRANSACTION 

update lcc_aggr_sp_MDD_Coverage_All_Curves 
set entidad='GANDIAPLAYA'
where entidad= 'GANDIA' and report_type= 'MUN'

commit

BEGIN TRANSACTION 
update AGGRCoverage.dbo.lcc_aggr_sp_MDD_Coverage_All_Indoor
set entidad='GANDIAPLAYA'
where entidad= 'GANDIA' and report_type= 'MUN'

commit





