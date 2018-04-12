declare @tech as varchar (256)='4G'
declare @entidad as varchar (256)='AVE-Motilla-Albacete-R5'
declare @date_reporting as varchar (256)='17_04'
declare @report_type as varchar (256)='VDF'
declare @bbdd as varchar (256)
declare @sheet as varchar (256)=''

if @tech='4G'
	begin
	set @bbdd='AGGRData4G'
	end

if @tech='3G'
	begin
	set @bbdd='AGGRData3G'
	end

	
if @tech='4G_Road'
	begin
	set @bbdd='AGGRData4G_Road'
	end

exec('
select 
	dl_ce.entidad,
	case 
		when dl_ce.mnc=''01'' then ''VODAFONE''
		when dl_ce.mnc=''07'' then ''MOVISTAR''
		when dl_ce.mnc=''03'' then ''ORANGE''
		when dl_ce.mnc=''04'' then ''YOIGO''
	end as Operator,



	sum(dl_ce.[Navegaciones]) as DL_CE_ATTEMPTS,
	sum(dl_ce.[Fallos de Acceso]) as DL_CE_ERRORS_ACCESSIBILITY,
	sum(dl_ce.[Fallos de descarga]) as DL_CE_ERRORS_RETAINABILITY,
	case when sum(dl_ce.[Count_Throughput])>0 then sum(dl_ce.[Throughput]*dl_ce.[Count_Throughput])/sum(dl_ce.[Count_Throughput]) 
		else 0 end as DL_CE_D1,
	'''',
	case when sum(dl_ce.[Count_Throughput])>0 then 1.0*sum(dl_ce.[Count_Throughput_3M])/(sum(dl_ce.[Count_Throughput]))
		else 0 end as DL_CE_D2,
	sum(dl_ce.[Count_Throughput_3M]) as DL_CE_CONNECTIONS_TH_3MBPS,
	sum(dl_ce.[Count_Throughput_1M]) as DL_CE_CONNECTIONS_TH_1MBPS,
	max(dl_ce.[Throughput Max]) as DL_CE_PEAK,
	'''',
	'''',
	'''',
	'''',
	'''',
	'''',


	ul_Ce.UL_CE_ATTEMPTS,
	ul_Ce.UL_CE_ERRORS_ACCESSIBILITY,
	ul_Ce.UL_CE_ERRORS_RETAINABILITY,
	ul_ce.UL_CE_D3,
	'''',
	ul_ce.UL_CE_PEAK,
	'''',
	'''',
	'''',
	'''',
	'''',
	'''',


	dl_nc.DL_NC_ATTEMPTS,
	dl_nc.DL_NC_ERRORS_ACCESSIBILITY,
	dl_nc.DL_NC_ERRORS_RETAINABILITY,
	dl_nc.DL_NC_CONNECTIONS_TH_128KBPS,
	dl_nc.DL_NC_MEAN,
	'''',
	dl_nc.DL_NC_PEAK,
	'''',
	'''',
	'''',
	'''',
	'''',
	'''',


	ul_nc.UL_NC_ATTEMPTS,
	ul_nc.UL_NC_ERRORS_ACCESSIBILITY,
	ul_nc.UL_NC_ERRORS_RETAINABILITY,
	ul_nc.UL_NC_CONNECTIONS_TH_64KBPS,
	ul_nc.UL_NC_MEAN,
	'''',
	ul_nc.UL_NC_PEAK,
	'''',
	'''',
	'''',
	'''',
	'''',
	'''',



	ping.LAT_PINGS,
	'''' as LAT_MEDIAN,
	cast(ping.LAT_AVG as int) as LAT_AVG,
	'''',
	'''',


	web.WEB_ATTEMPS,
	web.WEB_ERRORS_ACCESSIBILITY,
	web.WEB_ERRORS_RETAINABILITY,
	web.WEB_D5,
	web.WEB_IP_ACCESS_TIME,
	web.WEB_HTTP_TRANSFER_TIME,
	web.WEB_ATTEMPS_HTTPS,
	web.WEB_ERRORS_ACCESSIBILITY_HTTPS,
	web.WEB_ERRORS_RETAINABILITY_HTTPS,
	web.WEB_D5_HTTPS,
	web.WEB_IP_ACCESS_TIME_HTTPS,
	web.WEB_HTTP_TRANSFER_TIME_HTTPS,


	ytb.[avg video resolution],
	ytb.[B4 hd share],
	ytb.[video mos],
	ytb.YTB_HD_ATTEMPS,
	ytb. YTB_HD_AVG_START_TIME,
	ytb.YTB_HD_FAILS,
	ytb.YTB_HD_B1,
	ytb.YTB_HD_REPR_NO_INTERRUPTIONS,
	ytb.YTB_HD_REPR_NO_COMPRESSION,
	ytb.YTB_HD_B2,
	ytb.YTB_HD_SUCC_DL,





	dl_Ce.date_reporting,
	dl_ce.meas_week,
	dl_ce.date_reporting,
	dl_ce.week_reporting

from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Data_DL_Thput_CE'+@sheet+ ' dl_ce 

	left outer join (

		select 
			entidad,
			sum([Subidas]) as UL_CE_ATTEMPTS,
			sum([Fallos de Acceso]) as UL_CE_ERRORS_ACCESSIBILITY,
			sum([Fallos de descarga]) as UL_CE_ERRORS_RETAINABILITY,
			case when sum([Count_Throughput])>0 then sum([Throughput]*[Count_Throughput])/sum([Count_Throughput])
				else 0 end as UL_CE_D3,
			max([Throughput Max]) as UL_CE_PEAK,
			mnc,
			date_reporting		



		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Data_UL_Thput_CE'+@sheet+ '
		where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+''' 
		group by Entidad,mnc,date_reporting		


	)ul_Ce on (dl_ce.entidad=ul_Ce.Entidad and dl_Ce.mnc=ul_Ce.mnc and dl_ce.date_reporting=ul_ce.date_reporting)


	left outer join (

		select 
			entidad,
			sum([Navegaciones]) as DL_NC_ATTEMPTS,
			sum([Fallos de Acceso]) as DL_NC_ERRORS_ACCESSIBILITY,
			sum([Fallos de descarga]) as DL_NC_ERRORS_RETAINABILITY,
			sum([Count_Throughput_128k]) as DL_NC_CONNECTIONS_TH_128KBPS,
			case when sum([Count_Throughput])>0 then sum([Throughput]*[Count_Throughput])/sum([Count_Throughput])
				else 0 end as DL_NC_MEAN,
			max([Throughput Max]) as DL_NC_PEAK,
			mnc,
			date_reporting		

			


		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Data_DL_Thput_NC'+@sheet+ '
		where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+'''
		group by Entidad,mnc,date_reporting		


	)dl_nc on (dl_ce.entidad=dl_nc.Entidad and dl_Ce.mnc=dl_nc.mnc and dl_ce.date_reporting=dl_nc.date_reporting)


	left outer join (

		select 
			entidad,
			sum([Subidas]) as UL_NC_ATTEMPTS,
			sum([Fallos de Acceso]) as UL_NC_ERRORS_ACCESSIBILITY,
			sum([Fallos de descarga]) as UL_NC_ERRORS_RETAINABILITY,
			sum([Count_Throughput_64k]) as UL_NC_CONNECTIONS_TH_64KBPS,
			case when sum([Count_Throughput])>0 then sum([Throughput]*[Count_Throughput])/sum([Count_Throughput])
				else 0 end as UL_NC_MEAN,
			max([Throughput Max]) as UL_NC_PEAK,
			mnc,
			date_reporting		


		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Data_UL_Thput_NC'+@sheet+ '
		where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+'''
		group by Entidad,mnc,date_reporting		


	)ul_NC on (dl_ce.entidad=ul_NC.Entidad and dl_Ce.mnc=ul_NC.mnc and dl_ce.date_reporting=ul_NC.date_reporting)



	left outer join (

		select 
			entidad,
			sum(pings) as LAT_PINGS,
			case when sum(pings)> 0  then 1.0*sum(rtt*pings)/sum(pings)
				else 0 end as LAT_AVG,
			mnc,
			date_reporting		



		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Data_ping'+@sheet+ '
		where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+'''
		group by Entidad,mnc,date_reporting		


	)ping on (dl_ce.entidad=ping.Entidad and dl_Ce.mnc=ping.mnc and dl_ce.date_reporting=ping.date_reporting)



	left outer join (

		select 
			entidad,
			sum([Navegaciones]) as WEB_ATTEMPS,
			sum([Fallos de acceso]) as WEB_ERRORS_ACCESSIBILITY,
			sum([Navegaciones fallidas]) as WEB_ERRORS_RETAINABILITY,
			case when sum([Count_SessionTime]) >0 then sum([Session Time]*[Count_SessionTime])/sum([Count_SessionTime])
				else 0 end as WEB_D5,
			case when sum([Count_IPServiceSetupTime])>0 then sum([IP Service Setup Time]*[Count_IPServiceSetupTime])/sum([Count_IPServiceSetupTime]) 
				else 0 end as WEB_IP_ACCESS_TIME,
			case when sum([Count_TransferTime])>0 then sum([Transfer Time]*[Count_TransferTime])/sum([Count_TransferTime])
				else 0 end as WEB_HTTP_TRANSFER_TIME,
			sum([Navegaciones HTTPS]) as WEB_ATTEMPS_HTTPS,
			sum([Fallos de acceso HTTPS]) as WEB_ERRORS_ACCESSIBILITY_HTTPS,
			sum([Navegaciones fallidas HTTPS]) as WEB_ERRORS_RETAINABILITY_HTTPS,
			case when sum([Count_SessionTime HTTPS]) >0 then sum([Session Time HTTPS]*[Count_SessionTime HTTPS])/sum([Count_SessionTime HTTPS])
				else 0 end as WEB_D5_HTTPS,
			case when sum([Count_IPServiceSetupTime HTTPS])>0 then sum([IP Service Setup Time HTTPS]*[Count_IPServiceSetupTime HTTPS])/sum([Count_IPServiceSetupTime HTTPS]) 
				else 0 end as WEB_IP_ACCESS_TIME_HTTPS,
			case when sum([Count_TransferTime HTTPS])>0 then sum([Transfer Time HTTPS]*[Count_TransferTime HTTPS])/sum([Count_TransferTime HTTPS])
				else 0 end as WEB_HTTP_TRANSFER_TIME_HTTPS,
			mnc,
			date_reporting		

			


		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Data_web'+@sheet+ '
		where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+'''
		group by Entidad,mnc,date_reporting		


	)web on (dl_ce.entidad=web.Entidad and dl_Ce.mnc=web.mnc and dl_ce.date_reporting=web.date_reporting)



	left outer join (

		select 
			entidad,
			case when sum([Count_Video_Resolucion])>0 then
				cast((sum(cast (left([avg Video Resolution],3) as int)*[Count_Video_Resolucion])/sum([Count_Video_Resolucion])) as varchar(10)) + ''p''
				else null end as [avg video resolution],
			case when sum(isnull([B4], 0))>0 then sum([B4]) 
				when sum([ReproduccionesHD])<sum([Successful video download]) then sum([ReproduccionesHD]) 
				else sum([Successful video download]) end as [B4 hd share],
			case when sum([Count_Video_MOS])>0 then
				sum([Video MOS]*[Count_Video_MOS])/sum([Count_Video_MOS]) 
				else 0 end as [video mos],
			sum([Reproducciones]) as YTB_HD_ATTEMPS,
			case when sum([Reproducciones]-[Fails])>0 then sum([Time To First Image]*([Reproducciones]-[Fails]))/sum([Reproducciones]-[Fails])
				else 0 end as YTB_HD_AVG_START_TIME,
			sum([Fails]) as YTB_HD_FAILS ,
			case when sum([Reproducciones]) >0 then (1-1.0*sum([Fails])/sum([Reproducciones]))
				else 0 end as YTB_HD_B1,
			sum([ReproduccionesSinInt]) as YTB_HD_REPR_NO_INTERRUPTIONS,
			sum([ReproduccionesHD]) as YTB_HD_REPR_NO_COMPRESSION,
			case when sum([Reproducciones])>0 then 1.0*sum([ReproduccionesSinInt])/sum([Reproducciones])
				else 0 end as YTB_HD_B2,
			sum([Successful video download]) as YTB_HD_SUCC_DL,
			mnc,
			date_reporting		



		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Data_youtube_hd'+@sheet+ '
		where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+''' 
		group by Entidad,mnc,date_reporting		


	)ytb on (dl_ce.entidad=ytb.Entidad and dl_Ce.mnc=ytb.mnc and dl_ce.date_reporting=ytb.date_reporting)



where dl_ce.entidad like '''+@entidad+''' and dl_ce.date_reporting='''+@date_reporting+''' and dl_ce.Report_Type='''+@report_type+'''



group by dl_ce.entidad, dl_ce.mnc, dl_Ce.date_reporting, dl_ce.meas_week, dl_ce.date_reporting, dl_ce.week_reporting, 
ul_Ce.UL_CE_ATTEMPTS, ul_Ce.UL_CE_ERRORS_ACCESSIBILITY, ul_Ce.UL_CE_ERRORS_RETAINABILITY, ul_ce.UL_CE_D3, ul_ce.UL_CE_PEAK,
dl_nc.DL_NC_ATTEMPTS, dl_nc.DL_NC_ERRORS_ACCESSIBILITY, dl_nc.DL_NC_ERRORS_RETAINABILITY, dl_nc.DL_NC_CONNECTIONS_TH_128KBPS, dl_nc.DL_NC_MEAN,	dl_nc.DL_NC_PEAK,
ul_nc.UL_NC_ATTEMPTS, ul_nc.UL_NC_ERRORS_ACCESSIBILITY,	ul_nc.UL_NC_ERRORS_RETAINABILITY, ul_nc.UL_NC_CONNECTIONS_TH_64KBPS, ul_nc.UL_NC_MEAN, ul_nc.UL_NC_PEAK,
ping.LAT_PINGS,	ping.LAT_AVG,
web.WEB_ATTEMPS, web.WEB_ERRORS_ACCESSIBILITY, web.WEB_ERRORS_RETAINABILITY, web.WEB_D5, web.WEB_IP_ACCESS_TIME, web.WEB_HTTP_TRANSFER_TIME, web.WEB_ATTEMPS_HTTPS,	web.WEB_ERRORS_ACCESSIBILITY_HTTPS,	web.WEB_ERRORS_RETAINABILITY_HTTPS,	web.WEB_D5_HTTPS, web.WEB_IP_ACCESS_TIME_HTTPS,	web.WEB_HTTP_TRANSFER_TIME_HTTPS,
ytb.[avg video resolution],	ytb.[B4 hd share],ytb.[video mos], ytb.YTB_HD_ATTEMPS, ytb. YTB_HD_AVG_START_TIME, ytb.YTB_HD_FAILS, ytb.YTB_HD_B1,	ytb.YTB_HD_REPR_NO_INTERRUPTIONS, ytb.YTB_HD_REPR_NO_COMPRESSION, ytb.YTB_HD_B2, ytb.YTB_HD_SUCC_DL


order by case 
		when dl_ce.mnc=''01'' then 1
		when dl_ce.mnc=''07'' then 2
		when dl_ce.mnc=''03'' then 3
		when dl_ce.mnc=''04'' then 4
	end 


')