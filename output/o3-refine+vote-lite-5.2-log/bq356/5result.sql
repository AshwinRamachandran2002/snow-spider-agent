-- stations that started on/before 2000‑01‑01 and ran at least through 2019‑06‑30
WITH eligible_stations AS (
  SELECT
    usaf,
    wban,
    PARSE_DATE('%Y%m%d', IFNULL(begin, '19000101'))     AS begin_date,
    PARSE_DATE('%Y%m%d', IFNULL(`end`,  '29991231'))    AS end_date
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE PARSE_DATE('%Y%m%d', IFNULL(begin, '19000101')) <= DATE '2000-01-01'
    AND PARSE_DATE('%Y%m%d', IFNULL(`end`,  '29991231')) >= DATE '2019-06-30'
),

-- daily 2019 observations with all three temperatures present (not 9999.9 or NULL)
daily_2019 AS (
  SELECT
    stn   AS usaf,
    wban,
    DATE(CONCAT(year,'-',mo,'-',da)) AS obs_date
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE temp <> 9999.9  AND max <> 9999.9  AND min <> 9999.9
),

-- count valid‑temperature days per station in 2019
counts AS (
  SELECT
    s.usaf,
    s.wban,
    COUNT(d.obs_date)                             AS valid_days,
    -- maximum possible days in 2019 for this station
    DATE_DIFF(
      LEAST(s.end_date, DATE '2019-12-31'),
      DATE '2019-01-01', DAY
    ) + 1                                         AS possible_days
  FROM eligible_stations s
  LEFT JOIN daily_2019 d
    ON s.usaf = d.usaf
   AND s.wban = d.wban
   AND d.obs_date BETWEEN DATE '2019-01-01' AND DATE '2019-12-31'
  GROUP BY s.usaf, s.wban, possible_days
)

-- number of stations reaching ≥90 % of their possible days
SELECT COUNT(*) AS stations_reaching_90pct
FROM counts
WHERE valid_days >= 0.9 * possible_days;