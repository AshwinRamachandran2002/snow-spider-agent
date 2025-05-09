WITH tract_geoms AS (
  SELECT
    ct_geom."geo_id",
    ST_GeogFromWKB(ct_geom."tract_geom") AS "tract_geog"
  FROM 
    "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_WASHINGTON" AS ct_geom
),
tract_data AS (
  SELECT
    ct_data."geo_id",
    ct_data."total_pop",
    ct_data."income_per_capita"
  FROM
    "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2017_5YR" AS ct_data
),
tracts AS (
  SELECT
    tg."geo_id",
    tg."tract_geog",
    td."total_pop",
    td."income_per_capita"
  FROM
    tract_geoms AS tg
  JOIN
    tract_data AS td
  ON
    tg."geo_id" = td."geo_id"
),
zip_geoms AS (
  SELECT
    zip_geom."zip_code",
    ST_GeogFromWKB(zip_geom."zip_code_geom") AS "zip_geog"
  FROM
    "CENSUS_BUREAU_ACS_1"."GEO_US_BOUNDARIES"."ZIP_CODES" AS zip_geom
  WHERE
    zip_geom."state_code" = 'WA'
),
overlaps AS (
  SELECT
    z."zip_code",
    t."geo_id",
    ST_Intersection(t."tract_geog", z."zip_geog") AS "overlap_geog",
    t."total_pop",
    t."income_per_capita",
    ST_Area(t."tract_geog") AS "tract_area"
  FROM
    tracts AS t
  INNER JOIN
    zip_geoms AS z
  ON
    ST_Intersects(t."tract_geog", z."zip_geog")
),
allocations AS (
  SELECT
    "zip_code",
    "geo_id",
    ST_Area("overlap_geog") AS "overlap_area",
    "total_pop",
    "income_per_capita",
    "tract_area"
  FROM
    overlaps
  WHERE
    "overlap_geog" IS NOT NULL
),
proportions AS (
  SELECT
    "zip_code",
    ("overlap_area" / NULLIF("tract_area", 0)) AS "area_ratio",
    ("total_pop" * ("overlap_area" / NULLIF("tract_area", 0))) AS "allocated_pop",
    ("income_per_capita" * ("total_pop" * ("overlap_area" / NULLIF("tract_area", 0)))) AS "allocated_income"
  FROM
    allocations
),
zip_summary AS (
  SELECT
    "zip_code",
    SUM("allocated_pop") AS "total_pop",
    SUM("allocated_income") AS "total_income"
  FROM
    proportions
  GROUP BY
    "zip_code"
),
zip_centroids AS (
  SELECT
    z."zip_code",
    ST_Centroid(z."zip_geog") AS "zip_centroid_geog"
  FROM
    zip_geoms AS z
),
zips_with_distances AS (
  SELECT
    zs."zip_code",
    zs."total_pop",
    zs."total_income",
    ST_Distance(zc."zip_centroid_geog", ST_MakePoint(-122.191667, 47.685833)) AS "distance"
  FROM
    zip_summary AS zs
  JOIN
    zip_centroids AS zc
  ON
    zs."zip_code" = zc."zip_code"
),
zips_within_radius AS (
  SELECT
    "zip_code",
    "total_pop",
    "total_income"
  FROM
    zips_with_distances
  WHERE
    "distance" <= 8046.72
),
final_result AS (
  SELECT
    zwr."zip_code" AS "Zip_Code",
    ROUND(zwr."total_pop", 1) AS "Total_Population",
    ROUND(zwr."total_income" / NULLIF(zwr."total_pop", 0), 1) AS "Average_Individual_Income"
  FROM
    zips_within_radius AS zwr
)
SELECT
  *
FROM
  final_result
ORDER BY
  "Average_Individual_Income" DESC NULLS LAST
;