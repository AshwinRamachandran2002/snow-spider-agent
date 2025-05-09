WITH delivered AS (                         -- only orders that were actually delivered
    SELECT "order_id"
    FROM "pizza_clean_runner_orders"
    WHERE "cancellation" IS NULL
),
base AS (                                  -- base price for every pizza in each delivered order
    SELECT
        c."order_id",
        SUM(
            CASE WHEN c."pizza_id" = 1 THEN 12     -- Meat Lovers
                 WHEN c."pizza_id" = 2 THEN 10     -- Vegetarian
            END
        ) AS base_income
    FROM "pizza_clean_customer_orders"  c
    JOIN delivered                     d  ON d."order_id" = c."order_id"
    WHERE c."pizza_id" IN (1,2)
    GROUP BY c."order_id"
),
extras AS (                                -- $1 per extra topping, summed once per order
    SELECT "order_id",
           SUM("extras_count") AS extras_income
    FROM "pizza_get_extras"
    GROUP BY "order_id"
)
SELECT
    SUM(base_income + COALESCE(extras_income,0)) AS total_income
FROM base
LEFT JOIN extras USING ("order_id");