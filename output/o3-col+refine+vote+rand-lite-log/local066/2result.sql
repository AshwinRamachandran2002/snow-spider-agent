WITH delivered_orders AS (                 -- orders that were actually delivered
    SELECT "order_id"
    FROM   "pizza_clean_runner_orders"
    WHERE  "cancellation" IS NULL
),
delivered_pizzas AS (                      -- pizzas in those delivered orders
    SELECT cco."order_id",
           cco."pizza_id"
    FROM   "pizza_clean_customer_orders" AS cco
    JOIN   delivered_orders               USING ("order_id")
),
toppings_expanded AS (                     -- one row per topping used
    SELECT dp."order_id",
           CAST(TRIM(j.value) AS INTEGER) AS "topping_id"
    FROM   delivered_pizzas AS dp
    JOIN   "pizza_recipes" AS pr USING ("pizza_id"),
           json_each('[' || pr."toppings" || ']') AS j
)
SELECT pt."topping_name" AS ingredient,
       COUNT(*)          AS quantity
FROM   toppings_expanded AS te
JOIN   "pizza_toppings"  AS pt USING ("topping_id")
GROUP  BY pt."topping_name"
ORDER  BY quantity DESC;