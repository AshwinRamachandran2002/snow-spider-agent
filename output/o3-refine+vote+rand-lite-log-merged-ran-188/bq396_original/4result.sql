WITH weekend_weather AS (
  /*  Weekend (Saturday=7, Sunday=1) crashes only,
      classify prevailing weather as Rain or Clear            */
  SELECT
    state_name,
    CASE
      WHEN LOWER(COALESCE(atmospheric_conditions_1_name ,'')) LIKE '%rain%' 
        OR LOWER(COALESCE(atmospheric_conditions_2_name ,'')) LIKE '%rain%' 
        OR LOWER(COALESCE(atmospheric_conditions_name   ,'')) LIKE '%rain%' 
        THEN 'Rain'
      WHEN LOWER(COALESCE(atmospheric_conditions_1_name ,'')) LIKE '%clear%' 
        OR LOWER(COALESCE(atmospheric_conditions_2_name ,'')) LIKE '%clear%' 
        OR LOWER(COALESCE(atmospheric_conditions_name   ,'')) LIKE '%clear%' 
        THEN 'Clear'
      ELSE 'Other'
    END AS weather
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
  WHERE day_of_week IN (1,7)         -- 1 = Sunday, 7 = Saturday
), weather_filtered AS (
  /* retain only Rain and Clear rows */
  SELECT state_name, weather
  FROM weekend_weather
  WHERE weather IN ('Rain','Clear')
), weather_counts AS (
  /* count crashes per state & weather */
  SELECT
    state_name,
    COUNTIF(weather = 'Rain')  AS rain_accidents,
    COUNTIF(weather = 'Clear') AS clear_accidents
  FROM weather_filtered
  GROUP BY state_name
), differences AS (
  SELECT
    state_name,
    rain_accidents,
    clear_accidents,
    ABS(rain_accidents - clear_accidents) AS difference
  FROM weather_counts
)
SELECT
  state_name,
  difference
FROM differences
ORDER BY difference DESC, state_name
LIMIT 3;