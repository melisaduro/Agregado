--select [entidad], [meas_date], [Report_Type], entidad
--from AGGRVOLTE.dbo.lcc_aggr_sp_MDD_Voice_Llamadas
--where entidad like '%valencia%'
--group by [entidad], [meas_date], [Report_Type], entidad

declare @tech as varchar (256)='VOLTE'
declare @entidad as varchar (256)='ZARAGOZA-noLA'
--declare @date_reporting as varchar (256)= 'NULL'
declare @meas_date as varchar (256)= '15_02'
declare @report_type as varchar (256)='VDF'
declare @bbdd as varchar (256)
--declare @sheet as varchar (256)=''  /* Valores: sin nada para la pestaña ALL, _LTE pestaña 4G, _VOLTE pestaña Real VOLTE, _3G pestaña 3G*/
--declare @sheet as varchar (256)='_VOLTE'
declare @sheet as varchar (256)='_4G'

if @tech='VOLTE'
	begin
	set @bbdd='AGGRVOLTE'
	end



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

	
	v.meas_date,
	v.meas_week,
	v.date_reporting,
	v.week_reporting

from '+@bbdd+'.dbo.lcc_aggr_sp_mdd_voice_llamadas'+@sheet+ ' v

	left outer join(

		select 
			entidad,
			1.0*((1.0*sum([CST_MOMT_Alerting]*([Calls_AVG_ALERT_MO]+[Calls_AVG_ALERT_MT]))/sum([Calls_AVG_ALERT_MT]+[Calls_AVG_ALERT_MO]))) as CST_ALERTING,
			1.0*sum(1.0*[CST_MOMT_Connect]*([Calls_AVG_CONNECT_MO]+[Calls_AVG_CONNECT_MT]))/sum([Calls_AVG_CONNECT_MT]+[Calls_AVG_CONNECT_MO]) as CST_CONNECT,
			mnc,
			date_reporting		


		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Voice_CallSetupTime_CompletedCalls'+@sheet+ '
		where entidad like '''+@entidad+''' and meas_date='''+@meas_date+''' and Report_Type='''+@report_type+'''
		group by Entidad,mnc,date_reporting		

	) cst on (v.entidad=cst.Entidad and v.mnc=cst.mnc and v.date_reporting=cst.date_reporting)
	
	left outer join(

		select 
			entidad,
			1.0*(sum([MOS_ALL]*Calls_MOS))/sum(Calls_MOS) as MOS_NB,
			sum([Registers_NB]) as NUM_SAMPLES_NB,
			sum([MOS_NB_Samples_Under_2.5]) as NUM_SAMPLES_25_NB,
			--1.0*(sum(isnull([MOS],0)*[Registers]+isnull([MOS_NB],0)*[Registers_NB]))/sum([Registers]+[Registers_NB]) as MOS_OVER_old,
			1.0*(sum([MOS_ALL]*Calls_MOS))/sum(Calls_MOS) as MOS_OVER,
			sum([Registers]+[Registers_NB]) as NUM_SAMPLES_OVER,
			sum([MOS_Samples_Under_2.5]+[MOS_NB_Samples_Under_2.5]) as NUM_SAMPLES_25_OVER,
			sum([Calls_WB_only]) as CALLS_WB_AMR,
			1.0*sum([MOS_WBOnly]*[Calls_AVG_WB_ONLY])/sum([Calls_AVG_WB_ONLY]) as AVG_QUALITY_WB_AMR,
			mnc,
			date_reporting		


		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Voice_PESQ'+@sheet+ '
		where entidad like '''+@entidad+''' and meas_date='''+@meas_date+''' and Report_Type='''+@report_type+'''
		group by Entidad,mnc,date_reporting		

	) mos on (v.entidad=mos.Entidad and v.mnc=mos.mnc and v.date_reporting=mos.date_reporting)

	left outer join(

		select 
			entidad,
			case when sum(Count_Speech_Delay)>0 then sum(Count_Speech_Delay*volte_speech_delay)/sum(Count_Speech_Delay) 
							else 0 end as VOLTE_Speech_Delay, --se pondera el speech delay para dar el valor real agrupado para la entidad calculada
			sum (Started_VOLTE) as [VOICE CALLS STARTED AND TERMINATED ON VOLTE],
			sum(SRVCC) as [CALLS WITH SRVCC PROCEDURE], 
			1.0*sum(SRVCC)/sum(is_VOLTE) as [% use SRVCC],
			sum(is_volte) as is_VOLTE,
			mnc,
			date_reporting		


		from '+@bbdd+'.dbo.lcc_aggr_sp_MDD_Voice_VOLTE'+@sheet+ '
		where entidad like '''+@entidad+''' and meas_date='''+@meas_date+''' and Report_Type='''+@report_type+'''
		group by Entidad,mnc,date_reporting		

	) volte on (v.entidad=volte.Entidad and v.mnc=volte.mnc and v.date_reporting=volte.date_reporting)
	




where v.entidad like '''+@entidad+''' and v.meas_date='''+@meas_date+''' and v.Report_Type='''+@report_type+'''


group by v.entidad,v.mnc,v.meas_Date,v.meas_week,v.date_reporting,v.week_reporting,cst.CST_ALERTING,cst.CST_CONNECT,
mos.MOS_OVER, mos.NUM_SAMPLES_OVER,	mos.NUM_SAMPLES_25_OVER, mos.CALLS_WB_AMR, mos.AVG_QUALITY_WB_AMR,
volte.VOLTE_Speech_Delay, volte.[VOICE CALLS STARTED AND TERMINATED ON VOLTE], volte.[CALLS WITH SRVCC PROCEDURE],volte.[% use SRVCC]

order by case 
		when v.mnc=''01'' then 1
		when v.mnc=''07'' then 2
		when v.mnc=''03'' then 3
		when v.mnc=''04'' then 4
	end 

')