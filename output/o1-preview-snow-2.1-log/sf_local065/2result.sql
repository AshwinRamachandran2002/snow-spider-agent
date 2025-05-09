WITH valid_orders AS (
    SELECT DISTINCT "order_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_RUNNER_ORDERS
    WHERE COALESCE(TRIM("cancellation"), '') = ''
),
order_details AS (
    SELECT 
        cust_orders."order_id", 
        cust_orders."pizza_id", 
        cust_orders."extras",
        pizza_names."pizza_name"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS AS cust_orders
    INNER JOIN valid_orders ON cust_orders."order_id" = valid_orders."order_id"
    INNER JOIN MODERN_DATA.MODERN_DATA.PIZZA_NAMES AS pizza_names
        ON cust_orders."pizza_id" = pizza_names."pizza_id"
),
order_pricing AS (
    SELECT
        "order_id",
        CASE
            WHEN "pizza_name" = 'Meatlovers' THEN 12
            WHEN "pizza_name" = 'Vegetarian' THEN 10
            ELSE 0
        END AS base_price,
        CASE
            WHEN TRIM("extras") IS NULL OR TRIM("extras") = '' THEN 0
            ELSE ARRAY_SIZE(SPLIT("extras", ','))
        END AS num_extras
    FROM order_details
)
SELECT
    ROUND(SUM(base_price + num_extras), 4) AS "total_income"
FROM order_pricing
WHERE base_price > 0;