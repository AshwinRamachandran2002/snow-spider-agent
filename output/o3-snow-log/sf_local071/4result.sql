/* 1.  Pull city-insert records that fall in June 2022
   2.  For every country, order the dates and build groups of consecutive days
   3.  Measure each group’s length (a “streak”)
   4.  Find every country’s longest streak
   5.  Return the country-codes whose longest streak equals the overall maximum */
WITH june_2022 AS (           -- step-1
    SELECT
        "country_code_2",
        TO_DATE("insert_date", 'YYYY-MM-DD') AS dt
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "insert_date" LIKE '2022-06%'           -- June 2022 only
      AND "country_code_2" IS NOT NULL
),
dedup AS (                    -- remove duplicate same-day inserts, if any
    SELECT DISTINCT "country_code_2", dt
    FROM june_2022
),
ordered AS (                  -- step-2: assign row numbers per country
    SELECT
        "country_code_2",
        dt,
        ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY dt) AS rn
    FROM dedup
),
grouped AS (                  -- build a constant key for each consecutive block
    SELECT
        "country_code_2",
        dt,
        DATEADD(day, -rn, dt) AS grp_key
    FROM ordered
),
streaks AS (                  -- step-3: length of each streak
    SELECT
        "country_code_2",
        grp_key,
        COUNT(*) AS streak_len
    FROM grouped
    GROUP BY "country_code_2", grp_key
),
country_max AS (              -- step-4: longest streak per country
    SELECT
        "country_code_2",
        MAX(streak_len) AS max_streak
    FROM streaks
    GROUP BY "country_code_2"
),
overall_max AS (              -- overall longest streak length
    SELECT MAX(max_streak) AS max_len
    FROM country_max
)
SELECT "country_code_2"       -- step-5: countries with that longest streak
FROM country_max
WHERE max_streak = (SELECT max_len FROM overall_max);