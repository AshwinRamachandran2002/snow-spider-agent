/* Build modelling dataset according to specifications */

WITH persons_per_crash AS (      -- persons and fatalities per crash
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                        AS n_persons,
    SUM(CASE WHEN injury_severity = 4 THEN 1 END)        AS n_fatalities
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
),

accident_base AS (               -- basic crash info + work‑zone flag
  SELECT
    state_number,
    consecutive_number,
    day_of_week,
    hour_of_crash,
    number_of_drunk_drivers,
    -- code 0 == “None”; every other code means some work‑zone condition
    CASE
      WHEN SAFE_CAST(work_zone AS INT64) = 0 THEN 0
      ELSE 1
    END AS work_zone_flag
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
),

vehicle_body AS (                -- choose a body_type per crash
  SELECT
    state_number,
    consecutive_number,
    MIN(body_type) AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY state_number, consecutive_number
),

speed_gap AS (                   -- average absolute speed difference
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit)) AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE
        SAFE_CAST(travel_speed AS INT64) BETWEEN 0 AND 151
    AND SAFE_CAST(speed_limit  AS INT64) BETWEEN 0 AND 80
  GROUP BY state_number, consecutive_number
),

speed_gap_binned AS (            -- bin into 0–4 levels (20‑mph bands)
  SELECT
    state_number,
    consecutive_number,
    CASE
      WHEN avg_speed_diff IS NULL THEN NULL
      WHEN avg_speed_diff < 20  THEN 0
      WHEN avg_speed_diff < 40  THEN 1
      WHEN avg_speed_diff < 60  THEN 2
      WHEN avg_speed_diff < 80  THEN 3
      ELSE                          4
    END AS speed_diff_level
  FROM speed_gap
)

/* ---------------- final labelled dataset ---------------- */
SELECT
  a.state_number,
  a.consecutive_number                      AS accident_id,
  vb.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  a.work_zone_flag,
  s.speed_diff_level,
  CASE WHEN p.n_fatalities > 1 THEN 1 ELSE 0 END AS label          -- target
FROM accident_base         AS a
JOIN persons_per_crash     AS p USING (state_number, consecutive_number)
JOIN vehicle_body          AS vb USING (state_number, consecutive_number)
LEFT JOIN speed_gap_binned AS s  USING (state_number, consecutive_number)
WHERE p.n_persons > 1;     -- only crashes with >1 distinct person