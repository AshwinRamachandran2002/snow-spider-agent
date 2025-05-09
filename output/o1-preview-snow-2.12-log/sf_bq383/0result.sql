SELECT
  YEAR("date") AS "Year",
  MAX(CASE WHEN "element" = 'PRCP' THEN ROUND("value" / 10.0, 4) END) AS "Max_Precipitation_mm",
  MAX(CASE WHEN "element" = 'TMAX' THEN ROUND("value" / 10.0, 4) END) AS "Max_Temperature_C",
  MIN(CASE WHEN "element" = 'TMIN' THEN ROUND("value" / 10.0, 4) END) AS "Min_Temperature_C"
FROM (
  SELECT "id", "date", "element", "value", "mflag", "qflag", "sflag", "time"
  FROM GHCN_D.GHCN_D."GHCND_2013"
  UNION ALL
  SELECT "id", "date", "element", "value", "mflag", "qflag", "sflag", "time"
  FROM GHCN_D.GHCN_D."GHCND_2014"
  UNION ALL
  SELECT "id", "date", "element", "value", "mflag", "qflag", "sflag", "time"
  FROM GHCN_D.GHCN_D."GHCND_2015"
  UNION ALL
  SELECT "id", "date", "element", "value", "mflag", "qflag", "sflag", "time"
  FROM GHCN_D.GHCN_D."GHCND_2016"
) AS combined_data
WHERE
  "id" = 'USW00094846'
  AND "element" IN ('PRCP', 'TMIN', 'TMAX')
  AND "qflag" IS NULL
  AND "date" BETWEEN '2013-12-17' AND '2016-12-31'
  AND (MONTH("date") = 12 AND DAY("date") BETWEEN 17 AND 31)
GROUP BY YEAR("date")
ORDER BY "Year";