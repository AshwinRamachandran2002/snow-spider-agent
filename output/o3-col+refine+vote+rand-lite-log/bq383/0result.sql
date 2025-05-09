-- Highest precipitation, max TMAX and min TMIN for the last 15 days (Dec 17–31)
-- of each year 2013-2016 at station USW00094846, using only validated records.
WITH period_data AS (
  SELECT
    _TABLE_SUFFIX AS yr,
    element,
    value
  FROM `bigquery-public-data.ghcn_d.ghcnd_*`
  WHERE
    _TABLE_SUFFIX IN ('2013','2014','2015','2016')   -- years of interest
    AND id        = 'USW00094846'                    -- target station
    AND qflag     IS NULL                            -- validated data only
    AND value     IS NOT NULL
    AND date BETWEEN DATE(CONCAT(_TABLE_SUFFIX,'-12-17'))
                 AND DATE(CONCAT(_TABLE_SUFFIX,'-12-31'))  -- last 15 days
    AND element IN ('PRCP','TMAX','TMIN')            -- required measurements
)

SELECT
  yr,
  MAX(CASE WHEN element = 'PRCP' THEN value END) / 10.0 AS max_prcp_mm,  -- mm
  MAX(CASE WHEN element = 'TMAX' THEN value END) / 10.0 AS max_tmax_c,   -- °C
  MIN(CASE WHEN element = 'TMIN' THEN value END) / 10.0 AS min_tmin_c    -- °C
FROM period_data
GROUP BY yr
ORDER BY yr;