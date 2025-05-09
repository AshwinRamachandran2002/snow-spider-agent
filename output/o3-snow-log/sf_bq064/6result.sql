/*————————————————————————————————————————————————————————————
  Zip-code population & average individual income within 5-mile
  radius of 47.685833 N, –122.191667 W  (Washington State)
————————————————————————————————————————————————————————————*/
SELECT
    z."zip_code"                                                          AS "zip_code",
    ROUND( SUM( CAST(a."total_pop"         AS FLOAT) ) , 1)               AS "total_population",
    ROUND( SUM( CAST(a."total_pop" AS FLOAT) 
               * CAST(a."income_per_capita" AS FLOAT) )
          / NULLIF( SUM( CAST(a."total_pop" AS FLOAT) ) ,0) , 1)          AS "average_individual_income"
FROM  CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  a
JOIN  CENSUS_BUREAU_ACS_1.GEO_US_BOUNDARIES."ZIP_CODES"          z
      ON a."geo_id" = z."zip_code"
WHERE ST_DISTANCE(
          TO_GEOGRAPHY(ST_MAKEPOINT(z."internal_point_lon", z."internal_point_lat")),
          TO_GEOGRAPHY(ST_MAKEPOINT(-122.191667, 47.685833))
      ) <= 5 * 1609.344         -- 5 miles in metres
GROUP BY z."zip_code"
ORDER BY "average_individual_income" DESC NULLS LAST;