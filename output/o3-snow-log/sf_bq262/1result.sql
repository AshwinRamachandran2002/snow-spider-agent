/*----------------------------------------------------------
Monthly sales, revenue and profit report
   • Period analysed : 2019-06  →  2019-12
   • Growth rates     : month-over-month, baseline month (June) kept
     for calculations but removed from the final output
----------------------------------------------------------*/
WITH order_item_base AS (   -- pull order-item level facts for the period
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("created_at" / 1000000)
        )                               AS "MONTH_START",
        "order_id"                      AS "ORDER_ID",
        "product_id"                    AS "PRODUCT_ID",
        "inventory_item_id"             AS "INVENTORY_ITEM_ID",
        "sale_price"                    AS "SALE_PRICE"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE DATE_TRUNC(
              'month',
              TO_TIMESTAMP("created_at" / 1000000)
          ) BETWEEN '2019-06-01' AND '2019-12-01'
),
joined_data AS (          -- enrich with category and cost
    SELECT
        oib."MONTH_START",
        p."category"                              AS "PRODUCT_CATEGORY",
        oib."ORDER_ID",
        oib."SALE_PRICE",
        (oib."SALE_PRICE" - ii."cost")            AS "PROFIT"
    FROM order_item_base oib
    LEFT JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p
           ON oib."PRODUCT_ID" = p."id"
    LEFT JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii
           ON oib."INVENTORY_ITEM_ID" = ii."id"
),
monthly_metrics AS (      -- aggregate to month/category level
    SELECT
        "MONTH_START",
        "PRODUCT_CATEGORY",
        COUNT(DISTINCT "ORDER_ID")      AS "TOTAL_ORDERS",
        SUM("SALE_PRICE")               AS "TOTAL_REVENUE",
        SUM("PROFIT")                   AS "TOTAL_PROFIT"
    FROM joined_data
    GROUP BY "MONTH_START", "PRODUCT_CATEGORY"
),
metrics_with_growth AS (  -- calculate MoM growth (uses June as previous month for July)
    SELECT
        "MONTH_START",
        "PRODUCT_CATEGORY",
        "TOTAL_ORDERS",
        "TOTAL_REVENUE",
        "TOTAL_PROFIT",
        LAG("TOTAL_ORDERS")  OVER (PARTITION BY "PRODUCT_CATEGORY" ORDER BY "MONTH_START") AS "PREV_ORDERS",
        LAG("TOTAL_REVENUE") OVER (PARTITION BY "PRODUCT_CATEGORY" ORDER BY "MONTH_START") AS "PREV_REVENUE",
        LAG("TOTAL_PROFIT")  OVER (PARTITION BY "PRODUCT_CATEGORY" ORDER BY "MONTH_START") AS "PREV_PROFIT"
    FROM monthly_metrics
)
SELECT
    TO_CHAR("MONTH_START", 'YYYY-MM')                         AS "MONTH",
    "PRODUCT_CATEGORY",
    "TOTAL_ORDERS",
    ROUND("TOTAL_REVENUE", 4)                                 AS "TOTAL_REVENUE",
    ROUND("TOTAL_PROFIT", 4)                                  AS "TOTAL_PROFIT",
    ROUND(
        ("TOTAL_ORDERS"  - "PREV_ORDERS")  / NULLIF("PREV_ORDERS", 0),
        4
    )                                                         AS "ORDER_GROWTH_RATE",
    ROUND(
        ("TOTAL_REVENUE" - "PREV_REVENUE") / NULLIF("PREV_REVENUE", 0),
        4
    )                                                         AS "REVENUE_GROWTH_RATE",
    ROUND(
        ("TOTAL_PROFIT"  - "PREV_PROFIT")  / NULLIF("PREV_PROFIT", 0),
        4
    )                                                         AS "PROFIT_GROWTH_RATE"
FROM metrics_with_growth
WHERE "MONTH_START" >= '2019-07-01'          -- omit June from final output
ORDER BY "MONTH", "PRODUCT_CATEGORY";