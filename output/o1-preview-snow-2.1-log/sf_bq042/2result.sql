SELECT TO_DATE(CONCAT("year", '-', LPAD("mo", 2, '0'), '-', LPAD("da", 2, '0')), 'YYYY-MM-DD') AS "Date",
       ROUND(CAST("temp" AS FLOAT), 4) AS "Temperature",
       ROUND(CAST("wdsp" AS FLOAT), 4) AS "Wind_Speed",
       ROUND(CAST("prcp" AS FLOAT), 4) AS "Precipitation"
FROM (
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2011"
    UNION ALL
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2012"
    UNION ALL
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2013"
    UNION ALL
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2014"
    UNION ALL
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2015"
    UNION ALL
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2016"
    UNION ALL
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2017"
    UNION ALL
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2018"
    UNION ALL
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2019"
    UNION ALL
    SELECT "year", "mo", "da", "temp", "wdsp", "prcp", "wban" FROM NOAA_DATA.NOAA_GSOD."GSOD2020"
) AS gsod_data
WHERE "wban" = '14732' AND "mo" = '06' AND "da" = '12'
ORDER BY "year";