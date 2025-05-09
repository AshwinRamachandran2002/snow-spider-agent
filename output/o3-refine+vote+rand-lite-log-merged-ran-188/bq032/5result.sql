WITH atlantic_2020 AS (
  -- 2020 North‑Atlantic track points with valid coordinates
  SELECT
    sid ,
    iso_time ,
    latitude ,
    longitude ,
    ST_GEOGPOINT(longitude , latitude) AS geom
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
),
seg_lengths AS (
  -- distance between consecutive points for every storm
  SELECT
    sid ,
    ST_DISTANCE(
      geom ,
      LEAD(geom) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS segment_m
  FROM atlantic_2020
),
storm_totals AS (
  -- total distance travelled by each storm
  SELECT
    sid ,
    SUM(segment_m) AS total_m
  FROM seg_lengths
  WHERE segment_m IS NOT NULL
  GROUP BY sid
),
second_longest_storm AS (
  -- storm that has the 2‑nd longest track
  SELECT sid
  FROM storm_totals
  QUALIFY DENSE_RANK() OVER (ORDER BY total_m DESC) = 2
),
final_position AS (
  -- last reported position for that storm
  SELECT
    latitude
  FROM atlantic_2020
  WHERE sid IN (SELECT sid FROM second_longest_storm)
  QUALIFY iso_time = MAX(iso_time) OVER (PARTITION BY sid)
)
SELECT latitude
FROM final_position;