declare @cmd nvarchar(4000)				
DECLARE @nameTabla varchar(256)							
DECLARE @pattern varchar(256) = '%AGGR%'		
				
				
DECLARE @nameBD varchar(256)				
declare @it2 bigint				
declare @MaxBBDD bigint							
declare @MaxTab bigint				
							
set @it2 = 1				
				
exec sp_lcc_dropifexists '_tmp_BBDD'				
				
select IDENTITY(int,1,1) id,name				
into _tmp_BBDD				
from sys.databases				
where name like  @pattern	
	and name not like '%_old'
	and name not like '%VFECNB%'
	
		
				
select @MaxBBDD = MAX(id) 				
from _tmp_BBDD				
				
while @it2 <= @MaxBBDD 				
begin				
				
	select @nameBD = name			
	from _tmp_BBDD			
	where id =@it2			
	print 'Nombre de la bbdd:  ' + @nameBD			
				
	
	if @nameBD	 like '%Voice%' or @nameBD like '%VOLTE%'
	begin				
		set @cmd = 'select g.*
				from(
				select a.parcel,a.entidad,p.region_vf as region_parcelas_vdf,a.region_vf as region_aggr_vdf,p.region_osp as region_parcelas_osp,a.region_osp as region_aggr_osp,
					case when p.region_vf<>a.region_vf then 1 else 0 end as prueba_vdf,
					case when p.region_osp<>a.region_osp then 1 else 0 end as prueba_osp
					from [AGRIDS].[dbo].lcc_parcelas p, ' +@nameBD+ '.dbo.lcc_aggr_sp_MDD_Voice_Llamadas a
				where isnull(p.nombre,''0.00000 Long, 0.00000 Lat'') = isnull(a.parcel,''0.00000 Long, 0.00000 Lat'')
				) g
				where g.prueba_vdf = 1 or g.prueba_osp = 1
			'
		print @cmd		
		exec (@cmd)
	end

	if @nameBD	 like '%Data%'
	begin				
		set @cmd = 'select g.*
				from(
				select a.parcel,a.entidad,p.region_vf as region_parcelas_vdf,a.region_vf as region_aggr_vdf,p.region_osp as region_parcelas_osp,a.region_osp as region_aggr_osp,
					case when p.region_vf<>a.region_vf then 1 else 0 end as prueba_vdf,
					case when p.region_osp<>a.region_osp then 1 else 0 end as prueba_osp
					from [AGRIDS].[dbo].lcc_parcelas p, ' +@nameBD+ '.dbo.lcc_aggr_sp_MDD_Data_DL_Thput_CE a
				where isnull(p.nombre,''0.00000 Long, 0.00000 Lat'') = isnull(a.parcel,''0.00000 Long, 0.00000 Lat'')
				) g
				where g.prueba_vdf = 1 or g.prueba_osp = 1
			'
		print @cmd		
		exec (@cmd)
	end
	if @nameBD	 like '%Coverage%'
	begin				
		set @cmd = 'select g.*
				from(
				select a.parcel,a.entidad,p.region_vf as region_parcelas_vdf,a.region_vf as region_aggr_vdf,p.region_osp as region_parcelas_osp,a.region_osp as region_aggr_osp,
					case when p.region_vf<>a.region_vf then 1 else 0 end as prueba_vdf,
					case when p.region_osp<>a.region_osp then 1 else 0 end as prueba_osp
					from [AGRIDS].[dbo].lcc_parcelas p, ' +@nameBD+ '.dbo.lcc_aggr_sp_MDD_Coverage_All_Curves a
				where isnull(p.nombre,''0.00000 Long, 0.00000 Lat'') = isnull(a.parcel,''0.00000 Long, 0.00000 Lat'')
				) g
				where g.prueba_vdf = 1 or g.prueba_osp = 1
			'
		print @cmd		
		exec (@cmd)
	end
		
						
	set @it2 = @it2 +1			
end				
				
				
exec sp_lcc_dropifexists '_tmp_BBDD'				
			
