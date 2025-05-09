WITH per_year_top_events AS (
  SELECT
    `state`,
    `magnitude`
  FROM (
    SELECT
      `state`,
      `magnitude`,
      ROW_NUMBER() OVER (PARTITION BY _TABLE_SUFFIX ORDER BY `magnitude` DESC) AS rn
    FROM
      `bigquery-public-data.noaa_historic_severe_storms.storms_*`
    WHERE
      _TABLE_SUFFIX BETWEEN '1980' AND '1995'
      AND `magnitude` IS NOT NULL
      AND `state` IS NOT NULL
  )
  WHERE
    rn <= 1000
)
SELECT
  `state`,
  COUNT(*) AS Number_of_Storm_Events
FROM
  per_year_top_events
GROUP BY
  `state`
ORDER BY
  Number_of_Storm_Events DESC
LIMIT
  5;