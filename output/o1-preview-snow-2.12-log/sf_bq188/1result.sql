WITH CategoryPurchases AS (
   SELECT P."category", COUNT(*) AS "total_quantity_purchased"
   FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" OI
   JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" P
     ON OI."product_id" = P."id"
   GROUP BY P."category"
   ORDER BY "total_quantity_purchased" DESC NULLS LAST
   LIMIT 1
),
ProductPageViews AS (
   SELECT
     E1."user_id",
     E1."session_id",
     E1."sequence_number",
     E1."created_at" AS "view_time",
     E1."uri",
     REGEXP_SUBSTR(E1."uri", '([0-9]+)$') AS "product_id_str",
     E2."created_at" AS "next_event_time"
   FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" E1
   LEFT JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" E2
     ON E1."user_id" = E2."user_id"
     AND E1."session_id" = E2."session_id"
     AND E2."sequence_number" = E1."sequence_number" + 1
   WHERE E1."event_type" = 'product'
),
ProductPageTimes AS (
   SELECT
     PPV.*,
     TRY_TO_NUMBER(PPV."product_id_str") AS "product_id"
   FROM ProductPageViews PPV
   WHERE PPV."product_id_str" IS NOT NULL
),
ProductPageTimesWithCategory AS (
   SELECT
     PPT.*,
     P."category",
     (PPT."next_event_time" - PPT."view_time") / 60000000.0 AS "time_spent_minutes"
   FROM ProductPageTimes PPT
   JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" P
     ON P."id" = PPT."product_id"
   WHERE PPT."next_event_time" IS NOT NULL
     AND P."category" IS NOT NULL
)
SELECT
   CPT."category" AS "Category_with_highest_total_quantity_purchased",
   ROUND(AVG(PPTWC."time_spent_minutes"), 4) AS "Average_time_spent_on_product_page_minutes"
FROM CategoryPurchases CPT
JOIN ProductPageTimesWithCategory PPTWC
  ON PPTWC."category" = CPT."category"
GROUP BY CPT."category";