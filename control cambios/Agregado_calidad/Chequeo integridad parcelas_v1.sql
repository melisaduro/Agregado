declare @cmd nvarchar(4000)				
DECLARE @nameTabla varchar(256)							
DECLARE @pattern varchar(256) = '%AGGR%'		
				
				
DECLARE @nameBD varchar(256)				
declare @it2 bigint				
declare @MaxBBDD bigint				
declare @it1 bigint				
declare @MaxTab bigint				
				
set @it1 = 1				
set @it2 = 1				
				
exec sp_lcc_dropifexists '_tmp_BBDD'				
				
select IDENTITY(int,1,1) id,name				
into _tmp_BBDD				
from sys.databases				
where name like  @pattern	
	and name not like '%_old'
	
		
				
select @MaxBBDD = MAX(id) 				
from _tmp_BBDD				
				
while @it2 <= @MaxBBDD 				
begin				
				
	select @nameBD = name			
	from _tmp_BBDD			
	where id =@it2			
	print 'Nombre de la bbdd:  ' + @nameBD			
				
	exec sp_lcc_dropifexists '_tmp_Tablas'			
	set @cmd = 'select IDENTITY(int,1,1) id,name			
	into _tmp_Tablas			
	from ['+@nameBD +'].sys.tables			
	where name like ''lcc_aggr_%''	
	and name not like ''lcc_aggr_%backup%''	 
	and name not like ''lcc_aggr_%old%''
	and name not like ''%2017%''
	and name not like ''lcc_aggr_%Coverage%2G''
	and name not like ''lcc_aggr_%Coverage%3G''
	and name not like ''lcc_aggr_%Coverage%4G''
	and name not like ''%2016%''
	and name not like ''%NEW%''
	and type=''U'''		
	print @cmd			
	exec (@cmd)			
	
	
	select @MaxTab = MAX(id) 			
	from _tmp_Tablas			
				
	set @it1 = 1			
				
	while @it1 <= @MaxTab			
	begin			
				
		select @nameTabla = name		
		from _tmp_Tablas		
		where id =@it1		
		print 'Nombre de la tabla:  ' + @nameTabla		
				
		set @cmd = 'select g.*
				from(
				select a.parcel,a.entidad,p.region_vf as region_parcelas_vdf,a.region_vf as region_aggr_vdf,p.region_osp as region_parcelas_osp,a.region_osp as region_aggr_osp,
					case when p.region_vf<>a.region_vf then 1 else 0 end as prueba_vdf,
					case when p.region_osp<>a.region_osp then 1 else 0 end as prueba_osp
					from [AGRIDS].[dbo].vlcc_parcelas_OSP p, ' +@nameBD+ '.dbo.' +@nameTabla+ ' a
				where isnull(p.parcela,''0.00000 Long, 0.00000 Lat'') = isnull(a.parcel,''0.00000 Long, 0.00000 Lat'')
				) g
				where g.prueba_vdf = 1 or g.prueba_osp = 1
			'
		
		--set @cmd='select * into '+@nameBD +'.dbo.'+ @nameTabla +'_backup_ALL from '+@nameBD +'.dbo.'+ @nameTabla
				
		print @cmd		
		exec (@cmd)
				
		set @it1 = @it1 +1		
	end			
				
	set @it2 = @it2 +1			
end				
				
				
exec sp_lcc_dropifexists '_tmp_BBDD'				
exec sp_lcc_dropifexists '_tmp_Tablas'				
