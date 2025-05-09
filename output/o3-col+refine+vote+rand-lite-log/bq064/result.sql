-- Total population and average individual income (per–capita)
-- for every ZIP whose polygon lies within 5 miles (≈ 8 046.72 m)
-- of the point 47.685833 N , -122.191667 W (Bellevue/Redmond WA).

WITH
/* 1. 2017 ACS census-tract facts + WA tract geometries  */
tracts AS (
  SELECT
    t.geo_id,
    t.total_pop,
    t.income_per_capita,          -- 2017 ACS per-capita income
    g.tract_geom
  FROM `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` t
  JOIN `bigquery-public-data.geo_census_tracts.census_tracts_washington` g
  ON   t.geo_id = g.geo_id
),

/* 2. ZIP-code polygons whose centroid is within 5 miles of the point */
zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE ST_DWithin(
          zip_code_geom,
          ST_GeogPoint(-122.191667, 47.685833),   -- (lon , lat)
          8046.72                                  -- 5 miles in meters
        )
),

/* 3.  Overlap ratio of each intersecting tract-ZIP pair               */
overlaps AS (
  SELECT
    z.zip_code,
    tr.geo_id,
    ST_Area(ST_Intersection(tr.tract_geom, z.zip_code_geom))
    / NULLIF(ST_Area(tr.tract_geom),0)            AS ratio
  FROM tracts tr
  JOIN zips   z
  ON  ST_Intersects(tr.tract_geom, z.zip_code_geom)
),

/* 4.  Allocate population & income proportionally by overlap          */
alloc AS (
  SELECT
    o.zip_code,
    tr.total_pop              * o.ratio AS pop_share,
    tr.income_per_capita * tr.total_pop * o.ratio AS income_share
  FROM overlaps o
  JOIN tracts  tr
  ON  tr.geo_id = o.geo_id
)

/* 5.  Aggregate to ZIP level and report results                       */
SELECT
  zip_code,
  ROUND(SUM(pop_share)                                   , 1) AS total_population,
  ROUND(SUM(income_share) / NULLIF(SUM(pop_share),0)     , 1) AS avg_individual_income
FROM alloc
GROUP BY zip_code
ORDER BY avg_individual_income DESC;