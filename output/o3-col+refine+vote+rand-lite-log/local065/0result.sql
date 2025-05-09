WITH delivered_orders AS (
    -- orders that were actually delivered
    SELECT c.order_id,
           c.pizza_id
    FROM   pizza_clean_customer_orders AS c
    JOIN   pizza_clean_runner_orders   AS r
           ON c.order_id = r.order_id
    WHERE  r.cancellation IS NULL
),
extras_totals AS (
    -- total extras (charged at $1 each) per order
    SELECT order_id,
           SUM(extras_count) AS extras_cnt
    FROM   pizza_get_extras
    GROUP  BY order_id
),
priced_orders AS (
    -- attach prices
    SELECT d.order_id,
           d.pizza_id,
           COALESCE(e.extras_cnt, 0)                    AS extras_cnt,
           CASE WHEN d.pizza_id = 1 THEN 12             -- Meat Lovers
                WHEN d.pizza_id = 2 THEN 10             -- Vegetarian
           END                                          AS base_price
    FROM   delivered_orders d
    LEFT   JOIN extras_totals e
           ON d.order_id = e.order_id
)
SELECT SUM(base_price + extras_cnt) AS total_revenue
FROM   priced_orders;