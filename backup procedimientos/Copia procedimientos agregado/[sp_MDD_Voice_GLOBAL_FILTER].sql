USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Llamadas_FY1617_GRID]    Script Date: 11/07/2017 16:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MDD_Voice_GLOBAL_FILTER] (
	 --Variables de entrada
		@ciudad as varchar(256),
		@simOperator as int,
		@sheet as varchar(256),				-- all: %%, 4G: 'LTE', 3G: 'WCDMA'
		@Date as varchar (256),
		@Indoor as int,
		@Report as varchar (256),
		@ReportVOLTE as int

)
AS

-----------------------------
----- Testing Variables -----
-----------------------------

--use FY1718_VOICE_JEREZ_4G_H1

--declare @ciudad as varchar(256) = 'JEREZ'
--declare @simOperator as int = 3
--declare @sheet as varchar(256) ='%%'
--declare @Date as varchar(256) = ''
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)
--declare @reportVOLTE as int=0
-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests as table (sessionid bigint, is_VoLTE int, is_SRVCC int)
declare @filtroTech as varchar(1024)  
declare @operator as varchar(256)
declare @tablaContorno as varchar(256)  
declare @cruceContorno as varchar(1024) 
declare @filtroContorno as varchar(1024)  
declare @filtroVOLTE as varchar(1024)  


if @sheet = '%%'
	set @filtroTech = ''

else if @sheet = 'LTE' or @sheet = 'VOLTE'
	
	if @Indoor = 0 --M2M	
		set @filtroTech = 'and (
			((v.is_csfb=2 or (v.is_VOLTE in (1,2) and v.is_CSFB in (0,1)))) 
			 or (v.callstatus=''Failed'' and (((v.is_csfb in (0,1) and v.is_volte in (0,1)) and 
			 ((v.csfb_device=''A'' and v.technology_Bside=''LTE'') or (v.csfb_device=''B'' and v.technology=''LTE''))) 
			 or (v.is_csfb=0 and v.is_volte=0 and v.technology_Bside=''LTE'' and v.technology=''LTE'')))
		 )'	
	else
		set @filtroTech = 'and ((v.is_csfb>0 or v.is_VOLTE>0)
							or (v.callstatus=''Failed'' and (v.is_csfb=0 and v.is_VOLTE=0) and v.technology=''LTE''))'
		
else if @sheet = 'WCDMA'
	if @Indoor = 0 --M2M
		set @filtroTech = 'and (v.is_CSFB=0 and (v.technology <> ''LTE'' and v.technology_BSide <> ''LTE'') and v.is_VOLTE = 0)'
	else 
		set @filtroTech = 'and (v.is_CSFB=0 and (v.technology <> ''LTE'') and v.is_VOLTE = 0)'

set @operator = convert(varchar,@simOperator)

--Dependiendo del contorno pasado por parametro, cruzamos por una tabla u otra
If @Report='VDF'
begin
	set @tablaContorno = 'lcc_position_Entity_List_Vodafone'
end
If @Report='OSP'
begin
	set @tablaContorno = 'lcc_position_Entity_List_Orange'
end
If @Report='MUN'
begin
	set @tablaContorno = 'lcc_position_Entity_List_Municipio'
end

--Si Indoor=0 (M2M), exigimos que en el fin de la llamada los dos terminales este dentro del contorno de la ciudad
--Si Indoor=1 (M2F), exigimos que en el fin de la llamada el terminal este dentro del contorno de la ciudad

if @Indoor = 0
begin
	set @cruceContorno =', '+@tablaContorno+' c, '+@tablaContorno+' c2'
	set @filtroContorno = 'and c.fileid=v.fileid
and c.entity_name = '''+@ciudad+'''
and c2.entity_name = '''+@ciudad+'''
and c.fileid=c2.fileid
and (c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitude_Fin_A], [Latitude_Fin_A])
and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitude_Fin_A]))
and (c2.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitude_Fin_B], [Latitude_Fin_B])
and c2.latid=master.dbo.fn_lcc_latitude2latid ([Latitude_Fin_B]))'
end	
else
begin 
	set @cruceContorno =', '+@tablaContorno+' c'
	set @filtroContorno = 'and c.fileid=v.fileid
and c.entity_name = '''+@ciudad+'''
and (c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitude_Fin_A], [Latitude_Fin_A])
and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitude_Fin_A]))'
end

if @ReportVOLTE=1
begin
	set @filtroVOLTE = 'and v.collectionname like ''%volte%'''
end
else
begin 
	set @filtroVOLTE = 'and v.collectionname not like ''%volte%'''
end

insert into @All_Tests
exec ('select v.sessionid, v.is_VOLTE, v.is_SRVCC
from lcc_Calls_detailed v, sessions s'+@cruceContorno+'
Where s.sessionid=v.sessionid
	and s.valid=1
	and v.MNC = '+ @operator +'	--MNC
	and v.MCC= 214				--MCC - Descartamos los valores erróneos
	and callStatus in (''Completed'',''Failed'',''Dropped'')
	'+ @filtroContorno +
	@filtroTech + @filtroVOLTE+'
	group by v.sessionid, v.is_VOLTE, v.is_SRVCC')



if @sheet = 'VOLTE'
begin
	delete from @All_Tests where (is_VoLTE is NULL or is_VoLTE<>2 or (is_volte=2 and is_SRVCC>0))
end


select * from @All_Tests

