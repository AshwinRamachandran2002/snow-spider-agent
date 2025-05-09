WITH accident_details AS (
  SELECT
    -- 1. Unique crash identifier
    consecutive_number,
    
    -- 2. County
    county,
    
    -- 3. Type of intersection
    type_of_intersection,
    
    -- 4. Light condition
    light_condition,
    
    -- 5. Weather / atmospheric condition
    atmospheric_conditions_1,
    
    -- 6. Hour of crash
    hour_of_crash,
    
    -- 7. Functional roadway system
    functional_system,
    
    -- 8. Crash‑level related factor (alias “related_factors”)
    related_factors_crash_level_1 AS related_factors,
    
    -- 9. Delay to hospital  (hour_of_ems_arrival_at_hospital – hour_of_crash)
    CASE
      WHEN hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
      THEN hour_of_ems_arrival_at_hospital - hour_of_crash
      ELSE NULL
    END AS delay_to_hospital,
    
    -- 10. Delay to scene  (hour_of_arrival_at_scene – hour_of_crash)
    CASE
      WHEN hour_of_arrival_at_scene BETWEEN 0 AND 23
      THEN hour_of_arrival_at_scene - hour_of_crash
      ELSE NULL
    END AS delay_to_scene
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
)

SELECT *
FROM accident_details
ORDER BY consecutive_number;