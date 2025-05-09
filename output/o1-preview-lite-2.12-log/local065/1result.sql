SELECT SUM(
    CASE
        WHEN p."pizza_name" = 'Meatlovers' THEN 12
        WHEN p."pizza_name" = 'Vegetarian' THEN 10
        ELSE 0
    END + COALESCE(e."extras_count", 0)
) AS "Total_Earnings"
FROM "pizza_customer_orders" AS o
JOIN "pizza_runner_orders" AS r ON o."order_id" = r."order_id"
JOIN "pizza_names" AS p ON o."pizza_id" = p."pizza_id"
LEFT JOIN "pizza_get_extras" AS e ON o."order_id" = e."order_id"
WHERE p."pizza_name" IN ('Meatlovers', 'Vegetarian') AND r."cancellation" IS NULL;