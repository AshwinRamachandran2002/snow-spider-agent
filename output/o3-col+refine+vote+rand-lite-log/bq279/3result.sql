-- Number of distinct bike-share stations marked “active” or “closed”
-- for the calendar years 2013 and 2014 (returns 0 when no rows exist)

WITH years AS (
  SELECT yr
  FROM UNNEST([2013, 2014]) AS yr
),
statuses AS (
  SELECT status
  FROM UNNEST(['active', 'closed']) AS status
),
all_combinations AS (
  SELECT y.yr, s.status
  FROM years AS y
  CROSS JOIN statuses AS s
),
counts AS (
  SELECT
    EXTRACT(YEAR FROM `modified_date`) AS yr,
    `status`,
    COUNT(DISTINCT `station_id`) AS num_stations
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE `status` IN ('active', 'closed')
    AND EXTRACT(YEAR FROM `modified_date`) IN (2013, 2014)
  GROUP BY yr, `status`
)
SELECT
  a.yr,
  a.status,
  COALESCE(c.num_stations, 0) AS num_stations
FROM all_combinations AS a
LEFT JOIN counts AS c
USING (yr, status)
ORDER BY a.yr, a.status;