/* -------------------------------------------------------------
   Produce final ingredient string for each pizza order
--------------------------------------------------------------*/
WITH orders AS (   /* deterministic ordering for each order row */
    SELECT
        ROW_NUMBER() OVER (ORDER BY "order_time", "order_id")     AS "ROW_ID",
        "order_id"                                                AS "ORDER_ID",
        "customer_id"                                             AS "CUSTOMER_ID",
        CASE WHEN "pizza_id" = 1 THEN 1 ELSE 2 END                AS "PIZZA_ID",
        COALESCE("exclusions", '')                                AS "EXCLUSIONS",
        COALESCE("extras",     '')                                AS "EXTRAS",
        "order_time"                                              AS "ORDER_TIME"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS
),

/* 1. explode standard recipe toppings */
standard_toppings AS (
    SELECT
        o."ROW_ID",
        TO_NUMBER(TRIM(f.value))            AS "TOPPING_ID"
    FROM orders o
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_RECIPES pr
          ON pr."pizza_id" = o."PIZZA_ID"
    CROSS JOIN LATERAL FLATTEN( INPUT => SPLIT(pr."toppings", ',')) f
),

/* 2. explode exclusions provided by customer */
exclusion_toppings AS (
    SELECT
        o."ROW_ID",
        TO_NUMBER(TRIM(f.value))            AS "TOPPING_ID"
    FROM orders o
    CROSS JOIN LATERAL FLATTEN( INPUT => SPLIT(o."EXCLUSIONS", ',')) f
    WHERE TRIM(o."EXCLUSIONS") <> ''
),

/* 3. explode extras requested by customer (duplicates allowed) */
extra_toppings AS (
    SELECT
        o."ROW_ID",
        TO_NUMBER(TRIM(f.value))            AS "TOPPING_ID"
    FROM orders o
    CROSS JOIN LATERAL FLATTEN( INPUT => SPLIT(o."EXTRAS", ',')) f
    WHERE TRIM(o."EXTRAS") <> ''
),

/* 4. build final list of topping IDs (keep std not-excluded, add extras) */
final_topping_rows AS (
    /* kept standard toppings */
    SELECT st."ROW_ID", st."TOPPING_ID"
    FROM   standard_toppings st
    LEFT   JOIN exclusion_toppings ex
           ON  st."ROW_ID"   = ex."ROW_ID"
          AND st."TOPPING_ID" = ex."TOPPING_ID"
    WHERE  ex."TOPPING_ID" IS NULL

    UNION ALL        /* append all extras (may duplicate) */
    SELECT et."ROW_ID", et."TOPPING_ID"
    FROM   extra_toppings et
),

/* 5. count occurrences of each topping within a single order row */
topping_counts AS (
    SELECT
        "ROW_ID",
        "TOPPING_ID",
        COUNT(*)                           AS "CNT"
    FROM final_topping_rows
    GROUP BY "ROW_ID", "TOPPING_ID"
),

/* 6. translate topping IDs to names, prefix “2x/3x …” when duplicated */
named_toppings AS (
    SELECT
        tc."ROW_ID",
        CASE WHEN tc."CNT" > 1
             THEN CONCAT(tc."CNT"::VARCHAR, 'x', pt."topping_name")
             ELSE pt."topping_name"
        END                                AS "INGREDIENT_NAME",
        pt."topping_name"                  AS "SORT_NAME"
    FROM topping_counts tc
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
          ON pt."topping_id" = tc."TOPPING_ID"
),

/* 7. concatenate toppings per row in alphabetical order */
ingredients_string AS (
    SELECT
        "ROW_ID",
        LISTAGG("INGREDIENT_NAME", ', ')
             WITHIN GROUP (ORDER BY "SORT_NAME")  AS "INGREDIENTS"
    FROM named_toppings
    GROUP BY "ROW_ID"
),

/* 8. assemble final string with pizza name + toppings */
result AS (
    SELECT
        o."ROW_ID",
        o."ORDER_ID",
        o."CUSTOMER_ID",
        pn."pizza_name"                               AS "PIZZA_NAME",
        CONCAT(pn."pizza_name", ': ', isg."INGREDIENTS") AS "FINAL_INGREDIENTS"
    FROM orders o
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_NAMES pn
          ON pn."pizza_id" = o."PIZZA_ID"
    JOIN ingredients_string isg
          ON isg."ROW_ID"  = o."ROW_ID"
)

/* 9. final output */
SELECT
    "ROW_ID"            AS row_id,
    "ORDER_ID"          AS order_id,
    "CUSTOMER_ID"       AS customer_id,
    "PIZZA_NAME"        AS pizza_name,
    "FINAL_INGREDIENTS" AS final_ingredients
FROM result
ORDER BY row_id;