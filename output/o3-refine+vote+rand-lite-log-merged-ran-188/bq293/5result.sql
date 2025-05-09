/*  Hour-by-hour yellow-taxi activity for 01-Jan-2015 with time-lag and
    moving-window metrics (top-5 ZIP/hour rows by trip count)            */
WITH
/* 1) Raw trips that fall inside NY-state ZIP polygons and have
       coordinates inside a crude NYC bounding box                      */
trips AS (
  SELECT
    z.zip_code,
    TIMESTAMP_TRUNC(t.pickup_datetime, HOUR) AS hr
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015` AS t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes`    AS z
    ON ST_CONTAINS(
         z.zip_code_geom,
         ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude)
       )
  WHERE z.state_code            = 'NY'
    AND t.pickup_longitude BETWEEN -75 AND -73   -- crude NYC bbox
    AND t.pickup_latitude  BETWEEN  40 AND  41
    /* history long enough for the 21-day window                     */
    AND DATE(t.pickup_datetime) BETWEEN '2014-12-11' AND '2015-01-01'
),

/* 2) Hourly trip counts actually observed                             */
agg AS (
  SELECT
    zip_code,
    hr,
    COUNT(*) AS trips
  FROM trips
  GROUP BY zip_code, hr
),

/* 3) Distinct ZIPs in the study window                                */
zips AS (
  SELECT DISTINCT zip_code FROM agg
),

/* 4) 21-day hour grid ending 01-Jan-2015                              */
hours AS (
  SELECT hr
  FROM UNNEST(
         GENERATE_TIMESTAMP_ARRAY('2014-12-11 00:00:00+00',
                                  '2015-01-01 23:00:00+00',
                                  INTERVAL 1 HOUR)
       ) AS hr
),

/* 5) ZIP × hour grid                                                  */
grid AS (
  SELECT z.zip_code, h.hr
  FROM  zips  AS z
  CROSS JOIN hours AS h
),

/* 6) Trip counts with zeros filled in                                 */
full_counts AS (
  SELECT
    g.zip_code,
    g.hr,
    IFNULL(a.trips, 0) AS trips
  FROM grid AS g
  LEFT JOIN agg AS a
    USING (zip_code, hr)
),

/* 7) Time-lag and moving-window statistics                            */
calc AS (
  SELECT
    *,
    LAG(trips,   1) OVER w AS trips_1h_ago,
    LAG(trips,  24) OVER w AS trips_24h_ago,
    LAG(trips, 168) OVER w AS trips_7d_ago,
    LAG(trips, 336) OVER w AS trips_14d_ago,
    AVG(trips)    OVER w14 AS ma_14d,
    STDDEV(trips) OVER w14 AS sd_14d,
    AVG(trips)    OVER w21 AS ma_21d,
    STDDEV(trips) OVER w21 AS sd_21d
  FROM full_counts
  WINDOW
    w   AS (PARTITION BY zip_code ORDER BY hr),
    w14 AS (PARTITION BY zip_code ORDER BY hr
             ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING),
    w21 AS (PARTITION BY zip_code ORDER BY hr
             ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)
)

/* 8)  Final answer: 01-Jan-2015 rows, top-5 by trip volume            */
SELECT
  zip_code,
  hr,
  trips,
  trips_1h_ago,
  trips_24h_ago,
  trips_7d_ago,
  trips_14d_ago,
  ma_14d,
  sd_14d,
  ma_21d,
  sd_21d
FROM calc
WHERE DATE(hr) = '2015-01-01'
ORDER BY trips DESC
LIMIT 5;