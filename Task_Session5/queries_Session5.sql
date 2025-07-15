-- 1.Write a query that classifies all products into price categories:
-- Products under $300: "Economy"
-- Products $300-$999: "Standard"
-- Products $1000-$2499: "Premium"
-- Products $2500 and above: "Luxury"
select 
   product_name,
   list_price,
   case
       when list_price < 300 then 'Economy'
       when list_price between 300 and 999 then 'Standard'
       when list_price between 1000 and 2499 then 'Premium'
       when list_price > 2500 then 'Luxury'
   end as price_categories
from production.products



-- 2.Create a query that shows order processing information with user-friendly status descriptions:
-- Status 1: "Order Received"
-- Status 2: "In Preparation"
-- Status 3: "Order Cancelled"
-- Status 4: "Order Delivered"
-- Also add a priority level:
    --  Orders with status 1 older than 5 days: "URGENT"
    --  Orders with status 2 older than 3 days: "HIGH"
    --  All other orders: "NORMAL"
select 
   order_status,
   case
       when order_status = 1 then 'Order Received'
       when order_status = 2 then 'In Preparation'
       when order_status = 3 then 'Order Cancelled'
       when order_status = 4 then 'Order Delivered'
   end as order_status_description,
   case
       when order_status = 1 And DATEDIFF(weekday,order_date,GETDATE()) > 5 then 'Urgent'
       when order_status = 2 And DATEDIFF(weekday,order_date,GETDATE()) > 3 then 'High'
       else 'Normal'
   end as PriorityLevel
from sales.orders



-- 3.Write a query that categorizes staff based on the number of orders they've handled:
-- 0 orders: "New Staff"
-- 1-10 orders: "Junior Staff"
-- 11-25 orders: "Senior Staff"
-- 26+ orders: "Expert Staff"
select 
  (s.first_name+' '+s.last_name) as full_name, 
  count(o.order_id) as count_order,
  case
     when count(o.order_id) = 0 then 'New Staff'
     when count(o.order_id) between 1 And 10 then 'Junior Staff'
     when count(o.order_id) between 11 And 25 then 'Senior Staff'
     when count(o.order_id) > 26 then 'Expert Staff'
  end as staff_category
from sales.staffs s
left join sales.orders o on s.staff_id = o.staff_id
group by s.first_name,s.last_name



-- 4.Create a query that handles missing customer contact information:
-- Use ISNULL to replace missing phone numbers with "Phone Not Available"
-- Use COALESCE to create a preferred_contact field (phone first, then email, then "No Contact Method")
-- Show complete customer information
select    
    customer_id,
    first_name +' '+last_name as full_name,
	email,
    ISNULL(phone, 'Phone Not Available') AS phone,
    COALESCE(phone, email, 'No Contact Method') AS preferred_contact
from sales.customers



-- 5.Write a query that safely calculates price per unit in stock:
-- Use NULLIF to prevent division by zero when quantity is 0
-- Use ISNULL to show 0 when no stock exists
-- Include stock status using CASE WHEN
-- Only show products from store_id = 1
select 
    p.product_name,
    s.quantity,
    p.list_price,
  ISNULL(p.list_price / NULLIF(s.quantity, 0), 0) AS price_per_unit,
  case
     when s.quantity = 0 then 'out of stock'
     when s.quantity between 1 AND 50 then 'low stock'
     else 'in stock'
  end as quantity_status
from production.stocks s
inner join production.products p on s.product_id = p.product_id
where s.store_id=1



-- 6.Create a query that formats complete addresses safely: 
-- Use COALESCE for each address component
-- Create a formatted_address field that combines all components
-- Handle missing ZIP codes gracefully
SELECT 
    first_name+' '+last_name as full_name,
    COALESCE(city, '') + ', ' + COALESCE(street, '') + ', ' +
    COALESCE(state, '') + ', ' + COALESCE(zip_code, 'ZIP Not Available') AS formatted_address
FROM sales.customers;



-- 7.Use a CTE to find customers who have spent more than $1,500 total:
-- Create a CTE that calculates total spending per customer
-- Join with customer information
-- Show customer details and spending
-- Order by total_spent descending
WITH customer_spending AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.list_price * (1 - COALESCE(oi.discount, 0))) AS total_spent
    FROM sales.orders  AS o
    JOIN sales.order_items AS oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    c.state,
    cs.total_spent
FROM customer_spending AS cs
JOIN sales.customers   AS c ON c.customer_id = cs.customer_id
WHERE cs.total_spent > 1500          
ORDER BY cs.total_spent DESC;



-- 8.Create a multi-CTE query for category analysis: 
-- CTE 1: Calculate total revenue per category
-- CTE 2: Calculate average order value per category
-- Main query: Combine both CTEs
-- Use CASE to rate performance: >$50000 = "Excellent", >$20000 = "Good", else = "Needs Improvement"
with total_revenues as (
    select c.category_id,c.category_name,SUM(o.quantity * o.list_price * (1 - o.discount)) AS total_revenue
	from production.categories c
	inner join production.products p on c.category_id = p.category_id
	inner join sales.order_items o on o.product_id = p.product_id
	group by c.category_id,c.category_name
),
 avg_order as (
    select c.category_id,c.category_name,Avg(o.order_id) AS Average_order
	from production.categories c
	inner join production.products p on c.category_id = p.category_id
	inner join sales.order_items oi on oi.product_id = p.category_id
	inner join sales.orders o on o.order_id = oi.order_id
	group by c.category_id,c.category_name
)

SELECT 
    tr.category_name,
    tr.total_revenue,
    CASE 
        WHEN tr.total_revenue > 50000 THEN 'Excellent'
        WHEN tr.total_revenue > 20000 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS performance_rating

FROM total_revenues AS tr
JOIN avg_order AS ao ON tr.category_id = ao.category_id
ORDER BY tr.total_revenue DESC;



-- 9.Use CTEs to analyze monthly sales trends: 
-- CTE 1: Calculate monthly sales totals
-- CTE 2: Add previous month comparison
-- Show growth percentage
WITH total_monthly_sales AS (
    SELECT 
        FORMAT(order_date, 'yyyy-MM') AS year_month,
        SUM(oi.quantity * oi.list_price * (1 - ISNULL(oi.discount, 0))) AS total_sales,
        FORMAT(DATEADD(MONTH, -1, FORMAT(order_date, 'yyyy-MM-01')), 'yyyy-MM') AS prev_month
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY FORMAT(order_date, 'yyyy-MM'), FORMAT(order_date, 'yyyy-MM-01')
),
sales_with_prev AS (
    SELECT 
        curr.year_month,
        curr.total_sales,
        prev.total_sales AS prev_month_sales
    FROM total_monthly_sales curr
    LEFT JOIN total_monthly_sales prev
        ON curr.prev_month = prev.year_month
)
SELECT 
    year_month,
    total_sales,
    prev_month_sales,
    CASE 
        WHEN prev_month_sales IS NULL THEN NULL
        WHEN prev_month_sales = 0 THEN NULL
        ELSE ROUND(((total_sales - prev_month_sales) * 100.0) / prev_month_sales, 2)
    END AS growth_percent
FROM sales_with_prev
ORDER BY year_month;



-- 10.Create a query that ranks products within each category: 
-- Use ROW_NUMBER() to rank by price (highest first)
-- Use RANK() to handle ties
-- Use DENSE_RANK() for continuous ranking
-- Only show top 3 products per category
select top 3
    category_name,
    product_name,
	list_price,
    ROW_NUMBER() over (partition by c.category_id order by p.list_price desc),
    RANK() over (partition by c.category_id order by p.list_price desc),
    DENSE_RANK() over (partition by c.category_id order by p.list_price desc)
from production.categories c
inner join production.products p on c.category_id = p.category_id



-- 11.Rank customers by their total spending:
-- Calculate total spending per customer
-- Use RANK() for customer ranking
-- Use NTILE(5) to divide into 5 spending groups
-- Use CASE for tiers: 1="VIP", 2="Gold", 3="Silver", 4="Bronze", 5="Standard"
WITH customer_spending AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
ranked_customers AS (
    SELECT
        cs.customer_id,
        c.first_name + ' ' + c.last_name as full_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank_pos,
        NTILE(5) OVER (ORDER BY cs.total_spent DESC) AS spending_group
    FROM customer_spending cs
    JOIN sales.customers c ON c.customer_id = cs.customer_id
)

SELECT 
    customer_id,
    total_spent,
    rank_pos,
    spending_group,
    CASE spending_group
        WHEN 1 THEN 'VIP'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze'
        ELSE 'Standard'
    END AS tier

FROM ranked_customers




-- 12.Create a comprehensive store performance ranking:
-- Rank stores by total revenue
-- Rank stores by number of orders
-- Use PERCENT_RANK() to show percentile performance
WITH store_revenue AS (
    SELECT 
        s.store_id,
        s.store_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM sales.stores s
    JOIN sales.staffs ss ON s.store_id = ss.store_id
    JOIN sales.orders o ON ss.staff_id = o.staff_id
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY s.store_id, s.store_name
),
ranked_stores AS (
    SELECT
        store_id,
        store_name,
        total_revenue,
        total_orders,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY total_orders DESC) AS order_count_rank,
        PERCENT_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_percentile
    FROM store_revenue
)

SELECT *
FROM ranked_stores
ORDER BY total_revenue DESC;




-- 13.Create a PIVOT table showing product counts by category and brand:
-- Rows: Categories
-- Columns: Top 4 brands (Electra, Haro, Trek, Surly)
-- Values: Count of products
select top 4 *
from (
   select c.category_name,b.brand_name
   from production.categories as c
   inner join production.products as p on p.category_id = c.category_id
   inner join production.brands as b on p.brand_id = b.brand_id
   WHERE b.brand_name IN ('Electra', 'Haro', 'Trek', 'Surly')
) as source_table
pivot (
    COUNT(brand_name)
    FOR brand_name IN ([Electra], [Haro], [Trek], [Surly])
)  AS PivotTable
ORDER BY category_name;



-- 14.Create a PIVOT showing monthly sales revenue by store:
-- Rows: Store names
-- Columns: Months (Jan through Dec)
-- Values: Total revenue
-- Add a total column

select *
from (
   select 
        s.store_name,
		LEFT(DATENAME(MONTH, o.order_date), 3) AS month_name, 
        MONTH(o.order_date) AS month_number,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
   from sales.stores s
   inner join sales.orders o on s.store_id = o.store_id
   inner join sales.order_items oi on o.order_id = oi.order_id
   GROUP BY s.store_name, MONTH(o.order_date), DATENAME(MONTH, o.order_date)
) as source_table
pivot (
    SUM(total_revenue)
    FOR month_name in ([Jan], [Feb], [Mar], [Apr], [May], [Jun],
                         [Jul], [Aug], [Sep], [Oct], [Nov], [Dec])
) AS PivotTable
order by month_number



-- 15.PIVOT order statuses across stores:
-- Rows: Store names
-- Columns: Order statuses (Pending, Processing, Completed, Rejected)
-- Values: Count of orders
select * 
from (
   select store_name,order_status,
   case order_status
      when 1 then 'Pending'
      when 2 then 'Processing'
      when 3 then 'Completed'
      when 4 then 'Rejected'
   end as status
   from sales.orders o
   inner join sales.staffs ss on o.staff_id = ss.staff_id
   inner join sales.stores s on s.store_id = ss.store_id
) as source_table
pivot (
    count(status)
    FOR status in ([Pending], [Processing], [Completed], [Rejected])
) AS PivotTable
ORDER BY store_name;



-- 16.Create a PIVOT comparing sales across years:
-- Rows: Brand names
-- Columns: Years (2016, 2017, 2018)
-- Values: Total revenue
-- Include percentage growth calculations
SELECT *
FROM (
    SELECT 
        b.brand_name,
        YEAR(o.order_date) AS sales_year,
        (oi.quantity * oi.list_price * (1 - COALESCE(oi.discount, 0))) AS revenue
    FROM production.brands b
    JOIN production.products p ON b.brand_id = p.brand_id
    JOIN sales.order_items oi ON p.product_id = oi.product_id
    JOIN sales.orders o ON o.order_id = oi.order_id
) AS source_table
PIVOT (
    SUM(revenue)
    FOR sales_year IN ([2016], [2017], [2018])
) AS PivotTable
ORDER BY brand_name;



-- 17.Use UNION to combine different product availability statuses:
-- Query 1: In-stock products (quantity > 0)
-- Query 2: Out-of-stock products (quantity = 0 or NULL)
-- Query 3: Discontinued products (not in stocks table)
SELECT 
    p.product_id,
    p.product_name,
    'In Stock' AS availability_status
FROM production.products p
JOIN production.stocks s ON p.product_id = s.product_id
WHERE s.quantity > 0
UNION
SELECT 
    p.product_id,
    p.product_name,
    'Out of Stock' AS availability_status
FROM production.products p
JOIN production.stocks s ON p.product_id = s.product_id
WHERE s.quantity = 0 OR s.quantity IS NULL
UNION
SELECT 
    p.product_id,
    p.product_name,
    'Discontinued' AS availability_status
FROM production.products p
WHERE Not EXISTS (
    SELECT * FROM production.stocks s WHERE s.product_id = p.product_id
)
ORDER BY product_id;



-- 18.Use INTERSECT to find loyal customers:
-- Find customers who bought in both 2017 AND 2018
-- Show their purchase patterns
SELECT  c.customer_id, c.first_name+ ' '+c.last_name as full_name
FROM sales.customers c
WHERE c.customer_id IN (
    SELECT customer_id
    FROM sales.orders
    WHERE YEAR(order_date) = 2017

    INTERSECT

    SELECT customer_id
    FROM sales.orders
    WHERE YEAR(order_date) = 2018
)
ORDER BY c.customer_id;



-- 19.Use multiple set operators to analyze product distribution:
-- INTERSECT: Products available in all 3 stores
SELECT  p.product_id, p.product_name, 'In All Stores' AS store_status      
FROM production.stocks s1
JOIN production.products p ON p.product_id = s1.product_id
WHERE s1.store_id = 1 
INTERSECT
SELECT  p.product_id, p.product_name, 'In All Stores' AS store_status
FROM production.stocks s2
JOIN production.products p ON p.product_id = s2.product_id
WHERE s2.store_id = 2 
INTERSECT
SELECT  p.product_id, p.product_name, 'In All Stores' AS store_status
FROM production.stocks s3
JOIN production.products p ON p.product_id = s3.product_id
WHERE s3.store_id = 3
-- EXCEPT: Products available in store 1 but not in store 2
SELECT  p.product_id, 'Only in Store 1' AS store_status      
FROM production.stocks s1
JOIN production.products p ON p.product_id = s1.product_id
WHERE s1.store_id = 1 
EXCEPT
SELECT  p.product_id, 'Only in Store 2' AS store_status
FROM production.stocks s2
JOIN production.products p ON p.product_id = s2.product_id
WHERE s2.store_id = 2 
-- UNION: Combine above results with different labels
UNION
SELECT DISTINCT product_id, 'All Combined' AS status
FROM production.products;



-- 20.Complex set operations for customer retention:
-- Use UNION ALL to combine all three groups
-- Find customers who bought in 2016 but not in 2017 (lost customers)
SELECT DISTINCT customer_id, 'Lost customers' AS customer_status
FROM sales.orders
WHERE YEAR(order_date) = 2016
EXCEPT
SELECT DISTINCT customer_id, 'Lost customers' AS customer_status
FROM sales.orders
WHERE YEAR(order_date) = 2017
-- Find customers who bought in 2017 but not in 2016 (new customers)
UNION ALL
SELECT DISTINCT customer_id, 'New customers' AS customer_status
FROM sales.orders
WHERE YEAR(order_date) = 2017
EXCEPT
SELECT DISTINCT customer_id, 'New customers' AS customer_status
FROM sales.orders
WHERE YEAR(order_date) = 2016
-- Find customers who bought in both years (retained customers)
UNION ALL
SELECT DISTINCT customer_id, 'Retained' AS customer_status
FROM sales.orders
WHERE YEAR(order_date) = 2016
INTERSECT
SELECT DISTINCT customer_id, 'Retained' AS customer_status
FROM sales.orders
WHERE YEAR(order_date) = 2017;
