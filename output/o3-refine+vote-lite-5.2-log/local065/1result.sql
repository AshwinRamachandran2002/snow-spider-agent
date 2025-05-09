WITH valid_orders AS (
    /* keep only orders that were actually delivered (not cancelled) */
    SELECT c.order_id,
           c.pizza_id
    FROM   pizza_clean_customer_orders  AS c
    JOIN   pizza_clean_runner_orders    AS r
           ON r.order_id = c.order_id
    WHERE  r.cancellation IS NULL
           OR r.cancellation = ''
),
extras_per_order AS (
    /* total number of extra toppings for every order */
    SELECT   order_id,
             COALESCE(SUM(extras_count),0) AS extras_cnt
    FROM     pizza_get_extras
    GROUP BY order_id
)
SELECT
    SUM(                                   -- grand total in dollars
        CASE                               -- base pizza price
            WHEN v.pizza_id = 1 THEN 12    -- Meat Lovers
            WHEN v.pizza_id = 2 THEN 10    -- Vegetarian
            ELSE 0
        END
        + COALESCE(e.extras_cnt,0) * 1     -- $1 per extra topping
    ) AS total_income
FROM   valid_orders      AS v
LEFT JOIN extras_per_order AS e
       ON e.order_id = v.order_id;