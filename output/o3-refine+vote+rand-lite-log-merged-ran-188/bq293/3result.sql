-- Hour-by-hour NYC yellow-cab activity for 01-Jan-2015
-- with lags and moving statistics (top-5 zip/hour pairs)

WITH valid_trips AS (       -- keep only plausible coordinates & dates needed for lags
  SELECT
    pickup_datetime,
    pickup_longitude,
    pickup_latitude
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`
  WHERE pickup_datetime BETWEEN '2014-12-11' AND '2015-01-02'
    AND pickup_latitude  BETWEEN -90  AND  90
    AND pickup_longitude BETWEEN -180 AND 180
),
mapped AS (                 -- spatially attach NY zip codes
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime, HOUR) AS pickup_hour
  FROM valid_trips t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` z
    ON ST_CONTAINS(
         z.zip_code_geom,
         ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude)
       )
  WHERE z.state_code = 'NY'                 -- limit to New-York State zips
),
agg AS (                   -- raw hourly counts
  SELECT
    zip_code,
    pickup_hour,
    COUNT(*) AS trips
  FROM mapped
  GROUP BY zip_code, pickup_hour
),
distinct_zips AS (         -- every zip that ever had a trip in the period
  SELECT DISTINCT zip_code FROM agg
),
all_hours AS (             -- 22-day horizon (21-day window + 01-Jan)
  SELECT hr
  FROM UNNEST(
         GENERATE_TIMESTAMP_ARRAY('2014-12-11 00:00:00',
                                  '2015-01-01 23:00:00',
                                  INTERVAL 1 HOUR)
       ) AS hr
),
zip_hour_grid AS (         -- ensure zip-hour completeness (fill missing hours)
  SELECT z.zip_code, h.hr AS pickup_hour
  FROM distinct_zips z
  CROSS JOIN all_hours  h
),
filled AS (                -- zeros where no trips occurred
  SELECT
    g.zip_code,
    g.pickup_hour,
    COALESCE(a.trips,0) AS trips
  FROM zip_hour_grid g
  LEFT JOIN agg a
    ON  a.zip_code     = g.zip_code
    AND a.pickup_hour  = g.pickup_hour
),
metrics AS (               -- lags & rolling statistics
  SELECT
    *,
    LAG(trips, 1)   OVER (PARTITION BY zip_code ORDER BY pickup_hour) AS trips_1h_ago,
    LAG(trips,24)   OVER (PARTITION BY zip_code ORDER BY pickup_hour) AS trips_24h_ago,
    LAG(trips,168)  OVER (PARTITION BY zip_code ORDER BY pickup_hour) AS trips_168h_ago,
    LAG(trips,336)  OVER (PARTITION BY zip_code ORDER BY pickup_hour) AS trips_336h_ago,
    AVG(trips)      OVER (PARTITION BY zip_code ORDER BY pickup_hour
                          ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING)  AS avg_14day,
    STDDEV_POP(trips) OVER (PARTITION BY zip_code ORDER BY pickup_hour
                             ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS std_14day,
    AVG(trips)      OVER (PARTITION BY zip_code ORDER BY pickup_hour
                          ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)  AS avg_21day,
    STDDEV_POP(trips) OVER (PARTITION BY zip_code ORDER BY pickup_hour
                             ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS std_21day
  FROM filled
)
SELECT
  zip_code,
  pickup_hour,
  trips,
  trips_1h_ago,
  trips_24h_ago,
  trips_168h_ago,
  trips_336h_ago,
  avg_14day,
  std_14day,
  avg_21day,
  std_21day
FROM metrics
WHERE pickup_hour BETWEEN '2015-01-01 00:00:00' AND '2015-01-01 23:00:00'
ORDER BY trips DESC
LIMIT 5;