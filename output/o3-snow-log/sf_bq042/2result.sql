/*  Average temperature, wind-speed, and precipitation for LaGuardia (station 725030)
    on 12-Jun for each year 2011-2020                                          */
WITH all_years AS (
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2011"
    UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2012"
    UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2013"
    UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2014"
    UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2015"
    UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2016"
    UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2017"
    UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2018"
    UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2019"
    UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2020"
)
SELECT
    "year",
    ROUND(AVG("temp"),2)                          AS "avg_temp_f",
    ROUND(AVG("wdsp"::FLOAT),2)                   AS "avg_wdsp_kts",
    ROUND(AVG(NULLIF("prcp",99.99)),2)            AS "prcp_in"
FROM all_years
WHERE "stn" = '725030'   -- LaGuardia Airport
  AND "mo"  = '06'
  AND "da"  = '12'
GROUP BY "year"
ORDER BY "year";