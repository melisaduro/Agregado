select *
from agrids.dbo.lcc_procedures_step1_GRID
where name_proc like '%youtube%'

begin transaction
select * into agrids.dbo.lcc_procedures_step1_GRID_20170228
from agrids.dbo.lcc_procedures_step1_GRID
where name_proc like '%youtube%'
commit

select * from agrids.dbo.lcc_procedures_step1_GRID_20170228
select * from agrids.dbo.lcc_procedures_step1_GRID_backup_20170228
select * from agrids.dbo.lcc_procedures_step1_GRID

begin transaction
select * into agrids.dbo.lcc_procedures_step1_GRID_backup_20170228
from agrids.dbo.lcc_procedures_step1_GRID
commit

drop table agrids.dbo.lcc_procedures_step1_GRID_backup_20170228

begin transaction
select * into agrids.dbo.lcc_procedures_step1_GRID
from agrids.dbo.lcc_procedures_step1_GRID_backup_20170228
commit

select * from 
agrids.dbo.lcc_procedures_step1_GRID_backup_20170228
where type_info ='data'