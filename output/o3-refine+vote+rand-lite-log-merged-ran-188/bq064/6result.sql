/*  Proportionally assign 2017 ACS tract population & income to the ZIP codes
    that fall within 5 miles of  (-122.191667 lon , 47.685833 lat) in Washington.
    Results: total pop & pop-weighted average individual income per ZIP,
    ordered by income descending.                                                  */
WITH
-- (1) ZIP polygons located inside the 5-mile (≈ 8 046.72 m) buffer
near_zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE ST_DWITHIN(
          zip_code_geom,
          ST_GEOGPOINT(-122.191667, 47.685833),   -- target point
          8046.72                                 -- 5 miles in metres
        )
),

-- (2) Overlay those ZIPs with WA census-tract polygons
--     and compute the tract-area share that lies in each ZIP
alloc AS (
  SELECT
    z.zip_code,
    a.total_pop,
    a.income_per_capita,
    ST_AREA(ST_INTERSECTION(t.tract_geom, z.zip_code_geom))
      / ST_AREA(t.tract_geom)        AS share          -- overlap ratio
  FROM  near_zips AS z
  JOIN  `bigquery-public-data.geo_census_tracts.census_tracts_washington` AS t
    ON  ST_INTERSECTS(t.tract_geom, z.zip_code_geom)
  JOIN  `bigquery-public-data.census_bureau_acs.censustract_2017_5yr`     AS a
    ON  a.geo_id = t.geo_id
),

-- (3) Aggregate the proportional allocations per ZIP
zip_stats AS (
  SELECT
    zip_code,
    SUM(total_pop * share)                               AS pop_alloc,
    SUM(income_per_capita * total_pop * share)
      / NULLIF(SUM(total_pop * share), 0)                AS avg_income
  FROM alloc
  GROUP BY zip_code
)

-- Final output
SELECT
  zip_code,
  ROUND(pop_alloc, 1)        AS total_population,
  ROUND(avg_income, 1)       AS avg_individual_income
FROM zip_stats
ORDER BY avg_individual_income DESC;