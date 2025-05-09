WITH all_monthly_readings AS (
    /* -------------------------------------------------------------------
       Collect the variables we need from every ICOADS table
       that contains years 2010-2014.
    -------------------------------------------------------------------- */
    SELECT  "year",
            "month",
            "air_temperature",
            "wetbulb_temperature",
            "dewpoint_temperature",
            "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2010
    UNION ALL
    SELECT  "year",
            "month",
            "air_temperature",
            "wetbulb_temperature",
            "dewpoint_temperature",
            "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2011
    UNION ALL
    SELECT  "year",
            "month",
            "air_temperature",
            "wetbulb_temperature",
            "dewpoint_temperature",
            "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2012
    UNION ALL
    SELECT  "year",
            "month",
            "air_temperature",
            "wetbulb_temperature",
            "dewpoint_temperature",
            "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2013
    UNION ALL
    SELECT  "year",
            "month",
            "air_temperature",
            "wetbulb_temperature",
            "dewpoint_temperature",
            "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS.ICOADS_CORE_2014
),
monthly_avgs AS (
    /* -------------------------------------------------------------------
       Compute monthly averages of each temperature variable.
    -------------------------------------------------------------------- */
    SELECT  "year",
            "month",
            AVG("air_temperature")      AS avg_air,
            AVG("wetbulb_temperature")  AS avg_wbt,
            AVG("dewpoint_temperature") AS avg_dew,
            AVG("sea_surface_temp")     AS avg_sst
    FROM    all_monthly_readings
    WHERE   "year" BETWEEN 2010 AND 2014
    GROUP BY "year", "month"
),
monthly_diff AS (
    /* -------------------------------------------------------------------
       For each year-month, calculate the sum of absolute differences
       between every pair of the four averages (6 pairs in total).
    -------------------------------------------------------------------- */
    SELECT
        "year",
        "month",
        /* six pair-wise absolute differences */
        ABS(avg_air - avg_wbt) +
        ABS(avg_air - avg_dew) +
        ABS(avg_air - avg_sst) +
        ABS(avg_wbt - avg_dew) +
        ABS(avg_wbt - avg_sst) +
        ABS(avg_dew - avg_sst)     AS sum_diff
    FROM monthly_avgs
    /* exclude months where any average is NULL (would give NULL diff) */
    WHERE avg_air IS NOT NULL
      AND avg_wbt IS NOT NULL
      AND avg_dew IS NOT NULL
      AND avg_sst IS NOT NULL
)
SELECT
    "year",
    "month",
    ROUND(sum_diff, 4) AS "sum_of_absolute_differences"
FROM monthly_diff
ORDER BY sum_diff ASC NULLS LAST
LIMIT 3;