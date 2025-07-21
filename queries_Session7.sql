-- 1.Create a non-clustered index on the email column in the sales.customers table to improve search performance when looking up customers by email.
CREATE NONCLUSTERED INDEX IX_Customers_Email
ON sales.customers (email);



-- 2.Create a composite index on the production.products table that includes category_id and brand_id columns to optimize searches that filter by both category and brand.
CREATE NONCLUSTERED INDEX IX_Products_Category_Brand
ON production.products (category_id, brand_id);



-- 3.Create an index on sales.orders table for the order_date column and include customer_id, store_id, and order_status as included columns to improve reporting queries.
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate
ON sales.orders (order_date)
INCLUDE (customer_id, store_id, order_status);



-- 4.Create a trigger that automatically inserts a welcome record into a customer_log table whenever a new customer is added to sales.customers. (First create the log table, then the trigger)
-- Customer activity log
CREATE TABLE sales.customer_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    action VARCHAR(50),
    log_date DATETIME DEFAULT GETDATE()
);
go
CREATE TRIGGER tr_customer_welcome_log
ON sales.customers
AFTER INSERT
AS
BEGIN
    INSERT INTO sales.customer_log (customer_id, action)
    SELECT customer_id, 'Welcome - New Customer Added'
    FROM INSERTED;
END;
select * from sales.customer_log



-- 5.Create a trigger on production.products that logs any changes to the list_price column into a price_history table, storing the old price, new price, and change date.
-- Price history tracking
CREATE TABLE production.price_history (
    history_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    change_date DATETIME DEFAULT GETDATE(),
    changed_by VARCHAR(100)
);
go
create trigger tr_log_chanes
on production.products
after update
as
begin
    IF UPDATE(list_price)
    BEGIN
        INSERT INTO production.price_history (product_id, old_price, new_price, changed_by)
        SELECT
            i.product_id,
            d.list_price,
            i.list_price,
            SYSTEM_USER
        FROM INSERTED i
        INNER JOIN DELETED d ON i.product_id = d.product_id
        WHERE i.list_price != d.list_price;
    END
end
update production.products
set list_price=400
where product_id=1

SELECT * FROM production.price_history;



-- 6.Create an INSTEAD OF DELETE trigger on production.categories that prevents deletion of categories that have associated products. Display an appropriate error message.
create trigger tr_prevent_deletion
on production.categories
instead of delete
as
begin
       if EXISTS (
        SELECT 1
        FROM production.products p
        inner join DELETED d ON p.category_id = d.category_id
    )
    BEGIN
        print 'error message: Cannot delete category'
        RETURN;
    END
end
delete from production.categories
where category_id=1



-- 7.Create a trigger on sales.order_items that automatically reduces the quantity in production.stocks when a new order item is inserted.
create trigger reduce_quatity 
on sales.order_items
after insert
as
begin
    update s
    set s.quantity = s.quantity - i.quantity
    FROM production.stocks s
    INNER JOIN INSERTED i ON s.product_id = i.product_id ;
end


-- 8.Create a trigger that logs all new orders into an order_audit table, capturing order details and the date/time when the record was created.
-- Order audit trail
CREATE TABLE sales.order_audit (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT,
    customer_id INT,
    store_id INT,
    staff_id INT,
    order_date DATE,
    audit_timestamp DATETIME DEFAULT GETDATE()
);
go
CREATE TRIGGER tr_log_new_order
ON sales.orders
AFTER INSERT
AS
BEGIN
    INSERT INTO sales.order_audit (order_id, customer_id, store_id, staff_id, order_date)
    SELECT order_id, customer_id, store_id, staff_id, order_date
    FROM INSERTED;
END;

insert into sales.order_audit (order_id, customer_id, store_id, staff_id)
values (11,1,1,5)

select * from sales.order_audit
