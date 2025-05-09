/* ----------------------------------------------------------------------
   Average Citi Bike trip counts on rain‑vs‑non‑rain days in 2016
   – use the NYC‑nearest (≤ 50 km) GHCN station that has the most
     valid precipitation (“PRCP”) records for 2016
------------------------------------------------------------------------*/
WITH
-- NYC reference point
origin AS (
  SELECT ST_GEOGPOINT(-74.0060 , 40.7128) AS nyc_geo
),

/* 1.  Stations within 50 km of NYC -------------------------------------*/
nearby_stations AS (
  SELECT
      s.id ,
      ST_DISTANCE(
          ST_GEOGPOINT(s.longitude , s.latitude) ,
          (SELECT nyc_geo FROM origin)
      ) / 1000 AS distance_km          -- convert to km
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` s
  WHERE s.longitude IS NOT NULL
    AND s.latitude  IS NOT NULL
),

/* 2.  Among nearby stations, keep the one with the most
       valid 2016 PRCP records (ties → closer station) ------------------*/
station_precip_counts AS (
  SELECT
      ns.id ,
      ns.distance_km ,
      COUNT(1) AS rec_cnt
  FROM nearby_stations   ns
  JOIN `bigquery-public-data.ghcn_d.ghcnd_2016` g
    ON g.id = ns.id
  WHERE ns.distance_km <= 50
    AND g.element = 'PRCP'
    AND g.qflag  IS NULL
  GROUP BY ns.id, ns.distance_km
),
chosen_station AS (
  SELECT id
  FROM station_precip_counts
  ORDER BY rec_cnt DESC, distance_km ASC
  LIMIT 1
),

/* 3.  Daily precipitation for that station (mm) ------------------------*/
precip_2016 AS (
  SELECT
      date ,
      value / 10.0 AS prcp_mm          -- convert 1/10 mm → mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id      = (SELECT id FROM chosen_station)
    AND element = 'PRCP'
    AND qflag   IS NULL
),

/* 4.  Flag each day as Rainy (>5 mm) or Non‑Rainy ----------------------*/
rain_flag AS (
  SELECT
      date ,
      CASE WHEN prcp_mm > 5 THEN 'Rainy' ELSE 'Non‑Rainy' END AS rain_type
  FROM precip_2016
),

/* 5.  Citi Bike trips per calendar day in 2016 -------------------------*/
citibike_daily AS (
  SELECT
      DATE(starttime) AS date ,
      COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY date
),

/* 6.  Join bike counts with rain classification -----------------------*/
bike_weather AS (
  SELECT
      b.date ,
      b.trips ,
      r.rain_type
  FROM citibike_daily b
  JOIN rain_flag     r
    ON b.date = r.date              -- keep dates present in both sets
)

/* 7.  Average trips by rain condition ---------------------------------*/
SELECT
    rain_type ,
    AVG(trips) AS avg_daily_trips
FROM bike_weather
GROUP BY rain_type
ORDER BY rain_type;