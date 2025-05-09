WITH valid_orders AS (
    /* keep only orders that were actually delivered (not cancelled) */
    SELECT  co.order_id ,
            co.pizza_id
    FROM    pizza_customer_orders AS co
    JOIN    pizza_runner_orders  AS ro
           ON co.order_id = ro.order_id
    WHERE   ro.cancellation IS NULL
),
price_list AS (          /* prices given in the problem statement */
    SELECT 1 AS pizza_id , 12 AS base_price
    UNION ALL
    SELECT 2 , 10
),
extras_totals AS (       /* total number of extra toppings per order */
    SELECT  order_id ,
            SUM(extras_count) AS extras_cnt
    FROM    pizza_get_extras
    GROUP BY order_id
),
order_revenue AS (       /* calculate revenue for each kept order */
    SELECT  v.order_id,
            pl.base_price ,
            COALESCE(et.extras_cnt,0)                     AS extras_cnt ,
            pl.base_price + COALESCE(et.extras_cnt,0)     AS order_income
    FROM    valid_orders  AS v
    JOIN    price_list    AS pl ON v.pizza_id = pl.pizza_id
    LEFT JOIN extras_totals AS et ON v.order_id = et.order_id
)
SELECT SUM(order_income) AS total_income
FROM   order_revenue;