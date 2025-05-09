/*--------------------------------------------------------------
  Comprehensive Seller Performance Report
  – Scope: Sellers with > 100 items sold
  – Metrics : total sales, avg item price, avg review score,
              avg packing time (hours),
              top-selling product category in English
--------------------------------------------------------------*/
WITH perf AS (  -- sales volume & value
    SELECT
        oi."seller_id",
        COUNT(*)                       AS items_sold,
        SUM(oi."price")                AS total_sales_value,
        AVG(oi."price")                AS avg_item_price
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS oi
    GROUP BY oi."seller_id"
    HAVING COUNT(*) > 100
),

rev AS (   -- average review score
    SELECT
        oi."seller_id",
        AVG(orv."review_score")        AS avg_review_score
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS   oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_REVIEWS orv
          ON oi."order_id" = orv."order_id"
    GROUP BY oi."seller_id"
),

pack AS (  -- average packing time (approval → shipping limit)
    SELECT
        oi."seller_id",
        AVG(
            DATEDIFF(
                'hour',
                TRY_TO_TIMESTAMP(o."order_approved_at"),
                TRY_TO_TIMESTAMP(oi."shipping_limit_date")
            )
        )                                AS avg_packing_time_hours
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.ORDERS      o
          ON oi."order_id" = o."order_id"
    WHERE o."order_approved_at"    <> ''
      AND oi."shipping_limit_date" <> ''
    GROUP BY oi."seller_id"
),

-- rank product categories (English) by items sold per seller
cat_rank AS (
    SELECT
        oi."seller_id",
        pct."product_category_name_english",
        COUNT(*)                        AS items_sold_in_category,
        ROW_NUMBER() OVER (
            PARTITION BY oi."seller_id"
            ORDER BY COUNT(*) DESC
        )                               AS rn
    FROM ELECTRONIC_SALES.ELECTRONIC_SALES.ORDER_ITEMS                    oi
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.PRODUCTS                       p
          ON oi."product_id" = p."product_id"
    JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.PRODUCT_CATEGORY_NAME_TRANSLATION pct
          ON p."product_category_name" = pct."product_category_name"
    GROUP BY oi."seller_id", pct."product_category_name_english"
),

top_cat AS (  -- keep only the top-selling category per seller
    SELECT
        "seller_id",
        "product_category_name_english",
        items_sold_in_category
    FROM cat_rank
    WHERE rn = 1
)

SELECT
    perf."seller_id",
    s."seller_city",
    s."seller_state",
    perf.items_sold,
    perf.total_sales_value,
    perf.avg_item_price,
    rev.avg_review_score,
    pack.avg_packing_time_hours,
    top_cat."product_category_name_english" AS top_product_category_english,
    top_cat.items_sold_in_category          AS top_category_items_sold
FROM perf
LEFT JOIN rev      ON perf."seller_id" = rev."seller_id"
LEFT JOIN pack     ON perf."seller_id" = pack."seller_id"
LEFT JOIN top_cat  ON perf."seller_id" = top_cat."seller_id"
LEFT JOIN ELECTRONIC_SALES.ELECTRONIC_SALES.SELLERS s
       ON perf."seller_id" = s."seller_id"
ORDER BY perf.items_sold DESC NULLS LAST;