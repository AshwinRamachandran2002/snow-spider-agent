SELECT 
    SUM( CASE cco.pizza_id                  -- base pizza price
             WHEN 1 THEN 12                 -- Meat Lovers
             WHEN 2 THEN 10                 -- Vegetarian
         END
         + COALESCE(ex.total_extras,0)      -- $1 for each extra topping
       ) AS total_income
FROM  pizza_clean_runner_orders  AS cro
JOIN  pizza_clean_customer_orders AS cco
      ON cro.order_id = cco.order_id
LEFT JOIN ( SELECT order_id,
                   SUM(extras_count) AS total_extras
            FROM   pizza_get_extras
            GROUP  BY order_id ) AS ex
      ON cco.order_id = ex.order_id
WHERE  cro.cancellation IS NULL             -- exclude cancelled orders
  AND  cco.pizza_id IN (1,2);               -- only Meat Lovers & Vegetarian