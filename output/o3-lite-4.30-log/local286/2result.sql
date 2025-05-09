WITH seller_sales AS (
    SELECT
        "seller_id",
        COUNT(*)            AS total_units_sold,
        SUM("price")        AS total_sales,
        AVG("price")        AS average_item_price
    FROM "order_items"
    GROUP BY "seller_id"
    HAVING COUNT(*) > 100
),
seller_reviews AS (
    SELECT
        oi."seller_id",
        AVG(orv."review_score") AS average_review_score
    FROM "order_items"   AS oi
    JOIN "order_reviews" AS orv
      ON oi."order_id" = orv."order_id"
    GROUP BY oi."seller_id"
),
seller_pack AS (
    SELECT
        t."seller_id",
        AVG(t.packing_time_days) AS average_packing_time_days
    FROM (
        SELECT DISTINCT
               oi."seller_id",
               oi."order_id",
               julianday(o."order_delivered_carrier_date")
             - julianday(o."order_purchase_timestamp") AS packing_time_days
        FROM "order_items" AS oi
        JOIN "orders"      AS o
          ON oi."order_id" = o."order_id"
        WHERE o."order_delivered_carrier_date" IS NOT NULL
    ) t
    GROUP BY t."seller_id"
),
seller_top_cat AS (
    SELECT *
    FROM (
        SELECT
            oi."seller_id",
            ptn."product_category_name_english",
            COUNT(*) AS items_sold,
            ROW_NUMBER() OVER (
                PARTITION BY oi."seller_id"
                ORDER BY COUNT(*) DESC
            ) AS rn
        FROM "order_items"                       AS oi
        JOIN "products"                          AS p
          ON p."product_id" = oi."product_id"
        LEFT JOIN "product_category_name_translation" AS ptn
          ON ptn."product_category_name" = p."product_category_name"
        GROUP BY oi."seller_id", ptn."product_category_name_english"
    )
    WHERE rn = 1
)
SELECT
    ss."seller_id",
    s."seller_city"                                   AS seller_name,
    stc."product_category_name_english",
    ss.total_units_sold,
    ROUND(ss.total_sales,4)                           AS total_sales,
    ROUND(ss.average_item_price,4)                    AS average_item_price,
    ROUND(sr.average_review_score,4)                  AS average_review_score,
    ROUND(sp.average_packing_time_days,4)             AS average_packing_time_days
FROM seller_sales        AS ss
JOIN "sellers"           AS s   ON s."seller_id" = ss."seller_id"
LEFT JOIN seller_reviews AS sr  ON sr."seller_id" = ss."seller_id"
LEFT JOIN seller_pack    AS sp  ON sp."seller_id" = ss."seller_id"
LEFT JOIN seller_top_cat AS stc ON stc."seller_id" = ss."seller_id"
ORDER BY ss.total_units_sold DESC,
         ss."seller_id";