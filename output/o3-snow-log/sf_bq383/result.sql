WITH daily AS (
    SELECT 
        EXTRACT(year FROM "date")            AS "year",
        "element",
        "value"
    FROM (
        SELECT "id","date","element","value","qflag" FROM "GHCN_D"."GHCN_D"."GHCND_2013"
        UNION ALL
        SELECT "id","date","element","value","qflag" FROM "GHCN_D"."GHCN_D"."GHCND_2014"
        UNION ALL
        SELECT "id","date","element","value","qflag" FROM "GHCN_D"."GHCN_D"."GHCND_2015"
        UNION ALL
        SELECT "id","date","element","value","qflag" FROM "GHCN_D"."GHCN_D"."GHCND_2016"
    )
    WHERE  "id" = 'USW00094846'
       AND "qflag" IS NULL
       AND "value" IS NOT NULL
       AND EXTRACT(year  FROM "date") BETWEEN 2013 AND 2016
       AND EXTRACT(month FROM "date") = 12
       AND EXTRACT(day   FROM "date") BETWEEN 17 AND 31
)
SELECT
    "year",
    MAX(CASE WHEN "element" = 'PRCP' THEN "value" END) / 10.0 AS "precipitation_mm",
    MIN(CASE WHEN "element" = 'TMIN' THEN "value" END) / 10.0 AS "minimum_temperature_c",
    MAX(CASE WHEN "element" = 'TMAX' THEN "value" END) / 10.0 AS "maximum_temperature_c"
FROM  daily
GROUP BY "year"
ORDER BY "year";