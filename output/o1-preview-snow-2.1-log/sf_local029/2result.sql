WITH customer_orders AS (
    SELECT
        c."customer_unique_id" AS "Customer_Unique_ID",
        c."customer_city" AS "City",
        c."customer_state" AS "State",
        COUNT(o."order_id") AS "Delivered_Order_Count",
        ROUND(AVG(p."payment_value"), 4) AS "Average_Payment_Value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_CUSTOMERS c
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDERS o
        ON c."customer_id" = o."customer_id"
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_ORDER_PAYMENTS p
        ON o."order_id" = p."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY
        c."customer_unique_id",
        c."customer_city",
        c."customer_state"
)
SELECT "Customer_Unique_ID", "Average_Payment_Value", "City", "State"
FROM customer_orders
ORDER BY "Delivered_Order_Count" DESC NULLS LAST
LIMIT 3;