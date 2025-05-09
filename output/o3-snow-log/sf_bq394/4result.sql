WITH union_data AS (      -- gather all observations 2010-2014
    SELECT "year",
           "month",
           "air_temperature",
           "wetbulb_temperature",
           "dewpoint_temperature",
           "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010
    UNION ALL
    SELECT "year",
           "month",
           "air_temperature",
           "wetbulb_temperature",
           "dewpoint_temperature",
           "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011
    UNION ALL
    SELECT "year",
           "month",
           "air_temperature",
           "wetbulb_temperature",
           "dewpoint_temperature",
           "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012
    UNION ALL
    SELECT "year",
           "month",
           "air_temperature",
           "wetbulb_temperature",
           "dewpoint_temperature",
           "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013
    UNION ALL
    SELECT "year",
           "month",
           "air_temperature",
           "wetbulb_temperature",
           "dewpoint_temperature",
           "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014
), monthly_avg AS (        -- compute monthly averages for each variable
    SELECT
        "year",
        "month",
        AVG("air_temperature")       AS avg_air,
        AVG("wetbulb_temperature")   AS avg_wbt,
        AVG("dewpoint_temperature")  AS avg_dew,
        AVG("sea_surface_temp")      AS avg_sst
    FROM union_data
    WHERE "year" BETWEEN 2010 AND 2014
    GROUP BY "year", "month"
)
SELECT
    "year",
    "month",
    /* sum of all pair-wise absolute differences between the four averaged temps */
    ABS(avg_air - avg_wbt) +
    ABS(avg_air - avg_dew) +
    ABS(avg_air - avg_sst) +
    ABS(avg_wbt - avg_dew) +
    ABS(avg_wbt - avg_sst) +
    ABS(avg_dew - avg_sst)          AS sum_diff
FROM monthly_avg
ORDER BY sum_diff ASC NULLS LAST
LIMIT 3;