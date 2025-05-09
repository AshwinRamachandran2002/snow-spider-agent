/* ------------------------------------------------------------
   Build the required “one-row-per-pizza-order” result
   ------------------------------------------------------------ */
WITH base_orders AS (  /* every pizza line that was ordered */
    SELECT
        ROW_NUMBER() OVER (PARTITION BY co."order_id"
                           ORDER BY co."order_time", co."pizza_id")  AS "ROW_ID",
        co."order_id"                                                AS "ORDER_ID",
        co."customer_id"                                             AS "CUSTOMER_ID",
        /* force the requested mapping: 1 = Meatlovers, 2 = every other pizza */
        CASE WHEN LOWER(pn."pizza_name") = 'meatlovers' THEN 1 ELSE 2 END
                                                                    AS "PIZZA_ID_MAPPED",
        pn."pizza_name"                                              AS "PIZZA_NAME",
        COALESCE(co."exclusions", '')                                AS "EXCLUSIONS_TXT",
        COALESCE(co."extras"    , '')                                AS "EXTRAS_TXT",
        co."order_time"                                              AS "ORDER_TIME"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CUSTOMER_ORDERS  co
    LEFT JOIN MODERN_DATA.MODERN_DATA.PIZZA_NAMES       pn
           ON co."pizza_id" = pn."pizza_id"
),
/* ---------- Standard toppings for every pizza (already re-mapped above) ---------- */
recipe_toppings AS (
    SELECT
        CASE WHEN LOWER(pn."pizza_name") = 'meatlovers' THEN 1 ELSE 2 END
                                                                    AS "PIZZA_ID_MAPPED",
        TRIM(f.value)::NUMBER                                        AS "TOPPING_ID"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_RECIPES  pr
    JOIN MODERN_DATA.MODERN_DATA.PIZZA_NAMES    pn
         ON pr."pizza_id" = pn."pizza_id",
         LATERAL FLATTEN(
             INPUT => SPLIT(REGEXP_REPLACE(pr."toppings", '\\s+', ''), ',')
         ) f
),
/* ---------- exclusions and extras split into individual IDs --------------------- */
order_exclusions AS (
    SELECT  bo."ROW_ID",
            bo."ORDER_ID",
            TRIM(f.value)::NUMBER AS "TOPPING_ID"
    FROM base_orders bo,
         LATERAL FLATTEN(
             INPUT => IFF(bo."EXCLUSIONS_TXT" = '',
                          NULL,
                          SPLIT(REGEXP_REPLACE(bo."EXCLUSIONS_TXT", '\\s+', ''), ','))
         ) f
),
order_extras AS (
    SELECT  bo."ROW_ID",
            bo."ORDER_ID",
            bo."CUSTOMER_ID",
            bo."PIZZA_NAME",
            TRIM(f.value)::NUMBER AS "TOPPING_ID",
            1                     AS "CNT"
    FROM base_orders bo,
         LATERAL FLATTEN(
             INPUT => IFF(bo."EXTRAS_TXT" = '',
                          NULL,
                          SPLIT(REGEXP_REPLACE(bo."EXTRAS_TXT", '\\s+', ''), ','))
         ) f
),
/* ---------- recipe items with the exclusions removed ---------------------------- */
recipe_after_excl AS (
    SELECT  bo."ROW_ID",
            bo."ORDER_ID",
            bo."CUSTOMER_ID",
            bo."PIZZA_NAME",
            rt."TOPPING_ID",
            1 AS "CNT"
    FROM base_orders      bo
    JOIN recipe_toppings  rt
         ON rt."PIZZA_ID_MAPPED" = bo."PIZZA_ID_MAPPED"
    LEFT JOIN order_exclusions ex
         ON ex."ROW_ID"      = bo."ROW_ID"
        AND ex."ORDER_ID"    = bo."ORDER_ID"
        AND ex."TOPPING_ID"  = rt."TOPPING_ID"
    WHERE ex."TOPPING_ID" IS NULL              -- drop anything that was excluded
),
/* ---------- union recipe + extras, then count duplicates ------------------------ */
all_ingredients AS (
    SELECT * FROM recipe_after_excl
    UNION ALL
    SELECT * FROM order_extras
),
ingredient_counts AS (
    SELECT  "ROW_ID",
            "ORDER_ID",
            MIN("CUSTOMER_ID")  AS "CUSTOMER_ID",
            MIN("PIZZA_NAME")   AS "PIZZA_NAME",
            "TOPPING_ID",
            SUM("CNT")          AS "CNT"
    FROM   all_ingredients
    GROUP  BY "ROW_ID", "ORDER_ID", "TOPPING_ID"
),
/* ---------- translate topping_id → topping_name -------------------------------- */
ingredient_names AS (
    SELECT  ic."ROW_ID",
            ic."ORDER_ID",
            ic."CUSTOMER_ID",
            ic."PIZZA_NAME",
            pt."topping_name"   AS "TOPPING_NAME",
            ic."CNT"
    FROM   ingredient_counts ic
    LEFT JOIN MODERN_DATA.MODERN_DATA.PIZZA_TOPPINGS pt
           ON pt."topping_id" = ic."TOPPING_ID"
),
/* ---------- build the final, ordered, duplicate-aware topping list -------------- */
final_per_pizza AS (
    SELECT
        "ROW_ID",
        "ORDER_ID",
        "CUSTOMER_ID",
        "PIZZA_NAME",
        LISTAGG(
            CASE WHEN "CNT" > 1
                 THEN "CNT" || 'x ' || "TOPPING_NAME"
                 ELSE "TOPPING_NAME"
            END,
            ', '
        ) WITHIN GROUP (ORDER BY "TOPPING_NAME")  AS "TOPPING_LIST"
    FROM ingredient_names
    GROUP BY "ROW_ID", "ORDER_ID", "CUSTOMER_ID", "PIZZA_NAME"
)
/* ----------------------------- final answer ------------------------------------- */
SELECT
    "ROW_ID",
    "ORDER_ID",
    "CUSTOMER_ID",
    "PIZZA_NAME",
    "PIZZA_NAME" || ': ' || "TOPPING_LIST"  AS "FINAL_INGREDIENTS"
FROM final_per_pizza
ORDER BY "ROW_ID", "ORDER_ID";