WITH category_product AS (
  SELECT
    p2."category"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" o2
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p2
    ON o2."product_id" = p2."id"
  GROUP BY p2."category"
  ORDER BY COUNT(o2."id") DESC NULLS LAST
  LIMIT 1
),
category_product_events AS (
  SELECT
    e."session_id",
    e."user_id",
    e."sequence_number",
    e."created_at" AS "event_time",
    LEAD(e."created_at") OVER (
      PARTITION BY e."session_id"
      ORDER BY e."sequence_number"
    ) AS "next_event_time"
  FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" e
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
    ON TRY_TO_NUMBER(SPLIT_PART(e."uri", '/', 3)) = p."id"
  WHERE e."event_type" = 'product'
    AND p."category" = (SELECT "category" FROM category_product)
)
SELECT
  (SELECT "category" FROM category_product) AS "Category_with_highest_total_quantity_purchased",
  ROUND(AVG( ("next_event_time" - "event_time") / 60000000.0 ), 4) AS "Average_time_spent_on_product_page_minutes"
FROM
  category_product_events
WHERE
  "next_event_time" IS NOT NULL
  AND "next_event_time" > "event_time";