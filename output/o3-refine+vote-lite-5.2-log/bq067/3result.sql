/*  Per‑accident labelled dataset for 2016 crashes  */
WITH person_stats AS (           -- how many persons / fatalities in each crash
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                              AS n_persons,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END)       AS n_fatalities
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
),
labeled_accidents AS (           -- keep crashes that involve >1 person
  SELECT
    state_number,
    consecutive_number,
    CASE WHEN n_fatalities > 1 THEN 1 ELSE 0 END AS label
  FROM person_stats
  WHERE n_persons > 1
),
first_vehicle_body AS (          -- body_type of the first in‑transport vehicle
  SELECT state_number, consecutive_number, body_type
  FROM (
    SELECT
      state_number,
      consecutive_number,
      body_type,
      ROW_NUMBER() OVER (PARTITION BY state_number, consecutive_number
                         ORDER BY vehicle_number) AS rn
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  )
  WHERE rn = 1
),
speed_diffs AS (                 -- average |travel_speed − speed_limit|
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed_int - speed_limit_int)) AS avg_speed_diff
  FROM (
    SELECT
      state_number,
      consecutive_number,
      SAFE_CAST(travel_speed AS INT64) AS travel_speed_int,
      SAFE_CAST(speed_limit  AS INT64) AS speed_limit_int
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  )
  WHERE travel_speed_int NOT IN (997, 998, 999)   -- coded / unknown values
    AND speed_limit_int  NOT IN (98, 99)          -- coded / unknown limits
    AND travel_speed_int <= 151
    AND speed_limit_int  <=  80
  GROUP BY state_number, consecutive_number
),
speed_categories AS (            -- bucket the average difference (0‑4)
  SELECT
    state_number,
    consecutive_number,
    CASE
      WHEN avg_speed_diff IS NULL     THEN NULL
      WHEN avg_speed_diff < 20        THEN 0
      WHEN avg_speed_diff < 40        THEN 1
      WHEN avg_speed_diff < 60        THEN 2
      WHEN avg_speed_diff < 80        THEN 3
      ELSE                                 4
    END AS avg_speed_diff_category
  FROM speed_diffs
),
accident_features AS (           -- predictors from accident_2016
  SELECT
    state_number,
    consecutive_number,
    number_of_drunk_drivers,
    day_of_week,
    hour_of_crash,
    CASE WHEN SAFE_CAST(work_zone AS INT64) = 0 THEN 0 ELSE 1 END
      AS work_zone_indicator
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
)
SELECT
  la.state_number,
  la.consecutive_number,
  fv.body_type,
  af.number_of_drunk_drivers,
  af.day_of_week,
  af.hour_of_crash,
  af.work_zone_indicator,
  sc.avg_speed_diff_category,
  la.label                                  -- 1 = >1 fatality, 0 = otherwise
FROM labeled_accidents      AS la
LEFT JOIN accident_features AS af USING (state_number, consecutive_number)
LEFT JOIN first_vehicle_body AS fv USING (state_number, consecutive_number)
LEFT JOIN speed_categories   AS sc USING (state_number, consecutive_number);