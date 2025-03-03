SELECT "year" AS "Year",
       NULLIF("temp", 9999.9) AS "Average_Temperature",
       TRY_TO_NUMBER(NULLIF("wdsp", '999.9')) AS "Average_Wind_Speed",
       NULLIF("prcp", 99.99) AS "Precipitation"
FROM (
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2011"
    UNION ALL
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2012"
    UNION ALL
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2013"
    UNION ALL
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2014"
    UNION ALL
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2015"
    UNION ALL
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2016"
    UNION ALL
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2017"
    UNION ALL
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2018"
    UNION ALL
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019"
    UNION ALL
    SELECT "year", "temp", "wdsp", "prcp", "stn", "mo", "da"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2020"
) AS combined_data
WHERE "stn" = '725030' AND "mo" = '06' AND "da" = '12'
ORDER BY "Year";