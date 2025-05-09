-- Highest precipitation, minimum TMIN, and maximum TMAX
-- during the final 15 days of each year 2013‑2016
-- for station USW00094846 (validated records only).

WITH last_15_days AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)            AS year,
    element,
    value                                   -- stored in tenths
  FROM
    `bigquery-public-data.ghcn_d.ghcnd_*`
  WHERE
        _TABLE_SUFFIX IN ('2013','2014','2015','2016')   -- years of interest
    AND id       = 'USW00094846'                         -- target station
    AND qflag IS NULL                                    -- keep validated data
    AND value IS NOT NULL                                -- non‑null values
    -- limit to 17‑31 December (the last 15 days)
    AND EXTRACT(MONTH FROM date) = 12
    AND EXTRACT(DAY   FROM date) BETWEEN 17 AND 31
)

SELECT
  year,
  ROUND(MAX(CASE WHEN element = 'PRCP' THEN value/10 END), 4) AS max_precip_mm, -- tenths → mm
  ROUND(MIN(CASE WHEN element = 'TMIN' THEN value/10 END), 4) AS min_temp_c,    -- tenths → °C
  ROUND(MAX(CASE WHEN element = 'TMAX' THEN value/10 END), 4) AS max_temp_c     -- tenths → °C
FROM last_15_days
GROUP BY year
ORDER BY year;