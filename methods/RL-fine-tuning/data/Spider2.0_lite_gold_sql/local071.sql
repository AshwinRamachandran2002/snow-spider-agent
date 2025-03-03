WITH dates_per_country AS (
    SELECT DISTINCT
        "country_code_2",
        "insert_date",
        julianday("insert_date") AS date_num
    FROM "cities"
    WHERE "insert_date" BETWEEN '2022-06-01' AND '2022-06-30'
),
ordered_dates AS (
    SELECT
        "country_code_2",
        "insert_date",
        date_num,
        ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY "insert_date") AS rn
    FROM dates_per_country
),
date_streaks AS (
    SELECT
        "country_code_2",
        rn,
        date_num,
        date_num - rn AS grp
    FROM ordered_dates
),
streaks AS (
    SELECT
        "country_code_2",
        grp,
        COUNT(*) AS streak_length
    FROM date_streaks
    GROUP BY "country_code_2", grp
),
max_streaks AS (
    SELECT
        "country_code_2",
        MAX(streak_length) AS max_streak
    FROM streaks
    GROUP BY "country_code_2"
),
longest_streak AS (
    SELECT
        MAX(max_streak) AS longest_streak_length
    FROM max_streaks
)
SELECT
    m."country_code_2"
FROM
    max_streaks m
    CROSS JOIN longest_streak l
WHERE
    m.max_streak = l.longest_streak_length
ORDER BY
    m."country_code_2";