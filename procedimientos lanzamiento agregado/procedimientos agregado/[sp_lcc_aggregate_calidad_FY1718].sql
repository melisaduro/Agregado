USE [DASHBOARD]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_aggregate_calidad_FY1718]    Script Date: 12/04/2018 10:28:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_lcc_aggregate_calidad_FY1718] (
	@ruta_entidades as varchar(4000) 
	)
as

-- TESTING VARIABLES
--declare @ruta_entidades as varchar (4000)='F:\VDF_Invalidate\aggr_calidad.xlsx'

-- Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_entidades_agregar'

-- Cogemos la informacion de la entidad del Excel en red
exec  [dbo].[sp_importExcelFileAsText] @ruta_entidades, 'cities','_entidades_agregar'

-- Le creamos un identificador a cada ciudad para luego crear un bucle
select identity(int,1,1) id,*
into #iterator
from [dbo].[_entidades_agregar]

--Mostramos las ciudades que se agregaran

 select * from #iterator

 --Comenzamos el bucle con todas las ciudades a agregar
declare @date_Ini as datetime = getdate()
declare @id int=1
declare @bbddAGGR as varchar (50)
DECLARE @nameTabla varchar(1000)
declare @it1 bigint
declare @MaxTab varchar(255)
declare @cmd nvarchar(4000)
declare @ParmDefinition nvarchar(500)
declare @entidad varchar(255)


if @@TRANCOUNT = 0  --Controlamos que no haya transacciones ya abiertas en la misma sesión

begin
	
	while @id<=(select max(id) from #iterator)
	begin

		BEGIN TRY
		BEGIN TRANSACTION T1

		-- Número de transacciones abiertas debe ser 1

		declare @pattern as varchar (256) = (select Entidades from #iterator where id=@id)
		declare @BBDDorigen as varchar (256)= (select BBDDorigen from #iterator  where id=@id)
		declare @Report as varchar (256)= (select Report from #iterator where id=@id)
		declare @pattern_2 as varchar (256) = replace(@pattern,'-','_')  --Variable declarada para las tablas temporales

		-- 20171214-@MDM: Actualización para no permitir el agregado por Vodafone
		if @Report = 'VDF'
		begin
			select 'Agregado VDF no permitido'
			GOTO salto
		end

		if @BBDDorigen like '%Voice%'
		begin
			declare @ReportType as varchar (256) = (select ReportType from #iterator where id=@id)
		end
		

		declare @Meas_Round as varchar(256)

		if (charindex('AVE',@BBDDorigen)>0 and charindex('Rest',@BBDDorigen)=0)
			begin 
			 set @Meas_Round= [master].dbo.fn_lcc_getElement(1, @BBDDorigen,'_') + '_' + [master].dbo.fn_lcc_getElement(6, @BBDDorigen,'_')
			end
		else
			begin
			 set @Meas_Round= [master].dbo.fn_lcc_getElement(1, @BBDDorigen,'_') + '_' + [master].dbo.fn_lcc_getElement(5, @BBDDorigen,'_')
			end

		-- PASO 1: Borramos previamente la entidad si ya está agregada, para eso comprobamos si se encuentra en la tabla de 
		-- lcc_aggr_sp_MDD_Voice_Llamadas (VOZ) o lcc_aggr_sp_MDD_Data_DL_Thput_CE (DATOS)

		-- En función del tipo de entidad seleccionamos la base de datos de agregado correspondiente

		--Entidades calidad
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
			set @nameTabla='lcc_aggr_sp_MDD_Data_DL_Thput_CE'
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
			set @nameTabla='lcc_aggr_sp_MDD_Voice_Llamadas'
		end

		--ENTIDADES calidad ROAD
		If @BBDDorigen like '%Data%Road%'
		begin
			 set @bbddAGGR='AGGRData4G_ROAD'
			 set @nameTabla='lcc_aggr_sp_MDD_Data_DL_Thput_CE'
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
			set @nameTabla='lcc_aggr_sp_MDD_Voice_Llamadas'
		end
		
		set @cmd = '
		exec sp_lcc_dropifexists ''_tmp_Entidades_'+@pattern_2+'_calidad''  --Tenemos en cuenta las entidades solo agregadas en OSP en la primera parte de FY1718_H1 (solo me interesa borrar esas entidades, el resto no)
		select t1.entidad 
					into _tmp_Entidades_'+@pattern_2+'_calidad
					from
						(
							select entidad,meas_round,report_type
							from  '+@bbddAGGR+'.dbo.'+ @nameTabla +'
							where Entidad like ''' + @pattern +'''
							and Meas_Round like ''' + @Meas_Round + '''
							and Report_Type like '''+ @Report + '''
						) t1
					inner join 
						(
							select entidad,meas_round,report_type
							from '+@bbddAGGR+'.dbo.'+ @nameTabla +'
							where meas_round like ''%1718%''
							group by entidad,meas_round,report_type
							having count(distinct(mnc))=1
						) t2
					on t1.entidad=t2.entidad
					and t1.meas_round=t2.meas_round
					and t1.report_type=t2.report_type
					group by t1.entidad

					'

		--print @cmd
		exec (@cmd)

		--Comprobamos que haya entidades en _tmp_entidades

		SET @ParmDefinition = N'@entidadOut varchar(255) output' 
		set @cmd='
		select @entidadOut = entidad from _tmp_Entidades_'+@pattern_2+'_calidad
		'
		EXEC sp_executesql @cmd,@ParmDefinition, @entidadOut= @entidad output

		--print 'Entidad a borrar:' + @entidad
		

		if @entidad <>'' --Si hay entidades en _tmp_Entidades, la borramos de agregado
		begin
			set @cmd = 'exec sp_lcc_dropifexists ''_tmp_Tablas_'+@pattern_2+'_calidad''
			select IDENTITY(int,1,1) id,name
			into _tmp_Tablas_'+@pattern_2+'_calidad
			from ['+@bbddAGGR +'].sys.tables
			where name like ''lcc_aggr_%''
				and type=''U'''
			--print @cmd
			exec (@cmd)
		
			SET @ParmDefinition = N'@MaxTabOut varchar(255) output' 
			set @cmd='
			select @MaxTabOut = max(id) from _tmp_Tablas_'+@pattern_2+'_calidad 
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
				from _tmp_Tablas_'+@pattern_2+'_calidad
				where id =@iterator
				'
				EXEC sp_executesql @cmd,@ParmDefinition,@iterator=@it1, @nameTablaOut= @nameTabla output

				--print 'Nombre de la tabla:  ' + @nameTabla

				set @cmd = 'delete '+@bbddAGGR +'.dbo.'+ @nameTabla +'
					where Entidad like ''' + @pattern +'''
						and Meas_Round like ''' + @Meas_Round + '''
						and Report_Type like '''+ @Report + '''
						option (Optimize for unknown)'

				--print @cmd
				exec (@cmd)

				set @it1 = @it1 +1
			end
			select 'Entidad borrada ' + @pattern

			insert into [DASHBOARD].dbo.[lcc_executions_aggr]
			select 'ENTIDAD BORRADA! - ' + @pattern, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
			NULL,NULL,NULL,@Report,NULL,NULL,NULL,NULL,@bbddAGGR
		
			
		end

		--Borramos las tablas temporales declaradas
			set @cmd=('
				exec sp_lcc_dropifexists ''_tmp_Entidades_'+@pattern_2+'_calidad''
				exec sp_lcc_dropifexists ''_tmp_Tablas_'+@pattern_2+'_calidad''
				')
			exec(@cmd)



	-- PASO 2: Una vez borrada la entidad (en el caso de hubiese que borrarla), pasamos a agregarla
	-- Variables fijas que predefinimos por defecto

		declare @aggrType as varchar(256)= 'GRID'
		declare @Methodology as varchar (50) = 'D16'
		declare @camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-Report_Type-Entidad'
		declare @operator as varchar (50)
		declare @Indoor as varchar (50)
		declare @Tech as varchar (50)


		-- Obetenmos la tecnologia a agregar

		if @BBDDorigen like '%3G%'

		  begin
		  set @Tech='3G'
		  end

		Else -- Indoor y 4G

		  begin
		  set @Tech='4G'
		  end

		-- Vemos si se trata de una entidad Indoor

		if @BBDDorigen like '%Voice%'

		  begin

				if @BBDDorigen like '%AVE%'
					begin
						set @Indoor='2'
					end
				else 
					begin
						If @BBDDorigen like '%Indoor%'
							begin
								set @Indoor='1'
							end
						else
							begin
								set @Indoor='0'
							end
				  end
		  end

		if @BBDDorigen like '%Data%'
		  begin

			  if @BBDDorigen like '%Indoor%'
				  begin
					  set @Indoor='1'
				  end
			  else
				  begin
					set @Indoor='0'
				  end
		  end


		-- Definimos los camposLlave en funcion del tipo de entidad

		if @BBDDorigen like '%Indoor%'
		begin
			set @camposLlave='MNC-Entidad-Num_Medida-Meas_Date-Report_Type'
		end

		If @BBDDorigen like '%Road%'
		begin
			set @camposLlave='MNC-Parcel-Meas_Round-Entidad-Report_Type'
		end

		If @BBDDorigen like '%AVE%'
		begin
			set @camposLlave='MNC-Parcel-Meas_Round-Entidad-Report_Type'
		end

		if @ReportType like '%VOLTE%'
		begin 
			set @ReportType='VOLTE'
		end
		else
		begin
			set @ReportType='CSFB'
		end


		print  @BBDDorigen

		if @BBDDorigen like '%Voice%'

			begin

			/**********************************************************************************************************
			*************************************Agregamos la VOZ******************************************************
			**********************************************************************************************************/
			
			begin
				set @operator='1'

				exec ('

				exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Voice_Aggr_D16_FY1718
				'''+ @pattern+''','+ @operator+','+
				 @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''','''+ @Methodology+''','''+ @Report+''','''+ @aggrType+''','''+ @ReportType+'''')

			end

			
			begin
				set @operator='7'
				
				exec ('

				exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Voice_Aggr_D16_FY1718
				'''+ @pattern+''','+ @operator+','+
				 @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''','''+ @Methodology+''','''+ @Report+''','''+ @aggrType+''','''+ @ReportType+'''')

			end

			begin
				set @operator='3'

				exec ('

				exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Voice_Aggr_D16_FY1718
				'''+ @pattern+''','+ @operator+','+
				 @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''','''+ @Methodology+''','''+ @Report+''','''+ @aggrType+''','''+ @ReportType+'''')

			end

			begin
				set @operator='4'

				exec ('

				exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Voice_Aggr_D16_FY1718 
				'''+ @pattern+''','+ @operator+','+
				 @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''','''+ @Methodology+''','''+ @Report+''','''+ @aggrType+''','''+ @ReportType+'''')

			end

			--Actualizacion de las fechas de reporte

			begin

				exec(' 
					exec '+@BBDDorigen+'.dbo.sp_lcc_update_Dates_Reporting_Aggr_D16 '''+
				@pattern+''', '''', ''Voice'','''+ @Methodology+''','''+ @aggrType+''','''+ @Report+''','''+ @ReportType+'''
			
				')

			end


		end --Fin de la VOZ



		If @BBDDorigen like '%Data%'

		begin

		/**********************************************************************************************************
		*************************************Agregamos los DATOS***************************************************
		**********************************************************************************************************/
			begin
				set @operator='1'

				exec ('

					exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Data_Aggr_D16_FY1718 '''+
					@pattern+''','+ @operator+','''+ @Tech+''','+ @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''', '''+@Methodology+''', '''+@Report+''','''+ @aggrType+'''
				')

			end

			begin
				set @operator='7'

				exec ('

					exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Data_Aggr_D16_FY1718 '''+
					@pattern+''','+ @operator+','''+ @Tech+''','+ @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''', '''+@Methodology+''', '''+@Report+''','''+ @aggrType+'''
				')

			end

			begin
				set @operator='3'

				exec ('

					exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Data_Aggr_D16_FY1718 '''+
					@pattern+''','+ @operator+','''+ @Tech+''','+ @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''', '''+@Methodology+''', '''+@Report+''','''+ @aggrType+'''
				')

			end

			begin
				set @operator='4'

				exec ('

					exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Data_Aggr_D16_FY1718 '''+
					@pattern+''','+ @operator+','''+ @Tech+''','+ @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''', '''+@Methodology+''', '''+@Report+''','''+ @aggrType+'''
				')

			end

			-- Actualizacion de las fechas de reporte

			begin

				exec(' 
					exec '+@BBDDorigen+'.dbo.sp_lcc_update_Dates_Reporting_Aggr_D16 '''+
				@pattern+''', '''', ''Data'','''+ @Methodology+''','''+ @aggrType+''','''+ @Report+''',''''
			
				')

			end

		end --Fin de los DATOS


	-- PASO 3: Control de transacciones para confirmar o deshacer la transacción.
	salto:

		IF @@TRANCOUNT = 0 -- ERROR. El número de transacciones es 0 (viene de hacer rollback en algunos de los procedimientos por operador)
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
				ROLLBACK TRANSACTION

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

		--Insertar ERROR EN LA TABLA DE CONTROL
		insert into [DASHBOARD].dbo.[lcc_executions_aggr]
		select 'ERROR! - ' + @pattern, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
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


