WITH valid_orders AS (
    /* keep only the customer orders that were actually delivered */
    SELECT cco.order_id,
           cco.pizza_id
    FROM pizza_clean_customer_orders AS cco
    JOIN pizza_clean_runner_orders AS cro
         ON cco.order_id = cro.order_id
    WHERE cro.cancellation IS NULL
),
order_extras AS (
    /* count how many extra toppings each kept order has */
    SELECT order_id,
           SUM(extras_count) AS extras_qty
    FROM pizza_get_extras
    GROUP BY order_id
),
priced_orders AS (
    /* attach prices for every kept order */
    SELECT vo.order_id,
           CASE vo.pizza_id
                WHEN 1 THEN 12      -- Meatlovers
                WHEN 2 THEN 10      -- Vegetarian
           END                     AS pizza_price,
           COALESCE(oe.extras_qty,0) AS extras_qty
    FROM valid_orders AS vo
    LEFT JOIN order_extras AS oe
           ON vo.order_id = oe.order_id
)
SELECT SUM(pizza_price + extras_qty) AS total_income
FROM priced_orders;