WITH persons AS (
  -- 1. keep only crashes with >1 person and count fatalities
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                          AS n_persons,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END)   AS n_fatal
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
  HAVING COUNT(DISTINCT person_number) > 1
),
labels AS (
  SELECT
    state_number,
    consecutive_number,
    CASE WHEN n_fatal > 1 THEN 1 ELSE 0 END AS label
  FROM persons
),
acc AS (
  -- 2. accident–level predictors
  SELECT
    state_number,
    consecutive_number,
    number_of_drunk_drivers,
    day_of_week,
    hour_of_crash,
    CASE
      WHEN CAST(work_zone AS STRING) <> '0' THEN 1
      ELSE 0
    END AS work_zone_flag
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
),
body AS (
  -- 3. take body_type of the first reported vehicle in the crash
  SELECT
    state_number,
    consecutive_number,
    ANY_VALUE(body_type) AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE vehicle_number = 1
  GROUP BY state_number, consecutive_number
),
spd AS (
  -- 4. average |travel_speed‑speed_limit| subject to validity rules
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit)) AS avg_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE
        travel_speed IS NOT NULL
    AND speed_limit  IS NOT NULL
    AND travel_speed BETWEEN 0 AND 151        -- discard code values 997‑999
    AND speed_limit  BETWEEN 0 AND 80         -- discard code values 98‑99
  GROUP BY state_number, consecutive_number
),
spd_cat AS (
  -- 5. bucket the average speed difference into 0–4
  SELECT
    state_number,
    consecutive_number,
    CASE
      WHEN avg_diff < 20 THEN 0
      WHEN avg_diff < 40 THEN 1
      WHEN avg_diff < 60 THEN 2
      WHEN avg_diff < 80 THEN 3
      ELSE 4
    END AS speed_diff_category
  FROM spd
)

-- 6. assemble the labelled, feature‑ready data set
SELECT
  l.state_number,
  l.consecutive_number,
  l.label,
  b.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  a.work_zone_flag,
  IFNULL(s.speed_diff_category, -1) AS speed_diff_category
FROM labels            AS l
JOIN acc               AS a USING (state_number, consecutive_number)
LEFT JOIN body         AS b USING (state_number, consecutive_number)
LEFT JOIN spd_cat      AS s USING (state_number, consecutive_number);