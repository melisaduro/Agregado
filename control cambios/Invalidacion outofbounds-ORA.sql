use FY1617_Data_Rest_4G_H1

select t.invalidReason, count(collectionname) as attemps, t.valid--, testname--, right(left(imsi,5),2) as operador
	from filelist f, sessions s, testinfo t
	where f.fileid=s.fileid and s.sessionid=t.sessionid
	and t.invalidReason like 'LCC OutOfBounds%'
	and collectionname like '%yaiza%'
	and testname not like 'YouTube SD'
	--and testname not like 'HTTP BrowserEbay'
	--and testname not like 'HTTP BrowserGoogle'
	--and testname not like 'HTTP BrowserYoutube'
	--and testname not like 'HTTP BrowserElPais'
	--and testname not like 'PingPayload'
group by t.invalidReason, t.valid--, testname--, imsi

use FY1617_Data_Rest_3G_H1

select t.invalidReason, count(collectionname) as attemps, t.valid--, right(left(imsi,5),2) as operador
	from filelist f, sessions s, testinfo t
	where f.fileid=s.fileid and s.sessionid=t.sessionid
	--and t.invalidReason like 'LCC OutOfBounds%ORA'
	and collectionname like '%sancristobal%'
	and testname not like 'YouTube SD'
	and t.valid=0
	and t.invalidReason like 'LCC%'

group by t.invalidReason, t.valid--, imsi


select *--count(collectionname) as attemps, right(left(imsi,5),2) as operador
	from filelist f, sessions s, testinfo t
	where f.fileid=s.fileid and s.sessionid=t.sessionid
	and collectionname like '%TIAS%'
	and testname ='HTTP TransferGET500M'
	and t.invalidReason like 'LCC OutOfBounds%ORA'
	and right(left(imsi,5),2)=3
group by collectionname, imsi