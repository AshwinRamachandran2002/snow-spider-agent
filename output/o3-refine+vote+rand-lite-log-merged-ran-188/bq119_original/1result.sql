-- Hurricane track with 3rd–longest travel path in the North Atlantic, season 2020
WITH track AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    usa_wind,
    ST_GEOGPOINT(longitude, latitude)                 AS pt,
    LAG(ST_GEOGPOINT(longitude, latitude)) OVER (
        PARTITION BY sid ORDER BY iso_time)           AS prev_pt
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
        season = '2020'          -- year 2020
    AND basin  = 'NA'            -- North Atlantic
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),

segments AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    COALESCE(wmo_wind, usa_wind)                      AS wind_kts,
    -- segment distance in kilometres
    CASE
      WHEN prev_pt IS NULL THEN 0
      ELSE ST_DISTANCE(pt, prev_pt) / 1000
    END                                               AS seg_km
  FROM track
),

cumulative AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wind_kts,
    seg_km,
    SUM(seg_km) OVER (PARTITION BY sid ORDER BY iso_time)  AS cum_km
  FROM segments
),

totals AS (
  SELECT
    sid,
    name,
    SUM(seg_km) AS total_km
  FROM segments
  GROUP BY sid, name
),

ranked AS (
  SELECT
    sid,
    name,
    total_km,
    ROW_NUMBER() OVER (ORDER BY total_km DESC) AS rnk
  FROM totals
)

SELECT
  c.sid,
  c.name,
  c.iso_time,
  c.latitude,
  c.longitude,
  c.cum_km        AS cumulative_distance_km,
  c.wind_kts      AS max_sustained_wind_kts
FROM cumulative c
JOIN ranked   r USING (sid, name)
WHERE r.rnk = 3                 -- third‑longest travelling hurricane
ORDER BY c.iso_time;