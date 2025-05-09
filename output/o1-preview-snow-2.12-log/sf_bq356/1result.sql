SELECT COUNT(*) AS "Number_of_Stations"
FROM (
  SELECT s."usaf", s."wban"
  FROM "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
  JOIN "NOAA_DATA"."NOAA_GSOD"."GSOD2019" g
    ON s."usaf" = g."stn" AND s."wban" = g."wban"
  WHERE s."begin" <= '20000101' AND s."end" >= '20190630'
    AND g."temp" IS NOT NULL AND g."max" IS NOT NULL AND g."min" IS NOT NULL
  GROUP BY s."usaf", s."wban"
  HAVING COUNT(*) >= 329
) AS T;