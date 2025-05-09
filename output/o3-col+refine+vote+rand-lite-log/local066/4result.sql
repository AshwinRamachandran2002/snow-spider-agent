WITH delivered AS (               -- orders that were actually delivered
    SELECT r."order_id",
           c."pizza_id"
    FROM   "pizza_runner_orders"  r
    JOIN   "pizza_customer_orders" c
           ON r."order_id" = c."order_id"
    WHERE  r."cancellation" IS NULL
),
recipes AS (                      -- attach the recipe string for each delivered pizza
    SELECT d."order_id",
           pr."toppings"
    FROM   delivered d
    JOIN   "pizza_recipes" pr
           ON d."pizza_id" = pr."pizza_id"
),
-- recursive splitter: turns a CSV like '1, 2, 3' into one row per topping_id
split(order_id, rest, topping_id) AS (
    SELECT "order_id",
           TRIM("toppings") AS rest,
           NULL            AS topping_id
    FROM   recipes
    UNION ALL
    SELECT order_id,
           CASE
               WHEN INSTR(rest, ',') = 0
               THEN ''
               ELSE SUBSTR(rest, INSTR(rest, ',') + 1)
           END                          AS rest,
           CAST(TRIM(
               CASE
                   WHEN INSTR(rest, ',') = 0
                   THEN rest
                   ELSE SUBSTR(rest, 1, INSTR(rest, ',') - 1)
               END) AS INTEGER)         AS topping_id
    FROM   split
    WHERE  rest <> ''
)
SELECT  t."topping_name" AS ingredient,
        COUNT(*)         AS quantity
FROM    split s
JOIN    "pizza_toppings" t
        ON t."topping_id" = s."topping_id"
WHERE   s."topping_id" IS NOT NULL
GROUP BY t."topping_name"
ORDER BY quantity DESC;