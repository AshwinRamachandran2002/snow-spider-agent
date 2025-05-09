WITH agg AS (
    SELECT
        TO_DATE(CONCAT(g."year",'-',LPAD(g."mo",2,'0'),'-',LPAD(g."da",2,'0'))) AS "date",
        s."country"                                                             AS "country",
        AVG(g."max")                                                            AS "avg_max",
        AVG(g."min")                                                            AS "avg_min",
        AVG(g."temp")                                                           AS "avg_temp"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2023" g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE g."year" = '2023'
      AND g."mo"   = '10'                      -- October 2023
      AND g."max"  IS NOT NULL AND g."max"  < 9999
      AND g."min"  IS NOT NULL AND g."min"  < 9999
      AND g."temp" IS NOT NULL AND g."temp" < 9999
      AND s."country" IN ('US','UK')
    GROUP BY
        TO_DATE(CONCAT(g."year",'-',LPAD(g."mo",2,'0'),'-',LPAD(g."da",2,'0'))),
        s."country"
),
us AS (
    SELECT
        "date",
        "avg_max"  AS "us_max",
        "avg_min"  AS "us_min",
        "avg_temp" AS "us_temp"
    FROM agg
    WHERE "country" = 'US'
),
uk AS (
    SELECT
        "date",
        "avg_max"  AS "uk_max",
        "avg_min"  AS "uk_min",
        "avg_temp" AS "uk_temp"
    FROM agg
    WHERE "country" = 'UK'
)
SELECT
    u."date",
    u."us_max"  - k."uk_max"  AS "diff_max",
    u."us_min"  - k."uk_min"  AS "diff_min",
    u."us_temp" - k."uk_temp" AS "diff_avg"
FROM us u
JOIN uk k
  ON u."date" = k."date"
ORDER BY u."date";