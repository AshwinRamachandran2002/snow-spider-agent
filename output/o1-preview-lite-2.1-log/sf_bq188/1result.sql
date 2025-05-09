WITH
Top_Category AS (
    SELECT P."category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" OI
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" P
      ON OI."product_id" = P."id"
    GROUP BY P."category"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
Category_Sessions AS (
    SELECT DISTINCT E."session_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" E
    CROSS JOIN Top_Category TC
    WHERE E."uri" ILIKE CONCAT('%/category/', REGEXP_REPLACE(LOWER(TC."category"), '[ &]', ''), '/%')
),
Session_Durations AS (
    SELECT
        E."session_id",
        (MAX(E."created_at") - MIN(E."created_at")) / 60000000.0 AS "session_duration_minutes"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."EVENTS" E
    WHERE E."session_id" IN (SELECT "session_id" FROM Category_Sessions)
    GROUP BY E."session_id"
)
SELECT
    (SELECT "category" FROM Top_Category) AS "Category",
    ROUND(AVG("session_duration_minutes"), 4) AS "Average_Time_Minutes"
FROM Session_Durations;