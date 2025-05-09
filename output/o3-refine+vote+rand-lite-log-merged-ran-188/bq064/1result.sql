-- Population & average individual income for every ZIP within 5 miles
-- of ( lat 47.685833  lon -122.191667 ) in Washington State
WITH
  -- reference point ----------------------------------------------------------
  ref AS (
    SELECT ST_GEOGPOINT(-122.191667, 47.685833) AS pt
  ),

  -- ZIP-codes whose centroids lie within 5 miles (≈ 8 046.72 m) --------------
  zips_near AS (
    SELECT
      zip_code,
      zip_code_geom
    FROM `bigquery-public-data.geo_us_boundaries.zip_codes`, ref
    WHERE ST_DISTANCE(ST_CENTROID(zip_code_geom), ref.pt) <= 8046.72
  ),

  -- Washington-state census tracts (ACS 2017 5-year) with geometry -----------
  tracts_wa AS (
    SELECT
      acs.geo_id,
      acs.total_pop,
      acs.income_per_capita,
      g.tract_geom
    FROM `bigquery-public-data.census_bureau_acs.censustract_2017_5yr`      AS acs
    JOIN `bigquery-public-data.geo_census_tracts.us_census_tracts_national` AS g
      ON acs.geo_id = g.geo_id
    WHERE g.state_name = 'Washington'
  ),

  -- proportionally allocate tract measures to overlapping ZIPs --------------
  alloc AS (
    SELECT
      z.zip_code,
      -- population allocated by area overlap -------------------------------
      SUM(acs.total_pop *
          ST_AREA( ST_INTERSECTION(acs.tract_geom, z.zip_code_geom) )
          / ST_AREA(acs.tract_geom))                                   AS alloc_pop,

      -- income “weights” for later average ---------------------------------
      SUM(acs.income_per_capita *
          ST_AREA( ST_INTERSECTION(acs.tract_geom, z.zip_code_geom) )
          / ST_AREA(acs.tract_geom))                                   AS alloc_income_weight,

      -- total weight (share) for each ZIP – used to form the average -------
      SUM(ST_AREA( ST_INTERSECTION(acs.tract_geom, z.zip_code_geom) )
          / ST_AREA(acs.tract_geom))                                   AS weight_sum
    FROM tracts_wa AS acs
    JOIN zips_near AS z
      ON ST_INTERSECTS(acs.tract_geom, z.zip_code_geom)
    GROUP BY z.zip_code
  )

-- ------------------- final results -----------------------------------------
SELECT
  zip_code,
  ROUND(alloc_pop, 1)                                          AS total_population,
  ROUND(alloc_income_weight / NULLIF(weight_sum, 0), 1)        AS average_individual_income
FROM alloc
ORDER BY average_individual_income DESC;