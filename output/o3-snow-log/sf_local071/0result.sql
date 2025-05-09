WITH june_cities AS (        -- 1. keep only June-2022 city insertions
    SELECT
        "country_code_2"           AS country_code,
        TO_DATE("insert_date")     AS ins_date
    FROM   CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE  TO_DATE("insert_date") BETWEEN DATE '2022-06-01' AND DATE '2022-06-30'
      AND  "country_code_2" IS NOT NULL
),
distinct_dates AS (          -- 2. one record per country/day
    SELECT DISTINCT
        country_code,
        ins_date
    FROM   june_cities
),
ordered_dates AS (           -- 3. order each country’s days
    SELECT
        country_code,
        ins_date,
        ROW_NUMBER() OVER (PARTITION BY country_code ORDER BY ins_date)                AS rn,
        DATEDIFF('day', DATE '1970-01-01', ins_date)                                   AS day_num
    FROM   distinct_dates
),
streak_groups AS (           -- 4. constant (day_num-rn) identifies each consecutive streak
    SELECT
        country_code,
        ins_date,
        day_num - rn AS grp_id
    FROM   ordered_dates
),
streak_lengths AS (          -- 5. length of every streak
    SELECT
        country_code,
        grp_id,
        COUNT(*) AS streak_len
    FROM   streak_groups
    GROUP BY country_code, grp_id
),
country_max_streak AS (      -- 6. longest streak per country
    SELECT
        country_code,
        MAX(streak_len) AS max_streak
    FROM   streak_lengths
    GROUP BY country_code
),
overall_max AS (             -- 7. overall longest streak length
    SELECT MAX(max_streak) AS top_streak
    FROM   country_max_streak
)
-- 8. countries that share the overall longest streak
SELECT country_code AS "country_code_2"
FROM   country_max_streak
WHERE  max_streak = (SELECT top_streak FROM overall_max)
ORDER BY country_code;