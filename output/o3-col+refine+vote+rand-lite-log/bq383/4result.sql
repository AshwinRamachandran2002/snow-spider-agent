WITH filtered AS (
  SELECT
    CAST(CONCAT('20', _TABLE_SUFFIX) AS INT64) AS year,
    element,
    value / 10.0                               AS val          -- convert 0.1-units to units
  FROM `bigquery-public-data.ghcn_d.ghcnd_20*`                -- wildcard tables 2000-series
  WHERE _TABLE_SUFFIX IN ('13', '14', '15', '16')             -- 2013-2016
    AND id = 'USW00094846'                                    -- target station
    AND qflag IS NULL                                         -- validated data only
    AND EXTRACT(MONTH FROM date) = 12                         -- December
    AND EXTRACT(DAY   FROM date) BETWEEN 17 AND 31            -- last 15 days
    AND element IN ('PRCP', 'TMAX', 'TMIN')                   -- required variables
)

SELECT
  year,
  MAX(CASE WHEN element = 'PRCP' THEN val END) AS highest_precip_mm,
  MIN(CASE WHEN element = 'TMIN' THEN val END) AS lowest_tmin_c,
  MAX(CASE WHEN element = 'TMAX' THEN val END) AS highest_tmax_c
FROM filtered
GROUP BY year
ORDER BY year;