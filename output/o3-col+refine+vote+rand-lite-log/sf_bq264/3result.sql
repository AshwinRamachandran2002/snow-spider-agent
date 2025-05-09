WITH period_users AS (
    SELECT "age"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1651276800000000  -- 01-Jan-2019 to 30-Apr-2022 (µs epoch)
),                                                     
limits AS (                                             
    SELECT MIN("age") AS youngest_age,
           MAX("age") AS oldest_age
    FROM period_users
),                                                     
counts AS (                                             
    SELECT
        SUM(CASE WHEN pu."age" = l.oldest_age   THEN 1 ELSE 0 END) AS cnt_oldest,
        SUM(CASE WHEN pu."age" = l.youngest_age THEN 1 ELSE 0 END) AS cnt_youngest
    FROM period_users pu
    CROSS JOIN limits l
)
SELECT
    cnt_oldest - cnt_youngest AS "difference_oldest_vs_youngest"
FROM counts;