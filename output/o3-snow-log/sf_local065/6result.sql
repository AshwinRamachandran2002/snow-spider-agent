/*  Total revenue for delivered Meat Lovers ($12) and Vegetarian ($10) pizzas,
    adding $1 for every extra topping and excluding any orders that were cancelled. */
SELECT
    SUM(
          CASE 
              WHEN c."pizza_id" = 1 THEN 12       -- Meat Lovers
              WHEN c."pizza_id" = 2 THEN 10       -- Vegetarian
          END
        +                                                          -- base pizza price
          CASE                                                     -- extras cost
              WHEN COALESCE(TRIM(c."extras"),'') = '' THEN 0
              ELSE ARRAY_SIZE(SPLIT(TRIM(c."extras"),',')) * 1
          END
    )  AS "TOTAL_REVENUE_EARNED"
FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS  AS c
JOIN MODERN_DATA.MODERN_DATA.PIZZA_RUNNER_ORDERS    AS r
      ON c."order_id" = r."order_id"
WHERE (r."cancellation" IS NULL OR TRIM(r."cancellation") = '')
  AND c."pizza_id" IN (1,2);