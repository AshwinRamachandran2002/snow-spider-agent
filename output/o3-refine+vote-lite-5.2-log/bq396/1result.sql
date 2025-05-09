WITH weekend_accidents AS (
  SELECT
    state_name,
    -- classify each crash’s weather condition
    CASE
      WHEN atmospheric_conditions_1_name = 'Rain'
        OR atmospheric_conditions_2_name = 'Rain'            THEN 'Rain'
      WHEN atmospheric_conditions_1_name = 'Clear'
        AND (atmospheric_conditions_2_name IS NULL
             OR atmospheric_conditions_2_name = 'No Additional Atmospheric Conditions') 
                                                           THEN 'Clear'
      ELSE 'Other'
    END AS weather
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  -- keep only weekend crashes (1 = Sunday, 7 = Saturday in FARS coding)
  WHERE day_of_week IN (1,7)
)

SELECT
  state_name,
  COUNTIF(weather = 'Rain')  AS rainy_accidents,
  COUNTIF(weather = 'Clear') AS clear_accidents,
  ABS(COUNTIF(weather = 'Rain') - COUNTIF(weather = 'Clear')) AS difference
FROM weekend_accidents
WHERE weather IN ('Rain','Clear')          -- ignore records that are neither clear nor rainy
GROUP BY state_name
ORDER BY difference DESC
LIMIT 3;