

-- PARA SABER QUE RELLENAR PARA PONER LOS DATOS

select entidad,report_type,meas_Date
FROM [AGGRCoverage].[dbo].[lcc_aggr_sp_MDD_Coverage_All_Curves]
where entidad like '%gandiaplaya%'
group by entidad,report_type,meas_Date


declare @cmd nvarchar(4000)			
DECLARE @nameTabla varchar(256)			
DECLARE @nameEntidad varchar(256) = 'GANDIAPLAYA'			
DECLARE @pattern varchar(256) = '%AGGRCoverage'	--BBDD de donde se quiere borrar	
declare @Meas_date varchar(256)='16_10'		
declare @report_type varchar(256)= 'VDF'	
			
			
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
			
select @MaxBBDD = MAX(id) 			
from _tmp_BBDD			
			
while @it2 <= @MaxBBDD 			
begin			
			
	select @nameBD = name		
	from _tmp_BBDD		
	where id =@it2		
	print 'Nombre de la bbdd:  ' + @nameBD		
			
	exec sp_lcc_dropifexists '_tmp_Tablas'		
	--declare @pattern as varchar (256) = 'ogrove'		
	set @cmd = 'select IDENTITY(int,1,1) id,name		
	into _tmp_Tablas		
	from ['+@nameBD +'].sys.tables		
	where name like ''lcc_aggr_%''		
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
			
		set @cmd = 'delete '+@nameBD +'.dbo.'+ @nameTabla +'	
			where Entidad like ''' + @nameEntidad +'''
			and Meas_date like ''' + @Meas_date + '''
			and report_type = '''+@report_type+''''

			
			
		print @cmd	
		exec (@cmd)	
			
		set @it1 = @it1 +1	
	end		
			
	set @it2 = @it2 +1		
end			
			
			
exec sp_lcc_dropifexists '_tmp_BBDD'			
exec sp_lcc_dropifexists '_tmp_Tablas'			
