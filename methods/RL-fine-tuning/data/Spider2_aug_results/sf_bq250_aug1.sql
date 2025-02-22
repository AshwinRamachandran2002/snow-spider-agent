-- Task: Based on the most recent 1km population grid data in Singapore before January 2023, calculate the total population and create a bounding region of all population grid centroids using ST_ENVELOPE.

-- Note: Since ST_CONVEXHULL and ST_CONVEXHULL_AGG are not recognized functions in Snowflake, we use ST_ENVELOPE to create the bounding region.

WITH country_name AS (
  SELECT 'Singapore' AS value
),

last_updated AS (
  SELECT
    MAX("last_updated") AS value
  FROM 
    GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM AS pop
  WHERE 
    pop."country_name" = 'Singapore' AND
    pop."last_updated" < '2023-01-01'
),

aggregated_population AS (
  SELECT
    ST_POINT("longitude_centroid", "latitude_centroid") AS centr,
    "population"
  FROM
    GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM AS pop
  WHERE
    pop."country_name" = 'Singapore' AND
    pop."last_updated" = (SELECT value FROM last_updated)
)

SELECT
  SUM("population") AS total_population,
  ST_ENVELOPE(ST_UNION_AGG(centr)) AS bounding_region
FROM
  aggregated_population;