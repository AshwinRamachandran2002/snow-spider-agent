WITH all_obs AS (   -- gather the 2010-2014 observations that contain all four temperatures
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
), monthly_avg AS (   -- compute monthly averages for each variable
    SELECT
        "year",
        "month",
        AVG("air_temperature")       AS avg_air,
        AVG("wetbulb_temperature")   AS avg_wbt,
        AVG("dewpoint_temperature")  AS avg_dew,
        AVG("sea_surface_temp")      AS avg_sst
    FROM all_obs
    WHERE "year" BETWEEN 2010 AND 2014
    GROUP BY "year","month"
), dispersion AS (   -- sum of absolute pair-wise differences among the four averages
    SELECT
        "year",
        "month",
        /* six pair-wise absolute differences */
          ABS(avg_air - avg_wbt)
        + ABS(avg_air - avg_dew)
        + ABS(avg_air - avg_sst)
        + ABS(avg_wbt - avg_dew)
        + ABS(avg_wbt - avg_sst)
        + ABS(avg_dew - avg_sst)      AS sum_abs_diff
    FROM monthly_avg
)
SELECT
    "year",
    "month",
    sum_abs_diff
FROM dispersion
ORDER BY sum_abs_diff ASC NULLS LAST
LIMIT 3;