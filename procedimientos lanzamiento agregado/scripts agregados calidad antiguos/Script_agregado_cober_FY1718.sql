use [FY1718_Coverage_Union_H1]


--Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_ciudades'

exec  [dbo].[sp_importExcelFileAsText] 'F:\VDF_Invalidate\aggr_coverage.xlsx', 'cities','_ciudades'


-- Le creamos un identificador a cada ciudad para luego crear un bucle

select identity(int,1,1) id,*
into #iterator
from [dbo].[_ciudades]


--Mostramos las ciudades que se agregaran

 select * from #iterator



 --Comenzamos el bucle con todas las ciudades a agregar

 declare @id int=1
 declare @date_Ini as datetime = getdate()

 while @id<=(select max(id) from #iterator)
 begin

BEGIN TRY
BEGIN TRANSACTION T1

  	declare @ciudad as varchar(256) = (select Entidades from #iterator where id=@id)
	declare @pattern as varchar (256) = (select Entidades from #iterator where id=@id)
	declare @Report as varchar (256) = (select Report from #iterator where id=@id)






declare @Methodology as varchar (50) = 'D16'
declare @monthYearDash as varchar(100) = '2017_07'
declare @weekDash as varchar(50) = 'W27' 
declare @camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-[Database]-carrier-Report_Type-Entidad'
declare @operator as integer
declare @aggrType as varchar(256)='GRID'




begin
set @operator=1

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
set @operator=7

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16_FY1718 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
set @operator=3

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
set @operator=4

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16_FY1718 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
exec sp_lcc_update_Dates_Reporting_Aggr_D16
  @ciudad, '', 'Coverage',@Methodology,@aggrType,@Report,''
end


IF @@TRANCOUNT > 0
begin
	COMMIT TRANSACTION T1
end

END TRY
BEGIN CATCH
	--Insertar ERROR EN LA TABLA DE CONTROL
	insert into [AddedValue].dbo.[lcc_executions_aggr]
	select 'ERROR! - ' + @pattern, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
	NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
END CATCH

-- Cierre del bucle

set @id=@id+1
end 


--Limpieza de tablas temporales

drop table #iterator

/*********************************************/
/*** DAVID ***/
/**

 USE [AddedValue]
 Exec plcc_UPDATE_ENTITY_COMPLETION_ALL

 **/


