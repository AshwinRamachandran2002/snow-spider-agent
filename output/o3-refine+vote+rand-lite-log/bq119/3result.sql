WITH atlantic_2020 AS (
  -- 1. 2020 North‑Atlantic main‑track positions
  SELECT
    sid,
    name,
    iso_time,                            -- TIMESTAMP of the fix
    latitude,
    longitude,
    IFNULL(usa_wind, wmo_wind) AS wind   -- 1‑min sustained wind (knots).  Fallback to WMO if USA missing
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    season = '2020'
    AND basin  = 'NA'          -- North Atlantic basin
    AND track_type = 'main'    -- exclude split/spur/other auxiliary fixes
),

fix_segments AS (
  -- 2. Distance (km) between successive fixes for every storm
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wind,
    -- distance in kilometres between this fix and the previous one
    ST_DISTANCE(
      ST_GEOGPOINT(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      ),
      ST_GEOGPOINT(longitude, latitude)
    ) / 1000.0               AS segment_km
  FROM atlantic_2020
),

cumulative_tracks AS (
  -- 3. Cumulative distance along the track
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wind,
    segment_km,
    SUM(COALESCE(segment_km,0)) 
      OVER (PARTITION BY sid ORDER BY iso_time) AS cumulative_km
  FROM fix_segments
),

storm_totals AS (
  -- 4. Total travelled distance per storm
  SELECT
    sid,
    name,
    SUM(COALESCE(segment_km,0)) AS total_km
  FROM fix_segments
  GROUP BY sid, name
),

ranked_storms AS (
  -- 5. Rank storms by total travelled distance (descending)
  SELECT
    sid,
    name,
    total_km,
    ROW_NUMBER() OVER (ORDER BY total_km DESC) AS rn
  FROM storm_totals
)

-- 6. Output: track for the 3rd‑longest travelling storm
SELECT
  t.sid,
  t.name,
  t.iso_time,
  t.latitude,
  t.longitude,
  ROUND(t.cumulative_km,2) AS cumulative_distance_km,
  t.wind                  AS max_sustained_wind_kts
FROM
  cumulative_tracks AS t
JOIN
  ranked_storms     AS r
ON  t.sid = r.sid
WHERE
  r.rn = 3                       -- third‑longest track
ORDER BY
  t.iso_time;