-- Count NOAA GSOD stations that met the ≥90 % valid‑temperature‑day criterion in 2019
WITH valid_2019_days AS (          -- 2019 daily records with non‑missing temp, max, min
  SELECT
    stn  AS usaf ,                 -- station identifier matches `stations.usaf`
    wban ,
    COUNT(*) AS n_valid_days
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE temp < 9999
    AND max  < 9999
    AND min  < 9999
  GROUP BY stn, wban
),
eligible_por AS (                  -- stations whose period of record fits the task limits
  SELECT DISTINCT
    usaf,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE SAFE_CAST(`begin` AS INT64) <= 20000101   -- began on or before 1 Jan 2000
    AND SAFE_CAST(`end`   AS INT64) >= 20190630   -- continued through ≥30 Jun 2019
)

SELECT COUNT(*) AS station_count
FROM valid_2019_days v
JOIN eligible_por p USING (usaf, wban)
WHERE v.n_valid_days >= 0.90 * 365;              -- at least 329 days