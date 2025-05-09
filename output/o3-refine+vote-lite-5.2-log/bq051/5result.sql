-- Average CitiBike trips on rainy vs. non–rainy days in 2016
WITH
/* 1.  Stations within 50 km of Times Sq. (40.7128 N,‑74.0060 E) */
candidate_stations AS (
  SELECT
    id,
    latitude,
    longitude,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(-74.0060, 40.7128)        -- NYC reference point
    ) AS distance_m
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
  WHERE ST_DISTANCE(
          ST_GEOGPOINT(longitude, latitude),
          ST_GEOGPOINT(-74.0060, 40.7128)
        ) <= 50000                           -- 50‑km radius
),

/* 2.  Keep only stations that actually reported un‑flagged PRCP in 2016,
       then pick the single nearest one                                            */
nearest_station AS (
  SELECT
    cs.id
  FROM candidate_stations  AS cs
  JOIN `bigquery-public-data.ghcn_d.ghcnd_2016` AS d
    ON d.id = cs.id
   AND d.element = 'PRCP'
   AND d.qflag  IS NULL                      -- quality flag
  GROUP BY cs.id, cs.distance_m
  ORDER BY MIN(cs.distance_m)                -- nearest first
  LIMIT 1
),

/* 3.  Daily precipitation (mm) for that station */
precip_2016 AS (
  SELECT
    date,
    SUM(value) / 10.0 AS prcp_mm             -- raw value is 0.1 mm units
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id = (SELECT id FROM nearest_station)
    AND element = 'PRCP'
    AND qflag IS NULL
  GROUP BY date
),

/* 4.  Daily CitiBike trip counts in 2016 */
trips_2016 AS (
  SELECT
    DATE(starttime) AS date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY date
)

/* 5.  Combine and compute averages */
SELECT
  CASE
      WHEN COALESCE(p.prcp_mm,0) > 5 THEN 'Rainy'
      ELSE 'Non‑rainy'
  END                           AS day_type,
  AVG(t.trips)                  AS avg_daily_trips
FROM trips_2016 t
LEFT JOIN precip_2016 p
  USING (date)
GROUP BY day_type;