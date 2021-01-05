select * from DIM_Customer
select * from DIM_Location
select * from DIM_Manufacturer
select * from DIM_Model
Select * from Fact_Transactions
select * from DIM_date

--Q1: List all the states in which we have customers who have bought cellphones from 2005 till today
select 
T1.IDLocation,
L1.State
from Fact_Transactions as T1
inner join DIM_Location as L1 
on T1.IDlocation=L1.IDlocation 
where year(T1.date)>='2005' 
group by T1.IDLocation, 
L1.State

--Q2: What state in the US is buying more 'Samsung' cell phones?
select Top 1 L1.State, sum(FT1.Quantity) as Qty, M2.Manufacturer_Name from FACT_TRANSACTIONS as FT1 
inner join DIM_LOCATION as L1
on FT1.IDLocation=L1.IDLocation
inner join DIM_MODEL as M1
on FT1.IDModel=M1.IDModel
inner join DIM_MANUFACTURER M2
on M1.IDManufacturer=M2.IDManufacturer
where M2.Manufacturer_Name= 'Samsung' and L1.country='US'
group by L1.State, M2.Manufacturer_Name
order by sum(FT1.quantity) DESC



--Q3: show the number of transactions for each model per zip code per state
select L1.state, L1.ZipCode, T1.IDModel, count(IDmodel) as No_of_transactions from FACT_TRANSACTIONS as T1 
inner join Dim_Location as L1 
on T1.IDlocation=L1.IDlocation 
group by L1.state, L1.ZipCode, T1.IDModel
order by T1.IDModel


--Q4: show the cheapest cell phone
select Top 1 IDModel, Model_Name, Unit_price, M2.Manufacturer_Name from DIM_MODEL as M1
inner join DIM_MANUFACTURER as M2
on M1.IDManufacturer=M2.IDManufacturer
order by Unit_price


--Q5: find out the average price for each model in the top 5 manufacturers in terms of sales quantity and order by avg price
select Top 5 m2.Manufacturer_Name, 
round(avg(totalprice),2) as Avg_Price,
sum(t1.Quantity) as Sales_Qty
from FACT_TRANSACTIONS as T1
inner join DIM_MODEL as M1
on T1.IDModel=M1.IDModel
inner join DIM_MANUFACTURER as M2
on M1.IDManufacturer=M2.IDManufacturer
group by m2.Manufacturer_Name 
order by sales_Qty desc


--Q6: list the names of the customers and the average amount spent in 2009 where the average is higher than 500
select C1.IDCustomer, C1.Customer_Name, avg(FT1.TotalPrice) from DIM_CUSTOMER as C1  
inner join FACT_TRANSACTIONS as FT1
on C1.IDCustomer=FT1.IDCustomer
where year (FT1.Date)='2009'
group by C1.Customer_Name, c1.IDCustomer
having avg(FT1.TotalPrice) > 500


--Q7: list if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010
select * from 
(select top 5 idmodel from FACT_TRANSACTIONS where year(date)= '2008' group by idmodel order by sum(quantity) desc 
 intersect
select top 5 idmodel from FACT_TRANSACTIONS where year(date)= '2009' group by idmodel order by sum(quantity) desc 
 intersect
select top 5 idmodel from FACT_TRANSACTIONS where year(date)='2010' group by idmodel order by sum(quantity) desc) as a1


--Q8: show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010
SELECT  top 1 *
 from
    (SELECT 
    TOP 2 Manufacturer_name,
    SUM(Quantity )  TQ1
    FROM Fact_Transactions T1
    LEFT JOIN DIM_Model D1 
	ON T1.IDModel = D1.IDModel
    LEFT JOIN DIM_MANUFACTURER D2  
	ON D2.IDManufacturer = D1.IDManufacturer
    Where DATEPART(Year,date)='2009' 
    group by Manufacturer_name, Quantity 
    Order by  SUM(Quantity ) DESC ) as A,


        (SELECT 
    Top 2 Manufacturer_name,
     SUM(Quantity ) TQ2
    FROM Fact_Transactions T2
    LEFT JOIN DIM_Model DM 
	ON T2.IDModel = DM.IDModel
    LEFT JOIN DIM_MANUFACTURER DM2  
	ON DM2.IDManufacturer = DM.IDManufacturer
    Where DATEPART(Year,date)='2010' 
    group by Manufacturer_name,Quantity
    Order by  SUM(Quantity )DESC ) as B


--Q9: show the manufacturers that sold cellphone in 2010 but didn't in 2009
select m.*
from DIM_MANUFACTURER m
where exists (select mo.IDManufacturer, FT1.IDModel
              from FACT_TRANSACTIONS FT1 join
                   DIM_MODEL mo
				   on FT1.IDModel = mo.IDModel 
				   where year (FT1.Date) = '2010'
             ) OR
      not exists (select mo.IDManufacturer, FT1.IDModel
                  from FACT_TRANSACTIONS FT1 join
                   DIM_MODEL mo
				   on FT1.IDModel = mo.IDModel 
				   where year (FT1.Date) = '2009'
                 ) 

--Q10: find the top 100 customers and their average spend and average quantity by each year and also the %age of change in their spend

 SELECT 
  top 100 T1.Customer_Name, T1.Year, T1.Avg_Price,T1.Avg_Qty,
    CASE
        WHEN T2.Year IS NOT NULL
        THEN FORMAT(CONVERT(DECIMAL(8,2),(T1.Avg_Price-T2.Avg_Price))/CONVERT(DECIMAL(8,2),T2.Avg_Price),'p') ELSE NULL 
        END AS 'YEARLY_%_CHANGE'
    FROM
        (SELECT t2.Customer_Name, YEAR(t1.DATE) AS YEAR, AVG(t1.TotalPrice) AS Avg_Price, AVG(t1.Quantity) AS Avg_Qty FROM FACT_TRANSACTIONS AS t1 
        left join DIM_CUSTOMER as t2 ON t1.IDCustomer=t2.IDCustomer
        where t1.IDCustomer in (select top 100 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by SUM(TotalPrice) desc)
        group by t2.Customer_Name, YEAR(t1.Date)
        )T1
    left join
        (SELECT t2.Customer_Name, YEAR(t1.DATE) AS YEAR, AVG(t1.TotalPrice) AS Avg_Price, AVG(t1.Quantity) AS Avg_Qty FROM FACT_TRANSACTIONS AS t1 
        left join DIM_CUSTOMER as t2 ON t1.IDCustomer=t2.IDCustomer
        where t1.IDCustomer in (select top 100 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by SUM(TotalPrice) desc)
        group by t2.Customer_Name, YEAR(t1.Date)
        )T2
        on T1.Customer_Name=T2.Customer_Name and T2.YEAR=T1.YEAR-1 