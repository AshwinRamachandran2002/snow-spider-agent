-- Task: For each customer, calculate the recency score based on their latest purchase timestamp from 'delivered' orders, and assign them into quintiles (1-5), where 1 is the most recent customers. Show the customer unique ID, last purchase date, and recency score. Limit to 100 records.

SELECT "customer_unique_id",
       MAX("order_purchase_timestamp") AS "last_purchase",
       NTILE(5) OVER (ORDER BY MAX("order_purchase_timestamp") DESC) AS "recency"
FROM E_COMMERCE.E_COMMERCE.ORDERS
    JOIN E_COMMERCE.E_COMMERCE.CUSTOMERS USING ("customer_id")
WHERE "order_status" = 'delivered'
GROUP BY "customer_unique_id"
LIMIT 100