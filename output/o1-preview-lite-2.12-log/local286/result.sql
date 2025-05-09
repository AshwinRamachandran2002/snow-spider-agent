WITH
  "total_sales_per_seller" AS (
    SELECT
      "seller_id",
      ROUND(SUM("price"), 4) AS "total_sales",
      ROUND(AVG("price"), 4) AS "average_item_price",
      COUNT("order_item_id") AS "total_quantity_sold"
    FROM "order_items"
    GROUP BY "seller_id"
    HAVING COUNT("order_item_id") > 100
  ),
  "average_review_scores" AS (
    SELECT
      "oi"."seller_id",
      ROUND(AVG("orw"."review_score"), 4) AS "average_review_score"
    FROM "order_items" AS "oi"
    JOIN "orders" AS "o" ON "oi"."order_id" = "o"."order_id"
    JOIN "order_reviews" AS "orw" ON "o"."order_id" = "orw"."order_id"
    WHERE "oi"."seller_id" IN (SELECT "seller_id" FROM "total_sales_per_seller")
    GROUP BY "oi"."seller_id"
  ),
  "average_packing_times" AS (
    SELECT
      "oi"."seller_id",
      ROUND(AVG(julianday("o"."order_delivered_carrier_date") - julianday("o"."order_approved_at")), 4) AS "average_packing_time"
    FROM "order_items" AS "oi"
    JOIN "orders" AS "o" ON "oi"."order_id" = "o"."order_id"
    WHERE "o"."order_approved_at" IS NOT NULL AND "o"."order_delivered_carrier_date" IS NOT NULL
      AND "oi"."seller_id" IN (SELECT "seller_id" FROM "total_sales_per_seller")
    GROUP BY "oi"."seller_id"
  ),
  "seller_category_sales" AS (
    SELECT
      "oi"."seller_id",
      "pct"."product_category_name_english",
      COUNT("oi"."order_item_id") AS "quantity_sold"
    FROM "order_items" AS "oi"
    JOIN "products" AS "p" ON "oi"."product_id" = "p"."product_id"
    JOIN "product_category_name_translation" AS "pct" ON "p"."product_category_name" = "pct"."product_category_name"
    WHERE "oi"."seller_id" IN (SELECT "seller_id" FROM "total_sales_per_seller")
    GROUP BY "oi"."seller_id", "pct"."product_category_name_english"
  ),
  "max_category_sales" AS (
    SELECT
      "seller_id",
      MAX("quantity_sold") AS "max_quantity_sold"
    FROM "seller_category_sales"
    GROUP BY "seller_id"
  ),
  "top_categories" AS (
    SELECT
      "scs"."seller_id",
      "scs"."product_category_name_english" AS "product_category_name_english_with_highest_sales_volume"
    FROM "seller_category_sales" AS "scs"
    JOIN "max_category_sales" AS "mcs"
      ON "scs"."seller_id" = "mcs"."seller_id"
      AND "scs"."quantity_sold" = "mcs"."max_quantity_sold"
  )
SELECT
  "tsp"."seller_id",
  "tsp"."total_sales",
  "tsp"."average_item_price",
  "ars"."average_review_score",
  "apt"."average_packing_time",
  "tc"."product_category_name_english_with_highest_sales_volume"
FROM "total_sales_per_seller" AS "tsp"
LEFT JOIN "average_review_scores" AS "ars" ON "tsp"."seller_id" = "ars"."seller_id"
LEFT JOIN "average_packing_times" AS "apt" ON "tsp"."seller_id" = "apt"."seller_id"
LEFT JOIN "top_categories" AS "tc" ON "tsp"."seller_id" = "tc"."seller_id"
ORDER BY "tsp"."seller_id";