WITH hurricane_data AS (
  SELECT 
    "sid",
    "iso_time",
    "latitude",
    "longitude",
    LAG("latitude") OVER (PARTITION BY "sid" ORDER BY "iso_time" ASC NULLS LAST) AS prev_latitude,
    LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time" ASC NULLS LAST) AS prev_longitude
  FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
  WHERE "season" = '2020' AND "basin" = 'NA'
),
distance_data AS (
  SELECT
    "sid",
    ST_DISTANCE(
      ST_MAKEPOINT("longitude", "latitude"),
      ST_MAKEPOINT(prev_longitude, prev_latitude)
    ) AS segment_distance
  FROM hurricane_data
  WHERE prev_latitude IS NOT NULL AND prev_longitude IS NOT NULL
),
total_distance AS (
  SELECT
    "sid",
    SUM(segment_distance) AS total_distance
  FROM distance_data
  GROUP BY "sid"
),
ranked_hurricanes AS (
  SELECT
    "sid",
    total_distance,
    RANK() OVER (ORDER BY total_distance DESC NULLS LAST) AS distance_rank
  FROM total_distance
),
final_positions AS (
  SELECT
    h."sid",
    h."iso_time",
    h."latitude",
    ROW_NUMBER() OVER (PARTITION BY h."sid" ORDER BY h."iso_time" DESC NULLS LAST) AS rn
  FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES h
  WHERE h."season" = '2020' AND h."basin" = 'NA'
)
SELECT TO_CHAR(ROUND(fp."latitude", 4), 'FM999999.0000') AS final_latitude
FROM final_positions fp
JOIN ranked_hurricanes rh ON fp."sid" = rh."sid"
WHERE rh.distance_rank = 2
  AND fp.rn = 1;