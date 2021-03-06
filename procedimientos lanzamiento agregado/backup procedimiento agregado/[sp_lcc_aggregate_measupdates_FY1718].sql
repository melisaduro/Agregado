USE [DASHBOARD]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_aggregate_measupdates_FY1718]    Script Date: 11/12/2017 14:55:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_lcc_aggregate_measupdates_FY1718] (
	@ruta_entidades as varchar(4000) 
	)
as

--TESTING VARIABLES
--declare @ruta_entidades as varchar (4000)='F:\VDF_Invalidate\meas_updates.xlsx'


--Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_ciudades'

exec  [dbo].[sp_importExcelFileAsText] @ruta_entidades, 'cities','_ciudades'


-- Le creamos un identificador a cada ciudad para luego crear un bucle

select identity(int,1,1) id,*
into #iterator
from [dbo].[_ciudades]


--Mostramos las ciudades que se agregaran

 select * from #iterator



 --Comenzamos el bucle con todas las ciudades a agregar

 declare @id int=1
 declare @date_Ini as datetime = getdate()

if @@TRANCOUNT = 0  --Controlamos que no haya transacciones ya abiertas en la misma sesión
begin

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

			
		-- Control de transacciones para confirmar o deshacer la transacción.

		IF @@TRANCOUNT = 0 -- ERROR. El número de transacciones es 0 (viene de hacer rollback en algunos de los procedimientos por operador)
		begin
			select 'El numero de transacciones no es correcto'

			--Insertar ERROR EN LA TABLA DE CONTROL
			insert into [DASHBOARD].dbo.[lcc_executions_aggr]
			select 'ERROR! - El número de transacciones en la sesíón no es correcto. @@TRANCOUNT=0' + @ciudad, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
		end
		
		IF @@TRANCOUNT = 1 -- OK
		begin
			COMMIT TRANSACTION T1
		end

		

		else --Si el número de transacciones no es 0 ni 1 (>1)
		begin
			if @@TRANCOUNT>0
				ROLLBACK TRANSACTION

			select 'Transacciones abiertas al inicio. Vuelva a ejecutar'

			--Insertar ERROR EN LA TABLA DE CONTROL
			insert into [DASHBOARD].dbo.[lcc_executions_aggr]
			select 'ERROR! - El número de transacciones en la sesíón no es correcto- GLOBAL - @@TRANCOUNT>1. ROLLBACK ' + @ciudad, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
		end


	END TRY
	BEGIN CATCH
		
		--Error en el procedimiento global
		if @@TRANCOUNT>0
			ROLLBACK TRANSACTION

		select 'Error en el procedimiento. Volver a ejecutar'

		--Insertar ERROR EN LA TABLA DE CONTROL
		insert into [DASHBOARD].dbo.[lcc_executions_aggr]
		select 'ERROR! - ' + @ciudad, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
	END CATCH



	set @id=@id+1

	end --Fin del while

end --Fin If @@TRANCOUNT=0
else --El número de transacciones abiertas es mayor de cero. Hay que cerrarlas previamente.
	begin
			--ROLLBACK TRANSACTION -- Hacemos rollback

			--Insertar ERROR EN LA TABLA DE CONTROL
			insert into [DASHBOARD].dbo.[lcc_executions_aggr]
			select 'ERROR! - Hay transacciones abiertas al inicio - @@TRANCOUNT<>0. ROLLBACK ', NULL, NULL, getdate(),NULL,NULL, NULL,NULL,NULL,
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL

			select 'Transacciones abiertas al inicio. Realice ROLLBACK y vuelva a ejecutar'
	end

--Limpieza de tablas temporales
drop table #iterator
		
-- Actualizamos las entidades completadas para OSP (3G, 4G y cobertura) 
--SOLO A FINAL DE SEMANA (@ESTHER/@MELISA).PROCEDIMIENTO NO CONCURRENTE
exec [AddedValue].[dbo].[plcc_Update_Entity_Completion_ALL_FY1718]
exec [AddedValue].[dbo].[plcc_Update_Entity_completed_Report_ALL]
