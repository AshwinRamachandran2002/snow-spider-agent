/*  Average Citi Bike trips on rainy vs. non-rainy days in 2016                */
/*  1. Pick the closest GHCN station (<50 km from NYC) that has PRCP for 2016  */
/*  2. Build daily precipitation (mm) from un-flagged PRCP records             */
/*  3. Count Citi Bike trips per day in 2016                                   */
/*  4. Classify each day (rainy > 5 mm) and compute the two required averages  */

WITH
-- Reference point : City Hall, New-York-City
ref AS (
  SELECT 40.7128 AS lat , -74.0060 AS lon
),

-- All stations within 50 km
near_stations AS (
  SELECT
    st.id ,
    st.name ,
    ST_DISTANCE( ST_GEOGPOINT(st.longitude , st.latitude),
                 ST_GEOGPOINT(ref.lon , ref.lat) ) /1000 AS distance_km
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` st , ref
  WHERE ST_DISTANCE( ST_GEOGPOINT(st.longitude , st.latitude),
                     ST_GEOGPOINT(ref.lon , ref.lat) ) < 50000       -- 50 km
),

-- Keep only those with PRCP data spanning 2016
stations_with_prcp AS (
  SELECT ns.*
  FROM near_stations  ns
  JOIN `bigquery-public-data.ghcn_d.ghcnd_inventory` inv
    ON ns.id = inv.id
  WHERE inv.element = 'PRCP'
    AND 2016 BETWEEN inv.firstyear AND inv.lastyear
),

-- Choose the single closest qualifying station
chosen_station AS (
  SELECT id
  FROM stations_with_prcp
  ORDER BY distance_km
  LIMIT 1
),

-- Daily precipitation in millimetres (sum of tenths-mm → mm)
precip AS (
  SELECT
    date                         AS trip_date,
    SUM(value)/10.0              AS precip_mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE element = 'PRCP'
    AND qflag IS NULL            -- keep only good measurements
    AND id IN (SELECT id FROM chosen_station)
  GROUP BY date
),

-- Daily Citi Bike trip counts for 2016
rides AS (
  SELECT
    DATE(starttime) AS trip_date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY trip_date
),

-- Average trips per day type (rainy > 5 mm)
avg_by_type AS (
  SELECT
    CASE WHEN COALESCE(p.precip_mm,0) > 5 THEN 'Rainy' ELSE 'Non-Rainy' END AS day_type,
    AVG(r.trips) AS avg_trips
  FROM rides r
  LEFT JOIN precip p USING (trip_date)
  GROUP BY day_type
)

SELECT
  MAX(CASE WHEN day_type = 'Rainy'     THEN avg_trips END) AS avg_trips_rainy_days,
  MAX(CASE WHEN day_type = 'Non-Rainy' THEN avg_trips END) AS avg_trips_non_rainy_days
FROM avg_by_type;