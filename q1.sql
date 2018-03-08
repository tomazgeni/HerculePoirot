/*

 Osamelci
,null vrednosti
,triki za pohitritev priprave podatkov
,normalizacija podatkov
,preverjanje korelacij

*/


----------------------
---
---tabela atributi
---
----------------------
SELECT TOP 10000
	 avginvoice
	,quantity
	,amount
	,avgprodajnacena
	,subvencij
	,zneseksubvencij
	,invoicingchannelname
	,utilitytype
	,pricelist
	,numberofmonths
	,startdate
	,zamuda
	,predplacilo
	,accountnum
	,opozorilaeposta
	,sonceogled
INTO dbo.TK_tmp_CustomerAtributes_delavnica
FROM  dbo.tmp_CustomerAtributes
-- (10000 rows affected)





SELECT
count(*) AS nof
,subvencij
FROM  dbo.tmp_CustomerAtributes
group by subvencij
order by 2


SELECT
count(*) AS nof
,opozorilaeposta
FROM  dbo.tmp_CustomerAtributes
group by opozorilaeposta
order by 2



SELECT
count(*) AS nof
,sonceogled
FROM  dbo.tmp_CustomerAtributes
group by sonceogled
order by 2

SELECT  
count(*) AS nof
,utilitytype
FROM  dbo.tmp_CustomerAtributes
group by utilitytype
order by 2


SELECT  
count(*) AS nof
,numberofmonths
FROM  dbo.tmp_CustomerAtributes
group by numberofmonths
order by 2





-- Outliers:

Create table #SetWithOutliers (Amount int);
Insert into #SetWithOutliers values (1),(3),(3),(5),(6),(8),(9),(15),(50);
SELECT 
 amount
,replicate('*',amount) as histo
FROM #setwithoutliers;

Declare @OutlierPoint int;
       SELECT
              @OutlierPoint = (max(ThirdQuartile) - max(FirstQuartile)) * 1.5 + max(ThirdQuartile)
       FROM
              (
              SELECT
                     percentile_disc(0.75) within group (order by Amount) over() as ThirdQuartile,
                     percentile_disc(0.25) within group (order by Amount) over() as FirstQuartile
              FROM #SetWithOutliers
       ) quartiles
SELECT * FROM #SetWithOutliers 
WHERE amount > @OutlierPoint;

DROP TABLE #SetWithOutliers;
GO


