-- 1.  Select stations whose period of record began on/before 1‑Jan‑2000
--    and continued through at least 30‑Jun‑2019.
WITH eligible_stations AS (
  SELECT
    usaf   AS stn,
    wban,
    begin,
    `end`
  FROM
    `bigquery-public-data.noaa_gsod.stations`
  WHERE
    CAST(begin AS INT64) <= 20000101     -- started on or before 1‑Jan‑2000
    AND CAST(`end`  AS INT64) >= 20190630 -- still reporting by 30‑Jun‑2019
),

-- 2.  Count 2019 days having valid temperature, max and min values
--     (all non‑missing; GSOD missing sentinels are very large).
valid_day_counts AS (
  SELECT
    stn,
    wban,
    COUNT(*) AS valid_days_2019          -- number of valid‑temperature days
  FROM
    `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE
        temp <  9000                    -- exclude 9999.9 sentinel
    AND max  <  9000
    AND min  <  9000
  GROUP BY
    stn, wban
),

-- 3.  Keep eligible stations that reached ≥90 % of 365 possible days (≥329)
qualified_stations AS (
  SELECT
    v.stn,
    v.wban
  FROM
    valid_day_counts v
  JOIN
    eligible_stations e
  ON  v.stn  = e.stn
  AND v.wban = e.wban
  WHERE
    v.valid_days_2019 >= 329             -- 90 % of 365 days
)

-- 4.  Final answer: how many such stations?
SELECT
  COUNT(*) AS station_count
FROM
  qualified_stations;