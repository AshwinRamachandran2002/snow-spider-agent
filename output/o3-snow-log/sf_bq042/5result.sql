/*  Average temperature, wind speed, and precipitation at LaGuardia (USAF 725030, WBAN 14732)
    for 12-June in each year 2011-2020                                          */

SELECT
    t."year"                                                AS "year",
    ROUND(AVG(t."temp"), 2)                                 AS "avg_temp_F",
    ROUND(AVG(NULLIF(CAST(t."wdsp" AS FLOAT), 999.9)), 2)   AS "avg_wind_speed_knots",
    ROUND(AVG(t."prcp"), 2)                                 AS "avg_prcp_in"
FROM (
         SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2011"
  UNION ALL SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2012"
  UNION ALL SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2013"
  UNION ALL SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2014"
  UNION ALL SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2015"
  UNION ALL SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2016"
  UNION ALL SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2017"
  UNION ALL SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2018"
  UNION ALL SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2019"
  UNION ALL SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD."GSOD2020"
) t
WHERE t."stn" = '725030'      -- LaGuardia Airport
  AND t."mo"  = '06'          -- June
  AND t."da"  = '12'          -- 12th day
  AND t."prcp" < 99.99        -- exclude “missing” precipitation flag
GROUP BY t."year"
ORDER BY t."year";