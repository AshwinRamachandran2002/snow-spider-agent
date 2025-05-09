WITH
-- 1. GHCN stations within 50 km of New‑York‑City’s coordinates
candidate_stations AS (
  SELECT
    id,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(-74.0060, 40.7128)
    ) AS dist_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
  WHERE ST_DISTANCE(
          ST_GEOGPOINT(longitude, latitude),
          ST_GEOGPOINT(-74.0060, 40.7128)
        ) < 50000
),

-- 2. Pick the nearest station that has valid 2016 PRCP data
chosen_station AS (
  SELECT id
  FROM candidate_stations c
  WHERE EXISTS (
        SELECT 1
        FROM `bigquery-public-data.ghcn_d.ghcnd_2016` d
        WHERE d.id = c.id
          AND d.element = 'PRCP'
          AND d.qflag  IS NULL
          AND d.date BETWEEN '2016-01-01' AND '2016-12-31'
        LIMIT 1
      )
  ORDER BY dist_m
  LIMIT 1
),

-- 3. Daily precipitation (millimetres) at that station for 2016
daily_precip AS (
  SELECT
    date,
    SUM(value) / 10.0 AS prcp_mm   -- raw value is tenths of mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016` d
  JOIN chosen_station s
    ON d.id = s.id
  WHERE d.element = 'PRCP'
    AND d.qflag  IS NULL
    AND d.date BETWEEN '2016-01-01' AND '2016-12-31'
  GROUP BY date
),

-- 4. Daily CitiBike trip counts for 2016
daily_trips AS (
  SELECT
    DATE(starttime) AS trip_day,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE DATE(starttime) BETWEEN '2016-01-01' AND '2016-12-31'
  GROUP BY trip_day
),

-- 5. Combine trips with precipitation (days with no precip record → 0 mm)
combined AS (
  SELECT
    t.trip_day,
    t.trips,
    IFNULL(p.prcp_mm, 0) AS prcp_mm
  FROM daily_trips t
  LEFT JOIN daily_precip p
    ON t.trip_day = p.date
)

-- 6. Final averages by rain category (≥5 mm considered rainy)
SELECT
  CASE WHEN prcp_mm > 5 THEN 'rainy' ELSE 'non_rainy' END
      AS rain_category,
  ROUND(AVG(trips), 4) AS average_daily_citibike_trips_2016
FROM combined
GROUP BY rain_category
ORDER BY rain_category;