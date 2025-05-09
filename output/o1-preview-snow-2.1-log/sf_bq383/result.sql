SELECT
  "Year",
  ROUND(MAX(CASE WHEN "element" = 'PRCP' THEN "value" / 10 ELSE NULL END), 4) AS "Max_Precipitation_mm",
  ROUND(MAX(CASE WHEN "element" = 'TMAX' THEN "value" / 10 ELSE NULL END), 4) AS "Max_Temperature_C",
  ROUND(MIN(CASE WHEN "element" = 'TMIN' THEN "value" / 10 ELSE NULL END), 4) AS "Min_Temperature_C"
FROM (
  SELECT '2013' AS "Year", "id", "date", "element", "value", "qflag"
  FROM GHCN_D.GHCN_D.GHCND_2013
  UNION ALL
  SELECT '2014' AS "Year", "id", "date", "element", "value", "qflag"
  FROM GHCN_D.GHCN_D.GHCND_2014
  UNION ALL
  SELECT '2015' AS "Year", "id", "date", "element", "value", "qflag"
  FROM GHCN_D.GHCN_D.GHCND_2015
  UNION ALL
  SELECT '2016' AS "Year", "id", "date", "element", "value", "qflag"
  FROM GHCN_D.GHCN_D.GHCND_2016
) AS all_data
WHERE
  "id" = 'USW00094846'
  AND "date" BETWEEN TO_DATE("Year" || '-12-17', 'YYYY-MM-DD') AND TO_DATE("Year" || '-12-31', 'YYYY-MM-DD')
  AND "qflag" IS NULL
GROUP BY "Year"
ORDER BY "Year";