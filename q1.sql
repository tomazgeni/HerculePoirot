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


alter table TK_tmp_CustomerAtributes_delavnica add primary key  (accountnum);
GO
-- error

-- create non nullable column
alter table TK_tmp_CustomerAtributes_delavnica
alter column accountnum nvarchar(20) not null

-- create primary key
alter table TK_tmp_CustomerAtributes_delavnica add primary key  (accountnum);
GO

-- mamo podvojene vrednosti?!
SELECT 
* FROM TK_tmp_CustomerAtributes_delavnica
where accountnum = 'C0001573'

-- naredimo kljuè malo drugaèe
alter table TK_tmp_CustomerAtributes_delavnica add primary key  (accountnum, utilitytype);
GO


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





select t.*,
       (price - avg_price) / nullif(std_price, 0) as z_price
from t join
     (select product, avg(price) as avg_price, stdev(price) as std_price
      from t
      group by product
     ) tt
     on t.product = tt.product
order by abs(z_price) desc;




CREATE OR ALTER PROCEDURE [dbo].[InterquartileRangeSP]
@DatabaseName as nvarchar(128) = NULL, @SchemaName as nvarchar(128), @TableName as nvarchar(128),@ColumnName AS nvarchar(128), @PrimaryKeyName as nvarchar(400), @OrderByCode as tinyint = 1, @DecimalPrecision AS nvarchar(50)
AS
SET @DatabaseName = @DatabaseName + '.'
DECLARE @SchemaAndTableName nvarchar(400)
SET @SchemaAndTableName = ISNull(@DatabaseName, '') + @SchemaName + '.' + @TableName
DECLARE @SQLString nvarchar(max)

SET @SQLString = 'DECLARE @OrderByCode tinyint,
@Count bigint,
@LowerPoint bigint,
@UpperPoint bigint,
@LowerRemainder decimal(38,37), — use the maximum precision and scale for these two variables to make the
procedure flexible enough to handle large datasets; I suppose I could use a float
@UpperRemainder decimal(38,37),
@LowerQuartile decimal(' + @DecimalPrecision + '),
@UpperQuartile decimal(' + @DecimalPrecision + '),
@InterquartileRange decimal(' + @DecimalPrecision + '),
@LowerInnerFence decimal(' + @DecimalPrecision + '),
@UpperInnerFence decimal(' + @DecimalPrecision + '),
@LowerOuterFence decimal(' + @DecimalPrecision + '),
@UpperOuterFence decimal(' + @DecimalPrecision + ') 

SET @OrderByCode = ' + CAST(@OrderByCode AS nvarchar(50)) + ' SELECT @Count=Count(' + @ColumnName + ')
FROM ' + @SchemaAndTableName +
' WHERE ' + @ColumnName + ' IS NOT NULL

SELECT @LowerPoint = (@Count + 1) / 4, @LowerRemainder =  ((CAST(@Count AS decimal(' + @DecimalPrecision + ')) + 1) % 4) /4,
@UpperPoint = ((@Count + 1) *3) / 4, @UpperRemainder =  (((CAST(@Count AS decimal(' + @DecimalPrecision + ')) + 1) *3) % 4) / 4; –multiply by 3 for the left s' + @PrimaryKeyName + 'e on the upper point to get 75 percent

WITH TempCTE
(' + @PrimaryKeyName + ', RN, ' + @ColumnName + ')
AS (SELECT ' + @PrimaryKeyName + ', ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY ' + @ColumnName + ' ASC) AS RN, ' + @ColumnName + '
FROM ' + @SchemaAndTableName + '
WHERE ' + @ColumnName + ' IS NOT NULL),
TempCTE2 (QuartileValue)
AS (SELECT TOP 1 ' + @ColumnName + ' + ((Lead(' + @ColumnName + ', 1) OVER (ORDER BY ' + @ColumnName + ') – ' + @ColumnName + ') * @LowerRemainder) AS QuartileValue
FROM TempCTE
WHERE RN BETWEEN @LowerPoint AND @LowerPoint + 1

UNION

SELECT TOP 1 ' + @ColumnName + ' + ((Lead(' + @ColumnName + ', 1) OVER (ORDER BY ' + @ColumnName + ') – ' + @ColumnName + ') * @UpperRemainder) AS QuartileValue
FROM TempCTE
WHERE RN BETWEEN @UpperPoint AND @UpperPoint + 1)

SELECT @LowerQuartile = (SELECT TOP 1 QuartileValue
FROM TempCTE2 ORDER BY QuartileValue ASC), @UpperQuartile = (SELECT TOP 1 QuartileValue
FROM TempCTE2 ORDER BY QuartileValue DESC)

SELECT @InterquartileRange = @UpperQuartile – @LowerQuartile
SELECT @LowerInnerFence = @LowerQuartile – (1.5 * @InterquartileRange), @UpperInnerFence = @UpperQuartile + (1.5 * @InterquartileRange), @LowerOuterFence = @LowerQuartile – (3 * @InterquartileRange), @UpperOuterFence = @UpperQuartile + (3 * @InterquartileRange)

–SELECT @LowerPoint AS LowerPoint, @LowerRemainder AS LowerRemainder, @UpperPoint AS UpperPoint, @UpperRemainder AS UpperRemainder
— uncomment this line to debug the inner calculations

SELECT @LowerQuartile AS LowerQuartile, @UpperQuartile AS UpperQuartile, @InterquartileRange AS InterQuartileRange,@LowerInnerFence AS LowerInnerFence, @UpperInnerFence AS UpperInnerFence,@LowerOuterFence AS LowerOuterFence, @UpperOuterFence AS UpperOuterFence

SELECT ' + @PrimaryKeyName + ', ' + @ColumnName + ', OutlierDegree
FROM  (SELECT ' + @PrimaryKeyName + ', ' + @ColumnName + ',
       ”OutlierDegree” =  CASE WHEN (' + @ColumnName + ' < @LowerInnerFence AND ' + @ColumnName + ' >= @LowerOuterFence) OR (' +
@ColumnName + ' > @UpperInnerFence
AND ' + @ColumnName + ' <= @UpperOuterFence) THEN 1
       WHEN ' + @ColumnName + ' < @LowerOuterFence OR ' + @ColumnName + ' > @UpperOuterFence THEN 2
       ELSE 0 END
       FROM ' + @SchemaAndTableName + '
       WHERE ' + @ColumnName + ' IS NOT NULL) AS T1
      ORDER BY CASE WHEN @OrderByCode = 1 THEN ' + @PrimaryKeyName + ' END ASC,
CASE WHEN @OrderByCode = 2 THEN ' + @PrimaryKeyName + ' END DESC,
CASE WHEN @OrderByCode = 3 THEN ' + @ColumnName + ' END ASC,
CASE WHEN @OrderByCode = 4 THEN ' + @ColumnName + ' END DESC,
CASE WHEN @OrderByCode = 5 THEN OutlierDegree END ASC,
CASE WHEN @OrderByCode = 6 THEN OutlierDegree END DESC'

--SELECT @SQLString -- uncomment this to debug string errors
EXEC (@SQLString)



EXEC dbo.[InterquartileRangeSP]
			 @DatabaseName = N'BiSandbox'
			,@SchemaName = N'dbo'
			,@TableName = N'TK_tmp_CustomerAtributes_delavnica'
			,@ColumnName = N'numberofmonths'
			,@PrimaryKeyName = N''
			--,@OrderByCode = 6
			--,@DecimalPrecision = N'38,21'