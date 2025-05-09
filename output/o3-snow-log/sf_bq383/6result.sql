WITH data_union AS (
    /* bring together the four yearly partitions that may contain the target dates */
    SELECT "id","date","element","value","qflag" FROM GHCN_D.GHCN_D."GHCND_2013"
    UNION ALL
    SELECT "id","date","element","value","qflag" FROM GHCN_D.GHCN_D."GHCND_2014"
    UNION ALL
    SELECT "id","date","element","value","qflag" FROM GHCN_D.GHCN_D."GHCND_2015"
    UNION ALL
    SELECT "id","date","element","value","qflag" FROM GHCN_D.GHCN_D."GHCND_2016"
),
filtered AS (
    /* keep only validated observations for the last 15 days of each year (Dec 17-31) */
    SELECT
        EXTRACT(YEAR  FROM "date")                AS yr,
        "element",
        "value"
    FROM data_union
    WHERE "id"      = 'USW00094846'      -- target station
      AND "qflag"   IS NULL              -- validated (no quality flag)
      AND "value"   IS NOT NULL
      AND EXTRACT(MONTH FROM "date") = 12
      AND EXTRACT(DAY   FROM "date") >= 17
)
SELECT
    yr                                                AS "YEAR",
    MAX(CASE WHEN "element" = 'PRCP' THEN "value" END) / 10  AS "PRECIP_MM_MAX",
    MIN(CASE WHEN "element" = 'TMIN' THEN "value" END) / 10  AS "TMIN_C_MIN",
    MAX(CASE WHEN "element" = 'TMAX' THEN "value" END) / 10  AS "TMAX_C_MAX"
FROM filtered
GROUP BY yr
ORDER BY yr;