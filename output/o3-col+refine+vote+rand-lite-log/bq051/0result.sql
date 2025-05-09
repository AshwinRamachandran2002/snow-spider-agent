/* Average daily Citi Bike trips in 2016 on rainy (> 5 mm) vs. non-rainy days
   – rain is taken from the closest (≤ 50 km) GHCN station to Downtown NYC
     that has the most valid, un-flagged 2016 precipitation measurements      */

WITH candidate_stations AS (         -- stations within 50 km of (40.7128 N, -74.0060 W)
  SELECT
    s.id,
    ST_DISTANCE(
        ST_GEOGPOINT(s.longitude, s.latitude),
        ST_GEOGPOINT(-74.0060, 40.7128)
    ) AS distance_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` s
  WHERE ST_DISTANCE(
          ST_GEOGPOINT(s.longitude, s.latitude),
          ST_GEOGPOINT(-74.0060, 40.7128)
        ) < 50000                               -- 50 km
),
station_prcp_counts AS (             -- how many good PRCP rows each station has in 2016
  SELECT
    id,
    COUNT(*) AS good_rows
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE element = 'PRCP'
    AND qflag  IS NULL               -- keep only un-flagged measurements
    AND id IN (SELECT id FROM candidate_stations)
  GROUP BY id
),
best_station AS (                    -- choose the best-covered (ties → nearest)
  SELECT c.id
  FROM   candidate_stations c
  JOIN   station_prcp_counts p USING(id)
  ORDER BY p.good_rows DESC, c.distance_m
  LIMIT 1
),

/*  Daily precipitation for that station, flagged rainy if >5 mm  */
daily_prcp AS (
  SELECT
    DATE(date)              AS prcp_date,
    value/10.0              AS prcp_mm,        -- convert 0.1 mm units → mm
    CASE WHEN value/10.0 > 5 THEN 'Rainy'
         ELSE 'Non-rainy' END AS rain_flag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE element = 'PRCP'
    AND qflag  IS NULL
    AND id = (SELECT id FROM best_station)
),

/*  Daily Citi Bike trip counts for 2016  */
daily_trips AS (
  SELECT
    DATE(starttime) AS trip_date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY trip_date
),

/*  Combine trips with rain flag, then average  */
stats AS (
  SELECT
    p.rain_flag,
    AVG(t.trips) AS avg_trips
  FROM daily_trips t
  JOIN daily_prcp p
    ON t.trip_date = p.prcp_date
  GROUP BY p.rain_flag
)

/*  Final comparison (and difference)  */
SELECT
  ROUND(MAX(CASE WHEN rain_flag = 'Rainy'     THEN avg_trips END),2) AS avg_trips_rainy,
  ROUND(MAX(CASE WHEN rain_flag = 'Non-rainy' THEN avg_trips END),2) AS avg_trips_non_rainy,
  ROUND(
        MAX(CASE WHEN rain_flag = 'Non-rainy' THEN avg_trips END) -
        MAX(CASE WHEN rain_flag = 'Rainy'     THEN avg_trips END)
       ,2) AS difference
FROM stats;