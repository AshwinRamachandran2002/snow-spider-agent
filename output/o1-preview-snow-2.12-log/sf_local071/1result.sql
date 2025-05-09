WITH cte AS (
    SELECT
        "country_code_2",
        CAST("insert_date" AS DATE) AS "insert_date"
    FROM
        "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
    WHERE
        "insert_date" >= '2022-06-01' AND "insert_date" < '2022-07-01'
),
ordered_dates AS (
    SELECT
        "country_code_2",
        "insert_date",
        ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY "insert_date") AS rn
    FROM cte
),
date_groups AS (
    SELECT
        "country_code_2",
        "insert_date",
        rn,
        DATEDIFF('day', '1900-01-01', "insert_date") - rn AS grp
    FROM ordered_dates
),
streaks AS (
    SELECT
        "country_code_2",
        COUNT(*) AS streak_length
    FROM date_groups
    GROUP BY
        "country_code_2",
        grp
),
max_streaks AS (
    SELECT
        "country_code_2",
        MAX(streak_length) AS max_streak_length
    FROM streaks
    GROUP BY "country_code_2"
),
overall_max AS (
    SELECT MAX(max_streak_length) AS overall_max_streak
    FROM max_streaks
)
SELECT
    m."country_code_2"
FROM
    max_streaks m
    CROSS JOIN overall_max o
WHERE
    m.max_streak_length = o.overall_max_streak;