begin transaction
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_CE_GRID','Data','ALL','Y','ALL','CA','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_CE_GRID','Data','ALL','Y','LTE','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_CE_GRID','Data','ALL','Y','WCDMA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_CE_GRID','Data','ALL','Y','CA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_CE_LTE_FY1617_GRID','Data','LTE','Y','CA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_CE_LTE_FY1617_GRID','Data','LTE','Y','WCDMA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_CE_LTE_FY1617_GRID','Data','LTE','Y','ALL','CA','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_CE_LTE_FY1617_GRID','Data','LTE','Y','LTE','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_NC_GRID','Data','ALL','Y','ALL','CA','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_NC_GRID','Data','ALL','Y','LTE','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_NC_GRID','Data','ALL','Y','WCDMA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_NC_GRID','Data','ALL','Y','CA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_NC_LTE_FY1617_GRID','Data','LTE','Y','CA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_NC_LTE_FY1617_GRID','Data','LTE','Y','WCDMA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_NC_LTE_FY1617_GRID','Data','LTE','Y','ALL','CA','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_DL_Technology_NC_LTE_FY1617_GRID','Data','LTE','Y','LTE','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_CE_GRID','Data','ALL','Y','ALL','CA','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_CE_GRID','Data','ALL','Y','LTE','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_CE_GRID','Data','ALL','Y','WCDMA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_CE_GRID','Data','ALL','Y','CA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_CE_LTE_FY1617_GRID','Data','LTE','Y','CA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_CE_LTE_FY1617_GRID','Data','LTE','Y','WCDMA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_CE_LTE_FY1617_GRID','Data','LTE','Y','ALL','CA','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_CE_LTE_FY1617_GRID','Data','LTE','Y','LTE','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_NC_GRID','Data','ALL','Y','ALL','CA','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_NC_GRID','Data','ALL','Y','LTE','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_NC_GRID','Data','ALL','Y','WCDMA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_NC_GRID','Data','ALL','Y','CA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_NC_LTE_FY1617_GRID','Data','LTE','Y','CA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_NC_LTE_FY1617_GRID','Data','LTE','Y','WCDMA','ALL','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_NC_LTE_FY1617_GRID','Data','LTE','Y','ALL','CA','D16'
insert into AGRIDs.dbo.lcc_procedures_step1_grid 
select 'sp_MDD_Data_UL_Technology_NC_LTE_FY1617_GRID','Data','LTE','Y','LTE','ALL','D16'
commit

select *
from AGRIDs.dbo.lcc_procedures_step1_grid
where name_proc like '%tech%'
and methodology in ('ALL','D16')
order by 1