use [DASHBOARD]


--Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_entidades_agregar'

exec  [dbo].[sp_importExcelFileAsText] 'F:\VDF_Invalidate\aggr_VOLTE.xlsx', 'cities','_entidades_agregar'


-- Le creamos un identificador a cada ciudad para luego crear un bucle

select identity(int,1,1) id,*
into #iterator
from [dbo].[_entidades_agregar]


--Mostramos las ciudades que se agregaran

 select * from #iterator



 --Comenzamos el bucle con todas las ciudades a agregar

 declare @id int=1
 while @id<=(select max(id) from #iterator)
 begin

    -- Cogemos la informacion de la entidad del Excel en red

	declare @pattern as varchar (256) = (select Entidades from #iterator where id=@id)
    declare @BBDDorigen as varchar (256)= (select BBDDorigen from #iterator  where id=@id)
    declare @Report as varchar (256)= (select Report from #iterator where id=@id)




    -- Variables fijas que predefinimos por defecto

    declare @aggrType as varchar(256)= 'Collectionname'
    declare @Methodology as varchar (50) = 'D15'
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

    if @BBDDorigen like '%VOLTE%' or @BBDDorigen like '%Voice%'

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






if @BBDDorigen like '%VOLTE%' or @BBDDorigen like '%Voice%'

begin

/**********************************************************************************************************
*************************************Agregamos la VOZ******************************************************
**********************************************************************************************************/

declare @mob1 as varchar(256) = '354720054741835'
declare @mob2 as varchar(256) = 'Ninguna'
declare @mob3 as varchar(256) = 'Ninguna'

declare @fecha_ini_text1 as varchar (256) = '2015-05-27 09:10:00.000'
declare @fecha_fin_text1 as varchar (256) = '2015-05-27 14:30:00.000'
declare @fecha_ini_text2 as varchar (256) = '2015-05-27 15:15:00.000'
declare @fecha_fin_text2 as varchar (256) = '2015-05-27 22:00:00.000'
declare @fecha_ini_text3 as varchar (256) = '2015-05-28 08:20:00.000'
declare @fecha_fin_text3 as varchar (256) = '2015-05-28 15:40:00.000'
declare @fecha_ini_text4 as varchar (256) = '2014-06-23 18:30:00:000'
declare @fecha_fin_text4 as varchar (256) = '2014-06-23 18:30:00:000'
declare @fecha_ini_text5 as varchar (256) = '2014-06-23 18:30:00:000'
declare @fecha_fin_text5 as varchar (256) = '2014-06-23 18:30:00:000'
declare @fecha_ini_text6 as varchar (256) = '2014-06-23 18:30:00:000'
declare @fecha_fin_text6 as varchar (256) = '2014-06-23 18:30:00:000'
declare @fecha_ini_text7 as varchar (256) = '2014-08-07 10:40:00:000'
declare @fecha_fin_text7 as varchar (256) = '2014-08-07 10:40:00:000'
declare @fecha_ini_text8 as varchar (256) = '2014-08-12 09:40:00:000'
declare @fecha_fin_text8 as varchar (256) = '2014-08-12 09:40:00:000'
declare @fecha_ini_text9 as varchar (256) = '2014-08-12 09:40:00:000'
declare @fecha_fin_text9 as varchar (256) = '2014-08-12 09:40:00:000'
declare @fecha_ini_text10 as varchar (256) = '2014-08-12 09:40:00:000'
declare @fecha_fin_text10 as varchar (256) = '2014-08-12 09:40:00:000'



begin
set @operator='1'

exec ('

exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Voice_Aggr_D16 '''+
@mob1+''','''+ @mob2+''','''+ @mob3+''','''+ @pattern+''','+ @operator+','''+ @fecha_ini_text1+''','''+ @fecha_fin_text1+''','''+ @fecha_ini_text2+''','''+ @fecha_fin_text2+''','''+ @fecha_ini_text3+''','''+ @fecha_fin_text3+''','''+ @fecha_ini_text4+''','''+ @fecha_fin_text4+''','''+ @fecha_ini_text5+''','''+ @fecha_fin_text5+''','''+ @fecha_ini_text6+''','''+ @fecha_fin_text6+''','''+ @fecha_ini_text7+''','''+ @fecha_fin_text7+''','''+ @fecha_ini_text8+''','''+ @fecha_fin_text8+''','''+ @fecha_ini_text9+''','''+ @fecha_fin_text9+''','''+ @fecha_ini_text10+''','''+ @fecha_fin_text10+''','''','+
 @Indoor+','''+ @pattern+''', ''N'','''+ @camposLlave+''','''+ @Methodology+''','''+ @Report+''','''+ @aggrType+'''')
end



-- Actualizacion de las fechas de reporte

begin

	exec(' 
		exec '+@BBDDorigen+'.dbo.sp_lcc_update_Dates_Reporting_Aggr_D16 '''+
    @pattern+''', '''', ''Voice'','''+ @Methodology+''','''+ @aggrType+''','''+ @Report+'''
			
	')


end


end --Fin de la VOZ





-- Cierre del bucle

set @id=@id+1
end


--Limpieza de tablas temporales

drop table #iterator
