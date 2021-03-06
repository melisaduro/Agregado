USE [DASHBOARD]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_aggregate_delete_FY1718]    Script Date: 11/12/2017 14:54:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_lcc_aggregate_delete_FY1718] (
	@ruta_entidades as varchar(4000) 
	)
as


-- TESTING VARIABLES
 --declare @ruta_entidades as varchar (4000)='F:\VDF_Invalidate\aggr_borrado.xlsx'



	--Importamos el excel que contiene el nombre de todas las ciudades a agregar

	exec sp_lcc_dropifexists '_entidades_borrar'

	exec  [dbo].[sp_importExcelFileAsText] @ruta_entidades, 'cities','_entidades_borrar'


	-- Le creamos un identificador a cada ciudad para luego crear un bucle

	select identity(int,1,1) id,*
	into #iterator
	from [dbo].[_entidades_borrar]


	--Mostramos las ciudades que se agregaran

	 select * from #iterator

	declare @bbddAGGR as varchar (50)
	DECLARE @nameTabla varchar(256)
	declare @it1 bigint
	declare @MaxTab varchar(256)
	declare @id int=1
	declare @cmd nvarchar(4000)
	declare @ParmDefinition nvarchar(500)

	declare @date_Ini as datetime = getdate()

if @@TRANCOUNT = 0  --Controlamos que no haya transacciones ya abiertas en la misma sesión
begin
	 --Comenzamos el bucle con todas las ciudades a borrar
	 while @id<=(select max(id) from #iterator)
	 begin

	BEGIN TRY
	BEGIN TRANSACTION T1

		-- Cogemos la informacion de la entidad del Excel en red

		declare @nameEntidad as varchar (256) = (select Entidad from #iterator where id=@id)
		declare @BBDDorigen as varchar (256)= (select [BBDDOrigen] from #iterator  where id=@id)
		declare @Meas_date varchar(256)=(select Meas_Date from #iterator  where id=@id)
		declare @Report as varchar (256)= (select Report from #iterator where id=@id)
		declare @ReportType as varchar (256)= (select ReportType from #iterator where id=@id)
		declare @pattern as varchar (256) = replace(@nameEntidad,'-','_')  --Variable declarada para las tablas temporales
	
		-- En función del tipo de entidad seleccionamos la base de datos de agregado correspondiente

		--ENTIDADES CALIDAD
		If @BBDDorigen like '%Data%'
		begin
			if @BBDDorigen like '%3G%'
				begin
					set @bbddAGGR='AGGRData3G'
				end
			Else
				begin
				 set @bbddAGGR='AGGRData4G'
				end
		end

		If @BBDDorigen like '%Voice%'
		begin
			if @ReportType like '%VOLTE%'
				begin
					set @bbddAGGR='AGGRVOLTE'
				end
			Else
				begin
				 set @bbddAGGR='AGGRVoice4G'
				end
		end

		--ENTIDADES CALIDAD ROAD
		If @BBDDorigen like '%Data%Road%'
		begin
			 set @bbddAGGR='AGGRData4G_ROAD'
		end

		If @BBDDorigen like '%Voice%Road%'
		begin
			if @ReportType like '%VOLTE%'
				begin
					set @bbddAGGR='AGGRVOLTE_ROAD'
				end
			Else
				begin
				 set @bbddAGGR='AGGRVoice4G_ROAD'
				end
		end

		--COBERTURA
		If @BBDDorigen like '%Coverage%'
		begin
			if @BBDDorigen like '%ROAD%'
			begin
				 set @bbddAGGR='AGGRCoverage_ROAD'
			end
			else 
			begin
				 set @bbddAGGR='AGGRCoverage'
			end
		end

		--PRINT @bbddAGGR


		set @cmd = 'exec sp_lcc_dropifexists ''_tmp_Tablas_'+@pattern+'_borrado''
			select IDENTITY(int,1,1) id,name
			into _tmp_Tablas_'+@pattern+'_borrado
			from ['+@bbddAGGR +'].sys.tables
			where name like ''lcc_aggr_%''
			  and name not like ''%backup%''
			  and name not like ''%2017%''
			  and name not like ''%2016%''
			  and name not like ''%4GDevice%''
			  and type=''U'''
		--print @cmd
		exec (@cmd)

		SET @ParmDefinition = N'@MaxTabOut varchar(255) output' 
		set @cmd='
		select @MaxTabOut = max(id) from _tmp_Tablas_'+@pattern+'_borrado
		'
		EXEC sp_executesql @cmd,@ParmDefinition, @MaxTabOut = @MaxTab output
			
		--print 'Id máximo:' + @MaxTab


		set @it1 = 1

		while @it1 <= @MaxTab
		begin

			--Nombre tabla
			SET @ParmDefinition = N'@iterator bigint,@nameTablaOut varchar(255) output' 
			set @cmd='
			select @nameTablaOut = name
			from _tmp_Tablas_'+@pattern+'_borrado
			where id =@iterator
			'
			EXEC sp_executesql @cmd,@ParmDefinition,@iterator=@it1, @nameTablaOut= @nameTabla output

			print 'Nombre de la tabla:  ' + @nameTabla


			set @cmd = 'delete '+@bbddAGGR +'.dbo.'+ @nameTabla +'
				where Entidad like ''' + @nameEntidad +'''
					and Meas_date like ''' + @Meas_date + '''
					and Report_Type like '''+ @Report + '''
					option (Optimize for unknown)'

			print @cmd
			exec (@cmd)


			set @it1 = @it1 +1
		end

		--Borramos las tablas temporales declaradas
			set @cmd=('
				exec sp_lcc_dropifexists ''_tmp_Tablas_'+@pattern+'_borrado''
				')
			exec(@cmd)


		-- Control de transacciones para confirmar o deshacer la transacción.

		IF @@TRANCOUNT = 0 -- ERROR. El número de transacciones es 0 (viene de hacer rollback en algunos de los procedimientos por operador)
		begin
			select 'El numero de transacciones no es correcto'

			--Insertar ERROR EN LA TABLA DE CONTROL
			insert into [DASHBOARD].dbo.[lcc_executions_aggr]
			select 'ERROR BORRADO! - El número de transacciones en la sesíón no es correcto. @@TRANCOUNT=0' + @nameEntidad, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
		end

		IF @@TRANCOUNT = 1 -- OK
		begin
			COMMIT TRANSACTION T1

			insert into [DASHBOARD].dbo.[lcc_executions_aggr]
			select 'ENTIDAD BORRADA! - ' + @nameEntidad, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
			NULL,NULL,NULL,@Report,NULL,NULL,NULL,NULL,@bbddAGGR

			select 'Entidad borrada ' +@nameEntidad+' en base de datos ' +@bbddAGGR
		end

		
		else --Si el número de transacciones no es 0 ni 1 (>1)
		begin
			if @@TRANCOUNT>0
				ROLLBACK TRANSACTION -- Hacemos rollback

			select 'Transacciones abiertas al inicio. Vuelva a ejecutar'

			--Insertar ERROR EN LA TABLA DE CONTROL
			insert into [DASHBOARD].dbo.[lcc_executions_aggr]
			select 'ERROR BORRADO! - El número de transacciones en la sesíón no es correcto- GLOBAL - @@TRANCOUNT>1. ROLLBACK ' + @nameEntidad, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
		end


	END TRY
	BEGIN CATCH
		if @@TRANCOUNT>0
			ROLLBACK TRANSACTION

		select 'Error en el procedimiento. Volver a ejecutar'

		--Insertar ERROR EN LA TABLA DE CONTROL
		insert into [DASHBOARD].dbo.[lcc_executions_aggr]
		select 'ERROR BORRADO! - ' + @nameEntidad, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
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
			select 'ERROR BORRADO! - Hay transacciones abiertas al inicio - @@TRANCOUNT<>0. ROLLBACK ', NULL, NULL, getdate(),NULL,NULL, NULL,NULL,NULL,
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL

			select 'Transacciones abiertas al inicio.  Realice ROLLBACK y vuelva a ejecutar'
	end

--Limpieza de tablas temporales
drop table #iterator
