/* -------------------------------------------------------------
   Average Citi Bike trips on rainy vs. non‑rainy days (2016)
   – rainy  = daily precipitation > 5 mm
   – weather from the closest GHCN station (≤ 50 km of NYC)   */
WITH
-- NYC reference point
nyc AS (
  SELECT ST_GEOGPOINT(-74.0060, 40.7128) AS geom
),

/* 1.  Nearest GHCN station to NYC (within 50 km)  */
nearest_station AS (
  SELECT *
  FROM (
    SELECT
      id,
      latitude,
      longitude,
      ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),
        (SELECT geom FROM nyc)
      ) AS dist_m
    FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
    WHERE latitude IS NOT NULL
      AND longitude IS NOT NULL
  )
  WHERE dist_m <= 50000          -- 50 km
  ORDER BY dist_m
  LIMIT 1
),

/* 2.  Daily precipitation for that station in 2016 (mm)       */
prcp AS (
  SELECT
    `date`                          AS day,
    SUM(value) / 10.0               AS precip_mm         -- tenths‑of‑mm → mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE element = 'PRCP'
    AND id = (SELECT id FROM nearest_station)
    AND mflag IS NULL               -- valid measurement
    AND qflag IS NULL               -- passes QC
  GROUP BY day
),

/* 3.  Citi Bike trips per calendar day in 2016                */
daily_trips AS (
  SELECT
    DATE(starttime) AS day,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE starttime >= '2016-01-01'
    AND starttime <  '2017-01-01'
  GROUP BY day
)

/* 4.  Compare average trips on rainy (>5 mm) vs. non‑rainy days*/
SELECT
  CASE WHEN IFNULL(p.precip_mm, 0) > 5
       THEN 'rainy' ELSE 'non_rainy' END AS day_type,
  AVG(d.trips) AS avg_daily_trips
FROM daily_trips d
LEFT JOIN prcp p
  ON d.day = p.day
GROUP BY day_type
ORDER BY day_type;