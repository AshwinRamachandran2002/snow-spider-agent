WITH cn_july AS (   -- 1. Chinese cities inserted during July-2021
    SELECT
        TO_DATE("insert_date")            AS dt,
        INITCAP("city_name")              AS city_name,
        "city_id"                         AS city_id        -- unquoted alias
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "country_code_2" = 'cn'
      AND TO_DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
),
dts AS (            -- 2. distinct dates
    SELECT DISTINCT dt
    FROM cn_july
),
grp AS (            -- 2. group key for consecutive-date runs
    SELECT
        dt,
        DATEADD(day, -ROW_NUMBER() OVER (ORDER BY dt), dt) AS grp_key
    FROM dts
),
streaks AS (        -- 2. length of each streak
    SELECT
        grp_key,
        MIN(dt)  AS start_dt,
        MAX(dt)  AS end_dt,
        COUNT(*) AS len
    FROM grp
    GROUP BY grp_key
),
chosen AS (         -- 3. shortest & longest streak (earliest if tie)
    SELECT *
    FROM streaks
    WHERE len = (SELECT MIN(len) FROM streaks)
       OR len = (SELECT MAX(len) FROM streaks)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY len ORDER BY start_dt) = 1
),
chosen_dates AS (   -- all dates in those streaks
    SELECT g.dt
    FROM grp g
    JOIN chosen c
      ON g.grp_key = c.grp_key
),
one_row_per_date AS ( -- 4. pick one city (lowest city_id) per date
    SELECT
        cd.dt                       AS "date",
        cj.city_name                AS "city_name",
        ROW_NUMBER() OVER (PARTITION BY cd.dt ORDER BY cj.city_id) AS rn
    FROM chosen_dates cd
    JOIN cn_july   cj
      ON cj.dt = cd.dt
)
SELECT "date",
       "city_name"
FROM one_row_per_date
WHERE rn = 1                 -- exactly one record per date
ORDER BY "date";