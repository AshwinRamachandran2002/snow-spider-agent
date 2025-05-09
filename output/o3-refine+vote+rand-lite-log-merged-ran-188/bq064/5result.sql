-- Zip-level population & average individual income (2017 ACS),
-- for ZIP codes within 5 miles of 47.685833 N , -122.191667 W (WA)

WITH
-- 1.  Target point
params AS (
  SELECT ST_GEOGPOINT(-122.191667 , 47.685833) AS center
),

-- 2.  Washington ZIPs that lie within 5-mile (≈ 8 047 m) radius
nearby_zips AS (
  SELECT
    z.zip_code,
    z.zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
  CROSS JOIN params
  WHERE z.state_name = 'Washington'
    AND ST_DWITHIN(z.zip_code_geom , params.center , 8047)
),

-- 3.  Compute land-area share of each WA census-tract that falls inside each nearby ZIP
overlap AS (
  SELECT
    t.geo_id,                  -- tract id
    z.zip_code,                -- zip
    ST_AREA(
      ST_INTERSECTION(t.tract_geom , z.zip_code_geom)
    ) / NULLIF(ST_AREA(t.tract_geom),0)          AS share
  FROM `bigquery-public-data.geo_census_tracts.census_tracts_washington` AS t
  JOIN nearby_zips AS z
    ON ST_INTERSECTS(t.tract_geom , z.zip_code_geom)
),

-- 4.  Allocate tract population & income to ZIPs proportionally by the overlap share
alloc AS (
  SELECT
    o.zip_code,
    s.total_pop          * o.share AS pop_part,
    s.income_per_capita  * s.total_pop * o.share AS income_part
  FROM overlap AS o
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` AS s
    ON o.geo_id = s.geo_id
  WHERE s.total_pop IS NOT NULL
    AND s.income_per_capita IS NOT NULL          -- ignore tracts without income data
)

-- 5.  Aggregate to ZIP level & report
SELECT
  zip_code,
  ROUND(SUM(pop_part)                          , 1) AS total_population,
  ROUND(SUM(income_part) / SUM(pop_part)       , 1) AS avg_individual_income
FROM alloc
GROUP BY zip_code
ORDER BY avg_individual_income DESC;