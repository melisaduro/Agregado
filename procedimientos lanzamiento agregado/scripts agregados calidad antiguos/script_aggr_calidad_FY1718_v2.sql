use [DASHBOARD]

--Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_entidades_agregar'

exec  [dbo].[sp_importExcelFileAsText] 'F:\VDF_Invalidate\aggr_calidad.xlsx', 'cities','_entidades_agregar'


-- Le creamos un identificador a cada ciudad para luego crear un bucle

select identity(int,1,1) id,*
into #iterator
from [dbo].[_entidades_agregar]


--Mostramos las ciudades que se agregaran

 select * from #iterator



 --Comenzamos el bucle con todas las ciudades a agregar
 declare @date_Ini as datetime = getdate()
 declare @id int=1

if @@TRANCOUNT=0
begin
 while @id<=(select max(id) from #iterator)
 begin

BEGIN TRY
BEGIN TRANSACTION T1


    -- Cogemos la informacion de la entidad del Excel en red

	declare @pattern as varchar (256) = (select Entidades from #iterator where id=@id)
    declare @BBDDorigen as varchar (256)= (select BBDDorigen from #iterator  where id=@id)
    declare @Report as varchar (256)= (select Report from #iterator where id=@id)

	if @BBDDorigen like '%Voice%'
	begin
		declare @ReportType as varchar (256) = (select ReportType from #iterator where id=@id)
	end




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
	@pattern+''','+ @operator+', '''','''+ @Tech+''','+ @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''', ''Completed'', '''+@Methodology+''', '''+@Report+''','''+ @aggrType+'''
')

end

begin
set @operator='7'

exec ('

	exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Data_Aggr_D16_FY1718 '''+
	@pattern+''','+ @operator+', '''','''+ @Tech+''','+ @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''', ''Completed'', '''+@Methodology+''', '''+@Report+''','''+ @aggrType+'''
')

end

begin
set @operator='3'

exec ('

	exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Data_Aggr_D16_FY1718 '''+
	@pattern+''','+ @operator+', '''','''+ @Tech+''','+ @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''', ''Completed'', '''+@Methodology+''', '''+@Report+''','''+ @aggrType+'''
')

end

begin
set @operator='4'

exec ('

	exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Data_Aggr_D16_FY1718 '''+
	@pattern+''','+ @operator+', '''','''+ @Tech+''','+ @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''', ''Completed'', '''+@Methodology+''', '''+@Report+''','''+ @aggrType+'''
')

end

-- Actualizacion de las fechas de reporte

begin


    --exec sp_lcc_update_Dates_Reporting_Aggr_D16
    --@pattern, '', 'Data', @Methodology, @aggrType

	exec(' 
		exec '+@BBDDorigen+'.dbo.sp_lcc_update_Dates_Reporting_Aggr_D16 '''+
    @pattern+''', '''', ''Data'','''+ @Methodology+''','''+ @aggrType+''','''+ @Report+''',''''
			
	')

end

end --Fin de los DATOS

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
end


--Limpieza de tablas temporales

drop table #iterator
