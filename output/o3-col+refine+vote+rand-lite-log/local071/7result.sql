WITH june AS (
    SELECT DISTINCT "country_code_2",
                    "insert_date"
    FROM "cities"
    WHERE "insert_date" BETWEEN '2022-06-01' AND '2022-06-30'
),
ranked AS (
    SELECT  "country_code_2",
            "insert_date",
            ROW_NUMBER() OVER (PARTITION BY "country_code_2"
                               ORDER BY "insert_date")         AS rn,
            julianday("insert_date")                           AS jd
    FROM june
),
grouped AS (   -- assign a group-id; same id ⇒ consecutive dates
    SELECT  "country_code_2",
            jd - rn                                           AS grp_id
    FROM ranked
),
streaks AS (   -- length of every consecutive streak
    SELECT  "country_code_2",
            COUNT(*)                                          AS streak_len
    FROM grouped
    GROUP BY "country_code_2", grp_id
),
max_per_country AS (   -- longest streak for each country
    SELECT  "country_code_2",
            MAX(streak_len)                                   AS max_streak
    FROM streaks
    GROUP BY "country_code_2"
),
overall_max AS (
    SELECT MAX(max_streak) AS overall_max_streak
    FROM   max_per_country
)
SELECT "country_code_2"
FROM   max_per_country
WHERE  max_streak = (SELECT overall_max_streak FROM overall_max);