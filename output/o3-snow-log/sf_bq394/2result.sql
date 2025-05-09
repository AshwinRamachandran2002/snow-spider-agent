WITH combined AS (

    /* -----------------------------------------------------------------
       Gather the required temperature variables from each yearly table
       ----------------------------------------------------------------- */
    SELECT "year",
           "month",
           "air_temperature",
           "wetbulb_temperature",
           "dewpoint_temperature",
           "sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS."ICOADS_CORE_2010"

    UNION ALL
    SELECT "year","month","air_temperature","wetbulb_temperature",
           "dewpoint_temperature","sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS."ICOADS_CORE_2011"

    UNION ALL
    SELECT "year","month","air_temperature","wetbulb_temperature",
           "dewpoint_temperature","sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS."ICOADS_CORE_2012"

    UNION ALL
    SELECT "year","month","air_temperature","wetbulb_temperature",
           "dewpoint_temperature","sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS."ICOADS_CORE_2013"

    UNION ALL
    SELECT "year","month","air_temperature","wetbulb_temperature",
           "dewpoint_temperature","sea_surface_temp"
    FROM NOAA_DATA.NOAA_ICOADS."ICOADS_CORE_2014"
),

/* ---------------------------------------------------------------
   Calculate the monthly averages for each variable (2010-2014)
   --------------------------------------------------------------- */
monthly_avg AS (
    SELECT
        "year"  AS yr,
        "month" AS mo,
        AVG("air_temperature")      AS avg_air,
        AVG("wetbulb_temperature")  AS avg_wbt,
        AVG("dewpoint_temperature") AS avg_dew,
        AVG("sea_surface_temp")     AS avg_sst
    FROM combined
    WHERE "year" BETWEEN 2010 AND 2014
    GROUP BY "year","month"
    HAVING   COUNT("air_temperature")      > 0
         AND COUNT("wetbulb_temperature")  > 0
         AND COUNT("dewpoint_temperature") > 0
         AND COUNT("sea_surface_temp")     > 0
),

/* ---------------------------------------------------------------
   For each month-year, compute the sum of absolute differences
   across all six unordered pairs of the four means
   --------------------------------------------------------------- */
diffs AS (
    SELECT
        yr,
        mo,
        ABS(avg_air - avg_wbt) +
        ABS(avg_air - avg_dew) +
        ABS(avg_air - avg_sst) +
        ABS(avg_wbt - avg_dew) +
        ABS(avg_wbt - avg_sst) +
        ABS(avg_dew - avg_sst)     AS sum_of_diffs
    FROM monthly_avg
)

/* ---------------------------------------------------------------
   Return the three (year, month) combinations with the
   smallest total differences
   --------------------------------------------------------------- */
SELECT
    yr    AS "year",
    mo    AS "month",
    ROUND(sum_of_diffs,4) AS "sum_of_differences"
FROM diffs
ORDER BY sum_of_diffs ASC NULLS LAST
LIMIT 3;