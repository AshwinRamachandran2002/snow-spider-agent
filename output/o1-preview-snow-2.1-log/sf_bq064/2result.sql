SELECT z."zip_code",
       SUM(ct_data."total_pop") AS "Population",
       ROUND(AVG(ct_data."income_per_capita"), 1) AS "Average_Individual_Income"
FROM "CENSUS_BUREAU_ACS_1"."GEO_US_BOUNDARIES"."ZIP_CODES" z
JOIN "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_WASHINGTON" ct_geom
  ON ST_Intersects(
       ST_GeogFromWKB(z."zip_code_geom"),
       ST_GeogFromWKB(ct_geom."tract_geom")
     )
JOIN "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2017_5YR" ct_data
  ON ct_geom."geo_id" = ct_data."geo_id"
WHERE z."state_code" = 'WA'
  AND ST_Distance(
        ST_Centroid(ST_GeogFromWKB(z."zip_code_geom")),
        ST_MakePoint(-122.191667, 47.685833)
      ) <= 8046.72  -- 5 miles in meters
GROUP BY z."zip_code"
ORDER BY "Average_Individual_Income" DESC NULLS LAST;