SELECT
  CONCAT("year", '-', LPAD("mo", 2, '0'), '-', LPAD("da", 2, '0')) AS "DATE"
FROM NOAA_GSOD.NOAA_GSOD."GSOD2009"
WHERE "stn" = '723758'
  AND "year" = '2009'
  AND "mo"   = '10'
  AND "temp" <> 9999.9                     -- Exclude missing values
GROUP BY "year", "mo", "da"
ORDER BY AVG("temp") DESC NULLS LAST       -- Highest average daily temperature
LIMIT 3;