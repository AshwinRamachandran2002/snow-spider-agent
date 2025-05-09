/* 1 ─ Delivered (actually picked-up & not-cancelled) orders  */
WITH delivered_orders AS (   
    SELECT DISTINCT "order_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_RUNNER_ORDERS
    WHERE TRIM(COALESCE("cancellation", '')) = ''
      AND TRIM(COALESCE("pickup_time",   '')) <> ''
),

/* 2 ─ Pizza line-items in those delivered orders                            */
customer_items AS (
    SELECT  cco."order_id",
            cco."pizza_id",
            COALESCE(cco."exclusions", '') AS exclusions,
            COALESCE(cco."extras",     '') AS extras
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS cco
    JOIN delivered_orders d
      ON cco."order_id" = d."order_id"
),

/* 3 ─ Base recipe toppings after removing any exclusions                   */
base_toppings AS (
    SELECT  sub."order_id",
            sub.topping_id
    FROM (
        SELECT  ci."order_id",
                ci.exclusions,
                TRY_TO_NUMBER(f.value::STRING) AS topping_id       -- safe cast
        FROM customer_items ci
        JOIN MODERN_DATA.MODERN_DATA.PIZZA_RECIPES pr
              ON pr."pizza_id" = ci."pizza_id"
        ,     LATERAL FLATTEN(
                  INPUT => SPLIT(REGEXP_REPLACE(pr."toppings", '\s', ''), ',')
              ) f
    ) sub
    WHERE sub.topping_id IS NOT NULL
      AND NOT REGEXP_LIKE(
              CONCAT(',', REGEXP_REPLACE(sub.exclusions, '\s', ''), ','),
              CONCAT(',', sub.topping_id::STRING, ',')
          )
),

/* 4 ─ Extra toppings added by the customer                                  */
extra_toppings AS (
    SELECT  sub."order_id",
            sub.topping_id
    FROM (
        SELECT  ci."order_id",
                TRY_TO_NUMBER(fe.value::STRING) AS topping_id
        FROM customer_items ci
        ,     LATERAL FLATTEN(
                  INPUT => SPLIT(REGEXP_REPLACE(ci.extras, '\s', ''), ',')
              ) fe
    ) sub
    WHERE sub.topping_id IS NOT NULL
),

/* 5 ─ Combine all toppings from base recipes and extras                     */
all_toppings AS (
    SELECT topping_id FROM base_toppings
    UNION ALL
    SELECT topping_id FROM extra_toppings
)

/* 6 ─ Final ingredient usage summary                                        */
SELECT  pt."topping_name" AS name,
        COUNT(*)          AS quantity
FROM    all_toppings at
JOIN    MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
  ON    pt."topping_id" = at.topping_id
GROUP BY pt."topping_name"
ORDER BY quantity DESC NULLS LAST;