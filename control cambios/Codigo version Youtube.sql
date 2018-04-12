-------Codigo agregado

declare @methodology as varchar (256) = 'D16'
--StoredProcedure [dbo].[sp_MDD_Data_Youtube_HD_GRID] 
select v.sessionid, v.testid,
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
			else 'Mixed' 
		end as tech, v.[Longitud Final], v.[Latitud Final]

	from Lcc_Data_YOUTUBE v, testinfo t, lcc_position_Entity_List_Vodafone c
		Where t.testid=v.testid
			and t.valid=1
			and v.info like '%Completed%'
			and v.MNC = 1	--MNC
			and v.MCC= 214						--MCC - Descartamos los valores erróneos
			and c.fileid=v.fileid
			and c.entity_name = 'ALBACETE'
			and c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitud Final], [Latitud Final])
			and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitud Final])
		group by v.sessionid, v.testid,
			case when v.[% LTE]=1 then 'LTE'
				 when v.[% WCDMA]=1 then 'WCDMA'
			else 'Mixed' end,
			v.[Longitud Final], v.[Latitud Final]

select cast(avg(case when r.Player like '%v11%' then cast(replace(v.[Video Resolution],'p','')as int)
											   else
													case when cast (left(v.[Video Resolution],3) as int)<= 720 or v.[Video Resolution] is null then cast (left(v.[Video Resolution],3) as int)
													else 720 
													end
												end)
									as varchar(10)) + 'p' 
									 as 'avg video resolution' --B5

	from 
		TestInfo t,
		--@All_Tests a,
		Lcc_Data_YOUTUBE v,
		ResultsVideoStream r
	where	
		--a.Sessionid=t.Sessionid and a.TestId=t.TestId
		t.valid=1
		--and a.Sessionid=v.Sessionid and a.TestId=v.TestId
		and v.Sessionid=r.Sessionid and v.TestId=r.TestId
		and v.typeoftest like '%YouTube%' /*and v.testname like '%HD%'*/
	group by v.MNC



-----Codigo procesado

--/****** Object:  StoredProcedure [dbo].[sp_MDD_Data_NED_Libro_Resumen_KPIs_FY1617_GRID] 
use FY1617_Data_Smaller_3G_H2

	select v.sessionid, v.testid, 
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' end as tech,
		v.[Longitud Final], v.[Latitud Final]

	into #All_Tests 
	from Lcc_Data_YOUTUBE v, lcc_position_Entity_List_Vodafone c
	Where --v.collectionname like @Date + '%' + @ciudad + '%' + @Tech and
		v.info='completed' --DGP 17/09/2015: Filtramos solo los tests marcados como completados
		and v.MNC = 1	--MNC
		and v.MCC= 214						--MCC - Descartamos los valores erróneos
		and c.fileid=v.fileid
		and c.entity_name = 'ALBACETE'
		and c.lonid=master.dbo.fn_lcc_longitude2lonid ([Longitud Final], [Latitud Final])
		and c.latid=master.dbo.fn_lcc_latitude2latid ([Latitud Final])

	group by v.sessionid, v.testid, 
		case when v.[% LTE]=1 then 'LTE'
			 when v.[% WCDMA]=1 then 'WCDMA'
		else 'Mixed' end,
		v.[Longitud Final], v.[Latitud Final]

select cast( avg((case when ytb.Player like '%v11%' then (cast (left(ytb.[Video Resolution],3) as int))
			else
			
				case when cast (left(ytb.[Video Resolution],3) as int)<= 720 or ytb.[Video Resolution] is null then cast (left(ytb.[Video Resolution],3) as int)
				else 720 
				end
			end)

) as varchar(10)) + 'p' as 'YOU TUBE HD - B5 AVG  VIDEO RESOLUTION FOR QUALIFIED VIDEOS'
from 
	TestInfo test,
	#All_Tests t
		LEFT OUTER JOIN Lcc_Data_HTTPTransfer_DL dl		on dl.sessionid=t.sessionid and dl.testid=t.testid
		LEFT OUTER JOIN Lcc_Data_HTTPTransfer_UL ul		on ul.sessionid=t.sessionid and ul.testid=t.testid
		LEFT OUTER JOIN Lcc_Data_HTTPBrowser web	on web.sessionid=t.sessionid and web.testid=t.testid		
		LEFT OUTER JOIN (select y.*, r.player from Lcc_Data_YOUTUBE y, ResultsVideoStream r where y.sessionid=r.sessionid and y.testid=r.testid) ytb	on ytb.sessionid=t.sessionid and ytb.testid=t.testid
		LEFT OUTER JOIN LCC_Data_Latencias lat	on lat.sessionid=t.sessionid and lat.testid=t.testid
		LEFT OUTER JOIN Agrids.dbo.lcc_parcelas lp	on lp.Nombre= master.dbo.fn_lcc_getParcel(t.[Longitud Final], t.[Latitud Final])
where test.SessionId=t.SessionId and test.TestId=t.TestId
	and test.valid=1





