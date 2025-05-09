WITH injuries AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(*) AS injuries                      -- non‑fatal injuries only
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE injury_severity IN (2,3,4,5)          -- exclude fatal (1) and no‑injury (0)
  GROUP BY state_number, consecutive_number
)

SELECT
  FORMAT_DATE('%Y-%m-%d', DATE(a.timestamp_of_crash))          AS accident_date,
  FORMAT('%.4f,%.4f', a.latitude, a.longitude)                 AS travel_coordinates,
  a.number_of_fatalities                                       AS fatalities,
  IFNULL(i.injuries, 0)                                        AS injuries,
  a.number_of_fatalities + IFNULL(i.injuries, 0)               AS total_casualties,
  CONCAT(a.state_name, ', County ', CAST(a.county AS STRING))  AS location_description
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
LEFT JOIN injuries AS i
USING (state_number, consecutive_number)
WHERE a.timestamp_of_crash IS NOT NULL
  AND a.latitude  NOT IN (77.7777, 88.8888, 99.9999)           -- filter out “not reported / unknown”
  AND a.longitude NOT IN (777.7777, 888.8888, 999.9999);