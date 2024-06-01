#CODEBASICS SQL PROJECT 

#Task 1
 
SELECT 
market
FROM gdb0041.dim_customer 
where customer ="Atliq Exclusive" and region ="APAC";

#Task 2
 
with cte1 as 
( 
SELECT count(distinct p.product_code) as unique_products_2020
 FROM dim_product p
 cross join fact_sales_monthly s 
 on p.product_code=s.product_code 
 where fiscal_year= "2020" ),
 cte2  as (SELECT count(distinct p.product_code) as unique_products_2021
 FROM dim_product p
 cross join fact_sales_monthly s 
 on p.product_code=s.product_code
 where fiscal_year= "2021" )
 select 
 unique_products_2020,
 unique_products_2021,
round(((unique_products_2021 - unique_products_2020) / unique_products_2020) * 100,2) as percentage_chg
 from cte1,cte2;

 #Task 3
  
 SELECT distinct segment, count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

#Task 4
 
with cte1 as (SELECT distinct segment, count(distinct p.product_code) as product_count_2020
from dim_product p 
cross join fact_sales_monthly s
on p.product_code=s.product_code
where fiscal_year ="2020"
group by p.segment ),
cte2 as (SELECT distinct segment, count(distinct p.product_code) as product_count_2021
from dim_product p 
cross join fact_sales_monthly s
on p.product_code=s.product_code
where fiscal_year ="2021"
group by p.segment
)
select
cte1.segment,
    cte1.product_count_2020,
    cte2.product_count_2021,
    (cte2.product_count_2021 - cte1.product_count_2020) AS difference
FROM
    cte1
INNER JOIN
    cte2 ON cte1.segment = cte2.segment
    order by difference desc
    limit 1;

#Task 5
 
SELECT p.product_code, p.product, f.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost f ON p.product_code = f.product_code
WHERE f.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
UNION ALL
SELECT p.product_code, p.product, f.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost f ON p.product_code = f.product_code
WHERE f.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

#Task 6 
 
 SELECT 
    c.customer_code,
    c.customer,
    round(AVG(p.pre_invoice_discount_pct* 100),2) AS average_discount_percentage
FROM 
  dim_customer c
  join fact_pre_invoice_deductions p 
  on c.customer_code=p.customer_code
WHERE 
    p.fiscal_year = 2021
    AND c.market = 'India'
GROUP BY 
    c.customer_code,
    c.customer
ORDER BY 
    average_discount_percentage DESC
LIMIT 5;

#Task 7 
 
SELECT 
    DATE_FORMAT(s.date, '%b') AS Month,
    s.fiscal_year as Year,
SUM(p.gross_price * s.sold_quantity) AS gross_sales_amount
    
FROM fact_sales_monthly s
JOIN fact_gross_price p ON s.product_code = p.product_code
JOIN dim_customer c ON c.customer_code = s.customer_code
WHERE p.fiscal_year = 2020
AND c.customer = 'Atliq Exclusive'
GROUP BY Year, Month;

#Task 8
 
with cte as(
select *,
case
when month(s.date) in (9,10,11) then "Q1"
 when month(s.date) in (12,1,2) then "Q2"
when month(s.date) in (3,4,5) then "Q3"
else "Q4"
end as Quarter
from fact_sales_monthly as s
where fiscal_year=2020
)
select 
 Quarter,
sum(sold_quantity) as total_sold_quantity
from cte
group by Quarter
order by total_sold_quantity desc;
    
 #Task 9
  
   WITH cte1 as(
SELECT c.channel,
       ROUND(SUM(g.gross_price * fs.sold_quantity/1000000), 2) AS Gross_sales_mln
FROM fact_sales_monthly fs
 JOIN dim_customer c 
 ON fs.customer_code = c.customer_code
JOIN fact_gross_price g
ON fs.product_code = g.product_code
WHERE fs.fiscal_year = 2021
GROUP BY channel
) SELECT channel, 
CONCAT(Gross_sales_mln,' M') AS Gross_sales_mln ,
CONCAT(ROUND(Gross_sales_mln*100/total , 2), ' %') AS percentage
FROM
((SELECT SUM(Gross_sales_mln) AS total FROM cte1) A,
(SELECT * FROM cte1) B)
ORDER BY percentage DESC ;

#Task 10
 
WITH cte1 AS (
    SELECT 
        p.division,
        p.product_code,
        p.product,
        SUM(s.sold_quantity) AS total_sold_quantity
    FROM 
        dim_product p
    JOIN 
        fact_sales_monthly s ON p.product_code = s.product_code
    WHERE 
        s.fiscal_year = 2021
    GROUP BY 
        p.division, p.product_code
),
cte2 AS (
    SELECT 
        division,
        product_code,
        product,
        total_sold_quantity,
        RANK() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
    FROM 
        cte1
)
SELECT 
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM 
    cte2
WHERE 
    rank_order <= 3;
