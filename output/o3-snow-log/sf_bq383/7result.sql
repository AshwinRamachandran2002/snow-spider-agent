SELECT
    YEAR("date")                                   AS "year",
    MAX(CASE WHEN "element" = 'PRCP' THEN "value" / 10 END) AS "max_prcp_mm",
    MAX(CASE WHEN "element" = 'TMIN' THEN "value" / 10 END) AS "max_tmin_c",
    MAX(CASE WHEN "element" = 'TMAX' THEN "value" / 10 END) AS "max_tmax_c"
FROM (
        SELECT "id","date","element","value","qflag","mflag" FROM GHCN_D.GHCN_D.GHCND_2013
        UNION ALL
        SELECT "id","date","element","value","qflag","mflag" FROM GHCN_D.GHCN_D.GHCND_2014
        UNION ALL
        SELECT "id","date","element","value","qflag","mflag" FROM GHCN_D.GHCN_D.GHCND_2015
        UNION ALL
        SELECT "id","date","element","value","qflag","mflag" FROM GHCN_D.GHCN_D.GHCND_2016
) AS d
WHERE  "id"       = 'USW00094846'
  AND  "element" IN ('PRCP','TMIN','TMAX')
  AND  "value"    IS NOT NULL
  AND  "qflag"    IS NULL        -- only validated records (no quality flags)
  AND  "mflag"    IS NULL
  AND  YEAR("date") BETWEEN 2013 AND 2016
  AND  MONTH("date") = 12        -- December
  AND  DAY("date")  >= 17         -- last 15 days (Dec 17-31)
GROUP BY YEAR("date")
ORDER BY "year";