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
),
total_distances AS (
  SELECT
    "sid",
    SUM("distance") AS "total_distance"
  FROM distances
  GROUP BY "sid"
),
ranked_hurricanes AS (
  SELECT
    "sid",
    "total_distance",
    RANK() OVER (ORDER BY "total_distance" DESC NULLS LAST) AS "rank"
  FROM total_distances
),
second_longest_hurricane AS (
  SELECT "sid"
  FROM ranked_hurricanes
  WHERE "rank" = 2
)
SELECT
  ROUND("latitude", 4) AS "final_latitude"
FROM "NOAA_DATA"."NOAA_HURRICANES"."HURRICANES"
WHERE "sid" = (SELECT "sid" FROM second_longest_hurricane)
ORDER BY "iso_time" DESC
LIMIT 1;