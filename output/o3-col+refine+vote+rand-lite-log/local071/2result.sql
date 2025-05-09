WITH june_dates AS (
    SELECT 
        "country_code_2",
        "insert_date",
        julianday("insert_date") 
          - ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY "insert_date") AS grp
    FROM "cities"
    WHERE "insert_date" LIKE '2022-06-%'
),
streaks AS (
    SELECT 
        "country_code_2",
        grp,
        COUNT(*) AS streak_len
    FROM june_dates
    GROUP BY "country_code_2", grp
),
country_max AS (
    SELECT 
        "country_code_2",
        MAX(streak_len) AS longest_streak
    FROM streaks
    GROUP BY "country_code_2"
),
global_max AS (
    SELECT MAX(longest_streak) AS mx FROM country_max
)
SELECT 
    c."country_code_2"
FROM 
    country_max c
    JOIN global_max g ON c.longest_streak = g.mx
ORDER BY 
    c."country_code_2";