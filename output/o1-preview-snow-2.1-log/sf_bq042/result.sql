SELECT 
   DATE_FROM_PARTS(TO_NUMBER(t."year"), TO_NUMBER(t."mo"), TO_NUMBER(t."da")) AS "Date",
   ROUND(t."temp", 4) AS "Temperature",
   ROUND(t."wdsp", 4) AS "Wind_Speed",
   ROUND(t."prcp", 4) AS "Precipitation"
FROM (
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2011
   UNION ALL
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2012
   UNION ALL
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2013
   UNION ALL
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2014
   UNION ALL
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2015
   UNION ALL
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2016
   UNION ALL
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2017
   UNION ALL
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2018
   UNION ALL
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2019
   UNION ALL
   SELECT "stn", "wban", "year", "mo", "da", "temp", "wdsp", "prcp" FROM NOAA_DATA.NOAA_GSOD.GSOD2020
) t
WHERE t."stn" = '725030' AND t."wban" = '14732'
  AND t."mo" = '06' AND t."da" = '12'
ORDER BY t."year";