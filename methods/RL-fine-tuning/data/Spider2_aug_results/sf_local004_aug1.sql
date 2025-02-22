-- Task: Could you provide the number of orders, total payment, first order day, and last order day for each customer? Show the first 100 results.
SELECT
    "customer_unique_id",
    COUNT(DISTINCT E_COMMERCE.E_COMMERCE.ORDERS."order_id") AS order_count,
    SUM(TO_NUMBER("payment_value")) AS total_payment,
    DATE_PART('day', MIN(TO_TIMESTAMP("order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS'))) AS first_order_day,
    DATE_PART('day', MAX(TO_TIMESTAMP("order_purchase_timestamp", 'YYYY-MM-DD HH24:MI:SS'))) AS last_order_day
FROM E_COMMERCE.E_COMMERCE.CUSTOMERS 
    JOIN E_COMMERCE.E_COMMERCE.ORDERS USING ("customer_id")
    JOIN E_COMMERCE.E_COMMERCE.ORDER_PAYMENTS USING ("order_id")
GROUP BY "customer_unique_id"
LIMIT 100;