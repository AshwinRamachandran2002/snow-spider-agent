WITH all_years AS (          -- 1. Gather raw rows for the 4 years of interest
    SELECT "date",
           "element",
           "value",
           "id",
           "qflag"
    FROM GHCN_D.GHCN_D."GHCND_2013"
    UNION ALL
    SELECT "date","element","value","id","qflag"
    FROM GHCN_D.GHCN_D."GHCND_2014"
    UNION ALL
    SELECT "date","element","value","id","qflag"
    FROM GHCN_D.GHCN_D."GHCND_2015"
    UNION ALL
    SELECT "date","element","value","id","qflag"
    FROM GHCN_D.GHCN_D."GHCND_2016"
),
filtered AS (                -- 2. Keep only validated rows for the last 15 days of each year
    SELECT
        YEAR("date")                     AS yr,          -- extraction of calendar year
        "element",
        "value"
    FROM all_years
    WHERE "id"            = 'USW00094846'                -- target station
      AND "qflag"         IS NULL                        -- no quality issues
      AND "value"         IS NOT NULL                    -- non-null measurements
      AND "element"       IN ('PRCP','TMIN','TMAX')
      AND "date" BETWEEN                                  -- 15-day year-end window
          DATE_FROM_PARTS(YEAR("date"),12,17)
          AND
          DATE_FROM_PARTS(YEAR("date"),12,31)
)
SELECT                       -- 3. Aggregate to one record per year
    yr                                  AS "year",
    MAX(CASE WHEN "element"='PRCP' THEN "value" END)/10  AS "precipitation_mm",
    MIN(CASE WHEN "element"='TMIN' THEN "value" END)/10  AS "min_temperature_c",
    MAX(CASE WHEN "element"='TMAX' THEN "value" END)/10  AS "max_temperature_c"
FROM filtered
GROUP BY yr
ORDER BY yr;