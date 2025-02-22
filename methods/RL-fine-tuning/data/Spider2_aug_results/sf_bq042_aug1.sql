-- Task: Retrieve the temperature, wind speed, and precipitation for LaGuardia Airport in NYC on June 12, 2011, using the station ID 725030.

SELECT 
   DATE_FROM_PARTS(TO_NUMBER("year"), TO_NUMBER("mo"), TO_NUMBER("da")) AS "Date",
   ROUND("temp", 4) AS "Temperature",
   ROUND("wdsp", 4) AS "Wind_Speed",
   ROUND("prcp", 4) AS "Precipitation"
FROM NOAA_DATA.NOAA_GSOD.GSOD2011
WHERE "stn" = '725030' AND "wban" = '14732'
  AND "mo" = '06' AND "da" = '12';