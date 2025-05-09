/* ---------------------------------------------------------------
   Comprehensive performance report for high-volume sellers (>100)
-----------------------------------------------------------------*/
WITH high_sellers AS (   -- sellers with >100 items sold
    SELECT
        "seller_id",
        COUNT(*) AS "items_sold"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS
    GROUP BY "seller_id"
    HAVING COUNT(*) > 100
),
seller_sales AS (        -- total sales & average item price
    SELECT
        oi."seller_id",
        COUNT(*)            AS "items_sold",
        SUM(oi."price")     AS "total_sales_value",
        AVG(oi."price")     AS "avg_item_price"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS oi
    JOIN high_sellers hs
      ON oi."seller_id" = hs."seller_id"
    GROUP BY oi."seller_id"
),
seller_reviews AS (      -- average review score
    SELECT
        oi."seller_id",
        AVG(r."review_score") AS "avg_review_score"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_REVIEWS r
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS oi
      ON r."order_id" = oi."order_id"
    JOIN high_sellers hs
      ON oi."seller_id" = hs."seller_id"
    GROUP BY oi."seller_id"
),
seller_packing AS (      -- average packing time in days (safe parsing)
    SELECT
        oi."seller_id",
        AVG(
            DATEDIFF(
                'day',
                TRY_TO_TIMESTAMP(o."order_approved_at"),
                TRY_TO_TIMESTAMP(o."order_delivered_carrier_date")
            )
        ) AS "avg_packing_days"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDERS o
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS oi
      ON o."order_id" = oi."order_id"
    JOIN high_sellers hs
      ON oi."seller_id" = hs."seller_id"
    WHERE TRY_TO_TIMESTAMP(o."order_approved_at")            IS NOT NULL
      AND TRY_TO_TIMESTAMP(o."order_delivered_carrier_date") IS NOT NULL
    GROUP BY oi."seller_id"
),
seller_info AS (         -- basic seller location
    SELECT
        "seller_id",
        "seller_city",
        "seller_state"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.SELLERS
),
category_sales AS (      -- volume by product category (English)
    SELECT
        pct."product_category_name_english" AS "category_en",
        COUNT(*)                            AS "items_sold"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS oi
    JOIN high_sellers hs
      ON oi."seller_id" = hs."seller_id"
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.PRODUCTS p
      ON oi."product_id" = p."product_id"
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.PRODUCT_CATEGORY_NAME_TRANSLATION pct
      ON p."product_category_name" = pct."product_category_name"
    GROUP BY pct."product_category_name_english"
),
top_category AS (        -- highest-volume category overall
    SELECT
        "category_en",
        "items_sold"
    FROM category_sales
    ORDER BY "items_sold" DESC NULLS LAST
    LIMIT 1
)

SELECT
    ss."seller_id",
    si."seller_city",
    si."seller_state",
    ss."items_sold",
    ss."total_sales_value",
    ss."avg_item_price",
    sr."avg_review_score",
    sp."avg_packing_days",
    tc."category_en"  AS "top_category_en",
    tc."items_sold"   AS "top_category_items_sold"
FROM seller_sales  ss
LEFT JOIN seller_info   si ON ss."seller_id" = si."seller_id"
LEFT JOIN seller_reviews sr ON ss."seller_id" = sr."seller_id"
LEFT JOIN seller_packing sp ON ss."seller_id" = sp."seller_id"
CROSS JOIN top_category tc
ORDER BY ss."total_sales_value" DESC NULLS LAST;