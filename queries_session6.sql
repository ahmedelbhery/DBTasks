-- 1.Write a query that uses variables to find the total amount spent by customer ID 1. Display a message showing whether they are a VIP customer (spent > $5000) or regular customer
DECLARE @customer_id INT = 1;
DECLARE @total_spent DECIMAL(10,2);
SELECT @total_spent = SUM(oi.quantity * oi.list_price * (1 -oi.discount))
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = @customer_id;
IF @total_spent > 5000
    PRINT 'Customer ID ' + CAST(@customer_id AS VARCHAR) + ' is a VIP customer and Total Spent: $' + CAST(@total_spent AS VARCHAR);
ELSE
    PRINT 'Customer ID ' + CAST(@customer_id AS VARCHAR) + ' is a Regular customer and Total Spent: $' + CAST(@total_spent AS VARCHAR);



-- 2.Create a query using variables to count how many products cost more than $1500. Store the threshold price in a variable and display both the c and count in a formatted message.
declare @threshold_price decimal(10,2) = 1500.00;
declare @count int;
select @count = count(*)
from production.products 
where list_price > @threshold_price;
print 'founded: '+ cast(@count as varchar) + ' item greater than: '+ cast(@threshold_price as varchar);



-- 3.Write a query that calculates the total sales for staff member ID 2 in the year 2017. Use variables to store the staff ID, year, and calculated total. Display the results with appropriate labels.
declare @total_sales decimal(10,2);
select @total_sales = SUM(oi.quantity * oi.list_price * (1 -oi.discount))
from sales.staffs s
inner join sales.orders o on s.staff_id = o.staff_id
inner join sales.order_items oi on o.order_id =oi.order_id
where s.staff_id=2 and YEAR(order_date) = 2017
print 'staff with id= 2 and sell order in 2017 tptat sales= '+cast(@total_sales as varchar)



-- 4.Create a query that displays the current server name, SQL Server version, and the number of rows affected by the last statement. Use appropriate global variables
select 
@@SERVERNAME as sever_name,
@@VERSION as verion,
@@ROWCOUNT as row_affected;



-- 5.5.Write a query that checks the inventory level for product ID 1 in store ID 1. Use IF statements to display different messages based on stock levels:#
--      If quantity > 20: Well stocked
--      If quantity 10-20: Moderate stock
--      If quantity < 10: Low stock - reorder needed
declare @quantity decimal(10,2);
select @quantity=quantity
from production.stocks
where product_id=1 and store_id=1
If @quantity > 20
   print 'Well stocked'
else if @quantity between 10 and 20
   print 'Moderate stock'
If @quantity < 10
   print 'Low stock - reorder needed'



-- 6.Create a WHILE loop that updates low-stock items (quantity < 5) in batches of 3 products at a time. Add 10 units to each product and display progress messages after each batch.
DECLARE @batch_size INT = 3;
DECLARE @updated_count INT = 1; 
DECLARE @batch_number INT = 1;

WHILE @updated_count > 0
BEGIN
    WITH ToUpdate AS (
        SELECT TOP (@batch_size) *
        FROM production.stocks
        WHERE quantity < 5
        ORDER BY quantity ASC 
    )
    UPDATE ToUpdate
    SET quantity = quantity + 10;
    SET @updated_count = @@ROWCOUNT;
    PRINT 'Batch ' + CAST(@batch_number AS VARCHAR) + ': Updated ' + CAST(@updated_count AS VARCHAR) + ' low-stock items.';
    SET @batch_number = @batch_number+1;
END



-- 7.Write a query that categorizes all products using CASE WHEN based on their list price:
--     Under $300: Budget
--     $300-$800: Mid-Range
--     $801-$2000: Premium
--     Over $2000: Luxury
select 
case 
   when list_price <300 then 'Budget'
   when list_price between 300 and 800 then 'Mid-Range'
   when list_price between 801 and 2000  then 'Premium'
   when list_price >2000 then 'Luxury'
end as price_type
from production.products



-- 8.Create a query that checks if customer ID 5 exists in the database. If they exist, show their order count. If not, display an appropriate message.
DECLARE @customer_id INT = 5;
DECLARE @order_count INT;
IF EXISTS (
    SELECT 1 
    FROM sales.customers 
    WHERE customer_id = @customer_id
)
   BEGIN
       SELECT @order_count = COUNT(*) 
       FROM sales.orders 
       WHERE customer_id = @customer_id;
   
       PRINT 'Customer ID ' + CAST(@customer_id AS VARCHAR) + 
             ' exists and has ' + CAST(@order_count AS VARCHAR) + ' orders.';
   END
ELSE
   BEGIN
       PRINT 'Customer ID ' + CAST(@customer_id AS VARCHAR) + ' does not exist.';
   END



-- 9.Create a scalar function named CalculateShipping that takes an order total as input and returns shipping cost:
--     Orders over $100: Free shipping ($0)
--     Orders $50-$99: Reduced shipping ($5.99)
--     Orders under $50: Standard shipping ($12.99)
CREATE FUNCTION dbo.CalculateShipping (@order_total DECIMAL(10, 2))
RETURNS DECIMAL(5, 2)
AS
BEGIN
    DECLARE @shipping_cost DECIMAL(5, 2);

    SET @shipping_cost = 
        CASE 
            WHEN @order_total > 100 THEN 0.00
            WHEN @order_total BETWEEN 50 AND 99.99 THEN 5.99
            ELSE 12.99
        END;

    RETURN @shipping_cost;
END;
select dbo.CalculateShipping(50) AS shipping_cost;



-- 10.Create an inline table-valued function named GetProductsByPriceRange that accepts minimum and maximum price parameters and returns all products within that price range with their brand and category information.
create function dbo.GetProductsByPriceRange(@min_price decimal(10,2) ,@max_price decimal(10,2))
returns table
as return
(  
   select c.category_name,b.brand_name,p.product_name,p.list_price
   from production.categories c
   inner join production.products p on c.category_id =p.category_id
   inner join production.brands b on b.brand_id =p.brand_id
   where p.list_price>@min_price and p.list_price<@max_price
)
go
select * from dbo.GetProductsByPriceRange(50,100)



-- 11.Create a multi-statement function named GetCustomerYearlySummary that takes a customer ID and returns a table with yearly sales data including total orders, total spent, and average order value for each year.
create function dbo.GetCustomerYearlySummary(@customerID int)
returns @summary table(yearly_sales int,total_order int,total_spent decimal(10,2),avg_order decimal(10,2))
as
begin 
   insert into @summary
   select 
        YEAR(order_date) as yearly_sales,
        count(o.order_id) as total_order,
        sum(oi.quantity*oi.list_price*(1-oi.discount)) as total_spent,
        AVG(oi.quantity*oi.list_price*(1-oi.discount)) as avg_order
   from sales.orders o
   inner join sales.order_items oi on oi.order_id = o.order_id
   where o.customer_id = @customerID
   group by YEAR(order_date)
   return
end
go
select * from dbo.GetCustomerYearlySummary(1);



-- 12.Write a scalar function named CalculateBulkDiscount that determines discount percentage based on quantity:
--     1-2 items: 0% discount
--     3-5 items: 5% discount
--     6-9 items: 10% discount
--     10+ items: 15% discount
CREATE FUNCTION dbo.CalculateBulkDiscount( @quantity INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @discount DECIMAL(10,2)

    SET @discount = 
        CASE 
            WHEN @quantity BETWEEN 1 AND 2 THEN 0.00
            WHEN @quantity BETWEEN 3 AND 5 THEN 5.00
            WHEN @quantity BETWEEN 6 AND 9 THEN 10.00
            WHEN @quantity >= 10 THEN 15.00
        END

    RETURN @discount
END
GO
SELECT dbo.CalculateBulkDiscount(5) AS discount_percentage



-- 13.Create a stored procedure named sp_GetCustomerOrderHistory that accepts a customer ID and optional start/end dates. Return the customer's order history with order totals calculated.
CREATE PROC sp_GetCustomerOrderHistory
    @customer_id INT,
    @start_date DATE = NULL,
    @end_date DATE = NULL
AS
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS order_total
    FROM sales.orders o
    INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @customer_id
        AND (@start_date IS NULL OR o.order_date >= @start_date)
        AND (@end_date IS NULL OR o.order_date <= @end_date)
    GROUP BY o.order_id, o.order_date
END
GO
EXEC sp_GetCustomerOrderHistory @customer_id = 5, @start_date = '2023-01-01', @end_date = '2023-12-31';



-- 14.Write a stored procedure named sp_RestockProduct with input parameters for store ID, product ID, and restock quantity. Include output parameters for old quantity, new quantity, and success status.
create proc sp_RestockProduct
@storeId int,
@productId int,
@restock_qty int
as 
begin
     DECLARE @old_qty INT, @new_qty INT, @success BIT;
 IF EXISTS (
        SELECT 1
        FROM production.stocks
        WHERE store_id = @storeId AND product_id = @productId
    )
    begin
        SELECT @old_qty = quantity
        FROM production.stocks
        WHERE store_id = @storeId AND product_id = @productId;

        UPDATE production.stocks
        SET quantity = quantity + @restock_qty
        WHERE store_id = @storeId AND product_id = @productId;

        SELECT @new_qty = quantity
        FROM production.stocks
        WHERE store_id = @storeId AND product_id = @productId;
    end
    else
    begin
        SET @old_qty = null;
        SET @new_qty = null;
        SET @success = 0;
    end

    select @old_qty AS old_quantity,@new_qty AS new_quantity,@success AS status;;
end
go
EXEC sp_RestockProduct @storeId = 1, @productId = 100, @restock_qty = 20;




-- 15.Create a stored procedure named sp_ProcessNewOrder that handles complete order creation with proper transaction control and error handling. Include parameters for customer ID, product ID, quantity, and store ID.
create proc sp_ProcessNewOrder
@customerId int,
@productId int,
@quantity int,
@storeId int
as
begin
end



-- 16.Write a stored procedure named sp_SearchProducts that builds dynamic SQL based on optional parameters: product name search term, category ID, minimum price, maximum price, and sort column.
create proc sp_SearchProducts
@productName nvarchar(100),
@categoryId int,
@minPrice decimal(10,2),
@maxPrice decimal(10,2),
@sort_column NVARCHAR(50)
as
begin
   
    SELECT 
        p.product_id,
        p.product_name,
        p.category_id,
        c.category_name,
        p.list_price
    FROM production.products p
    LEFT JOIN production.categories c ON p.category_id = c.category_id
    where p.product_name =@productName and p.category_id=@categoryId
          and p.list_price>@minPrice and p.list_price<@maxPrice
    order by case 
            WHEN @sort_column = 'productName' THEN p.product_name
            WHEN @sort_column = 'listPrice' THEN CAST(p.list_price AS NVARCHAR)
            WHEN @sort_column = 'categoryId' THEN CAST(p.category_id AS NVARCHAR)
            ELSE CAST(p.product_id AS NVARCHAR)
        END
end
go 
exec sp_SearchProducts @productName='Adidas 3-Stripes Club Polo - Navy',@categoryId=1,@minPrice=5.5
,@maxPrice=100.5,@sort_column = 'productName';



-- 17.Create a complete solution that calculates quarterly bonuses for all staff members. Use variables to store date ranges and bonus rates. Apply different bonus percentages based on sales performance tiers.
DECLARE @StartDate DATE = '2022-04-01',@EndDate DATE = '2022-06-30';
select s.staff_id, s.first_name+' '+ s.last_name as full_name,
       SUM(oi.quantity * oi.list_price * (1 -oi.discount)) AS total_sales,
       case
       when SUM(oi.quantity * oi.list_price * (1 -oi.discount))>10000 then 0.10
       when SUM(oi.quantity * oi.list_price * (1 -oi.discount))>50000 and SUM(oi.quantity * oi.list_price * (1 -oi.discount))<99999 then 0.08
       when SUM(oi.quantity * oi.list_price * (1 -oi.discount))>20000 and SUM(oi.quantity * oi.list_price * (1 -oi.discount))<49999 then 0.05
       else 0.02
       end as bonus_rate
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
JOIN sales.staffs s ON o.staff_id = s.staff_id
WHERE o.order_date BETWEEN @StartDate AND @EndDate
GROUP BY s.staff_id, s.first_name, s.last_name



--18.Write a complex query with nested IF statements that manages inventory restocking. Check current stock levels and apply different reorder quantities based on product categories and current stock levels.
SELECT p.product_id,p.product_name,c.category_name,
    s.store_id,s.quantity AS current_stock,
    CASE 
        WHEN s.quantity < 10 THEN
            CASE 
                WHEN c.category_name = 'Men'+''+'s Jeans' THEN 50
                WHEN c.category_name = 'Men'+''+'s Outerwear' THEN 30
                WHEN c.category_name = 'Women'+''+'s Dresses' THEN 20
                ELSE 10
            END
        WHEN s.quantity BETWEEN 10 AND 20 THEN
            CASE 
                WHEN c.category_name = 'Men'+''+'s Jeans' THEN 30
                WHEN c.category_name = 'Men'+''+'s Outerwear' THEN 20
                WHEN c.category_name = 'Women'+''+'s Dresses' THEN 10
                ELSE 5
            END 
        ELSE 0 
    END AS reorder_quantity
FROM production.products p
JOIN production.categories c ON p.category_id = c.category_id
JOIN production.stocks s ON p.product_id = s.product_id 



-- 19.Create a comprehensive solution that assigns loyalty tiers to customers based on their total spending. Handle customers with no orders appropriately and use proper NULL checking.
select  c.customer_id,c.first_name+' '+c.last_name as full_name,
        sum(oi.quantity*oi.list_price*(1-oi.discount)) as total_spent,
        CASE 
           WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) IS NULL THEN 'No Orders'
        ELSE 
           CAST(SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS VARCHAR(20))
        END AS spending_status
FROM sales.customers c
LEFT JOIN sales.orders o ON c.customer_id = o.customer_id
LEFT JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY  c.customer_id,  c.first_name, c.last_name

-- 20.Write a stored procedure that handles product discontinuation including checking for pending orders, optional product replacement in existing orders, clearing inventory, and providing detailed status messages
create PROC handle_product_discountation
    @success_msg NVARCHAR(150),
    @error_msg NVARCHAR(150)
AS
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales,
        CASE 
            WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 10000 THEN @success_msg + ' 9%'
            WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) between 7000 and 9999 THEN @success_msg + ' 6%'
            WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) between 5000 and 6999 THEN @success_msg + ' 3%'
            ELSE @error_msg
        END AS discount_status
    FROM production.products p
    LEFT JOIN sales.order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name;
END;
exec handle_product_discountation @success_msg='you will take discount equal ',@error_msg='sorry, you will not take not discount'




-- Bonus Challenges::
-- 21.Create a query that combines multiple advanced concepts to generate a comprehensive sales report showing monthly trends, staff performance, and product category analysis.
WITH MonthlySales as (
    SELECT
        format(o.order_date, 'yyyy-MM') AS format_date,
        SUM(oi.quantity * (oi.list_price * (1 - oi.discount))) AS MonthlyRevenue
    FROM sales.orders o
    join sales.order_items oi ON o.order_id = oi.order_id
    where o.order_status = 4 
    GROUP BY format(o.order_date, 'yyyy-MM')
),
StaffPerformance AS (
    SELECT
        s.staff_id,
        s.first_name+ ' '+ s.last_name as staff_name,
        count(o.order_id) as countOrders,
        SUM(oi.quantity * (oi.list_price * (1 - oi.discount))) AS TotalSales
    FROM sales.staffs s
    JOIN sales.orders o ON s.staff_id = o.staff_id
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 4
    GROUP BY s.staff_id, s.first_name, s.last_name
),
CategoryAnalysis AS (
    SELECT
        c.category_name,
        SUM(oi.quantity) AS totalUnitsSold,
        SUM(oi.quantity * (oi.list_price * (1 - oi.discount))) AS Revenue
    FROM production.categories c
    JOIN production.products p ON c.category_id = p.category_id
    JOIN sales.order_items oi ON p.product_id = oi.product_id
    JOIN sales.orders o ON o.order_id = oi.order_id
    WHERE o.order_status = 4
    GROUP BY c.category_name
)
SELECT 
    'Monthly Trends' AS Section, 
    format_date AS Info1, 
    CAST(MonthlyRevenue AS DECIMAL(18,2)) AS Info2, 
    NULL AS Info3
FROM MonthlySales

UNION ALL

SELECT 
    'Staff Performance',
    staff_name,
    CAST(countOrders AS VARCHAR),
    CAST(TotalSales AS DECIMAL(18,2))
FROM StaffPerformance

UNION ALL

SELECT 
    'Category Analysis',
    category_name,
    CAST(totalUnitsSold AS VARCHAR),
    CAST(Revenue AS DECIMAL(18,2))
FROM CategoryAnalysis;



--22.Build a complete data validation system using functions and procedures that ensures data integrity when inserting new orders, including customer validation, inventory checking, and business rule enforcement.
CREATE FUNCTION dbo.fn_is_valid_customer(@customer_id INT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_valid BIT;
    SELECT @is_valid = CASE 
                        WHEN EXISTS (SELECT 1 FROM sales.customers WHERE customer_id = @customer_id) THEN 1
                        ELSE 0 
                        END;
    RETURN @is_valid;
END;

CREATE FUNCTION dbo.fn_is_enough_inventory(@product_id INT, @requested_qty INT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_enough BIT;
    SELECT @is_enough =CASE 
                       WHEN (SELECT quantity FROM sales.stocks WHERE product_id = @product_id) >= @requested_qty
                       THEN 1 ELSE 0 
                       END;
    RETURN @is_enough;
END;




















