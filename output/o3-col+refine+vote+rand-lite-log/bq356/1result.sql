-- stations that meet period-of-record requirement and whose 2019
-- valid-temperature coverage is at least 90 %
WITH eligible_stations AS (
  SELECT
    usaf,
    wban,
    PARSE_DATE('%Y%m%d', begin) AS begin_date,
    PARSE_DATE('%Y%m%d', `end`) AS end_date
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE PARSE_DATE('%Y%m%d', begin) <= DATE '2000-01-01'     -- began on/before 1-Jan-2000
    AND PARSE_DATE('%Y%m%d', `end`)  >= DATE '2019-06-30'     -- active through 30-Jun-2019
),
possible_days AS (          -- maximum days each station could report in 2019
  SELECT
    usaf,
    wban,
    DATE_DIFF(
      LEAST(DATE '2019-12-31', end_date),
      GREATEST(DATE '2019-01-01', begin_date),
      DAY
    ) + 1 AS possible_days_2019
  FROM eligible_stations
),
valid_days AS (             -- days with non-missing temp / max / min in 2019
  SELECT
    stn AS usaf,
    wban,
    COUNT(*) AS valid_days_2019
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE temp != 9999.9
    AND `max` != 9999.9
    AND `min` != 9999.9
  GROUP BY stn, wban
)
SELECT
  COUNT(*) AS stations_with_90pct_or_more_coverage_2019
FROM possible_days AS p
JOIN valid_days   AS v USING (usaf, wban)
WHERE v.valid_days_2019 >= 0.9 * p.possible_days_2019;