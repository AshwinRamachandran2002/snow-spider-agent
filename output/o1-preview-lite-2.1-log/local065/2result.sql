SELECT SUM(
    CASE n."pizza_name"
        WHEN 'Meatlovers' THEN 12
        WHEN 'Vegetarian' THEN 10
        ELSE 0
    END
    + 
        CASE
            WHEN c."extras" IS NULL OR TRIM(c."extras") = '' THEN 0
            ELSE LENGTH(c."extras") - LENGTH(REPLACE(c."extras", ',', '')) + 1
        END
    ) AS "Total_Earnings"
FROM "pizza_customer_orders" AS c
JOIN "pizza_runner_orders" AS r ON c."order_id" = r."order_id"
JOIN "pizza_names" AS n ON c."pizza_id" = n."pizza_id"
WHERE (r."cancellation" IS NULL OR TRIM(r."cancellation") = '')
  AND r."pickup_time" IS NOT NULL AND TRIM(r."pickup_time") <> ''
  AND n."pizza_name" IN ('Meatlovers', 'Vegetarian');