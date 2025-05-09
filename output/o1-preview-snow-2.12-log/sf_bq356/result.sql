SELECT COUNT(*) AS "Number_of_Stations"
FROM (
  SELECT s."usaf", s."wban"
  FROM NOAA_DATA.NOAA_GSOD.STATIONS s
  JOIN NOAA_DATA.NOAA_GSOD.GSOD2019 g
    ON s."usaf" = g."stn" AND s."wban" = g."wban"
  WHERE TO_DATE(s."begin", 'YYYYMMDD') <= DATE '2000-01-01'
    AND (s."end" IS NULL OR TO_DATE(s."end", 'YYYYMMDD') >= DATE '2019-06-30')
    AND g."temp" IS NOT NULL 
    AND g."max" IS NOT NULL 
    AND g."min" IS NOT NULL
  GROUP BY s."usaf", s."wban"
  HAVING COUNT(g."stn") >= 0.9 * 365
) t;