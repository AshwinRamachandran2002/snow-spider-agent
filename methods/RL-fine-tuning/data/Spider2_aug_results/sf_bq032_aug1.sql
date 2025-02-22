-- Task: Can you provide the total distance traveled by each hurricane in the North Atlantic during 2020?
WITH hurricane_tracks AS (
  SELECT
    "sid",
    "iso_time",
    "latitude",
    "longitude",
    LAG("latitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "prev_latitude",
    LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "prev_longitude"
  FROM "NOAA_DATA"."NOAA_HURRICANES"."HURRICANES"
  WHERE "season" = 2020 AND "basin" = 'NA'
),
distances AS (
  SELECT
    "sid",
    CASE
      WHEN "prev_latitude" IS NOT NULL AND "prev_longitude" IS NOT NULL THEN
        ST_DISTANCE(
          ST_MAKEPOINT("longitude", "latitude"),
          ST_MAKEPOINT("prev_longitude", "prev_latitude")
        )
      ELSE 0
    END AS "distance"
  FROM hurricane_tracks
)
SELECT
  "sid",
  SUM("distance") AS "total_distance"
FROM distances
GROUP BY "sid";