/* -------------------------------------------------------------------------
   Month-by-month 2023 profitability report for the “Sleep & Lounge” category
   ------------------------------------------------------------------------- */
WITH months_2023 AS (   -- build one row for each month of the 2023 calendar year
    SELECT
        TO_CHAR(
            DATE_TRUNC(
                'month',
                DATEADD(month, seq4(), '2023-01-01')
            ),
            'YYYY-MM'
        ) AS "month"
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),
sleep_lounge_2023 AS (  -- aggregate completed Sleep & Lounge order-items
    SELECT
        TO_CHAR(
            DATE_TRUNC(
                'month',
                TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
            ),
            'YYYY-MM'
        )                                 AS "month",
        COUNT(*)                          AS "complete_orders",
        SUM(oi."sale_price")              AS "total_sales",
        SUM(ii."cost")                    AS "total_cost",
        SUM(oi."sale_price" - ii."cost")  AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS     oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS ii
         ON oi."inventory_item_id" = ii."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS        p
         ON oi."product_id" = p."id"
    WHERE p."category" ILIKE '%Sleep%Lounge%'            -- focus category
      AND oi."status" = 'Complete'                       -- only completed items
      AND oi."created_at" BETWEEN 1672531200000000       -- 01-Jan-2023 00:00:00
                             AND 1704067199000000        -- 31-Dec-2023 23:59:59
    GROUP BY 1
)
SELECT
    m."month",
    COALESCE(s."complete_orders", 0)  AS "complete_orders",
    COALESCE(s."total_sales", 0)      AS "total_sales",
    COALESCE(s."total_cost", 0)       AS "total_cost",
    COALESCE(s."total_profit", 0)     AS "total_profit",
    CASE
        WHEN COALESCE(s."total_cost", 0) <> 0
        THEN ROUND(s."total_profit" / s."total_cost", 4)
        ELSE NULL
    END                               AS "profit_to_cost_ratio"
FROM months_2023 m
LEFT JOIN sleep_lounge_2023 s
       ON m."month" = s."month"
ORDER BY m."month";