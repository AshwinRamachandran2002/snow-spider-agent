WITH july_cn_dates AS (
    SELECT DISTINCT "insert_date"
    FROM "cities"
    WHERE "country_code_2" = 'cn'
      AND "insert_date" BETWEEN '2021-07-01' AND '2021-07-31'
),
seq AS (
    SELECT 
        "insert_date",
        (JULIANDAY("insert_date") - ROW_NUMBER() OVER (ORDER BY "insert_date")) AS streak_id
    FROM july_cn_dates
),
streak_lengths AS (
    SELECT streak_id, COUNT(*) AS streak_len
    FROM seq
    GROUP BY streak_id
),
target_streaks AS (
    SELECT streak_id
    FROM streak_lengths
    WHERE streak_len = (SELECT MIN(streak_len) FROM streak_lengths)
       OR streak_len = (SELECT MAX(streak_len) FROM streak_lengths)
)
SELECT 
    s."insert_date",
    UPPER(SUBSTR(c."city_name",1,1)) || LOWER(SUBSTR(c."city_name",2)) AS "city_name"
FROM seq s
JOIN target_streaks t USING (streak_id)
JOIN "cities" c
  ON  c."insert_date"   = s."insert_date"
  AND c."country_code_2" = 'cn'
GROUP BY s."insert_date"
ORDER BY s."insert_date";