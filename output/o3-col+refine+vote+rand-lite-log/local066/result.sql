WITH delivered AS (
    SELECT
        c."pizza_id",
        COUNT(*) AS delivered_qty
    FROM "pizza_runner_orders"   AS r
    JOIN "pizza_customer_orders" AS c
      ON r."order_id" = c."order_id"
    WHERE r."cancellation" IS NULL
    GROUP BY c."pizza_id"
),
recipe_expanded AS (
    SELECT
        pr."pizza_id",
        CAST(value AS INTEGER) AS topping_id
    FROM "pizza_recipes" AS pr,
         json_each('[' || REPLACE(pr."toppings", ' ', '') || ']')
),
topping_totals AS (
    SELECT
        re."topping_id",
        SUM(d.delivered_qty) AS quantity
    FROM recipe_expanded AS re
    JOIN delivered       AS d  ON re."pizza_id" = d."pizza_id"
    GROUP BY re."topping_id"
)
SELECT
    pt."topping_name" AS ingredient,
    tt."quantity"
FROM topping_totals AS tt
JOIN "pizza_toppings" AS pt
  ON tt."topping_id" = pt."topping_id"
ORDER BY tt."quantity" DESC;