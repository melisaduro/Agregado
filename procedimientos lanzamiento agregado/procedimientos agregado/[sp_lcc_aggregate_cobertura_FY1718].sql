USE [DASHBOARD]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_aggregate_cobertura_FY1718]    Script Date: 12/04/2018 10:29:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_lcc_aggregate_cobertura_FY1718] (
	@ruta_entidades as varchar(4000) 
	)
as

-- TESTING VARIABLES
-- declare @ruta_entidades as varchar (4000)='F:\VDF_Invalidate\aggr_coverage.xlsx'

-- Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_ciudades'

-- Cogemos la informacion de la entidad del Excel en red
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

		declare @BBDDorigen as varchar (256)= (select BBDDorigen from #iterator  where id=@id)	
  		declare @ciudad as varchar(256) = (select Entidades from #iterator where id=@id)
		declare @pattern as varchar (256) = (select Entidades from #iterator where id=@id)
		declare @Report as varchar (256) = (select Report from #iterator where id=@id)

		-- 20171214-@MDM: Actualización para no permitir el agregado por Vodafone
		if @Report = 'VDF'
		begin
			select 'Agregado VDF no permitido'
			GOTO salto
		end

		declare @Methodology as varchar (50) = 'D16'

		--Declaramos las variables monthyeardash, weekdash en función de la fecha de ejecución (no impactan en el resto de procedimientos)
		declare @monthYearDash as varchar(100) = (select right(convert(varchar(256),datepart(yy, getdate())),2) + '_'	 + convert(varchar(256),format(getdate(),'MM')))
		declare @weekDash as varchar(50) = 'W' +convert(varchar,DATEPART(iso_week, getdate()))

		declare @camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-[Database]-carrier-Report_Type-Entidad'
		declare @operator as varchar(256)
		declare @aggrType as varchar(256)='GRID'

		print @monthYearDash
		print @weekDash

		begin
			set @operator='1'

			exec('
			exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
			'''+@ciudad+''', '+@operator+', 0,'''', 0, 1, '''+@pattern+''', ''Y'', '''+@camposLlave+''', '''+@monthYearDash+''', '''+@weekDash+''','''+@Methodology+''','''+@Report+''','''+@aggrType+'''
			')
		end

		begin
			set @operator='7'

			exec('
			exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
			'''+@ciudad+''', '+@operator+', 0,'''', 0, 1, '''+@pattern+''', ''Y'', '''+@camposLlave+''', '''+@monthYearDash+''', '''+@weekDash+''','''+@Methodology+''','''+@Report+''','''+@aggrType+'''
			')
		end

		begin
			set @operator='3'

			exec('
			exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
			'''+@ciudad+''', '+@operator+', 0,'''', 0, 1, '''+@pattern+''', ''Y'', '''+@camposLlave+''', '''+@monthYearDash+''', '''+@weekDash+''','''+@Methodology+''','''+@Report+''','''+@aggrType+'''
			')
		end

		begin
			set @operator='4'

			exec('
			exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
			'''+@ciudad+''', '+@operator+', 0,'''', 0, 1, '''+@pattern+''', ''Y'', '''+@camposLlave+''', '''+@monthYearDash+''', '''+@weekDash+''','''+@Methodology+''','''+@Report+''','''+@aggrType+'''
			')
		end

		begin
			exec(' 
			exec '+@BBDDorigen+'.dbo.sp_lcc_update_Dates_Reporting_Aggr_D16 '''+
			@ciudad+''', '''', ''Coverage'','''+ @Methodology+''','''+ @aggrType+''','''+ @Report+''',''''
			')
		end

		-- Control de transacciones para confirmar o deshacer la transacción.
		salto:

		IF @@TRANCOUNT = 0 -- ERROR. El número de transacciones es 0 (viene de hacer rollback en algunos de los procedimientos anteriores)
		begin
			select 'El numero de transacciones no es correcto'

			--Insertar ERROR EN LA TABLA DE CONTROL
			insert into [DASHBOARD].dbo.[lcc_executions_aggr]
			select 'ERROR! - El número de transacciones en la sesíón no es correcto. @@TRANCOUNT=0' + @pattern, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
		end

		IF @@TRANCOUNT = 1 -- OK
		begin
			COMMIT TRANSACTION T1
		end

		else --Si el número de transacciones no es 0 ni 1 (>1)
		begin
			if @@TRANCOUNT>0
				ROLLBACK TRANSACTION -- Hacemos rollback
			
			select 'Transacciones abiertas al inicio. Vuelva a ejecutar'

			--Insertar ERROR EN LA TABLA DE CONTROL
			insert into [DASHBOARD].dbo.[lcc_executions_aggr]
			select 'ERROR! - El número de transacciones en la sesíón no es correcto- GLOBAL - @@TRANCOUNT>1. ROLLBACK ' + @pattern, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
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
		select 'ERROR! - ' + @pattern, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
	END CATCH
		
	set @id=@id+1 --Siguiente entidad

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



