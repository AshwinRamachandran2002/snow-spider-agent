/*  Average daily Citi Bike trips in 2016 on
    1) “rainy” days  (total daily PRCP > 5 mm)
    2) “non‑rainy” days (≤ 5 mm)

    Steps
    1. Pick the single GHCN station within 50 km of
       (40.7128 N, –74.0060 E) that is closest to that point
       and has un‑flagged 2016 PRCP data.
    2. Build a daily precipitation table for that station.
    3. Build a daily Citi Bike trip‐count table for 2016.
    4. Join the two tables and compare average trips.
*/
WITH nearest_station AS (
  SELECT id
  FROM (
    SELECT
      s.id,
      -- distance in kilometres from NYC reference point
      ST_DISTANCE(
        ST_GEOGPOINT(s.longitude, s.latitude),
        ST_GEOGPOINT(-74.0060, 40.7128)
      ) / 1000 AS dist_km
    FROM `bigquery-public-data.ghcn_d.ghcnd_stations` AS s
    JOIN `bigquery-public-data.ghcn_d.ghcnd_2016`           AS p
      ON  p.id      = s.id
      AND p.element = 'PRCP'
      AND (p.qflag IS NULL OR p.qflag = '')
    WHERE ST_DISTANCE(
            ST_GEOGPOINT(s.longitude, s.latitude),
            ST_GEOGPOINT(-74.0060, 40.7128)
          ) <= 50000        -- 50 km in metres
    GROUP BY s.id, dist_km
  )
  ORDER BY dist_km
  LIMIT 1
),
/* Daily precipitation (millimetres) and rain flag            */
precip_daily AS (
  SELECT
    date                       AS day,
    SUM(value) / 10.0          AS prcp_mm,           -- 1/10 mm → mm
    SUM(value) / 10.0 > 5.0    AS is_rainy
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE element = 'PRCP'
    AND (qflag IS NULL OR qflag = '')
    AND id IN (SELECT id FROM nearest_station)
  GROUP BY day
),
/* Daily Citi Bike trip counts (all trips that started in 2016) */
trips_daily AS (
  SELECT
    DATE(starttime) AS day,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE DATE(starttime) BETWEEN '2016-01-01' AND '2016-12-31'
  GROUP BY day
),
/* Combine trips with weather                                  */
combined AS (
  SELECT
    t.day,
    t.trips,
    p.is_rainy
  FROM trips_daily   AS t
  JOIN precip_daily  AS p
    ON t.day = p.day           -- only days with precipitation data
)
SELECT
  CASE WHEN is_rainy
       THEN 'Rainy  (>5 mm)'
       ELSE 'Non‑rainy (≤5 mm)'
  END                          AS day_type,
  AVG(trips)                   AS avg_trips_per_day
FROM combined
GROUP BY day_type
ORDER BY day_type;