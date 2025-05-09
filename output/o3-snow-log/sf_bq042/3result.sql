/*  June-12 weather summary for LaGuardia Airport (USAF 725030) – years 2011-2020  */
WITH june12_lga AS (

    /* 2011 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2011"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'

    UNION ALL
    /* 2012 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2012"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'

    UNION ALL
    /* 2013 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2013"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'

    UNION ALL
    /* 2014 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2014"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'

    UNION ALL
    /* 2015 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2015"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'

    UNION ALL
    /* 2016 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2016"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'

    UNION ALL
    /* 2017 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2017"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'

    UNION ALL
    /* 2018 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2018"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'

    UNION ALL
    /* 2019 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2019"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'

    UNION ALL
    /* 2020 */
    SELECT "year","temp","wdsp","prcp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2020"
    WHERE  "stn" = '725030' AND "mo" = '06' AND "da" = '12'
)

SELECT  "year",
        ROUND(AVG("temp"),2)                              AS "avg_temp_f",
        ROUND(AVG(TRY_TO_NUMBER("wdsp")),2)               AS "avg_wind_knots",
        ROUND(SUM(CASE WHEN "prcp" < 99 THEN "prcp" END),2) AS "daily_prcp"
FROM    june12_lga
GROUP BY "year"
ORDER BY "year";