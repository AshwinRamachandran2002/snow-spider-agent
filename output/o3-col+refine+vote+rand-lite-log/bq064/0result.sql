-- Allocate 2017 ACS tract population & income to ZIP codes by overlapping area,
-- then keep only ZIPs whose polygons fall within 5 miles of the reference point
-- (47.685833 N, -122.191667 W).  Finally, report total population and
-- average individual income per ZIP, ordered by income (highest first).

WITH near_zips AS (          -- ZIP polygons ≤ 5 mi from the point
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE ST_DWITHIN(
          zip_code_geom,
          ST_GEOGPOINT(-122.191667, 47.685833),
          8046.72                           -- 5 miles in metres
        )
),

overlap AS (                 -- intersecting (ZIP, tract) pairs + area share
  SELECT
    z.zip_code,
    t.geo_id,                                         -- tract ID
    ST_AREA( ST_INTERSECTION(z.zip_code_geom, t.tract_geom) )
    / ST_AREA(t.tract_geom)        AS share_of_tract
  FROM near_zips AS z
  JOIN `bigquery-public-data.geo_census_tracts.census_tracts_washington` AS t
    ON ST_INTERSECTS(z.zip_code_geom, t.tract_geom)
  WHERE ST_AREA( ST_INTERSECTION(z.zip_code_geom, t.tract_geom) ) > 0
),

alloc AS (                   -- allocate tract-level data to ZIPs
  SELECT
    o.zip_code,
    a.total_pop * o.share_of_tract                      AS pop_alloc,
    a.total_pop * a.income_per_capita * o.share_of_tract AS income_alloc
  FROM overlap AS o
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` AS a
    ON a.geo_id = o.geo_id
)

SELECT
  zip_code,
  ROUND(SUM(pop_alloc), 1)                           AS total_population,
  ROUND(SUM(income_alloc) / SUM(pop_alloc), 1)       AS avg_individual_income
FROM alloc
GROUP BY zip_code
ORDER BY avg_individual_income DESC;