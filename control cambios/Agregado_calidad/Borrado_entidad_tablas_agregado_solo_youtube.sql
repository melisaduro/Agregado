--declare @entidad as varchar (256)='BORRIANABURRIANA'

--select [database],entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type
--from [AGGRData3G].dbo.lcc_aggr_sp_MDD_Data_Youtube_HD
--where entidad= @entidad
--group by [database],entidad,meas_Date,meas_week,date_reporting,week_reporting,report_type
--order by 1


declare @cmd nvarchar(4000)
DECLARE @nameTabla varchar(256)
DECLARE @nameEntidad varchar(256) = 'BORRIANABURRIANA'
DECLARE @pattern varchar(256) = 'AGGRData3G'
declare @Meas_date varchar(256)='17_02'
declare @Report_Type varchar (256)='MUN'


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
	--Nombre bbdd
	select @nameBD = name
	from _tmp_BBDD
	where id =@it2
	print 'Nombre de la bbdd:  ' + @nameBD

	exec sp_lcc_dropifexists '_tmp_Tablas'
	--declare @pattern as varchar (256) = 'ogrove'
	set @cmd = 'select IDENTITY(int,1,1) id,name
	into _tmp_Tablas
	from ['+@nameBD +'].sys.tables
	where name like ''%youtube%''
		and type=''U'''
	print @cmd
	exec (@cmd)

	select @MaxTab = MAX(id) 
	from _tmp_Tablas

	set @it1 = 1

	while @it1 <= @MaxTab
	begin
		--Nombre tabla
		select @nameTabla = name
		from _tmp_Tablas
		where id =@it1
		print 'Nombre de la tabla:  ' + @nameTabla

		set @cmd = 'delete '+@nameBD +'.dbo.'+ @nameTabla +'
			where Entidad like ''' + @nameEntidad +'''
				and Meas_date like ''' + @Meas_date + '''
				and Report_Type like '''+ @Report_Type + '''
				option (Optimize for unknown)'

		print @cmd
		exec (@cmd)

		set @it1 = @it1 +1
	end

	set @it2 = @it2 +1
end


exec sp_lcc_dropifexists '_tmp_BBDD'
exec sp_lcc_dropifexists '_tmp_Tablas'