USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_aggregate_parcel_cober]    Script Date: 22/06/2017 17:38:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[sp_lcc_aggregate_parcel_cober_NEW] (
	@dborigen as varchar(256), 
	@dbdestino as varchar(256), 
	@pattern as varchar(256), 
	@overwrite as varchar(1), --Y/N se sobreescriben las parcelas o no
	
	--@camposLlave as STRINGARRAY READONLY
	@camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round' -- Default value
	)
as

 --------------------------------------------------------------------------------
 ----- Testing Variables -----
 --------------------------------------------------------------------------------
 --declare @dborigen varchar(50)
 --declare @dbdestino varchar(50)
 --declare @pattern as varchar(256)
 --declare @overwrite as varchar(1)
 --declare @camposLlave as varchar(1024)
 
 --SET @dborigen = 'FY1617_Voice_Rest_3G_H2_8'
 --SET @dbdestino = 'FY1617_TEST_CECI'
 --SET @pattern = 'quartdepoblet'
 --set @overwrite = 'Y'
 --SET @camposLlave = 'MNC-Parcel-Meas_Round' --MNC-Parcel-Meas_Round En Indoor: MNC-Entidad-Num_Medida-Meas_Date
 --------------------------------------------------------------------------------
 
 DECLARE @MyTableRdo table( TabOrig varchar(255),
							TabDest varchar(255),
                            Comentario varchar(255));
 
 declare @cmd nvarchar(max)

 --CAC 14/06/2017: se insertan [] para entidades con caracteres raros
 set @cmd = 'lcc_warning_aggr_' +@pattern
 print 'Tabla warning: '+@cmd
 EXECUTE sp_lcc_dropifexists_BBDD @dborigen, @cmd
 exec('CREATE TABLE '+@dborigen+'.dbo.[lcc_warning_aggr_' +@pattern+'](
	Parcel varchar(255) NOT NULL,
	TabOrig varchar(255) NOT NULL,
	TabDest varchar(255) NOT NULL,
	[Key] varchar(255) NOT NULL
 )')

 --------------------------------------------------------------------------------
 --Cruces por campos clave
 --------------------------------------------------------------------------------
 declare @updateCruce varchar(8000)
 declare @camposLlaveQuery as varchar(8000)
 declare @Campo varchar(255)
 declare @camposLlaveOrig as varchar(1024)
 declare @indCampo bigint
 
 set @updateCruce = ''
 set @camposLlaveQuery = ''
 set @camposLlaveOrig = @camposLlave
 
 --Con @camposLlave = Campo1_Campo2_ ... _CampoN
 declare @tmp as varchar(50)
 set @tmp = 'seguir'
 while @tmp = 'seguir' 
	begin
		set @indCampo = CHARINDEX('-',@camposLlave)
		if @indCampo != 0
			set @Campo =  LEFT(@camposLlave,@indCampo-1)
		else
			begin
				set @Campo = @camposLlave
				set @tmp = 'parar'
			end
		set @camposLlave = RIGHT(@camposLlave, len(@camposLlave)-@indCampo)
		set @updateCruce = @updateCruce + 'o.' + @Campo + '=d.' + @Campo + ' AND '
		set @camposLlaveQuery = @camposLlaveQuery + ' convert(varchar, o.'+ @Campo + ') + ''_'' + '
	end
set @updateCruce = substring(@updateCruce,1,len(@updateCruce)-3)
set @camposLlaveQuery =  substring(@camposLlaveQuery,1,len(@camposLlaveQuery)-8)

--print 'Cruce de tablas: ' +@updateCruce
--print 'Campos llave:' +@camposLlaveQuery

--------------------------------------------------------------------------------
--Tablas origen de las que vamos a insertar la información
--------------------------------------------------------------------------------
set @cmd = 'select IDENTITY(int,1,1) id,t.name 
into ##t_o_cober_'+ @pattern +'
from ' + @dborigen+ '.sys.tables t
where t.name like ''lcc_aggr_%''
	and t.name like ''%'+ @pattern +'%''
	and t.type=''U'''
--print @cmd	
exec (@cmd)
-- select * from ##t_o_cober
-- drop table ##t_o_cober

--------------------------------------------------------------------------------
--Tablas destino en las que vamos a insertar la información
--------------------------------------------------------------------------------
set @cmd = 'select IDENTITY(int,1,1) id,t.name 
into ##t_d_cober_'+ @pattern +'
from ' + @dbdestino+ '.sys.tables t
where t.name like ''lcc_aggr_%''
	and t.type=''U'''
--print @cmd	
exec (@cmd)
-- select * from ##t_d_cober
-- drop table ##t_d_cober
	

--------------------------------------------------------------------------------
--Información de las columnas de las tablas origen
--------------------------------------------------------------------------------
set @cmd = 'select t.name table_name, c.name column_name, c.column_id 
into ##c_o_cober_'+ @pattern +'
from ' + @dborigen+ '.sys.tables t, ' + @dborigen+ '.sys.columns c
where t.object_id=c.object_id 
	and t.name like ''lcc_aggr_%''
	and t.name like ''%'+ @pattern +'%''
	and t.type=''U'''
--print @cmd	
exec (@cmd)
-- select * from ##c_o_cober
-- drop table ##c_o_cober	


--------------------------------------------------------------------------------
--Información de las columnas de las tablas destino
--------------------------------------------------------------------------------
set @cmd = 'select t.name table_name, c.name column_name, c.column_id 
into ##c_d_cober_'+ @pattern +'
from ' + @dbdestino+ '.sys.tables t, ' + @dbdestino+ '.sys.columns c
where t.object_id=c.object_id 
	and t.name like ''lcc_aggr_%''
	and t.type=''U'''
--print @cmd	
exec (@cmd)
-- select * from ##c_d_cober
-- drop table ##c_d_cober



--------------------------------------------------------------------------------
--Lógica de inserción de registros
--------------------------------------------------------------------------------

 declare @it1 bigint
 declare @it2 bigint
 declare @MaxTabOrig bigint
 declare @MaxColOrig bigint
 declare @TabOrig varchar(255)
 declare @TabDest varchar(255)
 declare @ColOrig varchar(255)
 declare @idColDest bigint
 declare @TipoColOrig varchar(255)
 declare @TamColOrig bigint
 declare @PrecColOrig bigint
 declare @ScaColOrig bigint
 --declare @parcelasNOinsert bigint
 
 declare @insert varchar(max)
 declare @select varchar(max)
 declare @alter varchar(max)
 declare @update varchar(max)
 declare @updateFrom varchar(max)
 declare @selectNOinsert varchar(max)
 
 declare @ParmDefinition nvarchar(500)
 
 set @it1 = 1
 set @it2 = 1
 
 SET @ParmDefinition = N'@MaxTabOrigOut bigint output' 

  set @cmd =('select @MaxTabOrigOut = MAX(id) 
 from ##t_o_cober_'+@pattern+'')

 exec sp_executesql @cmd,@ParmDefinition,@MaxTabOrigOut = @MaxTabOrig output
 print @MaxTabOrig
 
 while @it1 <= @MaxTabOrig --Por cada tabla origen realizamos la agregación
 begin
	--Iniciamos variables
	 set @insert = 'INSERT '
	 set @select = 'SELECT '
	 set @update = 'UPDATE '
	 set @TabOrig = ''
	 set @TabDest = ''
	 set @selectNOinsert = 'SELECT '
 
	--Nombre tabla origen
	SET @ParmDefinition = N'@iterator bigint, @TabOrigOut varchar(255) output' 

	set @cmd='select @TabOrigOut = name
	from ##t_o_cober_'+ @pattern +'
	where id = @iterator'

	exec sp_executesql @cmd,@ParmDefinition, @iterator=@it1, @TabOrigOut= @TabOrig output
	print 'Nombre de la tabla origen:' + @TabOrig
	
	--Nombre de la tabla destino equivalente
	SET @ParmDefinition = N'@TabOrig varchar(255), @TabDestOut varchar(255) output' 

	set @cmd='select @TabDestOut = name
	from ##t_d_cober_'+ @pattern +'
	where @TabOrig = name +''_''+'''+ @pattern +''''

	exec sp_executesql @cmd,@ParmDefinition, @TabOrig, @TabDestOut= @TabDest output
	print 'Nombre de la tabla destino:' + @TabDest
	
	if @TabDest <> '' --La tabla origen existe en la bbdd destino
		begin
		set @MaxColOrig = 0
		
		--Insertamos la tabla destino en los scripts
		set @insert = @insert + @dbdestino +'.dbo.['+ @TabDest + '] ('
		set @update = @update + @dbdestino +'.dbo.['+ @TabDest +']'+ CHAR(13) + 'SET '
		
		--Recorremos sus columnas (puede tener mas columnas que la tabla destino)
		--Número de columnas de la tabla origen
		SET @ParmDefinition = N'@TabOrig varchar(255),@MaxColOrigOut varchar(255) output'

		set @cmd='select @MaxColOrigOut = MAX(column_id) 
		from ##c_o_cober_'+ @pattern +'
		where table_name = @TabOrig'

		exec sp_executesql @cmd,@ParmDefinition, @TabOrig, @MaxColOrigOut= @MaxColOrig output
		print 'Número de columnas de la tabla origen:  ' + convert(varchar,@MaxColOrig)
		
		--Iniciamos variables del bucle por columna
		set @alter = 'ALTER TABLE '
		set @it2 = 1	
		
		while @it2 <= @MaxColOrig 
		begin
			set @ColOrig = ''
			set @idColDest = 0
			
			--Nombre columna origen
			SET @ParmDefinition = N'@TabOrig varchar(255),@iterator bigint,@ColOrigOut varchar(255) output'

			set @cmd='select @ColOrigOut = column_name
			from ##c_o_cober_'+ @pattern +'
			where table_name = @TabOrig
				 and column_id =@iterator'
			--print (@cmd)
			exec sp_executesql @cmd,@ParmDefinition, @TabOrig, @iterator=@it2, @ColOrigOut= @ColOrig output
			print 'Nombre de la columna origen:' +@ColOrig
			--exec (@cmd)

			--print 'Nombre de la columna origen:  ' + @ColOrig
			
			if @ColOrig <> '' --Si la columna origen existe (el id puede corresponderse a una columna eliminada)
			begin

				--Id de la columna destino si existe
				SET @ParmDefinition = N'@TabDest varchar(255),@ColOrig varchar(255),@idColDestOut bigint output'
				set @cmd='select @idColDestOut = column_id
				from ##c_d_cober_'+ @pattern +'
				where table_name = @TabDest
					and  column_name =@ColOrig'
				--print (@cmd)
				exec sp_executesql @cmd,@ParmDefinition, @TabDest, @ColOrig, @idColDestoUT= @idColDest output
				print 'Id de la columna destino:' + convert(varchar,@idColDest)
				--exec (@cmd)
					
				if @idColDest = 0 --Columna no existente en la tabla destino
					begin
						set @TipoColOrig = ''
						set @TamColOrig = 0
						set @PrecColOrig = 0
						set @ScaColOrig = 0
						--Obtenemos el tipo de la columna en la tabla origen
						SET @ParmDefinition = N'@TipoColOrigOut varchar(255) output' 
						
						set @cmd = 'select @TipoColOrigOut = ty.name
						from '+@dborigen+'.sys.tables t, '+@dborigen+'.sys.columns c,sys.types ty
						where t.object_id=c.object_id 
							and t.name='''+@TabOrig+'''
							and c.name='''+@ColOrig+'''
							and t.type=''U''
							and c.user_type_id = ty.user_type_id'
						--print @cmd
						exec sp_executesql @cmd,@ParmDefinition,@TipoColOrigOut = @TipoColOrig output
						--print @TipoColOrig
						
						--Obtenemos el tamaño del tipo de la columna en la tabla origen	
						SET @ParmDefinition = N'@TamColOrigOut bigint output' 
						
						set @cmd = 'select @TamColOrigOut = c.max_length
						from '+@dborigen+'.sys.tables t, '+@dborigen+'.sys.columns c
						where t.object_id=c.object_id 
							and t.name='''+@TabOrig+'''
							and c.name='''+@ColOrig+'''
							and t.type=''U'''
						--print @cmd
						exec sp_executesql @cmd,@ParmDefinition,@TamColOrigOut = @TamColOrig output
						--print @TamColOrig
							
						--En los tipos numeric buscamos la precision y la escala
						if  @TipoColOrig = 'numeric'
							begin							
								--Obtenemos la precision 
								SET @ParmDefinition = N'@PrecColOrigOut bigint output' 
						
								set @cmd = 'select @PrecColOrigOut = c.precision
								from '+@dborigen+'.sys.tables t, '+@dborigen+'.sys.columns c
								where t.object_id=c.object_id 
									and t.name='''+@TabOrig+'''
									and c.name='''+@ColOrig+'''
									and t.type=''U'''
								--print @cmd
								exec sp_executesql @cmd,@ParmDefinition,@PrecColOrigOut = @PrecColOrig output
								--print @PrecColOrig

								--Obtenemos la escala 
								SET @ParmDefinition = N'@ScaColOrigOut bigint output' 
						
								set @cmd = 'select @ScaColOrigOut = c.scale
								from '+@dborigen+'.sys.tables t, '+@dborigen+'.sys.columns c
								where t.object_id=c.object_id 
									and t.name='''+@TabOrig+'''
									and c.name='''+@ColOrig+'''
									and t.type=''U'''
								--print @cmd
								exec sp_executesql @cmd,@ParmDefinition,@ScaColOrigOut = @ScaColOrig output
								--print @ScaColOrig
							end

						--Añadimos la nueva columna
						if  @TipoColOrig = 'varchar'
							begin
								set @alter = @alter + @dbdestino +'.dbo.['+ @TabDest + ']' + CHAR(13)+ ' ADD [' + @ColOrig + '] ' + @TipoColOrig +'('+ CONVERT(varchar,@TamColOrig)+')'
							end
						else if  @TipoColOrig = 'numeric'
							begin								
								set @alter = @alter + @dbdestino +'.dbo.['+ @TabDest + ']' + CHAR(13)+ ' ADD [' + @ColOrig + '] ' + @TipoColOrig +'('+ CONVERT(varchar,@PrecColOrig)+','+ CONVERT(varchar,@ScaColOrig)+')'
							end
						else 

							begin								
								set @alter = @alter + @dbdestino +'.dbo.['+ @TabDest + ']' + CHAR(13)+ ' ADD [' + @ColOrig + '] ' + @TipoColOrig
							end

						print @alter
						exec (@alter)

						set @alter = 'ALTER TABLE '
						
						--Registramos la columna modificada
						if  @TipoColOrig = 'varchar'
							begin
								insert @MyTableRdo
								values (@TabOrig,@TabDest,'Columna '+@ColOrig + ' ' + @TipoColOrig +'('+ CONVERT(varchar,@TamColOrig)+') creada en la tabla destino')
							end
						else if  @TipoColOrig = 'numeric'
							begin								
								insert @MyTableRdo
								values (@TabOrig,@TabDest,'Columna '+@ColOrig + ' ' + @TipoColOrig +'('+ CONVERT(varchar,@PrecColOrig)+','+ CONVERT(varchar,@ScaColOrig)+') creada en la tabla destino')
							end
						else 
							begin								
								insert @MyTableRdo
								values (@TabOrig,@TabDest,'Columna '+@ColOrig + ' ' + @TipoColOrig +' creada en la tabla destino')
							end

					end
				set @select = @select + 'o.[' + @ColOrig + '],' 
				set @insert = @insert + '[' + @ColOrig + '],' 
				--Si la columna no está incluida en el cruce, la incluimos para modificar su valor
				--(podríamos dejarla pero debemos acortar el tamaño del string)
				if charindex(@ColOrig,@updateCruce) = 0
					set @update = @update + '[' + @ColOrig + ']=o.' + '[' + @ColOrig + '],'
			end
			set @it2 = @it2 +1	
		end
		--print @select
		--print @insert
		--print @update
		
		--set @select = substring(@select,1,len(@select)-1)
		set @select = @select + ''''+ @camposLlaveOrig + ''''
		--UPDATE
		set @update = substring(@update,1,len(@update)-1)
		--set @update = @update + char(13) + 'FROM ' + @dborigen +'.dbo.'+@TabOrig + ' as o, ' + char(13) +
		--	@dbdestino +'.dbo.'+ @TabDest + ' as d' + char(13) +
		--	'WHERE ' +@updateCruce 
		--INSERT
		--set @select = @select + CHAR(13)+ ' from ' + @dborigen +'.dbo.'+@TabOrig
		set @select = @select + CHAR(13)+ ' from ' + @dborigen +'.dbo.['+@TabOrig + '] as o' + char(13) +
			'LEFT outer join ' + @dbdestino +'.dbo.['+ @TabDest + '] as d' + char(13) +
			'ON (' + @updateCruce + ')'+ char(13) +
			'WHERE d.[Database] is null'	
		set @selectNOinsert = 'select o.Parcel,'''+@TabOrig+''', '''+@TabDest+''', '+@camposLlaveQuery + CHAR(13)+ ' from ' + @dborigen +'.dbo.['+@TabOrig + '] as o' + char(13) +
			'LEFT outer join ' + @dbdestino +'.dbo.['+ @TabDest + '] as d' + char(13) +
			'ON (' + @updateCruce + ')'+ char(13) +
			'WHERE d.[Database] is not null'	
		--set @insert = substring(@insert,1,len(@insert)-1)
		--set @insert = @insert + ') '
		set @insert = @insert + 'Key_Fields) '
		
		if @overwrite = 'Y' --Sobreescribimos si la parcela existe y el resto insertamos
			begin
				print @update
				set @updateFrom = char(13) + 'FROM ' + @dborigen +'.dbo.['+@TabOrig + '] as o, ' + char(13) +
					@dbdestino +'.dbo.['+ @TabDest + '] as d' + char(13) +
					'WHERE ' +@updateCruce
				print @update + CHAR(13)+ @updateFrom
				exec (@update + @updateFrom)
				insert @MyTableRdo
				values (@TabOrig,@TabDest,'Update: '+ CONVERT(varchar,@@rowcount) +' filas afectadas')				
			end
		--Si existen parcelas que no se van a insertar porque la llave ya existe, las insertamos en la tabla de warning
		if @overwrite = 'N'
			begin
				 --CAC 14/06/2017: se insertan [] para entidades con caracteres raros
				print 'insert '+@dborigen+'.dbo.[lcc_warning_aggr_' +@pattern+'] '+@selectNOinsert
				exec('insert '+@dborigen+'.dbo.[lcc_warning_aggr_' +@pattern+'] '+@selectNOinsert)
			end			
		print @insert + CHAR(13)+ @select
		exec (@insert + ' '+ @select)
		insert @MyTableRdo
		values (@TabOrig,@TabDest,'Insert: '+ CONVERT(varchar,@@rowcount) +' filas afectadas')		
		end
	else
		begin
			insert @MyTableRdo
			values (@TabOrig,'','Tabla no existente en la db destino')
			
			exec('insert '+@dborigen+'.dbo.[lcc_warning_aggr_' +@pattern+']
			values ('+@TabOrig+','''',''Tabla no existente en la db destino'')')
		end
	set @it1 = @it1 +1
 end

exec('drop table ##t_o_cober_' +@pattern+', ##t_d_cober_' +@pattern+', ##c_o_cober_' +@pattern+', ##c_d_cober_' +@pattern+'')

select *
from @MyTableRdo
order by 1
  