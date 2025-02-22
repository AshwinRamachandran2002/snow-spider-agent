-- Task: Using the most recent 1km population grid data for Singapore before January 1, 2023, aggregate all grid cell centroids into a bounding rectangle by computing the ST_ENVELOPE of the union of the centroids. Then, identify hospitals from OpenStreetMap's planet layer (where "layer_code" is in (2110, 2120)) that fall within this bounding rectangle using ST_INTERSECTS. For each population grid cell with a population greater than zero, calculate the distance to its nearest hospital. Finally, determine the grid cell(s) that are farthest from any hospital and compute the total population of those cell(s).

WITH country_name AS (
  SELECT 'Singapore' AS value
),

last_updated AS (
  SELECT
    MAX("last_updated") AS value
  FROM GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM AS pop
    INNER JOIN country_name ON (pop."country_name" = country_name.value)
  WHERE "last_updated" < '2023-01-01'
),

aggregated_population AS (
  SELECT
    "geo_id",
    SUM("population") AS sum_population,
    ST_POINT("longitude_centroid", "latitude_centroid") AS centr  -- Compute centroid point for each geo_id
  FROM
    GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM AS pop
    INNER JOIN country_name ON (pop."country_name" = country_name.value)
    INNER JOIN last_updated ON (pop."last_updated" = last_updated.value)
  GROUP BY "geo_id", "longitude_centroid", "latitude_centroid"
),

population AS (
  SELECT
    SUM(sum_population) AS sum_population,
    ST_ENVELOPE(ST_UNION_AGG(centr)) AS boundingbox  -- Use ST_ENVELOPE to create bounding rectangle
  FROM aggregated_population
),

hospitals AS (
  SELECT
    layer."geometry"
  FROM
    GEO_OPENSTREETMAP_WORLDPOP.GEO_OPENSTREETMAP.PLANET_LAYERS AS layer
    INNER JOIN population ON ST_INTERSECTS(population.boundingbox, ST_GEOGFROMWKB(layer."geometry"))
  WHERE
    layer."layer_code" IN (2110, 2120)
),

distances AS (
  SELECT
    pop."geo_id",
    pop."population",
    MIN(ST_DISTANCE(ST_GEOGFROMWKB(pop."geog"), ST_GEOGFROMWKB(hospitals."geometry"))) AS distance
  FROM
    GEO_OPENSTREETMAP_WORLDPOP.WORLDPOP.POPULATION_GRID_1KM AS pop
    INNER JOIN country_name ON pop."country_name" = country_name.value
    INNER JOIN last_updated ON pop."last_updated" = last_updated.value
    CROSS JOIN hospitals
  WHERE pop."population" > 0
  GROUP BY "geo_id", "population"
)

SELECT
  SUM(pd."population") AS population
FROM
  distances pd
CROSS JOIN population p
GROUP BY distance
ORDER BY distance DESC
LIMIT 1;