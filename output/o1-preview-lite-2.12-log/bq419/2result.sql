SELECT state, COUNT(*) AS Number_of_Storm_Events
FROM (
  SELECT state
  FROM (
    SELECT state,
           ROW_NUMBER() OVER (PARTITION BY _TABLE_SUFFIX ORDER BY COALESCE(damage_property, 0) DESC) AS rn
    FROM `bigquery-public-data.noaa_historic_severe_storms.storms_*`
    WHERE _TABLE_SUFFIX BETWEEN '1980' AND '1995' AND state IS NOT NULL
  )
  WHERE rn <= 1000
)
GROUP BY state
ORDER BY Number_of_Storm_Events DESC
LIMIT 5;