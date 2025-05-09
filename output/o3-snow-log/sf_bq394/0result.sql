WITH all_core AS (          -- gather every report for 2010-2014
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
), monthly_avgs AS (         -- monthly means for the four temperatures
    SELECT
        "year",
        "month",
        AVG("air_temperature")        AS avg_air,
        AVG("wetbulb_temperature")    AS avg_wbt,
        AVG("dewpoint_temperature")   AS avg_dpt,
        AVG("sea_surface_temp")       AS avg_sst
    FROM   all_core
    GROUP  BY "year","month"
    HAVING  AVG("air_temperature")      IS NOT NULL
        AND AVG("wetbulb_temperature")  IS NOT NULL
        AND AVG("dewpoint_temperature") IS NOT NULL
        AND AVG("sea_surface_temp")     IS NOT NULL
), diffs AS (                 -- sum of pair-wise absolute differences
    SELECT
        "year",
        "month",
        ABS(avg_air-avg_wbt) + ABS(avg_air-avg_dpt) + ABS(avg_air-avg_sst) +
        ABS(avg_wbt-avg_dpt) + ABS(avg_wbt-avg_sst) + ABS(avg_dpt-avg_sst)
            AS sum_abs_diffs
    FROM monthly_avgs
)
SELECT
    "year",
    "month",
    sum_abs_diffs
FROM diffs
ORDER BY sum_abs_diffs ASC
LIMIT 3;