WITH city_one AS (   -- one city per day for Chinese cities in July 2021
    SELECT
        DATE("insert_date")                                  AS dt,
        INITCAP(LOWER("city_name"))                          AS city_name
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "country_code_2" = 'cn'
      AND DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY DATE("insert_date")
                               ORDER BY "city_name") = 1
),
dates_seq AS (        -- sequence number per distinct date
    SELECT
        dt,
        ROW_NUMBER() OVER (ORDER BY dt)                      AS seq
    FROM (SELECT DISTINCT dt FROM city_one)
),
dates_grp AS (        -- assign each date to a consecutive-day group
    SELECT
        dt,
        DATEADD(day, -seq, dt)                               AS grp
    FROM dates_seq
),
streaks AS (          -- length of every consecutive-day streak
    SELECT
        grp,
        COUNT(*)                                            AS streak_len
    FROM dates_grp
    GROUP BY grp
),
min_max AS (          -- shortest and longest streak lengths
    SELECT
        MIN(streak_len) AS min_len,
        MAX(streak_len) AS max_len
    FROM streaks
),
target_grp AS (       -- groups that are either shortest or longest
    SELECT grp
    FROM streaks
    JOIN min_max
      ON streak_len = min_len
      OR streak_len = max_len
)
SELECT
    d.dt          AS "DATE",
    c.city_name   AS "CITY_NAME"
FROM dates_grp       d
JOIN target_grp      tg ON d.grp = tg.grp
JOIN city_one        c  ON c.dt = d.dt
ORDER BY d.dt;