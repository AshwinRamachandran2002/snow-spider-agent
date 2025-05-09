WITH daily_country AS (
    SELECT
        /* build a proper date from the y/m/d text columns */
        TO_DATE(
            LPAD("year",4,'0')
            ||'-'||LPAD("mo",2,'0')
            ||'-'||LPAD("da",2,'0')
        )                                              AS "day_date",
        s."country"                                    AS "country",
        AVG(g."max")                                   AS "avg_max",
        AVG(g."min")                                   AS "avg_min",
        AVG(g."temp")                                  AS "avg_temp"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2023"  g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  s
         ON g."stn"  = s."usaf"
        AND g."wban" = s."wban"
    /* October 2023 and valid temperature values only */
    WHERE g."year" = '2023'
      AND g."mo"   = '10'
      AND g."max"  <> 9999.9
      AND g."min"  <> 9999.9
      AND g."temp" <> 9999.9
      AND s."country" IN ('US','UK')
    GROUP BY
        "day_date",
        s."country"
),
pivoted AS (
    /* lay US and UK averages side-by-side for each day */
    SELECT
        "day_date",
        MAX(CASE WHEN "country" = 'US' THEN "avg_max"  END) AS "us_avg_max",
        MAX(CASE WHEN "country" = 'UK' THEN "avg_max"  END) AS "uk_avg_max",
        MAX(CASE WHEN "country" = 'US' THEN "avg_min"  END) AS "us_avg_min",
        MAX(CASE WHEN "country" = 'UK' THEN "avg_min"  END) AS "uk_avg_min",
        MAX(CASE WHEN "country" = 'US' THEN "avg_temp" END) AS "us_avg_temp",
        MAX(CASE WHEN "country" = 'UK' THEN "avg_temp" END) AS "uk_avg_temp"
    FROM daily_country
    GROUP BY "day_date"
)
SELECT
    "day_date",
    /* US minus UK differences */
    "us_avg_max"  - "uk_avg_max"   AS "diff_max_temp",
    "us_avg_min"  - "uk_avg_min"   AS "diff_min_temp",
    "us_avg_temp" - "uk_avg_temp"  AS "diff_avg_temp"
FROM pivoted
ORDER BY "day_date";