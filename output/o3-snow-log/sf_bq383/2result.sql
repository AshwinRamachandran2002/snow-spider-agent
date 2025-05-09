WITH daily_data AS (
    SELECT "id",
           "date",
           "element",
           "value",
           "qflag"
    FROM GHCN_D.GHCN_D.GHCND_2013
    UNION ALL
    SELECT "id", "date", "element", "value", "qflag"
    FROM GHCN_D.GHCN_D.GHCND_2014
    UNION ALL
    SELECT "id", "date", "element", "value", "qflag"
    FROM GHCN_D.GHCN_D.GHCND_2015
    UNION ALL
    SELECT "id", "date", "element", "value", "qflag"
    FROM GHCN_D.GHCN_D.GHCND_2016
)
SELECT
    EXTRACT(YEAR FROM "date")                         AS "year",
    MAX(CASE WHEN "element" = 'PRCP'
             THEN "value" / 10.0 END)                AS "max_prcp_mm",
    MIN(CASE WHEN "element" = 'TMIN'
             THEN "value" / 10.0 END)                AS "min_tmin_c",
    MAX(CASE WHEN "element" = 'TMAX'
             THEN "value" / 10.0 END)                AS "max_tmax_c"
FROM daily_data
WHERE "id" = 'USW00094846'
  AND "qflag" IS NULL                  -- only validated records
  AND "value" IS NOT NULL
  AND MONTH("date") = 12               -- December
  AND DAY("date")  >= 17               -- last 15 days (17-31)
GROUP BY EXTRACT(YEAR FROM "date")
ORDER BY "year";