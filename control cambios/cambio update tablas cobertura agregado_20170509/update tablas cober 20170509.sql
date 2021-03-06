
SELECT [database],entidad,report_type, meas_week, week_reporting,meas_date, date_reporting, meas_round
  FROM [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves
  where entidad in ('ARCOSDELAFRONTERA','CADIZ','CHICLANA','CHIPIONA','ECIJA','JEREZ','PTOSANTAMARIA','PUERTOREAL','ROTA','SANFERNANDO','SANLUCARDEBARRAMEDA')
  group by [database],entidad,report_type, meas_week, week_reporting,meas_date, date_reporting, meas_round
  ORDER BY 2,8

SELECT [database],entidad,report_type, meas_week, week_reporting,meas_date, date_reporting, meas_round
  FROM [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Outdoor_20170508
  where entidad in ('ARCOSDELAFRONTERA','CADIZ','CHICLANA','CHIPIONA','ECIJA','JEREZ','PTOSANTAMARIA','PUERTOREAL','ROTA','SANFERNANDO','SANLUCARDEBARRAMEDA')
  group by [database],entidad,report_type, meas_week, week_reporting,meas_date, date_reporting, meas_round
  ORDER BY 2,8

begin transaction
update [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Indoor
set meas_week='W1', week_reporting='W1'
--SELECT [database],entidad,report_type, meas_week, week_reporting,meas_date, date_reporting, meas_round
  FROM [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Indoor
  where entidad in ('CHIPIONA')
  AND MEAS_ROUND='FY1617_H1'
  AND WEEK_REPORTING='W2'

commit


