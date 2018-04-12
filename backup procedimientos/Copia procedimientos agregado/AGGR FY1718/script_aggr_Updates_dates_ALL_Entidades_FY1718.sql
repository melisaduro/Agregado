use [FY1718_Coverage_Union_H1]


--Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_ciudades'

exec  [dbo].[sp_importExcelFileAsText] 'F:\VDF_Invalidate\meas_updates.xlsx', 'cities','_ciudades'


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

  	declare @ciudad as varchar(256) = (select Entidad from #iterator where id=@id)
	declare @isData as varchar (256)= (select [isData] from #iterator where id=@id)
	declare @isVoice as varchar (256)= (select [isVoice] from #iterator where id=@id)
	declare @isCoverage as varchar (256)= (select [isCoverage] from #iterator where id=@id)
	declare @bbddData as varchar (256)= (select [bbddData] from #iterator where id=@id)
	declare @bbddVoice as varchar (256)= (select [bbddVoice] from #iterator where id=@id)
	declare @bbddCoverage as varchar (256)= (select [bbddCoverage] from #iterator where id=@id)
	declare @Report as varchar (256)= (select [Report] from #iterator where id=@id)
	declare @ReportType as varchar (256)= (select [ReportType] from #iterator where id=@id)

	print @ciudad
	--print @isData
	--print @isVoice
	--print @isCoverage
	--print @bbddData
	--print @bbddVoice
	--print @bbddCoverage


	exec sp_lcc_update_Dates_Reporting_Entity_All_Aggr_D16_DDBB 
			@ciudad, 
			@isData,@isVoice,@isCoverage,
			@bbddData,@bbddVoice,@bbddCoverage,@report,@ReportType

	-- Cierre del bucle

IF @@TRANCOUNT > 0
begin
	COMMIT TRANSACTION T1
end

END TRY
BEGIN CATCH
	--Insertar ERROR EN LA TABLA DE CONTROL
	insert into [AddedValue].dbo.[lcc_executions_aggr]
	select 'ERROR! - ' + @ciudad, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
	NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
END CATCH

	set @id=@id+1
end 

-- Actualizamos las entidades completadas para OSP (3G, 4G y cobertura) 
--SOLO A FINAL DE SEMANA (@ESTHER/@MELISA).PROCEDIMIENTO NO CONCURRENTE
----exec [AddedValue].[dbo].[plcc_Update_Entity_completed_Report_ALL]

--Limpieza de tablas temporales

drop table #iterator
