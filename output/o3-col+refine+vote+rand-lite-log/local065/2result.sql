WITH extras_per_order AS (          -- how many paid-for extras were added to each order
    SELECT   order_id,
             SUM(extras_count) AS extras_ct
    FROM     pizza_get_extras
    GROUP BY order_id
),
delivered_items AS (                -- every pizza that was actually delivered
    SELECT  c.order_id,
            c.pizza_id,
            COALESCE(e.extras_ct,0) AS extras_ct
    FROM    pizza_clean_customer_orders  AS c
    JOIN    pizza_clean_runner_orders    AS r  ON c.order_id = r.order_id
           AND (r.cancellation IS NULL OR r.cancellation = '')
    LEFT JOIN extras_per_order           AS e  ON c.order_id = e.order_id
)
SELECT SUM(                          -- add base price + $1 per extra topping
           CASE WHEN pizza_id = 1 THEN 12        -- Meat-lovers
                WHEN pizza_id = 2 THEN 10        -- Vegetarian
           END
           + extras_ct
         ) AS total_income
FROM   delivered_items;