/*  Hubs whose number of finished orders grew more than 20 % from February to March
    (considering the latest year present in the data)                                   */

WITH finished_orders AS (       -- finished orders only, Feb & Mar for every year
    SELECT  o."order_created_year"       AS "YEAR",
            o."order_created_month"      AS "MONTH",
            s."hub_id"                   AS "HUB_ID",
            h."hub_name"                 AS "HUB_NAME",
            COUNT(*)                     AS "FINISHED_ORDERS"
    FROM  DELIVERY_CENTER.DELIVERY_CENTER.ORDERS   o
    JOIN  DELIVERY_CENTER.DELIVERY_CENTER.STORES   s ON o."store_id" = s."store_id"
    JOIN  DELIVERY_CENTER.DELIVERY_CENTER.HUBS     h ON s."hub_id"   = h."hub_id"
    WHERE o."order_status"        = 'FINISHED'
      AND o."order_created_month" IN (2,3)          -- February & March
    GROUP BY o."order_created_year",
             o."order_created_month",
             s."hub_id",
             h."hub_name"
),

latest_year AS (                -- focus on the most recent year in the table
    SELECT MAX("YEAR") AS "YEAR" FROM finished_orders
),

filtered AS (                   -- finished orders for that latest year only
    SELECT f.*
    FROM   finished_orders f
    JOIN   latest_year        ly ON f."YEAR" = ly."YEAR"
),

pivoted AS (                    -- put Feb & Mar side by side
    SELECT  "YEAR",
            "HUB_ID",
            "HUB_NAME",
            SUM(CASE WHEN "MONTH" = 2 THEN "FINISHED_ORDERS" ELSE 0 END) AS "FEB_ORDERS",
            SUM(CASE WHEN "MONTH" = 3 THEN "FINISHED_ORDERS" ELSE 0 END) AS "MAR_ORDERS"
    FROM    filtered
    GROUP BY "YEAR", "HUB_ID", "HUB_NAME"
),

growth AS (                     -- compute growth ratio
    SELECT  "YEAR",
            "HUB_ID",
            "HUB_NAME",
            "FEB_ORDERS",
            "MAR_ORDERS",
            CASE WHEN "FEB_ORDERS" > 0
                 THEN ("MAR_ORDERS" - "FEB_ORDERS") / "FEB_ORDERS"
                 ELSE NULL
            END AS "GROWTH_RATIO"
    FROM    pivoted
)

SELECT  "HUB_ID",
        "HUB_NAME",
        "YEAR",
        "FEB_ORDERS"  AS "FEB_FINISHED_ORDERS",
        "MAR_ORDERS"  AS "MAR_FINISHED_ORDERS",
        ROUND("GROWTH_RATIO" * 100, 2) AS "PERCENT_INCREASE"
FROM    growth
WHERE   "GROWTH_RATIO" > 0.20          -- more than 20 % increase
ORDER BY "PERCENT_INCREASE" DESC NULLS LAST;