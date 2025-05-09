WITH distinct_dates AS (
    SELECT DISTINCT
           "country_code_2",
           "insert_date"
    FROM   "cities"
    WHERE  "insert_date" BETWEEN '2022-06-01' AND '2022-06-30'
),
seq AS (
    SELECT
           "country_code_2",
           "insert_date",
           ROW_NUMBER() OVER (
               PARTITION BY "country_code_2"
               ORDER BY "insert_date"
           )                             AS rn,
           julianday("insert_date") -
           ROW_NUMBER() OVER (
               PARTITION BY "country_code_2"
               ORDER BY "insert_date"
           )                             AS grp_key
    FROM   distinct_dates
),
streaks AS (
    SELECT
           "country_code_2",
           COUNT(*)                      AS streak_len
    FROM   seq
    GROUP  BY "country_code_2", grp_key
),
longest_per_country AS (
    SELECT
           "country_code_2",
           MAX(streak_len)              AS longest_streak
    FROM   streaks
    GROUP  BY "country_code_2"
),
global_max AS (
    SELECT MAX(longest_streak) AS max_streak
    FROM   longest_per_country
)
SELECT
       l."country_code_2" AS country_code
FROM   longest_per_country l
JOIN   global_max g
       ON l.longest_streak = g.max_streak;