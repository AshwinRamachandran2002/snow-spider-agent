/*  Highest daily precipitation, minimum daily temperature, and maximum
    daily temperature recorded during the last 15 days (17 – 31 Dec)
    of each year 2013‑2016 at station USW00094846.
    –  Precipitation returned in millimetres
    –  Temperatures returned in °C
    –  Uses only rows with no quality flag (qflag IS NULL) and non‑missing values
*/
SELECT
  year,
  MAX_PRCP_mm AS max_precip_mm,
  MIN_TMIN_C  AS min_tmin_c,
  MAX_TMAX_C  AS max_tmax_c
FROM (
  WITH filtered AS (
    SELECT
      CAST(_TABLE_SUFFIX AS INT64)            AS year,
      element,
      value/10.0                              AS obs          -- convert tenths to standard units
    FROM `bigquery-public-data.ghcn_d.ghcnd_*`
    WHERE _TABLE_SUFFIX IN ('2013','2014','2015','2016')
      AND id       = 'USW00094846'
      AND element IN ('PRCP','TMIN','TMAX')
      AND qflag    IS NULL                    -- keep only validated data
      AND value    IS NOT NULL
      AND value   > -9990                     -- discard “missing” sentinel values (‑9999)
      AND date BETWEEN
            DATE(CONCAT(_TABLE_SUFFIX,'-12-17'))   -- 17 Dec
        AND DATE(CONCAT(_TABLE_SUFFIX,'-12-31'))   -- 31 Dec
  )
  SELECT
    year,
    MAX(CASE WHEN element = 'PRCP' THEN obs END) AS MAX_PRCP_mm,
    MIN(CASE WHEN element = 'TMIN' THEN obs END) AS MIN_TMIN_C,
    MAX(CASE WHEN element = 'TMAX' THEN obs END) AS MAX_TMAX_C
  FROM filtered
  GROUP BY year
)
ORDER BY year;