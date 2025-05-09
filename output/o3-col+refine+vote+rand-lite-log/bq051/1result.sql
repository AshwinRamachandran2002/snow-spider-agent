/*  Average Citi Bike trips on rainy vs non-rainy days (2016)
    using the closest GHCN station ≤ 50 km from NYC that has
    quality-controlled precipitation data for 2016              */

WITH prcp_2016 AS (                -- 2016 precipitation (1/10 mm)
  SELECT id, date, value
  FROM `bigquery-public-data.ghcn_d.ghcnd_*`
  WHERE _TABLE_SUFFIX = '2016'       -- use 2016 partition
    AND element = 'PRCP'
    AND qflag   IS NULL
),

candidate_stations AS (            -- stations within 50 km of NYC
  SELECT
    s.id,
    ST_Distance(
        ST_GeogPoint(s.longitude, s.latitude),
        ST_GeogPoint(-74.0060, 40.7128)) AS distance_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` s
  WHERE ST_DWithin(
          ST_GeogPoint(s.longitude, s.latitude),
          ST_GeogPoint(-74.0060, 40.7128),
          50000)                      -- 50 000 m
),

nearest_station AS (               -- pick nearest with PRCP data
  SELECT c.id
  FROM candidate_stations c
  JOIN (SELECT DISTINCT id FROM prcp_2016) p USING (id)
  ORDER BY c.distance_m
  LIMIT 1
),

rain_flag AS (                     -- classify each day
  SELECT
    date AS trip_date,
    CASE WHEN value/10.0 > 5 THEN 'rainy' ELSE 'non_rainy' END AS rain_flag
  FROM prcp_2016
  WHERE id = (SELECT id FROM nearest_station)
),

citi_daily AS (                    -- daily Citi Bike trip totals
  SELECT
    DATE(starttime) AS trip_date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY trip_date
)

SELECT
  r.rain_flag               AS day_type,
  ROUND(AVG(c.trips), 1)    AS average_daily_trips_2016
FROM citi_daily c
JOIN rain_flag r
  USING (trip_date)
GROUP BY day_type
ORDER BY day_type;