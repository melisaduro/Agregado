use [DASHBOARD]

--Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_entidades_borrar'

exec  [dbo].[sp_importExcelFileAsText] 'F:\VDF_Invalidate\aggr_borrado.xlsx', 'cities','_entidades_borrar'


-- Le creamos un identificador a cada ciudad para luego crear un bucle

select identity(int,1,1) id,*
into #iterator
from [dbo].[_entidades_borrar]


--Mostramos las ciudades que se agregaran

 select * from #iterator

declare @bbddAGGR as varchar (50)
DECLARE @nameTabla varchar(256)
declare @it1 bigint
declare @MaxTab bigint
declare @id int=1
declare @cmd nvarchar(4000)

declare @date_Ini as datetime = getdate()

 --Comenzamos el bucle con todas las ciudades a agregar
 while @id<=(select max(id) from #iterator)
 begin

BEGIN TRY
BEGIN TRANSACTION T1

    -- Cogemos la informacion de la entidad del Excel en red

	declare @nameEntidad as varchar (256) = (select Entidad from #iterator where id=@id)
    declare @BBDDorigen as varchar (256)= (select [Database] from #iterator  where id=@id)
	declare @Meas_date varchar(256)=(select Meas_Date from #iterator  where id=@id)
    declare @Report as varchar (256)= (select Report from #iterator where id=@id)
	declare @ReportType as varchar (256)= (select ReportType from #iterator where id=@id)
	
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


	exec sp_lcc_dropifexists '_tmp_Tablas'
	--declare @pattern as varchar (256) = 'ogrove'
	set @cmd = 'select IDENTITY(int,1,1) id,name
	into _tmp_Tablas
	from ['+@bbddAGGR +'].sys.tables
	where name like ''lcc_aggr_%''
		and type=''U'''
	print @cmd
	exec (@cmd)

	select @MaxTab = MAX(id) 
	from _tmp_Tablas

	set @it1 = 1

	while @it1 <= @MaxTab
	begin
		--Nombre tabla
		select @nameTabla = name
		from _tmp_Tablas
		where id =@it1
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

	-- Cierre del bucle

	
	IF @@TRANCOUNT > 0
	begin
		COMMIT TRANSACTION T1
	end

	END TRY
	BEGIN CATCH
		--Insertar ERROR EN LA TABLA DE CONTROL
		insert into [AddedValue].dbo.[lcc_executions_aggr]
		select 'ERROR BORRADO! - ' + @nameEntidad, NULL, @date_ini, getdate(),NULL,NULL, NULL,NULL,NULL,
		NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
	END CATCH


	set @id=@id+1
end


--Limpieza de tablas temporales

drop table #iterator