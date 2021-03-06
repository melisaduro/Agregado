USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_update_Dates_Reporting_Entity_All_Aggr_D16_DDBB]    Script Date: 14/08/2017 10:08:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_lcc_update_Dates_Reporting_Entity_All_Aggr_D16_DDBB] (				
		@ciudad as varchar(256),
		@isData as varchar(1),
		@isVoice as varchar(1),
		@isCoverage as varchar(1),
		@bbddData as varchar(256),
		@bbddVoice as varchar(256),
		@bbddCoverage as varchar(256),
		@Report as varchar (256), --CAC 18_05_2017
		@ReportType as varchar(256) -- 20170713: @MDM - Nueva variable de entrada para distinguir entre reporte VOLTE y CSFB
)
AS

----------------------------- ---------------------------------------------------------------------
----------------------------------------Testing Variables-----------------------------------------
--------------------------------------------------------------------------------------------------
--declare @ciudad as varchar(256) = 'ADEJE'
--declare @isData as varchar(1)='Y'
--declare @isVoice as varchar(1)='Y'
--declare @isCoverage as varchar(1)='N'
--declare @bbddData as varchar(256)='FY1516_Data_Rest_4G_H2'
--declare @bbddVoice as varchar(256)='FY1516_Voice_Rest_4G_H2'
--declare @bbddCoverage as varchar(256)=''
--declare @Report as varchar (256)='VDF'
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
print @ciudad + '  ' +@isData + '  ' +@isVoice + '  ' +@isCoverage + '  ' +isnull(@bbddData,'') + '  ' +isnull(@bbddVoice,'') + '  ' +isnull(@bbddCoverage,'') + '  ' +isnull(@ReportType,'')

declare @aggrType as varchar(256)='GRID' --Son las mismas tablas que sin GRID
declare @Methodology as varchar(256)='D16' 
--Difiere en D15 en tablas: Cover y Nuevos_KPIS estan en D16 y no en D15, por otro lado, YTB (SD antiguo) esta en D15 (se inserta a posteriori en datos)

declare @nombTablaBBDD as varchar(256)
declare @provider as varchar(256) = 'SQLNCLI11'
declare @server as varchar(256) = '10.1.12.32'
declare @Uid as varchar(256) = 'sa'
declare @Pwd as varchar(256) = 'Sw1ssqual.2015'
declare @cmd nvarchar(4000)
declare @bbddDestData varchar(255)
declare @bbddDestVoice varchar(255)
declare @bbddDestCover varchar(255)
declare @ParmDefinition nvarchar(500)	
declare @Tabla varchar(255)
declare @IsLTE varchar(10) --Ejecutar todos los procedimientos incluidos los de LTE o no

declare @sheetData as varchar(256) --Crear sólo la info total o la info total/4G/totalCA
declare @sheetVoice as varchar(256) --Crear sólo la info total o la info total/4G
declare @sheetNomb as varchar(256)
declare @TechProc as varchar (256) 
DECLARE @nameProcAux varchar(256)

declare @type_info as varchar(256)
declare @typeInfo_KPI as varchar(5)
declare @type_Measurement as varchar(3)

declare @idColDateRep bigint
declare @idColWeekRep bigint
declare @TipoCol varchar(255)
declare @TamCol bigint
declare @maxMeas_Date_Entity varchar(10)
declare @maxMeas_Week_Entity varchar(10)
declare @maxMeas_Date varchar(10)
declare @maxMeas_Week varchar(10)

DECLARE @nameProc varchar(256)
declare @it1 bigint
declare @MaxTab bigint
declare @aggrTypeAux as varchar(256)

declare @column_tablaBBDD  as table (
	[table_name] [sysname] NOT NULL,
	[column_name] [sysname] NULL,
	[column_id] [int] NOT NULL
)

declare @date_Ini as datetime = getdate()

BEGIN TRY
BEGIN TRANSACTION

	SET @ParmDefinition = N'@TablaOut varchar(255) output' 
	set @maxMeas_Date_Entity = ''
	set @maxMeas_Week_Entity = ''

	--CAC 18_05_2017:
	--ANTES las roads "normales" (A1,...,A7) estaban en CoverageUnion y debiamos distinguir por el nombre de @ciudad
	--if CHARINDEX('A1',@ciudad) > 0 or CHARINDEX('A2',@ciudad) > 0 or CHARINDEX('A3',@ciudad) > 0 or CHARINDEX('A4',@ciudad) > 0
	--	or CHARINDEX('A5',@ciudad) > 0 or CHARINDEX('A6',@ciudad) > 0 or CHARINDEX('A7',@ciudad) > 0
	--AHORA: roads normales estan en CoverageUnion_ROAD (para que la lógica distinga por ronda)
	-- y las roads extra estan en CoverageUnion pero se procesan con @Report='ROAD'
	if  CHARINDEX('ROAD',db_name())> 0 or @Report='ROAD'
	begin
		set @bbddDestCover = '[AGGRCoverage_ROAD]'
	end
	else
	begin
		set @bbddDestCover = '[AGGRCoverage]'
	end

	if  CHARINDEX('3G',@bbddData)  > 0 
	begin 
		set @bbddDestData = '[AGGRData3G]'
		set @IsLTE = 'ALL' --Se ejecutaran los procedimientos de datos ALL
		set @sheetData = '(''ALL'',''WCDMA'')' --Se creará sólo la info total (de inicio valdra ALL para filtrar en los proc de step 1 pero luego pasara a valer %%)
	end
	else --Indoor es 4G
	begin 
		if  CHARINDEX('ROAD',@bbddData)  > 0 
		begin
			set @bbddDestData = '[AGGRData4G_ROAD]'
		end
		else
		begin
			set @bbddDestData = '[AGGRData4G]'
		end
		set @IsLTE = '%%' --Se ejecutaran todos los procedimientos de datos, ALL y LTE
		set @sheetData = '(''ALL'',''LTE'',''CA'',''WCDMA'')' --Se creará la info total/4G/totalCA
	end


	if  CHARINDEX('3G',@bbddVoice)  > 0 
	begin 
		set @bbddDestVoice = '[AGGRVoice3G]'
		set @sheetVoice = '(''ALL'',''WCDMA'')'  --Se creará sólo la info total (de inicio valdra ALL para filtrar en los proc de step 1 pero luego pasara a valer %%)
		set @type_info = '(''Voice'')'
	end

	else --Indoor es 4G
	begin  
		if @ReportType='VOLTE'
			if  CHARINDEX('ROAD',db_name())  > 0 ---Entidad ROAD con VOLTE
				begin
					set @bbddDestVoice = '[AGGRVOLTE_ROAD]'
					set @sheetVoice= '(''VOLTE'',''ALL'',''LTE'',''WCDMA'')' 
					set @type_info = '(''Voice'', ''VOLTE'')'
				end
			else  ---Entidad con VOLTE
				begin
					set @bbddDestVoice='[AGGRVOLTE]'
					set @sheetVoice= '(''VOLTE'',''ALL'',''LTE'',''WCDMA'')' 
					set @type_info = '(''Voice'', ''VOLTE'')'
				end
		else
		if  CHARINDEX('ROAD',db_name())  > 0 ---Entidad ROAD sin VOLTE
			begin
					set @bbddDestVoice = '[AGGRVoice4G_ROAD]'
					set @sheetVoice= '(''ALL'',''LTE'',''WCDMA'')'  --Se creará la info total/only 4G
					set @type_info = '(''Voice'')'
			end
		else  ---Entidad sin VOLTE
			begin
					set @bbddDestVoice='[AGGRVoice4G]'
					set @sheetVoice= '(''ALL'',''LTE'',''WCDMA'')' 
					set @type_info = '(''Voice'')'
			end
	end

	set @TechProc = 'ALL' --Antes habia CA, ahora NO

	if @aggrType = 'GRID'
	begin
		set @aggrTypeAux = '_GRID'
	end
	else
	begin
		set @aggrTypeAux = ''
	end

	print '(1) CALCULAMOS FECHAS'
	--------------------------------------------------------------------------------------------------------------------------------------------
	------------------------------------Calculamos la fecha de reporting------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------

	if @isData = 'Y'
	begin
	----------------------------------------------DATA------------------------------------------------

		--Recorremos los procedimientos de paso 1 existentes y actualizamos la info de Date_Reporting/Week_Reporting.
		--En el caso que no existan las columnas las creamos.
	
		print '------------------DATA------------------'	
		DECLARE @nameTablaData varchar(256)

	
		set @it1 = 1

		declare @tmp_procedures_step1_Data  as table (
			[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
			[Name_proc] [varchar](128) not NULL,
			[Type_Info_KPI] [varchar](5) NULL,
			[Type_Measurement] [varchar](3) not NULL,
			[Methodology] [varchar] (50) NULL
		)

		set @cmd = 'select Name_proc,Type_Info_KPI,Type_Measurement
		from [AGRIDS].[dbo].[lcc_procedures_step1'+@aggrTypeAux+'] --Tabla en la que se registran los procedimientos de paso 1
		where type_Info=''Data''
			and Is_LTE like '''+@IsLTE+'''
			and Type_Info_KPI in '+@sheetData+'
			and Type_Measurement like '''+@TechProc+'''
			and (Methodology = ''ALL'' or Methodology ='''+@Methodology+''')'
		--print(@cmd)
		insert into @tmp_procedures_step1_Data (Name_proc,Type_Info_KPI,Type_Measurement)
		exec (@cmd)

		if  CHARINDEX('3G',@bbddData)  > 0 
		begin 
			insert into @tmp_procedures_step1_Data (Name_proc,Type_Info_KPI,Type_Measurement)
			select 'sp_MDD_Data_Youtube_GRID','WCDMA','ALL'
			union
			select 'sp_MDD_Data_Youtube_GRID','ALL','ALL'
		end
		else
		begin 
			if  CHARINDEX('ROAD',@bbddData)  > 0 
			begin
				insert into @tmp_procedures_step1_Data (Name_proc,Type_Info_KPI,Type_Measurement)
				select 'sp_MDD_Data_Youtube_GRID','ALL','ALL'
				union
				select 'sp_MDD_Data_Youtube_GRID','LTE','ALL'
			end 
			else
			begin
				insert into @tmp_procedures_step1_Data (Name_proc,Type_Info_KPI,Type_Measurement)
				select 'sp_MDD_Data_Youtube_GRID','CA','ALL'
				union
				select 'sp_MDD_Data_Youtube_GRID','WCDMA','ALL'
				union
				select 'sp_MDD_Data_Youtube_GRID','ALL','ALL'
				union
				select 'sp_MDD_Data_Youtube_GRID','LTE','ALL'
			end
		end
		--select * from @tmp_procedures_step1

		if CHARINDEX('3G',@bbddData)  > 0 --En 3G 
			set @sheetData = '%%'

		select @MaxTab = MAX(id) 
		from @tmp_procedures_step1_Data

		--print 'Nº tablas: '+convert(varchar,@MaxTab)
		while @it1 <= @MaxTab 
		begin
			set @maxMeas_Date = ''
			set @maxMeas_Week = ''
			set @idColDateRep = 0
			set @idColWeekRep = 0

			--Nombre procedimiento
			select @nameProc = Name_proc
			from @tmp_procedures_step1_Data
			where id =@it1
			print 'Nombre del procedimiento:  ' + @nameProc
			--Tipo info KPI
			select @typeInfo_KPI = Type_Info_KPI
			from @tmp_procedures_step1_Data
			where id =@it1
			print 'Tipo info KPI:  ' + @typeInfo_KPI
			--Tipo medida
			select @type_Measurement = Type_Measurement
			from @tmp_procedures_step1_Data
			where id =@it1
			print 'Tipo medida:  ' + @type_Measurement

			set @sheetNomb = @typeInfo_KPI --Posibles valores actuales ALL, LTE, WCDMA, CA
			if @typeInfo_KPI = 'LTE'
			begin
				set @sheetNomb = '4G'
			end
			if @typeInfo_KPI = 'WCDMA'
			begin
				set @sheetNomb = '3G'
			end
			if @typeInfo_KPI = 'CA'
			begin
				set @sheetNomb = 'CA_ONLY'
			end

			--Para procs por GRID
			if @aggrType = 'GRID' and CHARINDEX('_GRID',@nameProc)>0
			begin
				set @nameProcAux = SUBSTRING(@nameProc,0,CHARINDEX('_GRID',@nameProc))
			end
			else
			begin
				set @nameProcAux = @nameProc
			end
			--print @nameProcAux
			---Para procs de 1617
			if CHARINDEX('FY1617',@nameProc) > 0
			begin		
				set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1617',@nameProcAux))
			end
			--print @nameProcAux
		

			--Nombre de la tabla dependera del tipo de la medida
			set @nameTablaData = @nameProcAux		

			if @typeInfo_KPI  <> 'ALL' --Si no es la info total, el nombre de la tabla llevará esta información
			begin
				set @nameTablaData = @nameTablaData + '_' + @sheetNomb
			end
		
			if @typeInfo_KPI = 'ALL' --Si es la info total, el filtro es '%%'
			begin 
				set @typeInfo_KPI ='%%'
			end

			set @nombTablaBBDD = 'lcc_aggr_'+ @nameTablaData 
			print 'Nombre tabla: '+@nameTablaData
			
			SET @ParmDefinition = N'@TipoColOrigOut varchar(255) output' 
						
			set @cmd = 'select @maxMeas_DateOut = max([Meas_Date]),
				@maxMeas_WeekOut=max([Meas_Week])
			FROM ' + @bbddDestData +'.dbo.'+ @nombTablaBBDD  +'
			where [Database] ='''+ @bbddData+'''
				and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			--print @cmd
			exec sp_executesql @cmd, N'@maxMeas_DateOut varchar(10) output,@maxMeas_WeekOut varchar(10) output',@maxMeas_DateOut = @maxMeas_Date output,@maxMeas_WeekOut = @maxMeas_Week output

			print 'Fecha medida, mes:'+@maxMeas_Date+', año:'+@maxMeas_Week

			if @maxMeas_Date <> '' or @maxMeas_Week <> ''
			begin
				--Si mes es mayor, cambiamos todo (Ejemplo: 16_12 W53 y 17_01 W01, la semana es menor pero es nuevo año)
				if @maxMeas_Date>@maxMeas_Date_Entity
				begin				
					set @maxMeas_Date_Entity = @maxMeas_Date
					set @maxMeas_Week_Entity = @maxMeas_Week				
				end
				--Si mes es igual, miramos si la semana es mayor para modificarla
				if @maxMeas_Date=@maxMeas_Date_Entity
				begin
					if @maxMeas_Week>@maxMeas_Week_Entity
					begin
						set @maxMeas_Week_Entity = @maxMeas_Week
					end
				end
			end	
			set @it1 = @it1 +1
		END
	end
	if @isVoice = 'Y'
	begin
	----------------------------------------------VOICE-----------------------------------------------
		print '------------------VOICE------------------'
		--Recorremos los procedimientos de paso 1 existentes y actualizamos la info de Date_Reporting/Week_Reporting.
		--En el caso que no existan las columnas las creamos.

		DECLARE @nameTablaVoice varchar(256)

		set @it1 = 1

		declare @tmp_procedures_step1_Voice  as table (
			[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
			[Name_proc] [varchar](128) not NULL,
			[Type_Info_KPI] [varchar](5) NULL
		)
	
		set @cmd = 'select Name_proc,Type_Info_KPI
		from [AGRIDS].[dbo].[lcc_procedures_step1'+@aggrTypeAux+'] --Tabla en la que se registran los procedimientos de paso 1
		where type_Info in '+@type_info+'
			and Type_Info_KPI in '+@sheetVoice+'
			and (Methodology = ''ALL'' or Methodology ='''+@Methodology+''')'
		--print(@cmd)
		insert into @tmp_procedures_step1_Voice (Name_proc,Type_Info_KPI)
		exec (@cmd)

		--select * from @tmp_procedures_step1

		if CHARINDEX('3G',@bbddVoice)  > 0 --En 3G 
			set @sheetVoice = '%%'

		select @MaxTab = MAX(id) 
		from @tmp_procedures_step1_Voice

		while @it1 <= @MaxTab
		begin
			set @maxMeas_Date = ''
			set @maxMeas_Week = ''
			set @idColDateRep = 0
			set @idColWeekRep = 0

			--Nombre procedimiento
			select @nameProc = Name_proc
			from @tmp_procedures_step1_Voice
			where id =@it1
			print 'Nombre del procedimiento:  ' + @nameProc
			--Tipo info KPI
			select @typeInfo_KPI = Type_Info_KPI
			from @tmp_procedures_step1_Voice
			where id =@it1
			print 'Tipo info KPI:  ' + @typeInfo_KPI

			set @sheetNomb = @typeInfo_KPI --Psoibles valores actuales ALL, LTE
			if @typeInfo_KPI = 'LTE'
			begin
				set @sheetNomb = '4G'
			end
			if @typeInfo_KPI = 'WCDMA'
			begin
				set @sheetNomb = '3G'
			end

			--Para procs por GRID
			if @aggrType = 'GRID' and CHARINDEX('_GRID',@nameProc)>0
			begin
				set @nameProcAux = SUBSTRING(@nameProc,0,CHARINDEX('_GRID',@nameProc))
			end
			else
			begin
				set @nameProcAux = @nameProc
			end
			--print @nameProcAux
			---Para procs de 1617
			if CHARINDEX('FY1617',@nameProc) > 0
			begin		
				set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1617',@nameProcAux))
			end
			print @nameProcAux	
		

			--Nombre de la tabla dependera del tipo de la medida
			set @nameTablaVoice = @nameProcAux
			if @typeInfo_KPI  <> 'ALL' --Si no es la info total, el nombre de la tabla llevará esta información
			begin
				set @nameTablaVoice = @nameTablaVoice + '_' + @sheetNomb
			end
			if @typeInfo_KPI = 'ALL' --Si es la info total, el filtro es '%%'
			begin 
				set @typeInfo_KPI ='%%'
			end


			set @nombTablaBBDD = 'lcc_aggr_'+ @nameTablaVoice
	
			SET @ParmDefinition = N'@TipoColOrigOut varchar(255) output' 
						
			set @cmd = 'select @maxMeas_DateOut = max([Meas_Date]),
				@maxMeas_WeekOut=max([Meas_Week])
			FROM ' + @bbddDestVoice +'.dbo.'+ @nombTablaBBDD  +'
			where [Database] ='''+ @bbddVoice+'''
				and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			--print @cmd
			exec sp_executesql @cmd, N'@maxMeas_DateOut varchar(10) output,@maxMeas_WeekOut varchar(10) output',@maxMeas_DateOut = @maxMeas_Date output,@maxMeas_WeekOut = @maxMeas_Week output

			print 'Fecha medida, mes:'+@maxMeas_Date+', año:'+@maxMeas_Week

			if @maxMeas_Date <> '' or @maxMeas_Week <> ''
			begin
				--Si mes es mayor, cambiamos todo (Ejemplo: 16_12 W53 y 17_01 W01, la semana es menor pero es nuevo año)
				if @maxMeas_Date>@maxMeas_Date_Entity
				begin				
					set @maxMeas_Date_Entity = @maxMeas_Date
					set @maxMeas_Week_Entity = @maxMeas_Week				
				end
				--Si mes es igual, miramos si la semana es mayor para modificarla
				if @maxMeas_Date=@maxMeas_Date_Entity
				begin
					if @maxMeas_Week>@maxMeas_Week_Entity
					begin
						set @maxMeas_Week_Entity = @maxMeas_Week
					end
				end
			end	
			set @it1 = @it1 +1
		END
	end
	if @isCoverage = 'Y'
	begin	
	---------------------------------------------COVERAGE---------------------------------------------
		print '------------------COVERAGE------------------'
		--Recorremos los procedimientos de paso 1 existentes y actualizamos la info de Date_Reporting/Week_Reporting.
	
		set @it1 = 1

		declare @tmp_procedures_step1_Coverage  as table (
			[id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
			[Name_proc] [varchar](128) not NULL
		)
	
		set @cmd = 'select Name_proc
		from [AGRIDS].[dbo].[lcc_procedures_step1'+@aggrTypeAux+'] --Tabla en la que se registran los procedimientos de paso 1
		where type_Info=''Coverage''
		and (Methodology = ''ALL'' or Methodology ='''+@Methodology+''')'
		--print(@cmd)
		insert into @tmp_procedures_step1_Coverage (Name_proc)
		exec (@cmd)

		--select * from @tmp_procedures_step1

		select @MaxTab = MAX(id) 
		from @tmp_procedures_step1_Coverage

		while @it1 <= @MaxTab 
		begin
			set @maxMeas_Date = ''
			set @maxMeas_Week = ''
			set @idColDateRep = 0
			set @idColWeekRep = 0

			--Nombre procedimiento
			select @nameProc = Name_proc
			from @tmp_procedures_step1_Coverage
			where id =@it1
			print 'Nombre del procedimiento:  ' + @nameProc	

			----CAC 18_05_2017: excepcion, agregado de sp_MDD_Coverage_All_Outdoor SI y SÓLO para AVEs
			--if ((@nameProc = 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())> 0)
			--	or (@nameProc <> 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())= 0))
			--CAC 30/05/2017: agregado de sp_MDD_Coverage_All_Outdoor SI y SÓLO para AVEs
			--				agregado Roads SÓLO sp_MDD_Coverage_All_Indoor
			if ((@nameProc = 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())> 0)			
				or (@nameProc = 'sp_MDD_Coverage_All_Indoor' and CHARINDEX('AVE',db_name())= 0 and (CHARINDEX('ROAD',db_name())> 0 or @Report='ROAD'))
				or (@nameProc <> 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())= 0) and CHARINDEX('ROAD',db_name())= 0 and @Report<>'ROAD')
			begin
				--Para procs por GRID
				if @aggrType = 'GRID' and CHARINDEX('_GRID',@nameProc)>0
				begin
					set @nameProcAux = SUBSTRING(@nameProc,0,CHARINDEX('_GRID',@nameProc))
				end
				else
				begin
					set @nameProcAux = @nameProc
				end
				--print @nameProcAux
				---Para procs de 1617
				if CHARINDEX('FY1617',@nameProc) > 0
				begin		
					set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1617',@nameProcAux))
				end
				print @nameProcAux		

				set @nombTablaBBDD = 'lcc_aggr_'+ @nameProcAux 
	
				SET @ParmDefinition = N'@TipoColOrigOut varchar(255) output' 
						
				set @cmd = 'select @maxMeas_DateOut = max([Meas_Date]),
					@maxMeas_WeekOut=max([Meas_Week])
				FROM ' + @bbddDestCover +'.dbo.'+ @nombTablaBBDD  +'
				where [Database] ='''+ @bbddCoverage+'''
					and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
				--print @cmd
				exec sp_executesql @cmd, N'@maxMeas_DateOut varchar(10) output,@maxMeas_WeekOut varchar(10) output',@maxMeas_DateOut = @maxMeas_Date output,@maxMeas_WeekOut = @maxMeas_Week output

				print 'Fecha medida, mes:'+@maxMeas_Date+', año:'+@maxMeas_Week

				if @maxMeas_Date <> '' or @maxMeas_Week <> ''
				begin
					--Si mes es mayor, cambiamos todo (Ejemplo: 16_12 W53 y 17_01 W01, la semana es menor pero es nuevo año)
					if @maxMeas_Date>@maxMeas_Date_Entity
					begin				
						set @maxMeas_Date_Entity = @maxMeas_Date
						set @maxMeas_Week_Entity = @maxMeas_Week				
					end
					--Si mes es igual, miramos si la semana es mayor para modificarla
					if @maxMeas_Date=@maxMeas_Date_Entity
					begin
						if @maxMeas_Week>@maxMeas_Week_Entity
						begin
							set @maxMeas_Week_Entity = @maxMeas_Week
						end
					end
				end	
			end
			set @it1 = @it1 +1
		END
	end

	print '(2) MODIFICAMOS FECHAS'
	--------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------Modificamos la fecha de reporting------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------
	if @isData = 'Y'
	begin
		----------------------------------------------DATA------------------------------------------------
		print '------------------DATA------------------'
		--Recorremos los procedimientos de paso 1 existentes y actualizamos la info de Date_Reporting/Week_Reporting.
	
		set @it1 = 1
	
		if CHARINDEX('3G',@bbddData)  > 0 --En 3G 
			set @sheetData = '%%'
	
		select @MaxTab = MAX(id) 
		from @tmp_procedures_step1_Data

		while @it1 <= @MaxTab 
		begin
			set @maxMeas_Date = ''
			set @maxMeas_Week = ''
			set @idColDateRep = 0
			set @idColWeekRep = 0

			--Nombre procedimiento
			select @nameProc = Name_proc
			from @tmp_procedures_step1_Data
			where id =@it1
			print 'Nombre del procedimiento:  ' + @nameProc
			--Tipo info KPI
			select @typeInfo_KPI = Type_Info_KPI
			from @tmp_procedures_step1_Data
			where id =@it1
			print 'Tipo info KPI:  ' + @typeInfo_KPI
			--Tipo medida
			select @type_Measurement = Type_Measurement
			from @tmp_procedures_step1_Data
			where id =@it1
			print 'Tipo medida:  ' + @type_Measurement

			set @sheetNomb = @typeInfo_KPI --Posibles valores actuales ALL, LTE, WCDMA, CA
			if @typeInfo_KPI = 'LTE'
			begin
				set @sheetNomb = '4G'
			end
			if @typeInfo_KPI = 'WCDMA'
			begin
				set @sheetNomb = '3G'
			end
			if @typeInfo_KPI = 'CA'
			begin
				set @sheetNomb = 'CA_ONLY'
			end

			--Para procs por GRID
			if @aggrType = 'GRID' and CHARINDEX('_GRID',@nameProc)>0
			begin
				set @nameProcAux = SUBSTRING(@nameProc,0,CHARINDEX('_GRID',@nameProc))
			end
			else
			begin
				set @nameProcAux = @nameProc
			end
			--print @nameProcAux
			---Para procs de 1617
			if CHARINDEX('FY1617',@nameProc) > 0
			begin		
				set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1617',@nameProcAux))
			end
			--print @nameProcAux
		

			--Nombre de la tabla dependera del tipo de la medida
			set @nameTablaData = @nameProcAux
		
			if @typeInfo_KPI  <> 'ALL' --Si no es la info total, el nombre de la tabla llevará esta información
			begin
				set @nameTablaData = @nameTablaData + '_' + @sheetNomb
			end
		
			if @typeInfo_KPI = 'ALL' --Si es la info total, el filtro es '%%'
			begin 
				set @typeInfo_KPI ='%%'
			end

			set @nombTablaBBDD = 'lcc_aggr_'+ @nameTablaData 
				
			set @cmd = 'update ' + @bbddDestData +'.dbo.'+ @nombTablaBBDD  +'
			set Date_reporting = '''+@maxMeas_Date_Entity+'''
			where [Database] ='''+ @bbddData+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			print @cmd
			exec (@cmd)

			set @cmd ='update ' + @bbddDestData +'.dbo.'+ @nombTablaBBDD  +'
			set Week_reporting = '''+@maxMeas_Week_Entity+'''
			where [Database] ='''+ @bbddData+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			print @cmd
			exec (@cmd)
	
			set @it1 = @it1 +1
		END
	end
	if @isVoice = 'Y'
	begin
		----------------------------------------------VOICE-----------------------------------------------
		print '------------------VOICE------------------'
		--Recorremos los procedimientos de paso 1 existentes y actualizamos la info de Date_Reporting/Week_Reporting.
	
		set @it1 = 1
		
		if CHARINDEX('3G',@bbddVoice)  > 0 --En 3G 
			set @sheetVoice = '%%'

		select @MaxTab = MAX(id) 
		from @tmp_procedures_step1_Voice

		while @it1 <= @MaxTab
		begin
			set @maxMeas_Date = ''
			set @maxMeas_Week = ''
			set @idColDateRep = 0
			set @idColWeekRep = 0

			--Nombre procedimiento
			select @nameProc = Name_proc
			from @tmp_procedures_step1_Voice
			where id =@it1
			print 'Nombre del procedimiento:  ' + @nameProc
			--Tipo info KPI
			select @typeInfo_KPI = Type_Info_KPI
			from @tmp_procedures_step1_Voice
			where id =@it1
			print 'Tipo info KPI:  ' + @typeInfo_KPI

			set @sheetNomb = @typeInfo_KPI --Psoibles valores actuales ALL, LTE
			if @typeInfo_KPI = 'LTE'
			begin
				set @sheetNomb = '4G'
			end
			if @typeInfo_KPI = 'WCDMA'
			begin
				set @sheetNomb = '3G'
			end

			--Para procs por GRID
			if @aggrType = 'GRID' and CHARINDEX('_GRID',@nameProc)>0
			begin
				set @nameProcAux = SUBSTRING(@nameProc,0,CHARINDEX('_GRID',@nameProc))
			end
			else
			begin
				set @nameProcAux = @nameProc
			end
			--print @nameProcAux
			---Para procs de 1617
			if CHARINDEX('FY1617',@nameProc) > 0
			begin		
				set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1617',@nameProcAux))
			end
			--print @nameProcAux	
		

			--Nombre de la tabla dependera del tipo de la medida
			set @nameTablaVoice = @nameProcAux
			if @typeInfo_KPI  <> 'ALL' --Si no es la info total, el nombre de la tabla llevará esta información
			begin
				set @nameTablaVoice = @nameTablaVoice + '_' + @sheetNomb
			end
			if @typeInfo_KPI = 'ALL' --Si es la info total, el filtro es '%%'
			begin 
				set @typeInfo_KPI ='%%'
			end


			set @nombTablaBBDD = 'lcc_aggr_'+ @nameTablaVoice
		
			set @cmd = 'update ' + @bbddDestVoice +'.dbo.'+ @nombTablaBBDD  +'
			set Date_reporting = '''+@maxMeas_Date_Entity+'''
			where [Database] ='''+ @bbddVoice+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			print @cmd
			exec (@cmd)

			set @cmd ='update ' + @bbddDestVoice +'.dbo.'+ @nombTablaBBDD  +'
			set Week_reporting = '''+@maxMeas_Week_Entity+'''
			where [Database] ='''+ @bbddVoice+'''
			and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
			print @cmd
			exec (@cmd)
	
			set @it1 = @it1 +1
		END
	end
	if @isCoverage = 'Y'
	begin
	---------------------------------------------COVERAGE---------------------------------------------
		print '------------------COVERAGE------------------'
		--Recorremos los procedimientos de paso 1 existentes y actualizamos la info de Date_Reporting/Week_Reporting.
	
		set @it1 = 1

		select @MaxTab = MAX(id) 
		from @tmp_procedures_step1_Coverage

		while @it1 <= @MaxTab 
		begin
			set @maxMeas_Date = ''
			set @maxMeas_Week = ''
			set @idColDateRep = 0
			set @idColWeekRep = 0

			--Nombre procedimiento
			select @nameProc = Name_proc
			from @tmp_procedures_step1_Coverage
			where id =@it1
			print 'Nombre del procedimiento:  ' + @nameProc	

			----CAC 18_05_2017: excepcion, agregado de sp_MDD_Coverage_All_Outdoor SI y SÓLO para AVEs
			--if ((@nameProc = 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())> 0)
			--	or (@nameProc <> 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())= 0))
			--CAC 30/05/2017: agregado de sp_MDD_Coverage_All_Outdoor SI y SÓLO para AVEs
			--				agregado Roads SÓLO sp_MDD_Coverage_All_Indoor
			if ((@nameProc = 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())> 0)			
				or (@nameProc = 'sp_MDD_Coverage_All_Indoor' and CHARINDEX('AVE',db_name())= 0 and (CHARINDEX('ROAD',db_name())> 0 or @Report='ROAD'))
				or (@nameProc <> 'sp_MDD_Coverage_All_Outdoor' and CHARINDEX('AVE',db_name())= 0) and CHARINDEX('ROAD',db_name())= 0 and @Report<>'ROAD')
			begin
				--Para procs por GRID
				if @aggrType = 'GRID' and CHARINDEX('_GRID',@nameProc)>0
				begin
					set @nameProcAux = SUBSTRING(@nameProc,0,CHARINDEX('_GRID',@nameProc))
				end
				else
				begin
					set @nameProcAux = @nameProc
				end
				--print @nameProcAux
				---Para procs de 1617
				if CHARINDEX('FY1617',@nameProc) > 0
				begin		
					set @nameProcAux = SUBSTRING(@nameProcAux,0,CHARINDEX('_FY1617',@nameProcAux))
				end
				--print @nameProcAux
	
		

				set @nombTablaBBDD = 'lcc_aggr_'+ @nameProcAux 
				
				set @cmd = 'update ' + @bbddDestCover +'.dbo.'+ @nombTablaBBDD  +'
				set Date_reporting = '''+@maxMeas_Date_Entity+'''
				where [Database] ='''+ @bbddCoverage+'''
				and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
				print @cmd
				exec (@cmd)

				set @cmd ='update ' + @bbddDestCover +'.dbo.'+ @nombTablaBBDD  +'
				set Week_reporting = '''+@maxMeas_Week_Entity+'''
				where [Database] ='''+ @bbddCoverage+'''
				and [Entidad] = '''+substring(@ciudad,charindex('_',@ciudad)+1,len(@ciudad)-charindex('_',@ciudad))+''''
				print @cmd
				exec (@cmd)
			end
			set @it1 = @it1 +1
		END
	end

	select ''

	COMMIT TRANSACTION
	
	insert into [AddedValue].dbo.[lcc_executions_aggr]
	select 'DATES-' + @ciudad , 'sp_lcc_update_Dates_Reporting_Entity_All_Aggr_D16_DDBB', 
	@date_ini, getdate(),db_name(),@ciudad,NULL,NULL, NULL,
	NULL,NULL,NULL,@report,NULL,@ReportType,NULL,NULL,NULL

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH
