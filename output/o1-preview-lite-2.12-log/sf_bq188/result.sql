WITH
  AllCategoryQuantities AS (
    SELECT P."category", COUNT(*) AS "total_quantity_purchased"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" OI
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" P
      ON OI."product_id" = P."id"
    GROUP BY P."category"
  ),
  TopCategory AS (
    SELECT "category"
    FROM AllCategoryQuantities
    ORDER BY "total_quantity_purchased" DESC NULLS LAST
    LIMIT 1
  ),
  ProductEvents AS (
    SELECT
      E."session_id",
      E."created_at",
      TRY_TO_NUMBER(REGEXP_SUBSTR(E."uri", '/product/(\\d+)', 1, 1, 'e', 1)) AS "product_id"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS" E
    WHERE E."event_type" = 'product'
  ),
  TopCategoryProductEvents AS (
    SELECT
      PE."session_id",
      PE."created_at"
    FROM ProductEvents PE
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" P
      ON PE."product_id" = P."id"
    WHERE P."category" = (SELECT "category" FROM TopCategory)
  ),
  EventsWithNext AS (
    SELECT
      "session_id",
      "created_at",
      LEAD("created_at") OVER (PARTITION BY "session_id" ORDER BY "created_at") AS "next_event_time"
    FROM TopCategoryProductEvents
  )
SELECT
  (SELECT "category" FROM TopCategory) AS "Category_with_highest_total_quantity_purchased",
  ROUND(AVG( ("next_event_time" - "created_at") / 60000000.0 ), 4) AS "Average_time_spent_on_product_page_minutes"
FROM EventsWithNext
WHERE "next_event_time" IS NOT NULL;