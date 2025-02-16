-- Task: Could you review our records in June 2022 and determine the maximum length of consecutive city insert dates for each country? Please list the 2-letter country codes along with their maximum streak lengths. Show up to 100 entries.

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
)
SELECT
    "country_code_2",
    MAX(streak_length) AS max_streak_length
FROM streaks
GROUP BY "country_code_2"
ORDER BY "country_code_2"
LIMIT 100;