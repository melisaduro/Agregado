USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Voice_Llamadas_FY1617_GRID]    Script Date: 11/07/2017 16:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_MDD_Data_GLOBAL_FILTER] (
	 --Variables de entrada
		@ciudad as varchar(256),
		@simOperator as int,
		@sheet as varchar(256),				-- all: %%, 4G: 'LTE', 3G: 'WCDMA'
		@Date as varchar (256),
		@Tech as varchar (256),  -- Para seleccionar entre 3G, 4G y CA
		@Indoor as int,
		@Info as varchar (256),
		@Methodology as varchar (50),
		@Report as varchar (256),
		@table as varchar (256)

)
AS

-----------------------------
----- Testing Variables -----
-----------------------------

--use FY1718_DATA_REST_3G_H1_11

--declare @ciudad as varchar(256) = 'PUERTOLLANO'
--declare @simOperator as int = 1
--declare @sheet as varchar(256) = 'WCDMA' --%%/LTE/WCDMA
--declare @date as varchar(256) = ''
--declare @Tech as varchar (256) = '3G'
--declare @Indoor as bit = 0 -- O = False, 1 = True
--declare @Info as varchar (256) = 'Completed' --%% para procesados anteriores a 17/9/2015 y Completed para posteriores
--declare @methodology as varchar (256) = 'D16'
--declare @report as varchar(256) = 'VDF' --VDF (Reporte VDF), OSP (Reporte OSP), MUN (Municipal)
--declare @table as varchar(256) = 'Lcc_Data_HTTPTransfer_UL'

-------------------------------------------------------------------------------
-- GLOBAL FILTER:
-------------------------------------------------------------------------------	
declare @All_Tests_Tech as table (sessionid bigint, TestId bigint,tech varchar(5), hasCA varchar(2))
declare @All_Tests as table (sessionid bigint, TestId bigint)
declare @sheet1 as varchar(255)
declare @CA as varchar(255)

declare @operator as varchar(256) = convert(varchar,@simOperator)

If @Report='VDF'
begin
	insert into @All_Tests_Tech 
	exec('select v.sessionid, v.testid,
		case when v.[% LTE]=1 then ''LTE''
			 when v.[% WCDMA]=1 then ''WCDMA''
			else ''Mixed''
		end as tech,	
		''SC'' hasCA
	from '+@table+' v, testinfo t, lcc_position_Entity_List_Vodafone c
	where t.testid=v.testid
		and t.valid=1
		and v.info like '''+@Info+'''
		and v.MNC = '+@operator+'	--MNC
		and v.MCC= 214						--MCC - Descartamos los valores erróneos
		and c.fileid=v.fileid
		and c.entity_name = '''+@Ciudad+'''
		and c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitud Final], [Latitud Final])
		and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitud Final])
	group by v.sessionid, v.testid,
		case when v.[% LTE]=1 then ''LTE''
			 when v.[% WCDMA]=1 then ''WCDMA''
		else ''Mixed'' end,
		v.[Longitud Final], v.[Latitud Final]')
end

If @Report='OSP'
begin
	insert into @All_Tests_Tech 
	exec('select v.sessionid, v.testid,
		case when v.[% LTE]=1 then ''LTE''
			 when v.[% WCDMA]=1 then ''WCDMA''
			else ''Mixed''
		end as tech,	
		''SC'' hasCA
	from '+@table+' v, testinfo t, lcc_position_Entity_List_Orange c
	where t.testid=v.testid
		and t.valid=1
		and v.info like '''+@Info+'''
		and v.MNC = '+@operator+'	--MNC
		and v.MCC= 214						--MCC - Descartamos los valores erróneos
		and c.fileid=v.fileid
		and c.entity_name = '''+@Ciudad+'''
		and c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitud Final], [Latitud Final])
		and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitud Final])
	group by v.sessionid, v.testid,
		case when v.[% LTE]=1 then ''LTE''
			 when v.[% WCDMA]=1 then ''WCDMA''
		else ''Mixed'' end,
		v.[Longitud Final], v.[Latitud Final]')
end
If @Report='MUN'
begin
	insert into @All_Tests_Tech 
	exec('select v.sessionid, v.testid,
		case when v.[% LTE]=1 then ''LTE''
			 when v.[% WCDMA]=1 then ''WCDMA''
			else ''Mixed''
		end as tech,	
		''SC'' hasCA
	from '+@table+' v, testinfo t, lcc_position_Entity_List_Municipio c
	where t.testid=v.testid
		and t.valid=1
		and v.info like '''+@Info+'''
		and v.MNC = '+@operator+'	--MNC
		and v.MCC= 214						--MCC - Descartamos los valores erróneos
		and c.fileid=v.fileid
		and c.entity_name = '''+@Ciudad+'''
		and c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitud Final], [Latitud Final])
		and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitud Final])
	group by v.sessionid, v.testid,
		case when v.[% LTE]=1 then ''LTE''
			 when v.[% WCDMA]=1 then ''WCDMA''
		else ''Mixed'' end,
		v.[Longitud Final], v.[Latitud Final]')
end

If @sheet = 'CA' --Para la hoja de CA del procesado de CA (medidas con Note4 = CollectionName_CA)
begin
	set @sheet1 = 'LTE'
	set @CA='%CA%'
end
else 
begin
	set @sheet1 = @sheet
	set @CA='%%'
end

insert into @All_Tests
select sessionid, testid
from @All_Tests_Tech 
where tech like @sheet1 
	and hasCA like @CA


select * from @All_Tests
