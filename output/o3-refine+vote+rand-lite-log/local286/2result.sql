WITH
/* --------- 1.  Review score per order (one row per order) --------- */
"order_reviews_unique" AS (
    SELECT
        "order_id",
        AVG("review_score") AS "review_score"
    FROM "order_reviews"
    GROUP BY "order_id"
),

/* --------- 2.  Items sold per seller + category (to find top‑category) --------- */
"seller_category_counts" AS (
    SELECT
        oi."seller_id",
        COALESCE(pcnt."product_category_name_english", 'unknown') AS "category_english",
        COUNT(*) AS "items_sold"
    FROM "order_items"            AS oi
    JOIN "products"               AS p    ON p."product_id" = oi."product_id"
    LEFT JOIN "product_category_name_translation" AS pcnt
           ON pcnt."product_category_name" = p."product_category_name"
    GROUP BY oi."seller_id", "category_english"
),

/* keep only the category with the highest volume for each seller */
"seller_top_category" AS (
    SELECT
        "seller_id",
        "category_english" AS "top_category_english"
    FROM (
        SELECT
            "seller_id",
            "category_english",
            "items_sold",
            ROW_NUMBER() OVER (PARTITION BY "seller_id"
                               ORDER BY "items_sold" DESC) AS rn
        FROM "seller_category_counts"
    )
    WHERE rn = 1
),

/* --------- 3.  Main seller statistics --------- */
"seller_stats" AS (
    SELECT
        oi."seller_id",
        COUNT(*)                      AS "total_products_sold",
        SUM(oi."price")               AS "total_sales_value",
        AVG(oi."price")               AS "avg_item_price",
        AVG(oru."review_score")       AS "avg_review_score",
        /* packing time = time from approval to carrier delivery, in days */
        AVG(
            JULIANDAY(o."order_delivered_carrier_date")
          - JULIANDAY(o."order_approved_at")
        )                            AS "avg_packing_time_days"
    FROM "order_items"  AS oi
    JOIN "orders"       AS o   ON o."order_id" = oi."order_id"
    LEFT JOIN "order_reviews_unique" AS oru
           ON oru."order_id" = oi."order_id"
    /* ensure dates exist so the diff is meaningful */
    WHERE o."order_delivered_carrier_date" IS NOT NULL
      AND o."order_approved_at"            IS NOT NULL
    GROUP BY oi."seller_id"
)

/* --------- 4.  Final report: only sellers with >100 items sold --------- */
SELECT
    ss."seller_id",
    ss."total_products_sold",
    ROUND(ss."total_sales_value",      4) AS "total_sales_value",
    ROUND(ss."avg_item_price",         4) AS "avg_item_price",
    ROUND(ss."avg_review_score",       4) AS "avg_review_score",
    ROUND(ss."avg_packing_time_days",  4) AS "avg_packing_time_days",
    stc."top_category_english"
FROM "seller_stats"        AS ss
JOIN "seller_top_category" AS stc ON stc."seller_id" = ss."seller_id"
WHERE ss."total_products_sold" > 100
ORDER BY ss."total_sales_value" DESC,
         ss."seller_id";