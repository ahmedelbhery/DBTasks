-- 1. Count the total number of products in the database.
select count(*) as total_number
from production.products



--2. Find the average, minimum, and maximum price of all products.
select 
  AVG(list_price) as average,
  MIN(list_price) as minimum,
  MAX(list_price) as maximum
from production.products



--3. Count how many products are in each category.
select 
  c.category_name,
  count(p.product_id) as products_total_number
from production.products p
inner join production.categories c on p.category_id = c.category_id
group by c.category_name



--4. Find the total number of orders for each store.
select s.store_name, COUNT(o.order_id) as order_count
from sales.orders o
inner join sales.stores s on o.store_id = s.store_id
group by store_name



--5. Show customer first names in UPPERCASE and last names in lowercase for the first 10 customers.
select top 10 
  Upper(first_name) as FirstName,
  Lower(last_name) as LastName
from sales.customers



--6. Get the length of each product name. Show product name and its length for the first 10 products.
select top 10 
  product_name,
  Len(product_name) as FirstName
from production.products



--7. Format customer phone numbers to show only the area code (first 3 digits) for customers 1-15.
select Left(phone,3) AS area_code
from sales.customers
where customer_id between 1 and 15



--8. Show the current date and extract the year and month from order dates for orders 1-10.
select 
  getDate()  AS currentDate,
  YEAR(order_date) AS order_year,
  MONTH(order_date) AS order_month
from sales.orders
where customer_id between 1 and 10



--9. Join products with their categories. Show product name and category name for first 10 products.
select top 10
  p.product_name,
  c.category_name
from production.products p
inner join production.categories c on p.category_id = c.category_id



--10. Join customers with their orders. Show customer name and order date for first 10 orders.
select top 10
  c.first_name + ' ' + c.last_name AS customer_name,
  o.order_date
from sales.customers c
inner join sales.orders o on o.customer_id = c.customer_id


--11. Show all products with their brand names, even if some products don't have brands. Include product name, brand name (show 'No Brand' if null).
select p.product_id,p.product_name,
       coalesce(b.brand_name,'No Brand')  AS brand_name
from production.products p
left join production.brands b on p.brand_id = b.brand_id



--12. Find products that cost more than the average product price. Show product name and price.
select product_name,list_price
from production.products
where list_price > (select AVG(list_price) from production.products)



--13. Find customers who have placed at least one order. Use a subquery with IN. Show customer_id and customer_name.
select c.customer_id , c.first_name + ' ' + c.last_name AS customer_name
from sales.customers c
where customer_id in (
      select customer_id
	  from sales.orders 
)



--14. For each customer, show their name and total number of orders using a subquery in the SELECT clause.
select
    first_name + ' ' + last_name AS customer_name,
    (
        SELECT COUNT(*) 
        FROM sales.orders o 
        WHERE o.customer_id = c.customer_id
    ) AS total_orders
from sales.customers c;



--15. Create a simple view called easy_product_list that shows product name, category name, and price. Then write a query to select all products from this view where price > 100.
create view easy_product_list 
as 
select p.product_name, c.category_name ,list_price
from production.products p
join production.categories c on p.category_id = c.category_id

select *
from easy_product_list
where list_price>100



--16. Create a view called customer_info that shows customer ID, full name (first + last), email, and city and state combined. Then use this view to find all customers from California (CA).
create view customer_info 
as 
select 
  c.customer_id,
  c.first_name + ' ' + c.last_name AS customer_name,
  c.city,
  c.state
from sales.customers c


select *
from customer_info
where state= 'CA'


--17. Find all products that cost between $50 and $200. Show product name and price, ordered by price from lowest to highest.
select product_name,list_price
from production.products
where list_price between 50 and 200
order by list_price



--18. Count how many customers live in each state. Show state and customer count, ordered by count from highest to lowest.
select state ,count(customer_id) as order_count
from sales.customers
group by state
order by order_count desc



--19. Find the most expensive product in each category. Show category name, product name, and price.
SELECT 
    c.category_name,
    p.product_name,
    p.list_price
FROM production.products p
JOIN production.categories c ON p.category_id = c.category_id
JOIN (
    SELECT 
        category_id,
        MAX(list_price) AS max_price
    FROM production.products
    GROUP BY category_id
) AS max_prices ON p.category_id = max_prices.category_id AND p.list_price = max_prices.max_price;



--20. Show all stores and their cities, including the total number of orders from each store. Show store name, city, and order count.
select s.store_name,s.city,count(o.order_id) as order_count
from sales.stores s
left join sales.orders o on s.store_id = o.store_id
group by s.store_name,s.city