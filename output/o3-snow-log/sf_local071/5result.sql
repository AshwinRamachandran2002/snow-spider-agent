WITH base AS (   -- keep one record per country-day in June 2022
    SELECT DISTINCT 
           "country_code_2",
           TO_DATE("insert_date")          AS ins_date
    FROM   CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE  TO_DATE("insert_date") BETWEEN '2022-06-01' AND '2022-06-30'
),
ordered AS (      -- order the dates to prepare for streak calculation
    SELECT 
           "country_code_2",
           ins_date,
           ROW_NUMBER() OVER (PARTITION BY "country_code_2"
                              ORDER BY ins_date)            AS rn
    FROM   base
),
grp AS (          -- consecutive days share the same (date – row_number) value
    SELECT 
           "country_code_2",
           ins_date,
           DATEADD(day, -rn, ins_date)                     AS grp_id
    FROM   ordered
),
streaks AS (      -- length of each consecutive-day streak
    SELECT "country_code_2",
           grp_id,
           COUNT(*)                                       AS streak_len
    FROM   grp
    GROUP BY "country_code_2", grp_id
),
country_max AS (  -- longest streak per country
    SELECT "country_code_2",
           MAX(streak_len)                                AS max_streak
    FROM   streaks
    GROUP BY "country_code_2"
),
overall_max AS (  -- overall longest streak length
    SELECT MAX(max_streak)                                AS longest_streak
    FROM   country_max
)
SELECT cm."country_code_2"
FROM   country_max  cm
JOIN   overall_max  om
  ON   cm.max_streak = om.longest_streak
ORDER  BY cm."country_code_2";