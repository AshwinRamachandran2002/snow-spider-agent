WITH june_dates AS (   -- keep one record per country-date in June 2022
    SELECT DISTINCT 
           "country_code_2",
           TO_DATE("insert_date")        AS ins_date
    FROM   CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE  TO_DATE("insert_date") BETWEEN '2022-06-01' AND '2022-06-30'
),
ordered AS (           -- order the dates per country
    SELECT
           "country_code_2",
           ins_date,
           ROW_NUMBER() OVER (PARTITION BY "country_code_2"
                              ORDER BY ins_date)            AS rn
    FROM   june_dates
),
groups AS (            -- create a key that is constant inside each consecutive streak
    SELECT
           "country_code_2",
           ins_date,
           DATEADD(day, -rn, ins_date)                     AS grp_key
    FROM   ordered
),
streak_lengths AS (    -- length of every consecutive streak
    SELECT
           "country_code_2",
           grp_key,
           COUNT(*)                                        AS streak_len
    FROM   groups
    GROUP BY "country_code_2", grp_key
),
country_max AS (       -- longest streak per country
    SELECT
           "country_code_2",
           MAX(streak_len)                                 AS max_streak
    FROM   streak_lengths
    GROUP BY "country_code_2"
),
global_max AS (        -- overall longest streak length
    SELECT MAX(max_streak) AS longest_streak
    FROM   country_max
)
SELECT c."country_code_2"
FROM   country_max  c
JOIN   global_max   g
       ON c.max_streak = g.longest_streak;