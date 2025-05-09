/*  Highest PRCP, lowest TMIN and highest TMAX during the last 15 days
    (17 Dec – 31 Dec) of each year 2013-2016 for station USW00094846      */
WITH all_years AS (
     SELECT "id","date","element","value","qflag"
     FROM GHCN_D.GHCN_D."GHCND_2013"
     UNION ALL
     SELECT "id","date","element","value","qflag"
     FROM GHCN_D.GHCN_D."GHCND_2014"
     UNION ALL
     SELECT "id","date","element","value","qflag"
     FROM GHCN_D.GHCN_D."GHCND_2015"
     UNION ALL
     SELECT "id","date","element","value","qflag"
     FROM GHCN_D.GHCN_D."GHCND_2016"
),
last_15_days AS (
     SELECT
         EXTRACT(year FROM "date")                           AS "year",
         "element",
         "value"
     FROM   all_years
     WHERE  "id"      = 'USW00094846'         -- target station
       AND  "qflag"   IS NULL                 -- only validated data
       AND  "value"   IS NOT NULL
       AND  "element" IN ('PRCP','TMAX','TMIN')
       AND  "date" BETWEEN
              DATE_FROM_PARTS(EXTRACT(year FROM "date"),12,17)
          AND DATE_FROM_PARTS(EXTRACT(year FROM "date"),12,31)
)
SELECT
    "year",
    MAX(CASE WHEN "element" = 'PRCP' THEN "value" END) / 10.0  AS "max_precip_mm",
    MIN(CASE WHEN "element" = 'TMIN' THEN "value" END) / 10.0  AS "min_temp_c",
    MAX(CASE WHEN "element" = 'TMAX' THEN "value" END) / 10.0  AS "max_temp_c"
FROM   last_15_days
GROUP  BY "year"
ORDER  BY "year";