WITH union_data AS (
    /*  Combine ICOADS core records for the requested years */
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
),
monthly_avg AS (
    /*  Calculate monthly‐mean values of the four temperatures  */
    SELECT
        "year",
        "month",
        AVG("air_temperature")       AS avg_air,
        AVG("wetbulb_temperature")   AS avg_wetbulb,
        AVG("dewpoint_temperature")  AS avg_dewpoint,
        AVG("sea_surface_temp")      AS avg_sst
    FROM union_data
    GROUP BY "year", "month"
    HAVING avg_air      IS NOT NULL
       AND avg_wetbulb IS NOT NULL
       AND avg_dewpoint IS NOT NULL
       AND avg_sst      IS NOT NULL
)
SELECT
    "year"  AS year,
    "month" AS month,
    /*  Sum of absolute pair-wise differences between the four monthly means  */
    ( ABS(avg_air      - avg_wetbulb)
    + ABS(avg_air      - avg_dewpoint)
    + ABS(avg_air      - avg_sst)
    + ABS(avg_wetbulb  - avg_dewpoint)
    + ABS(avg_wetbulb  - avg_sst)
    + ABS(avg_dewpoint - avg_sst) )   AS sum_abs_diff
FROM monthly_avg
ORDER BY sum_abs_diff ASC NULLS LAST
LIMIT 3;