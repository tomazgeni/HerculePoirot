/*

 Osamelci (eng. outliers)
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





SELECT  
count(*) AS nof
,avginvoice
FROM  dbo.TK_tmp_CustomerAtributes_delavnica
group by avginvoice
order by 2


--- kvartili
 SELECT DISTINCT
percentile_disc(0.75) within group (order by avginvoice) over() as ThirdQuartile,
percentile_disc(0.25) within group (order by avginvoice) over() as FirstQuartile
FROM TK_tmp_CustomerAtributes_delavnica


-- median
SELECT 
	DISTINCT Median = PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY avginvoice) OVER ()
FROM TK_tmp_CustomerAtributes_delavnica;


-- finding Outliers:
SELECT
        OutlierPoint = (max(ThirdQuartile) - max(FirstQuartile)) * 1.5 + max(ThirdQuartile)
FROM
        (
			 SELECT DISTINCT
				percentile_disc(0.75) within group (order by avginvoice) over() as ThirdQuartile,
				percentile_disc(0.25) within group (order by avginvoice) over() as FirstQuartile
			FROM TK_tmp_CustomerAtributes_delavnica
) quartiles


-- SELECTing Outliers:
SELECT * FROM TK_tmp_CustomerAtributes_delavnica
WHERE
	avginvoice >= 138



---Check data with R -- brez: na.rm=TRUE
EXEC sp_execute_external_script
	@language = N'R'
   ,@script = N'df <- InputDataSet
				OutputDataSet <- data.frame(m=median(df$inv))'
   ,@input_data_1 = N'SELECT CAST(avginvoice AS INT) as inv FROM TK_tmp_CustomerAtributes_delavnica'
WITH RESULT SETS
((
	median NUMERIC(16,3)
))


---Check data with R -- adding na.rm=TRUE
EXEC sp_execute_external_script
	@language = N'R'
   ,@script = N'df <- InputDataSet
				OutputDataSet <- data.frame(m=median(df$inv, na.rm=TRUE))'
   ,@input_data_1 = N'SELECT CAST(avginvoice AS INT) as inv FROM TK_tmp_CustomerAtributes_delavnica'
WITH RESULT SETS
((
median NUMERIC(16,3)
))
	


-- this mean we have NULL values in avginvoice in our dataset
SELECT * FROM TK_tmp_CustomerAtributes_delavnica
WHERE
	avginvoice IS NULL



--- NULL VALUES

-- povpreèje
SELECT 
	 AVG(avginvoice) AS AVG_function
	,SUM(avginvoice)/COUNT(*) AS AVG_manually
FROM 
	TK_tmp_CustomerAtributes_delavnica

-- avg will be the same if we eliminate the null values (per se)
SELECT 
	 AVG(avginvoice) AS AVG_function
	,SUM(avginvoice)/COUNT(*) AS AVG_manually
FROM 
	TK_tmp_CustomerAtributes_delavnica
WHERE
	avginvoice IS NOT NULL

-- assume we want to calculate Mode:

-- mode
EXEC sp_execute_external_script
	@language = N'R'
   ,@script = N'df <- InputDataSet
			# Create the function.
			getmode <- function(v) {
			   uniqv <- unique(v)
			   uniqv[which.max(tabulate(match(v, uniqv)))]
									}
				OutputDataSet <- data.frame(getmode(df$inv))'
   ,@input_data_1 = N'SELECT CAST(avginvoice AS INT) as inv FROM TK_tmp_CustomerAtributes_delavnica'
WITH RESULT SETS
((
mode INT
))

-- ha ha... NULL value is mode:
SELECT 
	COUNT(*) AS nof
	,CAST(avginvoice AS INT) as inv 

FROM TK_tmp_CustomerAtributes_delavnica
GROUP BY CAST(avginvoice AS INT)
ORDER BY nof DESC

-- if we eliminate NULL values, the mode should be: 41
EXEC sp_execute_external_script
	@language = N'R'
   ,@script = N'df <- InputDataSet
			# Create the function.
			getmode <- function(v) {
			   uniqv <- unique(v)
			   uniqv[which.max(tabulate(match(v, uniqv)))]
									}
				OutputDataSet <- data.frame(getmode(df$inv))'
   ,@input_data_1 = N'SELECT CAST(avginvoice AS INT) as inv FROM TK_tmp_CustomerAtributes_delavnica WHERE avginvoice IS NOT NULL'
	---- -------------------------------------------------------------------------------------------^ added WHERE clause
WITH RESULT SETS
((
mode INT
))



----------------------------------
---------- GETTING STATISTICS
----------------------------------

EXEC sp_execute_external_script
	@language = N'R'
   ,@script = N'df <- InputDataSet
			library(dplyr)
			df2<- df %>%
				summarise(
						   mean=mean(inv)
						  ,sd=sd(inv)
						  ,median=median(inv)
						  ,min=min(inv)
						  ,max=max(inv)
						  ,var=var(inv)
						  ,mode=mode(inv)
						  ,n = n()
						  ,total = sum(inv)
						  ,P25=quantile(inv, probs=0.25)
						 ,P50=quantile(inv, probs=0.5)
						 ,P75=quantile(inv, probs=0.75)
						 ,avg=mean(inv)
						  )
				OutputDataSet <- data.frame(df2)'
   ,@input_data_1 = N'SELECT CAST(avginvoice AS INT) as inv FROM TK_tmp_CustomerAtributes_delavnica WHERE avginvoice IS NOT NULL'
	---- -------------------------------------------------------------------------------------------^ added WHERE clause
WITH RESULT SETS
((
 mean NVARCHAR(100)
,sd NVARCHAR(100)
,median NVARCHAR(100)
,min NVARCHAR(100)
,max NVARCHAR(100)
,var NVARCHAR(100)
,mode NVARCHAR(100)
,nof_rows NVARCHAR(100)
,sum_total NVARCHAR(100)
,P25 NVARCHAR(100)
,P50 NVARCHAR(100)
,P75 NVARCHAR(100)
,avg NVARCHAR(100)
))


--- PARAMETRIZATION

CREATE OR ALTER PROCEDURE dbo.Descriptive_Stats
(
	 @TableName NVARCHAR(100)
	,@ColumnName NVARCHAR(100)
)
AS
BEGIN

DECLARE @Rcode NVARCHAR(MAX)
SET @Rcode = N'df <- InputDataSet
			library(dplyr)
			df2<- df %>%
				summarise(
						   mean=mean(inv)
						  ,sd=sd(inv)
						  ,median=median(inv)
						  ,min=min(inv)
						  ,max=max(inv)
						  ,var=var(inv)
						  ,mode=mode(inv)
						  ,n = n()
						  ,total = sum(inv)
						  ,P25=quantile(inv, probs=0.25)
						 ,P50=quantile(inv, probs=0.5)
						 ,P75=quantile(inv, probs=0.75)
						 ,avg=mean(inv, na.rm=TRUE)
						  )
				OutputDataSet <- data.frame(df2)'

DECLARE @TSQLcode NVARCHAR(MAX)
SET @TSQLcode = N'SELECT CAST('+CAST(@ColumnName AS NVARCHAR(100))+' AS INT) as inv FROM '+@TableName+' WHERE '+CAST(@ColumnName AS VARCHAR(100))+' IS NOT NULL '
PRINT @TSQLcode

EXEC sp_execute_external_script
	@language = N'R'
   ,@script = @Rcode
   ,@input_data_1 = @TSQLCode
	
WITH RESULT SETS
((
 mean NVARCHAR(100)
,sd NVARCHAR(100)
,median NVARCHAR(100)
,min NVARCHAR(100)
,max NVARCHAR(100)
,var NVARCHAR(100)
,mode NVARCHAR(100)
,nof_rows NVARCHAR(100)
,sum_total NVARCHAR(100)
,P25 NVARCHAR(100)
,P50 NVARCHAR(100)
,P75 NVARCHAR(100)
,avg NVARCHAR(100)
))

END
GO


SELECT top 10 * FROM TK_tmp_CustomerAtributes_delavnica



EXEC dbo.Descriptive_Stats
	 @TableName = N'TK_tmp_CustomerAtributes_delavnica'
	,@ColumnName = N'quantity'



EXEC dbo.Descriptive_Stats
	 @TableName = N'TK_tmp_CustomerAtributes_delavnica'
	,@ColumnName = N'avgprodajnacena'


EXEC dbo.Descriptive_Stats
	 @TableName = N'TK_tmp_CustomerAtributes_delavnica'
	,@ColumnName = N'amount'


EXEC dbo.Descriptive_Stats
	 @TableName = N'TK_tmp_CustomerAtributes_delavnica'
	,@ColumnName = N'subvencij'