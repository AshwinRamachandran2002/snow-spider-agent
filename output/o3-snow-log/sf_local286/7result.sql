/*  Comprehensive seller-performance report
    – includes only sellers with >100 items sold
    – shows total sales, avg item price, avg review score,
      avg packing days, and the English product category
      with the highest sales volume for each seller          */

WITH sales_perf AS (     ----------------------------------------------------
    SELECT
        "seller_id",
        COUNT(*)        AS "items_sold",
        SUM("price")    AS "total_sales_value",
        AVG("price")    AS "avg_item_price"
    FROM "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_ITEMS"
    GROUP BY "seller_id"
    HAVING COUNT(*) > 100
),                                                             -- reviews ----
reviews AS (
    SELECT
        oi."seller_id",
        AVG(orv."review_score") AS "avg_review_score"
    FROM "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_ITEMS"   oi
    JOIN "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_REVIEWS" orv
          ON oi."order_id" = orv."order_id"
    GROUP BY oi."seller_id"
),                                                           -- packing time --
packing AS (
    SELECT
        oi."seller_id",
        AVG(
            DATEDIFF(
                'day',
                TRY_TO_TIMESTAMP(o."order_approved_at"),
                TRY_TO_TIMESTAMP(oi."shipping_limit_date")
            )
        ) AS "avg_packing_days"
    FROM "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_ITEMS"  oi
    JOIN "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDERS"       o
          ON oi."order_id" = o."order_id"
    WHERE TRY_TO_TIMESTAMP(o."order_approved_at")    IS NOT NULL
      AND TRY_TO_TIMESTAMP(oi."shipping_limit_date") IS NOT NULL
    GROUP BY oi."seller_id"
),                                                        -- category counts --
category_counts AS (
    SELECT
        oi."seller_id",
        pct."product_category_name_english",
        COUNT(*) AS "category_items_sold",
        ROW_NUMBER() OVER (
            PARTITION BY oi."seller_id"
            ORDER BY COUNT(*) DESC,
                     pct."product_category_name_english" ASC
        ) AS "rn"
    FROM "ELECTRONIC_SALES"."ELECTRONIC_SALES"."ORDER_ITEMS"          oi
    JOIN "ELECTRONIC_SALES"."ELECTRONIC_SALES"."PRODUCTS"             p
          ON oi."product_id" = p."product_id"
    LEFT JOIN "ELECTRONIC_SALES"."ELECTRONIC_SALES"."PRODUCT_CATEGORY_NAME_TRANSLATION" pct
          ON p."product_category_name" = pct."product_category_name"
    GROUP BY
        oi."seller_id",
        pct."product_category_name_english"
),                                                      -- top category only --
top_category AS (
    SELECT
        "seller_id",
        "product_category_name_english" AS "top_category_english",
        "category_items_sold"           AS "top_category_items"
    FROM category_counts
    WHERE "rn" = 1
)                                                               -- final -----
SELECT
    s."seller_id",
    s."seller_city",
    s."seller_state",
    sp."items_sold",
    sp."total_sales_value",
    sp."avg_item_price",
    rv."avg_review_score",
    pk."avg_packing_days",
    tc."top_category_english",
    tc."top_category_items"
FROM "ELECTRONIC_SALES"."ELECTRONIC_SALES"."SELLERS"  s
JOIN sales_perf  sp ON s."seller_id" = sp."seller_id"
LEFT JOIN reviews     rv ON s."seller_id" = rv."seller_id"
LEFT JOIN packing     pk ON s."seller_id" = pk."seller_id"
LEFT JOIN top_category tc ON s."seller_id" = tc."seller_id"
ORDER BY sp."total_sales_value" DESC NULLS LAST;