/* -----------------------------------------------------------
   Comprehensive sellers performance report
   – Focus: total sales, average item price, average review
     scores, average packing-time and best-selling category
   – Scope: only sellers with more than 100 items sold
------------------------------------------------------------*/
WITH seller_sales AS (   -- basic commercial metrics
    SELECT
        "seller_id",
        COUNT(*)                              AS "items_sold",
        SUM("price")                          AS "total_sales_value",
        AVG("price")                          AS "avg_item_price"
    FROM  ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_ITEMS"
    GROUP BY "seller_id"
),
seller_packing AS (      -- packing time (approved → shipping-limit)
    SELECT
        oi."seller_id",
        AVG(
            DATEDIFF(
                'hour',
                TRY_TO_TIMESTAMP(o."order_approved_at"),
                TRY_TO_TIMESTAMP(oi."shipping_limit_date")
            )
        )                                    AS "avg_packing_time_hours"
    FROM  ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_ITEMS"  oi
    JOIN  ELECTRONIC_SALES.ELECTRONIC_SALES."ORDERS"       o
          ON oi."order_id" = o."order_id"
    WHERE o."order_approved_at" IS NOT NULL
      AND oi."shipping_limit_date" IS NOT NULL
    GROUP BY oi."seller_id"
),
seller_reviews AS (      -- average review score per seller
    SELECT
        so."seller_id",
        AVG(orv."review_score")              AS "avg_review_score"
    FROM (
            SELECT DISTINCT
                   "seller_id",
                   "order_id"
            FROM  ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_ITEMS"
         ) so
    JOIN  ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_REVIEWS" orv
          ON so."order_id" = orv."order_id"
    GROUP BY so."seller_id"
),
seller_top_category AS ( -- best-selling product category (English)
    SELECT
        "seller_id",
        "product_category_name_english"      AS "top_category_english",
        "items_in_category",
        ROW_NUMBER() OVER (PARTITION BY "seller_id"
                           ORDER BY "items_in_category" DESC) AS rn
    FROM (
            SELECT
                oi."seller_id",
                pct."product_category_name_english",
                COUNT(*)                         AS "items_in_category"
            FROM  ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_ITEMS" oi
            JOIN  ELECTRONIC_SALES.ELECTRONIC_SALES."PRODUCTS"    pr
                  ON oi."product_id" = pr."product_id"
            JOIN  ELECTRONIC_SALES.ELECTRONIC_SALES."PRODUCT_CATEGORY_NAME_TRANSLATION" pct
                  ON pr."product_category_name" = pct."product_category_name"
            GROUP BY
                  oi."seller_id",
                  pct."product_category_name_english"
         )
)
SELECT
    ss."seller_id",
    ss."items_sold",
    ROUND(ss."total_sales_value",     4) AS "total_sales_value",
    ROUND(ss."avg_item_price",        4) AS "avg_item_price",
    ROUND(sr."avg_review_score",      4) AS "avg_review_score",
    ROUND(sp."avg_packing_time_hours",4) AS "avg_packing_time_hours",
    stc."top_category_english",
    stc."items_in_category"               AS "top_category_items_sold"
FROM   seller_sales            ss
LEFT JOIN seller_packing       sp  ON ss."seller_id" = sp."seller_id"
LEFT JOIN seller_reviews       sr  ON ss."seller_id" = sr."seller_id"
LEFT JOIN seller_top_category  stc ON ss."seller_id" = stc."seller_id" AND stc.rn = 1
WHERE  ss."items_sold" > 100
ORDER  BY ss."total_sales_value" DESC NULLS LAST;