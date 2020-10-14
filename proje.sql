/* INTRODUCTION 
-	You can benefit from the ERD diagram given to you during your work.
-	You have to create a database and import into the given csv files. 
-	During the import process, you will need to adjust the date columns. You need to carefully observe the data types and how they should be.In our database, a star model will be created with one fact table and four dimention tables.
-	The data are not very clean and fully normalized. However, they don't prevent you from performing the given tasks. In some cases you may need to use the string, window, system or date functions.
-	There may be situations where you need to update the tables.
-	Manually verify the accuracy of your analysis.
*/

/*  https://www.youtube.com/watch?v=14FpoXKTEJw
you can watch video via this link, and it helps to import the csv file to sql server.

SECOND WAY
you can create databases, and then you click right on the database name. select the task. click import flat file.
you select the csv file from your browser and then upload the data.
*/


-- THIRD WAY
-- I got some problem when I tried to upload prod_dimen. I uploaded without some columns. I try to code which is below.
-- It works.

create table [dbo].[prod_dimen](
Product_Category nvarchar(50) not null,
Product_Sub_Category nvarchar(50) not null,
Prod_id nvarchar(50) primary key not null
)

CREATE VIEW product_view
as
select Product_Category, Product_Sub_Category, Prod_id from prod_dimen

bulk insert product_view
from 'C:\Users\smdkc\Desktop\clursway\SQL\proje\prod_dimen.csv'
with (firstrow=2,
	fieldterminator = ',',
	rowterminator = '\n',
	batchsize = 250000
	);

select * from [dbo].[prod_dimen]


select * from [dbo].[market_fact]

-- I put primary key and foreign key according to the ERD diagram.
-- you click the tools and then select options and then designers and then table and database designers.
-- you make uncheck the prevent saving changes that require table re-creation. it provides column modify easily.
-- how can modify column? you click table and click right on the column whatever you select. and then click modify. you can change column data type.

alter table [dbo].[market_fact]
add market_id int primary key identity(1,1)

ALTER TABLE [dbo].[market_fact] ADD CONSTRAINT FK_Ship_id FOREIGN KEY ([Ship_id])
      REFERENCES [dbo].[shipping_dimen] 

ALTER TABLE [dbo].[market_fact] ADD CONSTRAINT FK_Ord_id FOREIGN KEY ([Ord_id])
      REFERENCES [dbo].[orders_dimen] 

ALTER TABLE [dbo].[market_fact] ADD CONSTRAINT FK_Cust_id FOREIGN KEY ([Cust_id])
      REFERENCES [dbo].[cust_dimen] 

ALTER TABLE [dbo].[market_fact] ADD CONSTRAINT FK_Prod_id FOREIGN KEY ([Prod_id])
      REFERENCES [dbo].[prod_dimen] 


SELECT *
FROM [dbo].[cust_dimen]

SELECT *
FROM [dbo].[market_fact]


SELECT *
FROM [dbo].[orders_dimen] ORDER BY [Ord_ID] DESC

SELECT *
FROM [dbo].[shipping_dimen] ORDER BY  [Order_ID]

SELECT *
FROM [dbo].[prod_dimen]



/*
Join all the tables and create a new table with all of the columns, called
combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen,
shipping_dimen)
*/

SELECT M.[Ord_id],M.[Prod_id],M.[Ship_id],M.[Cust_id],[Sales],[Discount],[Order_Quantity],[Profit],
[Shipping_Cost],[Product_Base_Margin],
[Customer_Name],[Province],[Region],[Customer_Segment],
[Order_Date],[Order_Priority],
[Product_Category],s.[Order_ID],[Ship_Mode],[Ship_Date]
INTO combined_table
FROM [dbo].[market_fact] M JOIN [dbo].[cust_dimen] C ON M.[Cust_id]=C.Cust_id
	JOIN [dbo].[orders_dimen] O ON M.Ord_id=O.Ord_ID
	JOIN [dbo].[prod_dimen] P ON M.Prod_id=P.Prod_id
	JOIN [dbo].[shipping_dimen] S ON M.Ship_id=S.Ship_id

select * from [dbo].[combined_table]

--Find the top 3 customers who have the maximum count of orders
select top 3 Customer_Name, count(distinct Ord_id) as number_of_orders 
from dbo.combined_table
group by Customer_Name order by 2 desc

/*Create a new column at combined_table as DaysTakenForDelivery that
contains the date difference of Order_Date and Ship_Date.*/
alter table [dbo].[combined_table]
add DaysTakenForDelivery as datediff(day, [Order_Date],[Ship_Date])

--Find the customer whose order took the maximum time to get delivered.
select top 1 Customer_Name, [DaysTakenForDelivery]
from [dbo].[combined_table]
order by 2 desc

select Cust_id, Customer_Name, Order_Date, Ship_Date, DaysTakenForDelivery
from combined_table

select max([DaysTakenForDelivery])
from combined_table

select * from combined_table
where Cust_id = 'Cust_157'

--Retrieve total sales made by each product from the data (use Window function)
select distinct Prod_id, sum(Sales) over (partition by prod_id) total_sales
from combined_table
order by Prod_id
-- 2.way
select distinct Prod_id,  sum(Sales) over (partition by prod_id)
from
combined_table;



--Retrieve total profit made from each product from the data (use function)
SELECT distinct [Prod_id],
SUM([Profit]) OVER(PARTITION BY [Prod_id]) AS 'TOTAL PROFIT BY PRODUCT'
FROM [dbo].[combined_table] ORDER BY 2 DESC



/*Count the total number of unique customers in January and how many of them
came back every month over the entire year in 2011
*/

select count(distinct Cust_id) as unique_customers from combined_table where year(Order_Date) = 2011 AND month(Order_Date) = 01;


SELECT DISTINCT 
Year(Order_date) AS [YEAR], 
Month(Order_date) AS [MONTH], 
count(cust_id) OVER (PARTITION BY month(Order_date) order by month(Order_date)) ASTotal_Unique_Customers 
FROM combined_table 
WHERE year(Order_Date)=2011 
AND cust_id IN 
			(
			SELECT DISTINCT cust_id 
			FROM combined_table 
			WHERE year(Order_Date) = 2011 AND month(Order_Date) = 01
			);








/*
Find month-by-month customer retention ratei since the start of the business
(using views)
*/

/*Create a view where each user’s visits are logged by month, allowing for the
possibility that these will have occurred over multiple years since whenever
business started operations.
*/

create view user_visit as
select cust_id, Count_in_month, convert (date , month + '-01') Month_date
from
(
select Cust_id, SUBSTRING(cast(order_date as varchar), 1,7) as [Month], count(*) count_in_month
from combined_table
group by Cust_id, SUBSTRING(cast(order_date as varchar), 1,7)
) a

select *
from user_visit ;




--Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is


create view Time_lapse_vw as 
select  *, lead(Month_date) over (partition by cust_id order by Month_date) as Next_month_Visit
from user_visit; 


select * from time_lapse_vw;


--Calculate the time gaps between visits.

create view  time_gap_vw as 
select *, datediff ( month, Month_date, Next_month_Visit) as Time_gap 
from time_lapse_vw;

select * from time_gap_vw


--Categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned.

create view Customer_value_vw as 

select distinct cust_id, Average_time_gap,
case 
	when Average_time_gap<=1 then 'Retained'
    when Average_time_gap>1 then 'Irregular'
    when Average_time_gap is null then 'Churned'
    else 'Unknown data'
end  as  Customer_Value
from 
(
select cust_id, avg([Time_gap]) over(partition by cust_id) as Average_time_gap
from 
[dbo].[time_gap_vw]
) t;


select * from customer_value_vw;



select * from time_gap_vw
where
cust_id='Cust_1288';


select * from time_gap_vw





--Calculate the retention month wise.

create view retention_vw as 

select distinct next_month_visit as Retention_month,

sum(time_gap) over (partition by next_month_visit) as Retention_Sum_monthly

from time_gap_vw 
where time_gap<=1
--order by Retention_Sum_monthly desc;


select * from retention_vw;
