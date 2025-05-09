WITH top_category AS (
    SELECT P."category"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" OI
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" P
      ON OI."product_id" = P."id"
    GROUP BY P."category"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
session_durations AS (
    SELECT E."session_id",
           ((MAX(E."created_at") - MIN(E."created_at")) / (1e9 * 60.0)) AS "session_duration_minutes"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS" E
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" P
      ON CAST(SPLIT_PART(E."uri", '/', 3) AS NUMBER(38,0)) = P."id"
    WHERE E."uri" LIKE '/product/%'
      AND P."category" = (SELECT "category" FROM top_category)
      AND E."session_id" IS NOT NULL
      AND E."created_at" IS NOT NULL
    GROUP BY E."session_id"
)
SELECT (SELECT "category" FROM top_category) AS "Category",
       ROUND(AVG("session_duration_minutes"), 4) AS "Average_Time_Minutes"
FROM session_durations;