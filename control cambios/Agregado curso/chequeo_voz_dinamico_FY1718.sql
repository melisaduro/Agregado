declare @tech as varchar (256)='volte'
declare @entidad as varchar (256)='granada'
declare @date_reporting as varchar (256)='17_09'
declare @report_type as varchar (256)='mun'
declare @bbdd as varchar (256)
declare @sheet as varchar (256)='' /* Valores @tech=3G : _3g' para pestaña 3G y '' para pestaña ALL*/
								   /* Valores @tech=4G : '_4g' para pestaña 4G_ONLY, _3g' para pestaña 3G y '' para pestaña ALL*/
								   /* Valores @tech=VOLTE : '_VOLTE' para pestaña VOLTE REAL,'_4g' para pestaña 4G_ONLY, '_3g' para pestaña 3G y '' para pestaña ALL*/


if @tech='4G'
	begin
	set @bbdd='AGGRVoice4G'
	end

if @tech='3G'
	begin
	set @bbdd='AGGRVoice3G'
	end

if @tech='4G_Road'
	begin
	set @bbdd='AGGRVoice4G_Road'
	end

if @tech='VOLTE'
	begin
	set @bbdd='AGGRVOLTE'
	end

if @tech='VOLTE_Road'
	begin
	set @bbdd='AGGRVOLTE_ROAD'
	end

if @tech like '%VOLTE%' and @sheet not like '%3G%'
begin
	exec('


	select 
		v.entidad,
		case 
			when v.mnc=''01'' then ''VODAFONE''
			when v.mnc=''07'' then ''MOVISTAR''
			when v.mnc=''03'' then ''ORANGE''
			when v.mnc=''04'' then ''YOIGO''
		end as Operator,
		sum(v.mo_succeeded+v.mo_blocks+v.mo_drops+v.mt_succeeded+v.mt_blocks+v.mt_drops) as [CALL ATTEMPTS (N)],
		sum(v.mo_blocks+v.mt_blocks) as [ACCESS FAILURES (N)],
		'''',
		'''',
		'''',
		'''',
		sum(v.mo_drops+v.mt_drops) as [VOICE DROPPED  CALLS (N)],
		'''',
		sum(v.SQNS_WB) as [NUMBERS OF CALLS Non Sustainability WB],
		'''',
		'''',
		cst.CST_ALERTING,
		'''',
		'''',
		'''',
		'''',
		'''',
		cst.CST_CONNECT,
		'''',
		'''',
		'''',
		'''',
		'''',
		'''',
		'''',
		'''',
		mos.MOS_OVER,
		mos.NUM_SAMPLES_OVER,
		'''',
		mos.NUM_SAMPLES_25_OVER,
		'''',
		volte.VOLTE_Speech_Delay as [VOLTE AVG. SPEECH DELAY (RTT)],
		mos.CALLS_WB_AMR,
		mos.AVG_QUALITY_WB_AMR,
		'''',
		sum(v.started_ended_3G_comp) as [VOICE CALLS STARTED AND TERMINATED ON 3G (N)],
		sum(v.started_ended_2G_comp) as [VOICE CALLS STARTED AND TERMINATED ON 2G (N)],
		sum(v.calls_mixed_comp) as [VOICE CALLS - MIXED (N)],
		sum(v.started_4G_comp) as [VOICE CALLS STARTED ON 4G (N)],
		volte.[VOICE CALLS STARTED AND TERMINATED ON VOLTE],
		sum(v.duration_3G) as [3G TOTAL DURATION (S)],
		sum(v.duration_2G) as [2G TOTAL DURATION (S)],
		sum(v.GSM_calls_after_CSFB_comp) as [CALLS ON 2G LAYER AFTER CSFB PROCEDURE (N)],
		sum(v.umts_calls_after_csfb_comp) as [CALLS ON 3G LAYER AFTER CSFB PROCEDURE (N)],


		volte.[CALLS WITH SRVCC PROCEDURE],
		volte.[% use SRVCC],
	
		v.date_reporting,
		v.meas_week,
		v.date_reporting,
		v.week_reporting

	from '+@bbdd+'.dbo.lcc_aggr_sp_mdd_voice_llamadas'+@sheet+ ' v

		left outer join(

			select 
				entidad,
				case when sum([Calls_AVG_ALERT_MT]+[Calls_AVG_ALERT_MO])>0 then 1.0*((1.0*sum([CST_MOMT_Alerting]*([Calls_AVG_ALERT_MO]+[Calls_AVG_ALERT_MT]))/sum([Calls_AVG_ALERT_MT]+[Calls_AVG_ALERT_MO]))) end as CST_ALERTING,
				case when sum([Calls_AVG_CONNECT_MT]+[Calls_AVG_CONNECT_MO])>0 then 1.0*sum(1.0*[CST_MOMT_Connect]*([Calls_AVG_CONNECT_MO]+[Calls_AVG_CONNECT_MT]))/sum([Calls_AVG_CONNECT_MT]+[Calls_AVG_CONNECT_MO]) end as CST_CONNECT,
				mnc,
				date_reporting		


			from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+@sheet+ '
			where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+'''
			group by Entidad,mnc,date_reporting		

		) cst on (v.entidad=cst.Entidad and v.mnc=cst.mnc and v.date_reporting=cst.date_reporting)
	
		left outer join(

			select 
				entidad,
				case when sum(Calls_MOS)>0 then 1.0*(sum([MOS_ALL]*Calls_MOS))/sum(Calls_MOS) end as MOS_NB,
				sum([Registers_NB]) as NUM_SAMPLES_NB,
				sum([MOS_NB_Samples_Under_2.5]) as NUM_SAMPLES_25_NB,
				case when sum(Calls_MOS)>0 then 1.0*(sum([MOS_ALL]*Calls_MOS))/sum(Calls_MOS) end as MOS_OVER,
				sum([Registers]+[Registers_NB]) as NUM_SAMPLES_OVER,
				sum([MOS_Samples_Under_2.5]+[MOS_NB_Samples_Under_2.5]) as NUM_SAMPLES_25_OVER,
				sum([Calls_WB_only]) as CALLS_WB_AMR,
				1.0*sum([MOS_WBOnly]*[Calls_AVG_WB_ONLY])/sum([Calls_AVG_WB_ONLY]) as AVG_QUALITY_WB_AMR,
				mnc,
				date_reporting		


			from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Voice_PESQ'+@sheet+ '
			where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+'''
			group by Entidad,mnc,date_reporting		

		) mos on (v.entidad=mos.Entidad and v.mnc=mos.mnc and v.date_reporting=mos.date_reporting)
	
		left outer join(

			select 
				entidad,
				case when sum(Count_Speech_Delay)>0 then sum(Count_Speech_Delay*volte_speech_delay)/sum(Count_Speech_Delay) 
								else 0 end as VOLTE_Speech_Delay, --se pondera el speech delay para dar el valor real agrupado para la entidad calculada
				sum (Started_VOLTE) as [VOICE CALLS STARTED AND TERMINATED ON VOLTE],
				sum(SRVCC) as [CALLS WITH SRVCC PROCEDURE], 
				case when sum(is_VOLTE)>0 then 1.0*sum(SRVCC)/sum(is_VOLTE) end as [% use SRVCC],
				sum(is_volte) as is_VOLTE,
				mnc,
				date_reporting		


			from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Voice_VOLTE'+@sheet+ '
			where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+'''
			group by Entidad,mnc,date_reporting		

		) volte on (v.entidad=volte.Entidad and v.mnc=volte.mnc and v.date_reporting=volte.date_reporting)



	where v.entidad like '''+@entidad+''' and v.date_reporting='''+@date_reporting+''' and v.Report_Type='''+@report_type+'''


	group by v.entidad,v.mnc,v.date_reporting,v.meas_week,v.date_reporting,v.week_reporting,cst.CST_ALERTING,cst.CST_CONNECT,
	mos.MOS_OVER, mos.NUM_SAMPLES_OVER,	mos.NUM_SAMPLES_25_OVER, mos.CALLS_WB_AMR, mos.AVG_QUALITY_WB_AMR,
	volte.VOLTE_Speech_Delay, volte.[VOICE CALLS STARTED AND TERMINATED ON VOLTE], volte.[CALLS WITH SRVCC PROCEDURE],volte.[% use SRVCC]

	order by case 
			when v.mnc=''01'' then 1
			when v.mnc=''07'' then 2
			when v.mnc=''03'' then 3
			when v.mnc=''04'' then 4
		end 

	')
end
else
begin
	exec('


	select 
	v.entidad,
	case 
		when v.mnc=''01'' then ''VODAFONE''
		when v.mnc=''07'' then ''MOVISTAR''
		when v.mnc=''03'' then ''ORANGE''
		when v.mnc=''04'' then ''YOIGO''
	end as Operator,
	sum(v.mo_succeeded+v.mo_blocks+v.mo_drops+v.mt_succeeded+v.mt_blocks+v.mt_drops) as [CALL ATTEMPTS (N)],
	sum(v.mo_blocks+v.mt_blocks) as [ACCESS FAILURES (N)],
	'''',
	'''',
	'''',
	'''',
	sum(v.mo_drops+v.mt_drops) as [VOICE DROPPED  CALLS (N)],
	'''',
	sum(v.SQNS_WB) as [NUMBERS OF CALLS Non Sustainability WB],
	'''',
	'''',
	cst.CST_ALERTING,
	'''',
	'''',
	'''',
	'''',
	'''',
	cst.CST_CONNECT,
	'''',
	'''',
	'''',
	'''',
	'''',
	'''',
	'''',
	'''',
	mos.MOS_OVER,
	mos.NUM_SAMPLES_OVER,
	'''',
	mos.NUM_SAMPLES_25_OVER,
	'''',
	'''',
	mos.CALLS_WB_AMR,
	mos.AVG_QUALITY_WB_AMR,
	'''',
	sum(v.started_ended_3G_comp) as [VOICE CALLS STARTED AND TERMINATED ON 3G (N)],
	sum(v.started_ended_2G_comp) as [VOICE CALLS STARTED AND TERMINATED ON 2G (N)],
	sum(v.calls_mixed_comp) as [VOICE CALLS - MIXED (N)],
	sum(v.started_4G_comp) as [VOICE CALLS STARTED ON 4G (N)],
	'''',
	sum(v.duration_3G) as [3G TOTAL DURATION (S)],
	sum(v.duration_2G) as [2G TOTAL DURATION (S)],
	sum(v.GSM_calls_after_CSFB_comp) as [CALLS ON 2G LAYER AFTER CSFB PROCEDURE (N)],
	sum(v.umts_calls_after_csfb_comp) as [CALLS ON 3G LAYER AFTER CSFB PROCEDURE (N)],


	'''',
	'''',
	
	v.date_reporting,
	v.meas_week,
	v.date_reporting,
	v.week_reporting

	from '+@bbdd+'.dbo.lcc_aggr_sp_mdd_voice_llamadas'+@sheet+ ' v

	left outer join(

		select 
			entidad,
			case when sum([Calls_AVG_ALERT_MT]+[Calls_AVG_ALERT_MO])>0 then 1.0*((1.0*sum([CST_MOMT_Alerting]*([Calls_AVG_ALERT_MO]+[Calls_AVG_ALERT_MT]))/sum([Calls_AVG_ALERT_MT]+[Calls_AVG_ALERT_MO]))) end as CST_ALERTING,
			case when sum([Calls_AVG_CONNECT_MT]+[Calls_AVG_CONNECT_MO])>0 then 1.0*sum(1.0*[CST_MOMT_Connect]*([Calls_AVG_CONNECT_MO]+[Calls_AVG_CONNECT_MT]))/sum([Calls_AVG_CONNECT_MT]+[Calls_AVG_CONNECT_MO]) end as CST_CONNECT,
			mnc,
			date_reporting		


		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+@sheet+ '
		where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+'''
		group by Entidad,mnc,date_reporting		

	) cst on (v.entidad=cst.Entidad and v.mnc=cst.mnc and v.date_reporting=cst.date_reporting)
	
	left outer join(

		select 
			entidad,
			case when sum(Calls_MOS)>0 then 1.0*(sum([MOS_ALL]*Calls_MOS))/sum(Calls_MOS) end as MOS_NB,
			sum([Registers_NB]) as NUM_SAMPLES_NB,
			sum([MOS_NB_Samples_Under_2.5]) as NUM_SAMPLES_25_NB,
			--1.0*(sum(isnull([MOS],0)*[Registers]+isnull([MOS_NB],0)*[Registers_NB]))/sum([Registers]+[Registers_NB]) as MOS_OVER_old,
			case when sum(Calls_MOS)>0 then 1.0*(sum([MOS_ALL]*Calls_MOS))/sum(Calls_MOS) end as MOS_OVER,
			sum([Registers]+[Registers_NB]) as NUM_SAMPLES_OVER,
			sum([MOS_Samples_Under_2.5]+[MOS_NB_Samples_Under_2.5]) as NUM_SAMPLES_25_OVER,
			sum([Calls_WB_only]) as CALLS_WB_AMR,
			case when sum([Calls_AVG_WB_ONLY])>0 then 1.0*sum([MOS_WBOnly]*[Calls_AVG_WB_ONLY])/sum([Calls_AVG_WB_ONLY]) end as AVG_QUALITY_WB_AMR,
			mnc,
			date_reporting		


		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Voice_PESQ'+@sheet+ '
		where entidad like '''+@entidad+''' and date_reporting='''+@date_reporting+''' and Report_Type='''+@report_type+'''
		group by Entidad,mnc,date_reporting		

	) mos on (v.entidad=mos.Entidad and v.mnc=mos.mnc and v.date_reporting=mos.date_reporting)
	

	where v.entidad like '''+@entidad+''' and v.date_reporting='''+@date_reporting+''' and v.Report_Type='''+@report_type+'''


	group by v.entidad,v.mnc,v.date_reporting,v.meas_week,v.date_reporting,v.week_reporting,cst.CST_ALERTING,cst.CST_CONNECT,
	mos.MOS_OVER, mos.NUM_SAMPLES_OVER,	mos.NUM_SAMPLES_25_OVER, mos.CALLS_WB_AMR, mos.AVG_QUALITY_WB_AMR
	
	order by case 
		when v.mnc=''01'' then 1
		when v.mnc=''07'' then 2
		when v.mnc=''03'' then 3
		when v.mnc=''04'' then 4
	end 

	')
end