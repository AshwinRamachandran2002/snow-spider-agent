WITH extras_per_order AS (
    SELECT "order_id",
           SUM("extras_count") AS total_extras
    FROM   "pizza_get_extras"
    GROUP BY "order_id"
)
SELECT SUM(
           CASE 
               WHEN pco."pizza_id" = 1 THEN 12      -- Meat Lovers
               WHEN pco."pizza_id" = 2 THEN 10      -- Vegetarian
           END + COALESCE(e.total_extras, 0)        -- $1 per extra topping
         ) AS total_income
FROM   "pizza_clean_customer_orders" AS pco
JOIN   "pizza_clean_runner_orders"   AS pr
       ON pco."order_id" = pr."order_id"
LEFT JOIN extras_per_order AS e
       ON pco."order_id" = e."order_id"
WHERE  pr."cancellation" IS NULL
  AND  pco."pizza_id" IN (1, 2);