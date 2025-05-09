WITH tract_zip_overlap AS (
  -- Intersect each WA census tract with WA ZIP codes
  -- whose centroid is within 5 miles (≈ 8 047 m) of the target point
  SELECT
    z.zip_code,
    a.total_pop,
    a.income_per_capita,
    ST_AREA(t.tract_geom)                                   AS tract_area,
    ST_AREA(ST_INTERSECTION(t.tract_geom, z.zip_code_geom)) AS overlap_area
  FROM `bigquery-public-data.geo_census_tracts.census_tracts_washington`  AS t
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2017_5yr`     AS a
  USING (geo_id)
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes`                AS z
    ON ST_INTERSECTS(t.tract_geom, z.zip_code_geom)
  WHERE z.state_code = 'WA'
    AND ST_DWithin(
          z.internal_point_geom,
          ST_GEOGPOINT(-122.191667, 47.685833),  -- target point
          8047                                   -- 5 miles in metres
        )
),
allocated AS (
  -- Proportionally allocate tract population & income to ZIP by area
  SELECT
    zip_code,
    SAFE_DIVIDE(overlap_area, tract_area) AS area_weight,
    total_pop,
    income_per_capita
  FROM tract_zip_overlap
  WHERE overlap_area > 0
),
zip_totals AS (
  -- Aggregate allocated values to ZIP level
  SELECT
    zip_code,
    SUM(total_pop * area_weight)                    AS pop_alloc,
    SUM((total_pop * income_per_capita) * area_weight) AS income_alloc
  FROM allocated
  GROUP BY zip_code
)
-- Final result
SELECT
  zip_code,
  ROUND(pop_alloc, 1)                               AS total_population,
  ROUND(SAFE_DIVIDE(income_alloc, pop_alloc), 1)    AS average_individual_income
FROM zip_totals
ORDER BY average_individual_income DESC, zip_code;