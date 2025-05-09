WITH year_status_pairs AS (
  -- Every (year, status) combination we must report
  SELECT * FROM UNNEST([
    STRUCT(2013 AS year, 'active' AS station_status),
    STRUCT(2013 AS year, 'closed' AS station_status),
    STRUCT(2014 AS year, 'active' AS station_status),
    STRUCT(2014 AS year, 'closed' AS station_status)
  ])
),

station_counts AS (
  SELECT
    EXTRACT(YEAR FROM `modified_date`)          AS year,
    LOWER(`status`)                             AS station_status,
    COUNT(DISTINCT `station_id`)                AS num_distinct_stations
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE
    LOWER(`status`) IN ('active', 'closed')
  GROUP BY
    year, station_status
)

SELECT
  ysp.year,
  ysp.station_status,
  COALESCE(sc.num_distinct_stations, 0) AS num_distinct_stations
FROM
  year_status_pairs AS ysp
LEFT JOIN
  station_counts AS sc
USING (year, station_status)
ORDER BY
  year,
  station_status;