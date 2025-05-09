/* ---------------------------------------------------------------------------
   Average daily Citi Bike trip counts in 2016, comparing
   • “rainy” days  (total precipitation  >  5 mm → PRCP value > 50 tenth‑mm)
   • “non‑rainy” days (≤ 5 mm)
   Precipitation is taken from the single GHCN station located ≤ 50 km from
   (40.7128 N, ‑74.0060 W) that provides the most 2016 PRCP observations
   with no quality flags.
--------------------------------------------------------------------------- */

WITH
/* --------------------------------------------------------------------- */
/* 1.  Stations ≤ 50 km from NYC that have PRCP records covering 2016     */
candidate_stations AS (
  SELECT
    s.id,
    s.latitude,
    s.longitude
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations`  AS s
  JOIN `bigquery-public-data.ghcn_d.ghcnd_inventory` AS i
    ON s.id = i.id
  WHERE i.element   = 'PRCP'
    AND i.firstyear <= 2016
    AND i.lastyear  >= 2016
    AND ST_DISTANCE(
          ST_GEOGPOINT(s.longitude, s.latitude),
          ST_GEOGPOINT(-74.0060, 40.7128)
        ) <= 50000        -- 50 km (metres)
),

/* --------------------------------------------------------------------- */
/* 2.  Daily PRCP for all candidate stations during 2016                 */
station_daily AS (
  SELECT
    id,
    DATE(`date`)                        AS obs_date,
    SUM(value)                          AS prcp_tenth_mm          -- 0.1 mm units
  FROM `bigquery-public-data.ghcn_d.ghcnd_*`
  WHERE REGEXP_CONTAINS(_TABLE_SUFFIX, r'^\d{4}$')                -- yearly tables
    AND `date` BETWEEN '2016-01-01' AND '2016-12-31'
    AND element   = 'PRCP'
    AND qflag     IS NULL                                         -- good quality
    AND value     >= 0                                             -- ignore −9999
    AND id IN (SELECT id FROM candidate_stations)
  GROUP BY id, obs_date
),

/* --------------------------------------------------------------------- */
/* 3.  Pick the single station with the most 2016 observation days       */
best_station AS (
  SELECT id
  FROM   station_daily
  GROUP  BY id
  ORDER  BY COUNT(*) DESC
  LIMIT  1
),

/* --------------------------------------------------------------------- */
/* 4.  Daily precipitation from that best station                        */
daily_prcp AS (
  SELECT
    obs_date,
    prcp_tenth_mm
  FROM station_daily
  WHERE id = (SELECT id FROM best_station)
),

/* --------------------------------------------------------------------- */
/* 5.  Classify each day as rainy / non‑rainy                            */
rain_flags AS (
  SELECT
    obs_date,
    CASE WHEN prcp_tenth_mm > 50 THEN 'rainy' ELSE 'non_rainy' END AS rain_flag
  FROM daily_prcp
),

/* --------------------------------------------------------------------- */
/* 6.  Citi Bike trip counts per day in 2016                             */
daily_trips AS (
  SELECT
    DATE(starttime) AS trip_date,
    COUNT(*)        AS trip_cnt
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE starttime >= '2016-01-01'
    AND starttime  < '2017-01-01'
  GROUP BY trip_date
)

/* --------------------------------------------------------------------- */
/* 7.  Join rain flags with trip counts & compute averages               */
SELECT
  r.rain_flag              AS day_type,
  AVG(d.trip_cnt)          AS avg_daily_trips
FROM rain_flags  AS r
JOIN daily_trips AS d
  ON d.trip_date = r.obs_date
GROUP BY day_type
ORDER BY day_type;