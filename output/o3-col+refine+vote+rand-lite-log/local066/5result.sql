WITH delivered AS (
    /* orders that reached the customer */
    SELECT c."order_id",
           c."pizza_id"
    FROM   "pizza_clean_customer_orders" AS c
    JOIN   "pizza_clean_runner_orders"   AS r
           ON r."order_id" = c."order_id"
    WHERE  r."cancellation" IS NULL
),
base_recipe AS (
    /* every topping appearing in the standard recipe of every delivered pizza */
    SELECT d."order_id",
           json_extract(j.value, '$') AS topping_id,
           1 AS qty
    FROM   delivered d
    JOIN   "pizza_recipes" pr ON pr."pizza_id" = d."pizza_id",
           json_each('[' || pr."toppings" || ']') AS j
),
exclusions AS (
    /* toppings customers asked to remove */
    SELECT "order_id",
           "exclusions" AS topping_id
    FROM   "pizza_get_exclusions"
),
extras AS (
    /* extra toppings customers added (may be >1 of the same topping) */
    SELECT "order_id",
           "extras"       AS topping_id,
           "extras_count" AS qty
    FROM   "pizza_get_extras"
),
final_toppings AS (
    /* keep recipe toppings that were not excluded, and add all extras */
    SELECT br."order_id",
           br."topping_id",
           br.qty
    FROM   base_recipe br
    LEFT  JOIN exclusions e
           ON  br."order_id"  = e."order_id"
           AND br."topping_id" = e."topping_id"
    WHERE  e."topping_id" IS NULL
    
    UNION ALL
    
    SELECT * FROM extras
)
SELECT pt."topping_name"              AS ingredient,
       SUM(ft.qty)                    AS total_quantity
FROM   final_toppings ft
JOIN   "pizza_toppings" pt
       ON pt."topping_id" = ft."topping_id"
GROUP  BY pt."topping_name"
ORDER  BY total_quantity DESC;