WITH
-- 1)  All NYC ZIP polygons
zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_name = 'New York'
),

-- 2)  The 24 hourly instants for 01-Jan-2015 (UTC)
hours AS (
  SELECT hr
  FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY('2015-01-01 00:00:00+00',
                                 '2015-01-01 23:00:00+00',
                                 INTERVAL 1 HOUR)
       ) AS hr
),

-- 3)  Trip counts per (ZIP, hour) **over the 21-day history** ending 01-Jan-2015
hist_trips AS (
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime, HOUR) AS hr,
    COUNT(*) AS trips
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` AS t
  JOIN zips AS z
    ON ST_CONTAINS(z.zip_code_geom,
                   ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude))
  WHERE DATE(t.pickup_datetime) BETWEEN '2014-12-11' AND '2015-01-01'
    AND t.pickup_longitude IS NOT NULL AND t.pickup_latitude IS NOT NULL
    AND t.pickup_longitude != 0        AND t.pickup_latitude  != 0
  GROUP BY z.zip_code, hr
),

-- 4)  All (ZIP, hour) combinations for 01-Jan-2015
grid AS (
  SELECT
    z.zip_code,
    h.hr
  FROM zips  AS z
  CROSS JOIN hours AS h
),

-- 5)  Attach trip counts (0 when none)
joined AS (
  SELECT
    g.zip_code,
    g.hr,
    IFNULL(h.trips, 0) AS trips
  FROM grid AS g
  LEFT JOIN hist_trips AS h
    ON h.zip_code = g.zip_code
   AND h.hr       = g.hr
),

-- 6)  Add lags & rolling statistics
final AS (
  SELECT
    zip_code,
    hr,
    trips,
    LAG(trips,   1) OVER (PARTITION BY zip_code ORDER BY hr) AS trips_1h_ago,
    LAG(trips,  24) OVER (PARTITION BY zip_code ORDER BY hr) AS trips_24h_ago,
    LAG(trips, 168) OVER (PARTITION BY zip_code ORDER BY hr) AS trips_168h_ago,
    LAG(trips, 336) OVER (PARTITION BY zip_code ORDER BY hr) AS trips_336h_ago,
    AVG   (trips)  OVER (PARTITION BY zip_code ORDER BY hr
                         ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS avg_14day,
    STDDEV(trips)  OVER (PARTITION BY zip_code ORDER BY hr
                         ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS std_14day,
    AVG   (trips)  OVER (PARTITION BY zip_code ORDER BY hr
                         ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS avg_21day,
    STDDEV(trips)  OVER (PARTITION BY zip_code ORDER BY hr
                         ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS std_21day
  FROM joined
)

-- 7)  Return the five (ZIP, hour) groups with the most trips
SELECT *
FROM final
ORDER BY trips DESC
LIMIT 5;