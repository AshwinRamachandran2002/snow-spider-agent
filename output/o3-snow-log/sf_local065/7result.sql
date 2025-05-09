WITH valid_orders AS (
    /* keep only orders that were actually delivered */
    SELECT DISTINCT "order_id"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_RUNNER_ORDERS
    WHERE (TRIM(COALESCE("cancellation", '')) = '')
      AND (TRIM(COALESCE("pickup_time", '')) <> '')
),
pizza_prices AS (
    /* hard-code menu prices */
    SELECT 1  AS "pizza_id", 12 AS "base_price" UNION ALL
    SELECT 2  AS "pizza_id", 10 AS "base_price"
),
order_lines AS (
    /* customer order lines that belong to a delivered order
       and are either Meat Lovers (id 1) or Vegetarian (id 2) */
    SELECT
        c."order_id",
        c."pizza_id",
        p."base_price",
        /* count extra toppings (comma-separated list, optional spaces) */
        CASE
            WHEN TRIM(COALESCE(c."extras", '')) = '' THEN 0
            ELSE ARRAY_SIZE(
                     SPLIT(
                         REGEXP_REPLACE(c."extras", '\\s', ''),  -- remove spaces
                         ','
                     )
                 )
        END                                     AS "extras_cnt"
    FROM MODERN_DATA.MODERN_DATA.PIZZA_CLEAN_CUSTOMER_ORDERS      c
    JOIN valid_orders                                              v  ON v."order_id" = c."order_id"
    JOIN pizza_prices                                              p  ON p."pizza_id" = c."pizza_id"
)
SELECT
    SUM("base_price" + "extras_cnt") AS "total_income"
FROM order_lines;