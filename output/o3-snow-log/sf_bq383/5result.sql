WITH union_data AS (
    SELECT "date",
           "element",
           "value"
    FROM GHCN_D.GHCN_D.GHCND_2013
    WHERE "id" = 'USW00094846'
      AND "qflag" IS NULL
      AND "value" IS NOT NULL

    UNION ALL
    SELECT "date",
           "element",
           "value"
    FROM GHCN_D.GHCN_D.GHCND_2014
    WHERE "id" = 'USW00094846'
      AND "qflag" IS NULL
      AND "value" IS NOT NULL

    UNION ALL
    SELECT "date",
           "element",
           "value"
    FROM GHCN_D.GHCN_D.GHCND_2015
    WHERE "id" = 'USW00094846'
      AND "qflag" IS NULL
      AND "value" IS NOT NULL

    UNION ALL
    SELECT "date",
           "element",
           "value"
    FROM GHCN_D.GHCN_D.GHCND_2016
    WHERE "id" = 'USW00094846'
      AND "qflag" IS NULL
      AND "value" IS NOT NULL
)

SELECT  EXTRACT(year FROM "date")                          AS "year",
        MAX(CASE WHEN "element" = 'PRCP' THEN "value" / 10 END) AS "max_prcp_mm",
        MIN(CASE WHEN "element" = 'TMIN' THEN "value" / 10 END) AS "min_tmin_c",
        MAX(CASE WHEN "element" = 'TMAX' THEN "value" / 10 END) AS "max_tmax_c"
FROM    union_data
WHERE   "date" >= DATE_FROM_PARTS(EXTRACT(year FROM "date"), 12, 17)
  AND   "date" <= DATE_FROM_PARTS(EXTRACT(year FROM "date"), 12, 31)
GROUP BY EXTRACT(year FROM "date")
ORDER BY "year";