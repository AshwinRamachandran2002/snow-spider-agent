-- Population- and income-weighted ZIP-code statistics within 5 miles of
-- (lat 47.685833, lon ‑122.191667) in Washington State
WITH
-- 1.  Washington census tracts with 2017 population & 2019 per-capita income
tracts AS (
  SELECT
    g.geo_id,
    g.tract_geom,
    ST_AREA(g.tract_geom)                          AS tract_area_m2,
    p.total_pop,
    i.income_per_capita
  FROM `bigquery-public-data.geo_census_tracts.census_tracts_washington` g
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` p
    USING (geo_id)
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2019_5yr` i
    USING (geo_id)
),
-- 2.  WA ZIP codes whose polygons fall within 5 miles of the point
zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_name = 'Washington'
    AND ST_DWITHIN(
          zip_code_geom,
          ST_GEOGPOINT(-122.191667, 47.685833),
          5 * 1609.34 )              -- 5 miles in meters
),
-- 3.  Allocate each tract’s population & income to every intersecting ZIP
alloc AS (
  SELECT
    z.zip_code,
    -- area of overlap between tract & ZIP
    ST_AREA(ST_INTERSECTION(t.tract_geom, z.zip_code_geom))          AS inter_area,
    t.tract_area_m2,
    t.total_pop,
    t.income_per_capita
  FROM tracts t
  JOIN zips  z
    ON ST_INTERSECTS(t.tract_geom, z.zip_code_geom)
),
-- 4.  Convert overlaps into population & income shares
shares AS (
  SELECT
    zip_code,
    -- population allocated to the ZIP from this tract
    total_pop * SAFE_DIVIDE(inter_area, tract_area_m2)               AS pop_share,
    -- corresponding share of aggregate individual income
    income_per_capita * total_pop * SAFE_DIVIDE(inter_area, tract_area_m2)
                                                                      AS income_share
  FROM alloc
  WHERE inter_area > 0                                                -- ignore zero overlaps
)
-- 5.  Summarise by ZIP code
SELECT
  zip_code,
  ROUND(SUM(pop_share), 1)                                           AS total_population,
  ROUND(SAFE_DIVIDE(SUM(income_share), SUM(pop_share)), 1)           AS avg_individual_income
FROM shares
GROUP BY zip_code
ORDER BY avg_individual_income DESC;