WITH us_uk_gsod AS (
    /* 1.  Join the 2023 GSOD daily observations to the station-metadata
          so we know which station is in the United States (“US”)
          and which is in the United Kingdom (“UK”).                  */
    SELECT
        -- build a real DATE column from year / month / day fields
        TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))     AS "obs_date",
        st."country"                                                     AS "country",
        CAST(g."max"  AS FLOAT)                                          AS "max_temp",
        CAST(g."min"  AS FLOAT)                                          AS "min_temp",
        CAST(g."temp" AS FLOAT)                                          AS "avg_temp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2023"  g
    JOIN   NOAA_DATA.NOAA_GSOD."STATIONS"  st
           ON  g."stn"  = st."usaf"
           AND g."wban" = st."wban"
    /*  October 2023 only                                                */
    WHERE  g."year" = '2023'
      AND  g."mo"   = '10'
      /*  Keep US & UK stations only                                     */
      AND  st."country" IN ('US','UK')
      /*  Filter out the GSOD missing / invalid temperature codes        */
      AND  g."max"  NOT IN (999.9, 9999.9)
      AND  g."min"  NOT IN (999.9, 9999.9)
      AND  g."temp" NOT IN (999.9, 9999.9)
),
/* 2.  Aggregate by country-by-day                                       */
daily_country_stats AS (
    SELECT
        "obs_date",
        "country",
        AVG("max_temp") AS "avg_max_temp",
        AVG("min_temp") AS "avg_min_temp",
        AVG("avg_temp") AS "avg_avg_temp"
    FROM   us_uk_gsod
    GROUP  BY "obs_date","country"
),
/* 3.  Bring the two countries together and compute differences          */
daily_differences AS (
    SELECT
        us."obs_date",
        /*  (US – UK) differences                                         */
        us."avg_max_temp" - uk."avg_max_temp" AS "diff_max_temp",
        us."avg_min_temp" - uk."avg_min_temp" AS "diff_min_temp",
        us."avg_avg_temp" - uk."avg_avg_temp" AS "diff_avg_temp"
    FROM  daily_country_stats  us
    JOIN  daily_country_stats  uk
          ON  us."obs_date" = uk."obs_date"
    WHERE us."country" = 'US'
      AND uk."country" = 'UK'
)
SELECT
    "obs_date",
    "diff_max_temp",
    "diff_min_temp",
    "diff_avg_temp"
FROM   daily_differences
ORDER  BY "obs_date";