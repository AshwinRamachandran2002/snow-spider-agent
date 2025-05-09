SELECT
    SUM(p."base_price" + 
        CASE
            WHEN co."extras" IS NULL OR co."extras" = '' THEN 0
            ELSE ARRAY_SIZE(SPLIT(co."extras", ','))::int
        END
    ) AS "total_income"
FROM "MODERN_DATA"."MODERN_DATA"."PIZZA_CUSTOMER_ORDERS" co
JOIN "MODERN_DATA"."MODERN_DATA"."PIZZA_RUNNER_ORDERS" ro
    ON co."order_id" = ro."order_id"
    AND (ro."cancellation" IS NULL OR ro."cancellation" = '')
JOIN (
    SELECT 
        "pizza_id",
        CASE WHEN "pizza_id" = 1 THEN 12
             WHEN "pizza_id" = 2 THEN 10
        END AS "base_price"
    FROM "MODERN_DATA"."MODERN_DATA"."PIZZA_NAMES"
) p
    ON co."pizza_id" = p."pizza_id";