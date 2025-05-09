/*  Highest precipitation, lowest TMIN, and highest TMAX
    during the last 15 days (Dec 17‑31) of each year 2013‑2016
    for station USW00094846.  Values are returned in
    millimetres (PRCP) and °C (TMIN/TMAX).                 */

SELECT
  yr                       AS year,
  MAX_PRCP_mm              AS max_precip_mm,
  MIN_TMIN_C               AS min_temp_c,
  MAX_TMAX_C               AS max_temp_c
FROM (
  SELECT
    SAFE_CAST(_TABLE_SUFFIX AS INT64)                               AS yr,
    MAX(IF(element = 'PRCP', value, NULL)) / 10.0                  AS MAX_PRCP_mm,   -- tenths‑mm → mm
    MIN(IF(element = 'TMIN', value, NULL)) / 10.0                  AS MIN_TMIN_C,    -- tenths‑°C → °C
    MAX(IF(element = 'TMAX', value, NULL)) / 10.0                  AS MAX_TMAX_C     -- tenths‑°C → °C
  FROM
    `bigquery-public-data.ghcn_d.ghcnd_*`
  WHERE
        _TABLE_SUFFIX IN ('2013','2014','2015','2016')        -- restrict to needed years
    AND id          = 'USW00094846'                           -- requested station
    AND qflag IS NULL                                         -- keep only validated observations
    AND value IS NOT NULL                                     -- exclude null measurements
    AND EXTRACT(MONTH FROM date) = 12                         -- December …
    AND EXTRACT(DAY   FROM date) >= 17                        -- … 17‑31 (last 15 days)
  GROUP BY
    yr
)
ORDER BY
  year;