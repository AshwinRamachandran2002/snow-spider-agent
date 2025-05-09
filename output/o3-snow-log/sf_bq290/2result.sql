WITH joined AS (
    SELECT
        /* build real calendar date */
        TO_DATE(gs."year"||LPAD(gs."mo",2,'0')||LPAD(gs."da",2,'0'),'YYYYMMDD')          AS "date",
        st."country"                                                                      AS "country",
        gs."max"                                                                          AS "max_temp",
        gs."min"                                                                          AS "min_temp",
        gs."temp"                                                                         AS "avg_temp"
    FROM  NOAA_DATA.NOAA_GSOD."GSOD2023"        gs
    JOIN  NOAA_DATA.NOAA_GSOD."STATIONS"        st
          ON  gs."stn"  = st."usaf"
          AND gs."wban" = st."wban"
    WHERE gs."year" = '2023'
      AND gs."mo"   = '10'                       -- October only
      AND st."country" IN ('US','UK')            -- keep U.S. and U.K. stations
      /* discard missing / invalid temperature values */
      AND gs."max"  IS NOT NULL AND gs."max"  < 9999
      AND gs."min"  IS NOT NULL AND gs."min"  < 9999
      AND gs."temp" IS NOT NULL AND gs."temp" < 9999
),
daily_country AS (          -- daily averages for each country
    SELECT
        "date",
        "country",
        AVG("max_temp")  AS "avg_max",
        AVG("min_temp")  AS "avg_min",
        AVG("avg_temp")  AS "avg_temp"
    FROM joined
    GROUP BY "date","country"
)
SELECT
    "date",
    /* U.S. & U.K. daily averages */
    MAX(CASE WHEN "country"='US' THEN "avg_max"  END) AS "us_avg_max",
    MAX(CASE WHEN "country"='UK' THEN "avg_max"  END) AS "uk_avg_max",
    MAX(CASE WHEN "country"='US' THEN "avg_min"  END) AS "us_avg_min",
    MAX(CASE WHEN "country"='UK' THEN "avg_min"  END) AS "uk_avg_min",
    MAX(CASE WHEN "country"='US' THEN "avg_temp" END) AS "us_avg_temp",
    MAX(CASE WHEN "country"='UK' THEN "avg_temp" END) AS "uk_avg_temp",

    /* requested differences: U.S. minus U.K. */
    MAX(CASE WHEN "country"='US' THEN "avg_max"  END)
      - MAX(CASE WHEN "country"='UK' THEN "avg_max"  END)  AS "diff_max",
    MAX(CASE WHEN "country"='US' THEN "avg_min"  END)
      - MAX(CASE WHEN "country"='UK' THEN "avg_min"  END)  AS "diff_min",
    MAX(CASE WHEN "country"='US' THEN "avg_temp" END)
      - MAX(CASE WHEN "country"='UK' THEN "avg_temp" END)  AS "diff_avg"
FROM  daily_country
GROUP BY "date"
ORDER BY "date";