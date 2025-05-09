/* 1) pull all city–insert records from June-2022
   2) build streaks of consecutive insert dates per country
   3) find each country’s longest streak
   4) return the country (or countries) whose longest streak is the overall longest  */
WITH june_cities AS (
    SELECT
        "country_code_2",
        TO_DATE("insert_date")           AS insert_dt
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "insert_date" BETWEEN '2022-06-01' AND '2022-06-30'
),
distinct_dates AS (          -- get one row per country/day
    SELECT DISTINCT
        "country_code_2",
        insert_dt
    FROM june_cities
),
ordered_dates AS (           -- order the dates to build row numbers
    SELECT
        "country_code_2",
        insert_dt,
        ROW_NUMBER() OVER (
            PARTITION BY "country_code_2"
            ORDER BY     insert_dt
        ) AS rn
    FROM distinct_dates
),
grouped_dates AS (           -- same grp_key for consecutive days
    SELECT
        "country_code_2",
        insert_dt,
        DATEADD(day, -rn, insert_dt) AS grp_key
    FROM ordered_dates
),
streak_lengths AS (          -- length of every consecutive-day streak
    SELECT
        "country_code_2",
        COUNT(*) AS streak_len
    FROM grouped_dates
    GROUP BY
        "country_code_2",
        grp_key
),
max_streak_per_country AS (  -- longest streak per country
    SELECT
        "country_code_2",
        MAX(streak_len) AS max_streak
    FROM streak_lengths
    GROUP BY
        "country_code_2"
),
global_max AS (              -- overall longest streak length
    SELECT MAX(max_streak) AS longest_streak
    FROM   max_streak_per_country
)
SELECT
    m."country_code_2"
FROM
    max_streak_per_country m
    JOIN global_max g
      ON m.max_streak = g.longest_streak
ORDER BY
    m."country_code_2";