WITH cn_july21_dates AS (
    SELECT DISTINCT DATE("insert_date") AS dt
    FROM "cities"
    WHERE "country_code_2" = 'cn'
      AND DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
),
ordered_dates AS (
    SELECT
        dt,
        ROW_NUMBER() OVER (ORDER BY dt)          AS rn,
        julianday(dt)                            AS jd
    FROM cn_july21_dates
),
streaks AS (
    SELECT
        jd - rn                                  AS streak_id,
        COUNT(*)                                 AS len
    FROM ordered_dates
    GROUP BY streak_id
),
limits AS (
    SELECT MIN(len) AS shortest_len,
           MAX(len) AS longest_len
    FROM streaks
),
target_streaks AS (
    SELECT streak_id
    FROM streaks, limits
    WHERE len = shortest_len
       OR len = longest_len
),
streak_dates AS (
    SELECT od.dt
    FROM ordered_dates od
    JOIN target_streaks ts
      ON ts.streak_id = od.jd - od.rn
),
one_city_per_date AS (
    SELECT
        sd.dt,
        (
          SELECT "city_name"
          FROM "cities" c
          WHERE DATE(c."insert_date") = sd.dt
            AND c."country_code_2" = 'cn'
          ORDER BY c."city_id"
          LIMIT 1
        ) AS city_raw
    FROM streak_dates sd
)
SELECT
    dt                                    AS date,
    UPPER(SUBSTR(city_raw,1,1)) ||
    LOWER(SUBSTR(city_raw,2))             AS city_name
FROM one_city_per_date
ORDER BY date;