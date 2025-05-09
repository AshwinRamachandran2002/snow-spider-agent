WITH zip_radius AS (
  -- Washington ZIP codes whose centroids lie within 5 miles of the target point
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'WA'
    AND ST_DWithin(
          internal_point_geom,
          ST_GEOGPOINT(-122.191667, 47.685833),   -- lon, lat
          8046.72                                 -- 5 miles in metres
        )
),
tracts AS (
  -- 2017 ACS tracts, limited to WA via geometry table, with population & income
  SELECT
    a.geo_id,
    a.total_pop,
    a.income_per_capita,
    g.tract_geom,
    ST_AREA(g.tract_geom) AS tract_area
  FROM `bigquery-public-data.census_bureau_acs.censustract_2017_5yr`     a
  JOIN `bigquery-public-data.geo_census_tracts.census_tracts_washington` g
  USING (geo_id)
),
alloc AS (
  -- Allocate tract population & total income to intersecting ZIPs by area ratio
  SELECT
    z.zip_code,
    SUM(
      t.total_pop *
      ST_AREA(ST_INTERSECTION(z.zip_code_geom, t.tract_geom)) / t.tract_area
    ) AS pop_alloc,
    SUM(
      t.total_pop * t.income_per_capita *
      ST_AREA(ST_INTERSECTION(z.zip_code_geom, t.tract_geom)) / t.tract_area
    ) AS income_alloc
  FROM zip_radius z
  JOIN tracts t
    ON ST_INTERSECTS(z.zip_code_geom, t.tract_geom)
  GROUP BY z.zip_code
)
SELECT
  zip_code,
  ROUND(pop_alloc, 1)                                   AS total_population,
  ROUND(income_alloc / NULLIF(pop_alloc, 0), 1)          AS average_individual_income
FROM alloc
ORDER BY average_individual_income DESC, zip_code;