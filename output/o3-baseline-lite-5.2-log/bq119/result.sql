-- Hurricane track, cumulative distance, and wind data for the  
-- North‑Atlantic storm with the 3rd‑longest total travel distance in 2020
WITH atlantic_2020 AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    COALESCE(wmo_wind , usa_wind) AS wind,                     -- max sustained wind (knots)
    ROW_NUMBER() OVER (PARTITION BY sid ORDER BY iso_time) AS pt_idx
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'                      -- North‑Atlantic basin
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),

seg_distances AS (
  SELECT
    a.*,
    ST_GEOGPOINT(longitude , latitude )                             AS curr_pt,
    LAG(ST_GEOGPOINT(longitude , latitude ))
        OVER (PARTITION BY sid ORDER BY pt_idx)                     AS prev_pt
  FROM atlantic_2020 a
),

cumulated AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wind,
    pt_idx,
    IF(prev_pt IS NULL, 0, ST_DISTANCE(prev_pt, curr_pt))         AS seg_m,
    SUM(IF(prev_pt IS NULL, 0, ST_DISTANCE(prev_pt, curr_pt)))
         OVER (PARTITION BY sid ORDER BY pt_idx) / 1000.0          AS cum_km   -- km
  FROM seg_distances
),

totals AS (
  SELECT sid, MAX(cum_km) AS total_km
  FROM cumulated
  GROUP BY sid
),

ranked AS (
  SELECT
    sid,
    total_km,
    ROW_NUMBER() OVER (ORDER BY total_km DESC, sid) AS rk
  FROM totals
),

target AS (
  SELECT sid, total_km
  FROM ranked
  WHERE rk = 3                         -- 3rd‑longest travelling storm
)

SELECT
  c.sid,
  c.iso_time,
  c.latitude,
  c.longitude,
  c.cum_km          AS cumulative_travel_km,
  c.wind            AS max_sustained_wind_knots
FROM cumulated c
JOIN target  USING (sid)
ORDER BY c.pt_idx;