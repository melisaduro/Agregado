--Comprobaciones update OSP1617_H1
select e.* from lcc_entities_aggregated a 
inner join (select *
from lcc_entities_completed_Report e 
where e.meas_round like '%1617%'
and ([master].dbo.fn_lcc_getElement(2, e.meas_round,'_') = 'H2')) as e
on (a.entity_name=e.entity_name)
where a.meas_round like '%OSP%'


select [Coverage_MUN],[3G_Voice_MUN], [4G_Voice_MUN], [3G_Data_Mun], [4G_Data_MUN],* from lcc_entities_completed_report a, lcc_entities_aggregated e
where a.entity_name=e.entity_name
and a.meas_round=e.meas_round
and a.entity_name in ('MAIRENADELALCOR',
'LASOLANA',
'LORADELRIO',
'MANZANARES',
'DAIMIEL',
'ELVISODELALCOR',
'ARAHAL',
'CIEMPOZUELOS')
order by a.entity_name

--Ejecutar script update meas_round sobre estas entidades para incluirlo 

