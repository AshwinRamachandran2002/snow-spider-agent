/* Total quantity of each topping used in all successfully delivered pizzas */
SELECT
    pt.topping_name  AS ingredient,
    SUM(t.qty)       AS total_quantity
FROM (
        /* 1. Base recipe toppings (always +1 each) */
        SELECT
            cco.order_id,
            CAST(json_extract(j.value, '$') AS INTEGER) AS topping_id,
            1 AS qty
        FROM pizza_clean_customer_orders AS cco
        JOIN pizza_clean_runner_orders  AS cro
              ON cco.order_id = cro.order_id
        JOIN pizza_recipes              AS pr
              ON cco.pizza_id = pr.pizza_id,
             json_each('[' || pr.toppings || ']') AS j
        WHERE cro.cancellation IS NULL

        UNION ALL

        /* 2. Extras added by the customer (positive counts) */
        SELECT
            ge.order_id,
            ge.extras        AS topping_id,
            ge.extras_count  AS qty
        FROM pizza_get_extras         AS ge
        JOIN pizza_clean_runner_orders AS cro
              ON ge.order_id = cro.order_id
        WHERE cro.cancellation IS NULL

        UNION ALL

        /* 3. Exclusions requested by the customer (negative counts) */
        SELECT
            gx.order_id,
            gx.exclusions         AS topping_id,
           -gx.total_exclusions  AS qty
        FROM pizza_get_exclusions     AS gx
        JOIN pizza_clean_runner_orders AS cro
              ON gx.order_id = cro.order_id
        WHERE cro.cancellation IS NULL
) AS t
JOIN pizza_toppings AS pt
  ON pt.topping_id = t.topping_id
GROUP BY pt.topping_name
ORDER BY total_quantity DESC, pt.topping_name;