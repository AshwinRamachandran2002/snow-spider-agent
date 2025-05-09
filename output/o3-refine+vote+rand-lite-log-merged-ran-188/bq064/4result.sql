/* ❶ 5-mile ZIP population & income (2017 ACS) around 47.685833 N / -122.191667 W */
WITH
-- point of interest ------------------------------------------------------------
target AS (
  SELECT ST_GEOGPOINT(-122.191667, 47.685833) AS pt
),

-- Washington ZIP codes whose polygons are within 5 miles (~8 046.72 m) ----------
chosen_zips AS (
  SELECT
    z.zip_code,
    z.zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
  CROSS JOIN target
  WHERE z.state_name = 'Washington'
    AND ST_DISTANCE(z.zip_code_geom, pt) <= 8046.72         -- 5 miles
),

-- Washington census-tract geometries + 2017 ACS population & income ------------
wa_tracts AS (
  SELECT
    g.geo_id,
    g.tract_geom,
    a.total_pop,
    a.income_per_capita
  FROM `bigquery-public-data.geo_census_tracts.census_tracts_washington` AS g
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2017_5yr`     AS a
    ON g.geo_id = a.geo_id
  WHERE a.total_pop IS NOT NULL
),

-- Allocate tract population & income dollars to each overlapping ZIP ----------
alloc AS (
  SELECT
    z.zip_code,
    -- population share allocated by intersection-area proportion
    t.total_pop *
      ST_AREA(ST_INTERSECTION(z.zip_code_geom, t.tract_geom)) /
      ST_AREA(t.tract_geom)                                   AS pop_alloc,
    -- income dollars allocated the same way
    COALESCE(t.income_per_capita, 0) * t.total_pop *
      ST_AREA(ST_INTERSECTION(z.zip_code_geom, t.tract_geom)) /
      ST_AREA(t.tract_geom)                                   AS income_alloc
  FROM chosen_zips AS z
  JOIN wa_tracts  AS t
    ON ST_INTERSECTS(z.zip_code_geom, t.tract_geom)
)

-- final per-ZIP metrics --------------------------------------------------------
SELECT
  zip_code,
  ROUND(SUM(pop_alloc), 1)                                   AS total_population,
  ROUND(SUM(income_alloc) / NULLIF(SUM(pop_alloc), 0), 1)    AS avg_indiv_income
FROM alloc
GROUP BY zip_code
ORDER BY avg_indiv_income DESC;