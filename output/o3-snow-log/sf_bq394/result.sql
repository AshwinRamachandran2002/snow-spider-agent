WITH combined AS (
    /*  Collect required temperature fields from each yearly ICOADS table (2010-2014) */
    SELECT "year",
           "month",
           "air_temperature",
           "wetbulb_temperature",
           "dewpoint_temperature",
           "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010
    UNION ALL
    SELECT "year","month","air_temperature","wetbulb_temperature",
           "dewpoint_temperature","sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011
    UNION ALL
    SELECT "year","month","air_temperature","wetbulb_temperature",
           "dewpoint_temperature","sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012
    UNION ALL
    SELECT "year","month","air_temperature","wetbulb_temperature",
           "dewpoint_temperature","sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013
    UNION ALL
    SELECT "year","month","air_temperature","wetbulb_temperature",
           "dewpoint_temperature","sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014
),
monthly_avgs AS (
    /*  Average each temperature variable per year-month  */
    SELECT
        "year",
        "month",
        AVG("air_temperature")        AS avg_air,
        AVG("wetbulb_temperature")    AS avg_wet,
        AVG("dewpoint_temperature")   AS avg_dew,
        AVG("sea_surface_temp")       AS avg_sst
    FROM combined
    WHERE "year" BETWEEN 2010 AND 2014
    GROUP BY "year","month"
    HAVING avg_air IS NOT NULL
       AND avg_wet IS NOT NULL
       AND avg_dew IS NOT NULL
       AND avg_sst IS NOT NULL
),
diffs AS (
    /*  Sum of pair-wise absolute differences between the four averages  */
    SELECT
        "year",
        "month",
        ABS(avg_air - avg_wet)
      + ABS(avg_air - avg_dew)
      + ABS(avg_air - avg_sst)
      + ABS(avg_wet - avg_dew)
      + ABS(avg_wet - avg_sst)
      + ABS(avg_dew - avg_sst)       AS sum_diff
    FROM monthly_avgs
)
SELECT
    "year",
    "month",
    sum_diff
FROM diffs
ORDER BY sum_diff ASC NULLS LAST
LIMIT 3;