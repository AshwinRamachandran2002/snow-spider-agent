WITH base AS (   -- all completed order-items delivered before 2022
    SELECT
        p."category"                                                     AS "product_category",
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(oi."delivered_at"/1000000)) AS "month_start",
        oi."order_id"                                                    AS "order_id",
        oi."sale_price"                                                  AS "sale_price",
        ii."cost"                                                        AS "cost"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"      oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"         p
          ON p."id" = oi."product_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS"  ii
          ON ii."id" = oi."inventory_item_id"
    WHERE oi."status"       = 'Complete'
      AND oi."delivered_at" IS NOT NULL
      AND TO_TIMESTAMP_LTZ(oi."delivered_at"/1000000) < '2022-01-01'
), 
monthly AS (     -- monthly aggregates
    SELECT
        "product_category",
        "month_start",
        SUM("sale_price")                     AS "total_revenue",
        SUM("cost")                           AS "total_cost",
        COUNT(DISTINCT "order_id")            AS "total_orders"
    FROM base
    GROUP BY "product_category", "month_start"
)

SELECT
    "product_category",
    "month_start"                                                     AS "month_year",
    ROUND("total_revenue",4)                                          AS "total_revenue",
    "total_orders"                                                    AS "completed_orders",
    ROUND("total_cost",4)                                             AS "total_cost",
    ROUND("total_revenue" - "total_cost",4)                           AS "total_profit",
    ROUND(
         IFF("total_cost" = 0, NULL,
             ("total_revenue" - "total_cost") / "total_cost"),4)      AS "profit_to_cost_ratio",
    /* MoM revenue growth % */
    ROUND(
         IFF(
             LAG("total_revenue") OVER (PARTITION BY "product_category" ORDER BY "month_start") IN (0, NULL),
             NULL,
             ("total_revenue" - LAG("total_revenue") OVER (PARTITION BY "product_category" ORDER BY "month_start"))
             / LAG("total_revenue") OVER (PARTITION BY "product_category" ORDER BY "month_start") * 100
         ),4)                                                         AS "revenue_mom_growth_pct",
    /* MoM orders growth % */
    ROUND(
         IFF(
             LAG("total_orders") OVER (PARTITION BY "product_category" ORDER BY "month_start") IN (0, NULL),
             NULL,
             ("total_orders" - LAG("total_orders") OVER (PARTITION BY "product_category" ORDER BY "month_start"))
             / LAG("total_orders") OVER (PARTITION BY "product_category" ORDER BY "month_start") * 100
         ),4)                                                         AS "orders_mom_growth_pct"
FROM monthly
ORDER BY "product_category", "month_start" NULLS LAST;