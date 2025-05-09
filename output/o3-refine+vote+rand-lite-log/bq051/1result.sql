-- Average 2016 Citi Bike trips on rainy (>5 mm) vs. non‑rainy days
WITH
-- NYC reference point
nyc AS (
  SELECT ST_GEOGPOINT(-74.0060, 40.7128) AS geo
),

-- GHCN stations within 50 km of NYC
nearby_stations AS (
  SELECT
    s.id,
    ST_DISTANCE(ST_GEOGPOINT(s.longitude, s.latitude), n.geo) AS dist_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` AS s
  CROSS JOIN nyc AS n
  WHERE s.latitude IS NOT NULL
    AND s.longitude IS NOT NULL
    AND ST_DISTANCE(ST_GEOGPOINT(s.longitude, s.latitude), n.geo) <= 50000
),

-- Pick the single nearest station that has valid 2016 precipitation data
chosen_station AS (
  SELECT id
  FROM (
    SELECT
      ns.id,
      ns.dist_m,
      ROW_NUMBER() OVER (ORDER BY ns.dist_m) AS rn
    FROM nearby_stations AS ns
    JOIN `bigquery-public-data.ghcn_d.ghcnd_2016` AS d
      ON d.id = ns.id
     AND d.element = 'PRCP'
     AND d.qflag IS NULL
     AND d.mflag IS NULL
    GROUP BY ns.id, ns.dist_m
  )
  WHERE rn = 1
),

-- Daily precipitation (mm) from that station
daily_precip AS (
  SELECT
    date,
    value / 10.0 AS precip_mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id IN (SELECT id FROM chosen_station)
    AND element = 'PRCP'
    AND qflag IS NULL
    AND mflag IS NULL
),

-- Daily Citi Bike trip counts in 2016
daily_trips AS (
  SELECT
    DATE(starttime) AS date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE starttime >= '2016-01-01'
    AND starttime <  '2017-01-01'
  GROUP BY date
),

-- Combine trips with weather and tag days as Rainy / Non‑Rainy
combined AS (
  SELECT
    t.date,
    t.trips,
    CASE WHEN p.precip_mm > 5 THEN 'Rainy' ELSE 'Non‑Rainy' END AS day_type
  FROM daily_trips AS t
  JOIN daily_precip AS p
    ON p.date = t.date
)

-- Final comparison
SELECT
  day_type,
  ROUND(AVG(trips), 2) AS avg_daily_trips
FROM combined
GROUP BY day_type
ORDER BY day_type DESC;