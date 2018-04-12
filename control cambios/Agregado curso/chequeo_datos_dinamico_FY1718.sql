declare @tech as varchar (256)='4G_ROAD'
declare @entidad as varchar (256)='M50-MADRIDCIRCLE-R1'
declare @date_reporting as varchar (256)='17_10'
declare @report_type as varchar (256)='OSP'
declare @bbdd as varchar (256)
declare @sheet as varchar (256)=''   --'_4G' para 4G_ONLY, 'CA_ONLY' para CA_ONLY y '' PARA ALL

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
	dl_nc.DL_NC_CONNECTIONS_TH_384KBPS,
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
	ul_nc.UL_NC_CONNECTIONS_TH_384KBPS,
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


	ytb.[avg video resolution_video1],
	ytb.[B4 hd share_video1],
	ytb.[video mos_video1],
	ytb.YTB_HD_ATTEMPS_video1,
	ytb. YTB_HD_AVG_START_TIME_video1,
	ytb.YTB_HD_FAILS_video1,
	ytb.YTB_HD_B1_video1,
	ytb.YTB_HD_REPR_NO_INTERRUPTIONS_video1,
	ytb.YTB_HD_REPR_NO_COMPRESSION_video1,
	ytb.YTB_HD_B2_video1,
	ytb.YTB_HD_SUCC_DL_video1,

	ytb.[avg video resolution_video2],
	ytb.[B4 hd share_video2],
	ytb.[video mos_video2],
	ytb.YTB_HD_ATTEMPS_video2,
	ytb. YTB_HD_AVG_START_TIME_video2,
	ytb.YTB_HD_FAILS_video2,
	ytb.YTB_HD_B1_video2,
	ytb.YTB_HD_REPR_NO_INTERRUPTIONS_video2,
	ytb.YTB_HD_REPR_NO_COMPRESSION_video2,
	ytb.YTB_HD_B2_video2,
	ytb.YTB_HD_SUCC_DL_video2,

	ytb.[avg video resolution_video3],
	ytb.[B4 hd share_video3],
	ytb.[video mos_video3],
	ytb.YTB_HD_ATTEMPS_video3,
	ytb. YTB_HD_AVG_START_TIME_video3,
	ytb.YTB_HD_FAILS_video3,
	ytb.YTB_HD_B1_video3,
	ytb.YTB_HD_REPR_NO_INTERRUPTIONS_video3,
	ytb.YTB_HD_REPR_NO_COMPRESSION_video3,
	ytb.YTB_HD_B2_video3,
	ytb.YTB_HD_SUCC_DL_video3,

	ytb.[avg video resolution_video4],
	ytb.[B4 hd share_video4],
	ytb.[video mos_video4],
	ytb.YTB_HD_ATTEMPS_video4,
	ytb. YTB_HD_AVG_START_TIME_video4,
	ytb.YTB_HD_FAILS_video4,
	ytb.YTB_HD_B1_video4,
	ytb.YTB_HD_REPR_NO_INTERRUPTIONS_video4,
	ytb.YTB_HD_REPR_NO_COMPRESSION_video4,
	ytb.YTB_HD_B2_video4,
	ytb.YTB_HD_SUCC_DL_video4,





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
			sum([Count_Throughput_384k]) as DL_NC_CONNECTIONS_TH_384KBPS,
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
			sum([Count_Throughput_384k]) as UL_NC_CONNECTIONS_TH_384KBPS,
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
			case when sum([Count_Video_Resolucion_Video1])>0 then
				cast((sum(FLOOR(replace([avg Video Resolution_Video1],''p'',''''))*[Count_Video_Resolucion_Video1])/sum([Count_Video_Resolucion_Video1])) as varchar(10)) + ''p''
				else null end as [avg video resolution_Video1],
			case when sum(isnull([B4_Video1], 0))>0 then sum([B4_Video1]) 
				when sum([ReproduccionesHD_Video1])<sum([Successful video download_Video1]) then sum([ReproduccionesHD_Video1]) 
				else sum([Successful video download_Video1]) end as [B4 hd share_Video1],
			case when sum([Count_Video_MOS_Video1])>0 then
				sum([Video MOS_Video1]*[Count_Video_MOS_Video1])/sum([Count_Video_MOS_Video1]) 
				else 0 end as [video mos_Video1],
			sum([Reproducciones_Video1]) as YTB_HD_ATTEMPS_Video1,
			case when sum([Reproducciones_Video1]-[Fails_Video1])>0 then sum([Time To First Image_Video1]*([Reproducciones_Video1]-[Fails_Video1]))/sum([Reproducciones_Video1]-[Fails_Video1])
				else 0 end as YTB_HD_AVG_START_TIME_Video1,
			sum([Fails_Video1]) as YTB_HD_FAILS_Video1 ,
			case when sum([Reproducciones_Video1]) >0 then (1-1.0*sum([Fails_Video1])/sum([Reproducciones_Video1]))
				else 0 end as YTB_HD_B1_Video1,
			sum([ReproduccionesSinInt_Video1]) as YTB_HD_REPR_NO_INTERRUPTIONS_Video1,
			sum([ReproduccionesHD_Video1]) as YTB_HD_REPR_NO_COMPRESSION_Video1,
			case when sum([Reproducciones_Video1])>0 then 1.0*sum([ReproduccionesSinInt_Video1])/sum([Reproducciones_Video1])
				else 0 end as YTB_HD_B2_Video1,
			sum([Successful video download_Video1]) as YTB_HD_SUCC_DL_Video1,

			case when sum([Count_Video_Resolucion_Video2])>0 then
				cast((sum(FLOOR(replace([avg Video Resolution_Video2],''p'',''''))*[Count_Video_Resolucion_Video2])/sum([Count_Video_Resolucion_Video2])) as varchar(10)) + ''p''
				else null end as [avg video resolution_Video2],
			case when sum(isnull([B4_Video2], 0))>0 then sum([B4_Video2]) 
				when sum([ReproduccionesHD_Video2])<sum([Successful video download_Video2]) then sum([ReproduccionesHD_Video2]) 
				else sum([Successful video download_Video2]) end as [B4 hd share_Video2],
			case when sum([Count_Video_MOS_Video2])>0 then
				sum([Video MOS_Video2]*[Count_Video_MOS_Video2])/sum([Count_Video_MOS_Video2]) 
				else 0 end as [video mos_Video2],
			sum([Reproducciones_Video2]) as YTB_HD_ATTEMPS_Video2,
			case when sum([Reproducciones_Video2]-[Fails_Video2])>0 then sum([Time To First Image_Video2]*([Reproducciones_Video2]-[Fails_Video2]))/sum([Reproducciones_Video2]-[Fails_Video2])
				else 0 end as YTB_HD_AVG_START_TIME_Video2,
			sum([Fails_Video2]) as YTB_HD_FAILS_Video2 ,
			case when sum([Reproducciones_Video2]) >0 then (1-1.0*sum([Fails_Video2])/sum([Reproducciones_Video2]))
				else 0 end as YTB_HD_B1_Video2,
			sum([ReproduccionesSinInt_Video2]) as YTB_HD_REPR_NO_INTERRUPTIONS_Video2,
			sum([ReproduccionesHD_Video2]) as YTB_HD_REPR_NO_COMPRESSION_Video2,
			case when sum([Reproducciones_Video2])>0 then 1.0*sum([ReproduccionesSinInt_Video2])/sum([Reproducciones_Video2])
				else 0 end as YTB_HD_B2_Video2,
			sum([Successful video download_Video2]) as YTB_HD_SUCC_DL_Video2,

			case when sum([Count_Video_Resolucion_Video3])>0 then
				cast((sum(FLOOR(replace([avg Video Resolution_Video3],''p'',''''))*[Count_Video_Resolucion_Video3])/sum([Count_Video_Resolucion_Video3])) as varchar(10)) + ''p''
				else null end as [avg video resolution_Video3],
			case when sum(isnull([B4_Video3], 0))>0 then sum([B4_Video3]) 
				when sum([ReproduccionesHD_Video3])<sum([Successful video download_Video3]) then sum([ReproduccionesHD_Video3]) 
				else sum([Successful video download_Video3]) end as [B4 hd share_Video3],
			case when sum([Count_Video_MOS_Video3])>0 then
				sum([Video MOS_Video3]*[Count_Video_MOS_Video3])/sum([Count_Video_MOS_Video3]) 
				else 0 end as [video mos_Video3],
			sum([Reproducciones_Video3]) as YTB_HD_ATTEMPS_Video3,
			case when sum([Reproducciones_Video3]-[Fails_Video3])>0 then sum([Time To First Image_Video3]*([Reproducciones_Video3]-[Fails_Video3]))/sum([Reproducciones_Video3]-[Fails_Video3])
				else 0 end as YTB_HD_AVG_START_TIME_Video3,
			sum([Fails_Video3]) as YTB_HD_FAILS_Video3 ,
			case when sum([Reproducciones_Video3]) >0 then (1-1.0*sum([Fails_Video3])/sum([Reproducciones_Video3]))
				else 0 end as YTB_HD_B1_Video3,
			sum([ReproduccionesSinInt_Video3]) as YTB_HD_REPR_NO_INTERRUPTIONS_Video3,
			sum([ReproduccionesHD_Video3]) as YTB_HD_REPR_NO_COMPRESSION_Video3,
			case when sum([Reproducciones_Video3])>0 then 1.0*sum([ReproduccionesSinInt_Video3])/sum([Reproducciones_Video3])
				else 0 end as YTB_HD_B2_Video3,
			sum([Successful video download_Video3]) as YTB_HD_SUCC_DL_Video3,

			case when sum([Count_Video_Resolucion_Video4])>0 then
				cast((sum(FLOOR(replace([avg Video Resolution_Video4],''p'',''''))*[Count_Video_Resolucion_Video4])/sum([Count_Video_Resolucion_Video4])) as varchar(10)) + ''p''
				else null end as [avg video resolution_Video4],
			case when sum(isnull([B4_Video4], 0))>0 then sum([B4_Video4]) 
				when sum([ReproduccionesHD_Video4])<sum([Successful video download_Video4]) then sum([ReproduccionesHD_Video4]) 
				else sum([Successful video download_Video4]) end as [B4 hd share_Video4],
			case when sum([Count_Video_MOS_Video4])>0 then
				sum([Video MOS_Video4]*[Count_Video_MOS_Video4])/sum([Count_Video_MOS_Video4]) 
				else 0 end as [video mos_Video4],
			sum([Reproducciones_Video4]) as YTB_HD_ATTEMPS_Video4,
			case when sum([Reproducciones_Video4]-[Fails_Video4])>0 then sum([Time To First Image_Video4]*([Reproducciones_Video4]-[Fails_Video4]))/sum([Reproducciones_Video4]-[Fails_Video4])
				else 0 end as YTB_HD_AVG_START_TIME_Video4,
			sum([Fails_Video4]) as YTB_HD_FAILS_Video4 ,
			case when sum([Reproducciones_Video4]) >0 then (1-1.0*sum([Fails_Video4])/sum([Reproducciones_Video4]))
				else 0 end as YTB_HD_B1_Video4,
			sum([ReproduccionesSinInt_Video4]) as YTB_HD_REPR_NO_INTERRUPTIONS_Video4,
			sum([ReproduccionesHD_Video4]) as YTB_HD_REPR_NO_COMPRESSION_Video4,
			case when sum([Reproducciones_Video4])>0 then 1.0*sum([ReproduccionesSinInt_Video4])/sum([Reproducciones_Video4])
				else 0 end as YTB_HD_B2_Video4,
			sum([Successful video download_Video4]) as YTB_HD_SUCC_DL_Video4,


			mnc,
			date_reporting	



		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Data_youtube_hd'+@sheet+ '
		where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+''' 
		group by Entidad,mnc,date_reporting		


	)ytb on (dl_ce.entidad=ytb.Entidad and dl_Ce.mnc=ytb.mnc and dl_ce.date_reporting=ytb.date_reporting)



where dl_ce.entidad like '''+@entidad+''' and dl_ce.date_reporting='''+@date_reporting+''' and dl_ce.Report_Type='''+@report_type+'''



group by dl_ce.entidad, dl_ce.mnc, dl_Ce.date_reporting, dl_ce.meas_week, dl_ce.date_reporting, dl_ce.week_reporting, 
ul_Ce.UL_CE_ATTEMPTS, ul_Ce.UL_CE_ERRORS_ACCESSIBILITY, ul_Ce.UL_CE_ERRORS_RETAINABILITY, ul_ce.UL_CE_D3, ul_ce.UL_CE_PEAK,
dl_nc.DL_NC_ATTEMPTS, dl_nc.DL_NC_ERRORS_ACCESSIBILITY, dl_nc.DL_NC_ERRORS_RETAINABILITY, dl_nc.DL_NC_CONNECTIONS_TH_384KBPS, dl_nc.DL_NC_MEAN,	dl_nc.DL_NC_PEAK,
ul_nc.UL_NC_ATTEMPTS, ul_nc.UL_NC_ERRORS_ACCESSIBILITY,	ul_nc.UL_NC_ERRORS_RETAINABILITY, ul_nc.UL_NC_CONNECTIONS_TH_384KBPS, ul_nc.UL_NC_MEAN, ul_nc.UL_NC_PEAK,
ping.LAT_PINGS,	ping.LAT_AVG,
web.WEB_ATTEMPS, web.WEB_ERRORS_ACCESSIBILITY, web.WEB_ERRORS_RETAINABILITY, web.WEB_D5, web.WEB_IP_ACCESS_TIME, web.WEB_HTTP_TRANSFER_TIME, web.WEB_ATTEMPS_HTTPS,	web.WEB_ERRORS_ACCESSIBILITY_HTTPS,	web.WEB_ERRORS_RETAINABILITY_HTTPS,	web.WEB_D5_HTTPS, web.WEB_IP_ACCESS_TIME_HTTPS,	web.WEB_HTTP_TRANSFER_TIME_HTTPS,
ytb.[avg video resolution_video1],	ytb.[B4 hd share_video1],ytb.[video mos_video1], ytb.YTB_HD_ATTEMPS_video1, ytb. YTB_HD_AVG_START_TIME_video1, ytb.YTB_HD_FAILS_video1, ytb.YTB_HD_B1_video1,	ytb.YTB_HD_REPR_NO_INTERRUPTIONS_video1, ytb.YTB_HD_REPR_NO_COMPRESSION_video1, ytb.YTB_HD_B2_video1, ytb.YTB_HD_SUCC_DL_video1,
ytb.[avg video resolution_Video2],	ytb.[B4 hd share_Video2],ytb.[video mos_Video2], ytb.YTB_HD_ATTEMPS_Video2, ytb. YTB_HD_AVG_START_TIME_Video2, ytb.YTB_HD_FAILS_Video2, ytb.YTB_HD_B1_Video2,	ytb.YTB_HD_REPR_NO_INTERRUPTIONS_Video2, ytb.YTB_HD_REPR_NO_COMPRESSION_Video2, ytb.YTB_HD_B2_Video2, ytb.YTB_HD_SUCC_DL_Video2,
ytb.[avg video resolution_Video3],	ytb.[B4 hd share_Video3],ytb.[video mos_Video3], ytb.YTB_HD_ATTEMPS_Video3, ytb. YTB_HD_AVG_START_TIME_Video3, ytb.YTB_HD_FAILS_Video3, ytb.YTB_HD_B1_Video3,	ytb.YTB_HD_REPR_NO_INTERRUPTIONS_Video3, ytb.YTB_HD_REPR_NO_COMPRESSION_Video3, ytb.YTB_HD_B2_Video3, ytb.YTB_HD_SUCC_DL_Video3,
ytb.[avg video resolution_Video4],	ytb.[B4 hd share_Video4],ytb.[video mos_Video4], ytb.YTB_HD_ATTEMPS_Video4, ytb. YTB_HD_AVG_START_TIME_Video4, ytb.YTB_HD_FAILS_Video4, ytb.YTB_HD_B1_Video4,	ytb.YTB_HD_REPR_NO_INTERRUPTIONS_Video4, ytb.YTB_HD_REPR_NO_COMPRESSION_Video4, ytb.YTB_HD_B2_Video4, ytb.YTB_HD_SUCC_DL_Video4


order by case 
		when dl_ce.mnc=''01'' then 1
		when dl_ce.mnc=''07'' then 2
		when dl_ce.mnc=''03'' then 3
		when dl_ce.mnc=''04'' then 4
	end 


')