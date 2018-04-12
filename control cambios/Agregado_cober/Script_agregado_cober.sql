use [FY1617_Coverage_Union]


--Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_ciudades'

exec  [dbo].[sp_importExcelFileAsText] 'S:\VDF_Invalidate\aggr_coverage.xlsx', 'cities','_ciudades'


-- Le creamos un identificador a cada ciudad para luego crear un bucle

select identity(int,1,1) id,*
into #iterator
from [dbo].[_ciudades]


--Mostramos las ciudades que se agregaran

 select * from #iterator



 --Comenzamos el bucle con todas las ciudades a agregar

 declare @id int=1
 while @id<=(select max(id) from #iterator)
 begin

  	declare @ciudad as varchar(256) = (select Entidades from #iterator where id=@id)
	declare @pattern as varchar (256) = (select Entidades from #iterator where id=@id)






declare @Methodology as varchar (50) = 'D16'
declare @monthYearDash as varchar(100) = '2017_01'
declare @weekDash as varchar(50) = 'W01' 
declare @camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-[Database]-carrier-Report_Type-Entidad'
declare @operator as integer
declare @Report as varchar (256)='OSP'
declare @aggrType as varchar(256)='GRID'




begin
set @operator=1

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
set @operator=7

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
set @operator=3

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
set @operator=4

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
exec sp_lcc_update_Dates_Reporting_Aggr_D16 
  @ciudad, '', 'Coverage',@Methodology,@aggrType
end

-- Cierre del bucle

set @id=@id+1
end 

--Limpieza de tablas temporales

drop table #iterator

use [AddedValue]
exec plcc_Update_Entity_Completion_ALL