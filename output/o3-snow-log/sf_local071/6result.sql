WITH filtered AS (
    -- keep one row per country / date in June-2022
    SELECT DISTINCT 
           "country_code_2"        AS cc ,
           TO_DATE("insert_date")  AS dt
    FROM   "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
    WHERE  TO_DATE("insert_date") BETWEEN '2022-06-01' AND '2022-06-30'
),
ordered AS (
    -- order the dates inside each country
    SELECT  cc ,
            dt ,
            ROW_NUMBER() OVER (PARTITION BY cc ORDER BY dt) AS rn
    FROM    filtered
),
grouped AS (
    /* two dates are consecutive when the difference between the
       actual date and its row_number offset is constant               */
    SELECT  cc ,
            dt ,
            DATEADD(day, -rn, dt) AS grp_key
    FROM    ordered
),
streaks AS (
    -- length of every consecutive-days block within a country
    SELECT  cc ,
            COUNT(*) AS streak_len
    FROM    grouped
    GROUP BY cc , grp_key
),
max_streak_per_country AS (
    -- longest streak for each country
    SELECT  cc ,
            MAX(streak_len) AS max_len
    FROM    streaks
    GROUP BY cc
),
max_len_all AS (
    -- overall longest streak length
    SELECT MAX(max_len) AS global_max
    FROM   max_streak_per_country
)
-- countries that achieved the overall longest streak
SELECT  cc AS "country_code_2"
FROM    max_streak_per_country
JOIN    max_len_all
  ON    max_streak_per_country.max_len = max_len_all.global_max
ORDER BY cc;