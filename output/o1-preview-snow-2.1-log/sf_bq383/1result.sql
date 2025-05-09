SELECT
    EXTRACT(YEAR FROM "date") AS "Year",
    MAX(CASE WHEN "element" = 'PRCP' THEN "value" END) AS "Max_Precipitation_mm",
    MAX(CASE WHEN "element" = 'TMAX' THEN "value" END) / 10.0000 AS "Max_Temperature_C",
    MIN(CASE WHEN "element" = 'TMIN' THEN "value" END) / 10.0000 AS "Min_Temperature_C"
FROM
(
    SELECT "id", "date", "element", "value", "qflag"
    FROM "GHCN_D"."GHCN_D"."GHCND_2013"
    
    UNION ALL
    
    SELECT "id", "date", "element", "value", "qflag"
    FROM "GHCN_D"."GHCN_D"."GHCND_2014"
    
    UNION ALL
    
    SELECT "id", "date", "element", "value", "qflag"
    FROM "GHCN_D"."GHCN_D"."GHCND_2015"
    
    UNION ALL
    
    SELECT "id", "date", "element", "value", "qflag"
    FROM "GHCN_D"."GHCN_D"."GHCND_2016"
) AS combined_data
WHERE
    "id" = 'USW00094846'
    AND "element" IN ('PRCP', 'TMAX', 'TMIN')
    AND "qflag" IS NULL
    AND (
        ("date" BETWEEN '2013-12-17' AND '2013-12-31') OR
        ("date" BETWEEN '2014-12-17' AND '2014-12-31') OR
        ("date" BETWEEN '2015-12-17' AND '2015-12-31') OR
        ("date" BETWEEN '2016-12-17' AND '2016-12-31')
    )
GROUP BY
    EXTRACT(YEAR FROM "date")
ORDER BY
    "Year";