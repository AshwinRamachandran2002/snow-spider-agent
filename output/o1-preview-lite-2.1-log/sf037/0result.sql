WITH home_depot_stores AS (
   SELECT p."POI_ID" AS "Home_Depot_POI_ID", a."LATITUDE" AS "HD_LATITUDE", a."LONGITUDE" AS "HD_LONGITUDE"
   FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX p
   JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r ON p."POI_ID" = r."POI_ID"
   JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES a ON r."ADDRESS_ID" = a."ADDRESS_ID"
   WHERE p."POI_NAME" ILIKE '%Home%Depot%'
),
lowes_stores AS (
   SELECT p."POI_ID" AS "Lowes_POI_ID", a."LATITUDE" AS "Lowes_LATITUDE", a."LONGITUDE" AS "Lowes_LONGITUDE"
   FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX p
   JOIN US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS r ON p."POI_ID" = r."POI_ID"
   JOIN US_REAL_ESTATE.CYBERSYN.US_ADDRESSES a ON r."ADDRESS_ID" = a."ADDRESS_ID"
   WHERE p."POI_NAME" ILIKE '%Lowe%Home%Improvement%'
),
distances AS (
  SELECT
    hd."Home_Depot_POI_ID",
    l."Lowes_POI_ID" AS "Nearest_Lowes_POI_ID",
    ROUND((ST_DISTANCE(
      ST_MAKEPOINT(hd."HD_LONGITUDE", hd."HD_LATITUDE"),
      ST_MAKEPOINT(l."Lowes_LONGITUDE", l."Lowes_LATITUDE")
    ) / 1609.34), 4) AS "Distance_miles"
  FROM home_depot_stores hd
  CROSS JOIN lowes_stores l
),
min_distances AS (
  SELECT
    "Home_Depot_POI_ID",
    "Nearest_Lowes_POI_ID",
    "Distance_miles",
    ROW_NUMBER() OVER (PARTITION BY "Home_Depot_POI_ID" ORDER BY "Distance_miles") AS rn
  FROM distances
)
SELECT
  "Home_Depot_POI_ID",
  "Nearest_Lowes_POI_ID",
  "Distance_miles"
FROM min_distances
WHERE rn = 1;