USE [DASHBOARD]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_cerrar_cobertura_FY1718]    Script Date: 11/12/2017 14:55:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_lcc_cerrar_cobertura_FY1718] (
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


	while @id<=(select max(id) from #iterator)
	begin


	declare @BBDDorigen as varchar (256)= (select BBDD from #iterator  where id=@id)	
	declare @ciudad as varchar(256) = (select Entidad from #iterator where id=@id)


	--Cerramos el contorno de la entidad una vez esté agregada
	if (@BBDDorigen not like '%Road%' or @BBDDorigen not like '%AVE%')
	begin
		exec(' 
		exec '+@BBDDorigen+'.dbo.plcc_Coverage_union_cerrar_Entidad '''+
		@ciudad+'''
		')
	end

	select 'Entidad cerrada:' +@ciudad

		
	set @id=@id+1 --Siguiente entidad

	end --Fin del while


--Limpieza de tablas temporales
drop table #iterator



