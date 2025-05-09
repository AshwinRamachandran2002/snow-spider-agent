WITH union_data AS (      -- bring together the four yearly tables that might contain the rows we need
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
), filtered AS (          -- keep only rows for our station, elements of interest, last-15-days window, and good-quality data
    SELECT
           EXTRACT(year FROM "date")      AS "YEAR",
           "element",
           "value"
      FROM union_data
     WHERE "id"      = 'USW00094846'
       AND "qflag"   IS NULL            -- validated (no quality flag)
       AND "value"   IS NOT NULL
       AND "element" IN ('PRCP','TMIN','TMAX')
       AND EXTRACT(month FROM "date") = 12   -- December
       AND EXTRACT(day   FROM "date") >= 17  -- 17-31  (last 15 days)
)
SELECT
       "YEAR",
       MAX(CASE WHEN "element" = 'PRCP' THEN "value" END) / 10 AS "MAX_PRCP_MM",
       MIN(CASE WHEN "element" = 'TMIN' THEN "value" END) / 10 AS "MIN_TMIN_C",
       MAX(CASE WHEN "element" = 'TMAX' THEN "value" END) / 10 AS "MAX_TMAX_C"
  FROM filtered
 GROUP BY "YEAR"
 ORDER BY "YEAR";