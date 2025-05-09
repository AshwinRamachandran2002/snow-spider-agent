SELECT COUNT(*) AS "Number_of_Stations"
FROM (
  SELECT sd."usaf", sd."wban"
  FROM (
    SELECT s."usaf", s."wban",
           GREATEST(TO_DATE('2019-01-01', 'YYYY-MM-DD'), TO_DATE(s."begin", 'YYYYMMDD')) AS start_date_2019,
           LEAST(TO_DATE(s."end", 'YYYYMMDD'), TO_DATE('2019-12-31', 'YYYY-MM-DD')) AS end_date_2019,
           DATEDIFF('day',
             GREATEST(TO_DATE('2019-01-01', 'YYYY-MM-DD'), TO_DATE(s."begin", 'YYYYMMDD')),
             LEAST(TO_DATE(s."end", 'YYYYMMDD'), TO_DATE('2019-12-31', 'YYYY-MM-DD'))
           ) + 1 AS total_possible_days_2019
    FROM "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
    WHERE s."begin" <= '20000101' AND s."end" >= '20190630'
  ) sd
  JOIN (
    SELECT "stn", "wban", COUNT(*) AS valid_days
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019"
    WHERE "year" = 2019 AND "temp" IS NOT NULL AND "max" IS NOT NULL AND "min" IS NOT NULL
    GROUP BY "stn", "wban"
  ) vd
  ON sd."usaf" = vd."stn" AND sd."wban" = vd."wban"
  WHERE vd.valid_days >= 0.9 * sd.total_possible_days_2019
)