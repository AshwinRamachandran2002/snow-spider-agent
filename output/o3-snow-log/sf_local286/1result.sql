/* ---------------------------------------------------------
   Comprehensive performance report on sellers
   - Only sellers with > 100 items sold
   - Shows total sales, average item price, average review
     score, average packing time, and their top-selling
     product category (in English)
----------------------------------------------------------*/
WITH base_sales AS (      /* quantity & gross sales --------------------*/
    SELECT
        "seller_id",
        COUNT(*)                       AS "items_sold",
        SUM("price")                   AS "total_sales"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS
    GROUP BY "seller_id"
    HAVING COUNT(*) > 100
),

reviews AS (              /* average review score ----------------------*/
    SELECT
        oi."seller_id",
        AVG(r."review_score")          AS "avg_review_score"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS   oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_REVIEWS r
          ON oi."order_id" = r."order_id"
    GROUP BY oi."seller_id"
),

packing AS (              /* average packing time (days) ---------------*/
    SELECT
        oi."seller_id",
        AVG(
            DATEDIFF(
                'day',
                TO_TIMESTAMP(o."order_approved_at"),
                TO_TIMESTAMP(o."order_delivered_carrier_date")
            )
        )                                    AS "avg_packing_days"
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.ORDERS      o
          ON oi."order_id" = o."order_id"
    WHERE o."order_approved_at"            <> ''
      AND o."order_delivered_carrier_date" <> ''
    GROUP BY oi."seller_id"
),

top_cat AS (              /* top-selling English category --------------*/
    SELECT
        agg."seller_id",
        agg."product_category_name_english" AS "top_category_english"
    FROM (
        SELECT
            oi."seller_id",
            t."product_category_name_english",
            COUNT(*)                        AS "qty",
            ROW_NUMBER() OVER (
                PARTITION BY oi."seller_id"
                ORDER BY COUNT(*) DESC
            )                               AS "rn"
        FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS                   oi
        JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.PRODUCTS                      p
              ON oi."product_id" = p."product_id"
        JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.PRODUCT_CATEGORY_NAME_TRANSLATION t
              ON p."product_category_name" = t."product_category_name"
        GROUP BY
            oi."seller_id",
            t."product_category_name_english"
    ) agg
    QUALIFY agg."rn" = 1
)

/* --------------------------- final report -----------------------------*/
SELECT
    bs."seller_id",
    bs."items_sold",
    bs."total_sales",
    ROUND(bs."total_sales" / bs."items_sold", 4)  AS "avg_item_price",
    rv."avg_review_score",
    pk."avg_packing_days",
    tc."top_category_english"
FROM base_sales bs
LEFT JOIN reviews  rv ON bs."seller_id" = rv."seller_id"
LEFT JOIN packing  pk ON bs."seller_id" = pk."seller_id"
LEFT JOIN top_cat  tc ON bs."seller_id" = tc."seller_id"
ORDER BY bs."total_sales" DESC NULLS LAST;