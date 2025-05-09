-- Average temperature, wind speed, and precipitation at LaGuardia (USAF 725030)
-- on 12-Jun for each year 2011-2020
SELECT
    "year",
    AVG("temp")                      AS "avg_temp",
    AVG(CAST("wdsp" AS FLOAT))       AS "avg_wind_speed",
    AVG("prcp")                      AS "avg_prcp"
FROM (
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2011 UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2012 UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2013 UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2014 UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2015 UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2016 UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2017 UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2018 UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2019 UNION ALL
    SELECT "year","temp","wdsp","prcp","stn","mo","da" FROM NOAA_DATA.NOAA_GSOD.GSOD2020
) t
WHERE
    "stn" = '725030'
    AND "mo" = '06'
    AND "da" = '12'
GROUP BY
    "year"
ORDER BY
    "year";