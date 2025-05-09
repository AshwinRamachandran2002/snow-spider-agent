SELECT z."zip_code" AS "Zip_Code",
       CAST(ROUND(SUM(t."total_pop" * (overlap."overlap_area" / tract_area."tract_area")), 1) AS INT) AS "Total_Population",
       ROUND(AVG(t."income_per_capita"), 4) AS "Average_Individual_Income"
FROM "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2017_5YR" t
JOIN "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_WASHINGTON" g
  ON t."geo_id" = g."geo_id"
JOIN (
  SELECT "geo_id", ST_AREA(ST_GeogFromWKB("tract_geom")) AS "tract_area"
  FROM "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_WASHINGTON"
) tract_area ON g."geo_id" = tract_area."geo_id"
JOIN "CENSUS_BUREAU_ACS_1"."GEO_US_BOUNDARIES"."ZIP_CODES" z
  ON ST_INTERSECTS(
    ST_GeogFromWKB(g."tract_geom"),
    ST_GeogFromWKB(z."zip_code_geom")
  )
JOIN (
  SELECT g."geo_id", z."zip_code",
    ST_AREA(
      ST_INTERSECTION(
        ST_GeogFromWKB(g."tract_geom"),
        ST_GeogFromWKB(z."zip_code_geom")
      )
    ) AS "overlap_area"
  FROM "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_WASHINGTON" g
  JOIN "CENSUS_BUREAU_ACS_1"."GEO_US_BOUNDARIES"."ZIP_CODES" z
    ON ST_INTERSECTS(
      ST_GeogFromWKB(g."tract_geom"),
      ST_GeogFromWKB(z."zip_code_geom")
    )
) overlap ON t."geo_id" = overlap."geo_id" AND z."zip_code" = overlap."zip_code"
WHERE ST_DISTANCE(
  ST_GeogFromWKB(z."zip_code_geom"),
  ST_POINT(-122.191667, 47.685833)
) <= 5 * 1609.34
GROUP BY z."zip_code"
ORDER BY "Average_Individual_Income" DESC NULLS LAST;