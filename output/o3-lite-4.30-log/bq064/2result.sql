WITH zips AS (  -- ZIP codes within 5 miles of the given WA point
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'WA'
    AND ST_DISTANCE(
          internal_point_geom,
          ST_GEOGPOINT(-122.191667, 47.685833)
        ) <= 8046.72
),
pairs AS (       -- tract–ZIP overlaps with share of tract area in the ZIP
  SELECT
    z.zip_code,
    t.geo_id,
    ST_AREA(ST_INTERSECTION(t.tract_geom, z.zip_code_geom))
    / ST_AREA(t.tract_geom) AS share
  FROM zips AS z
  JOIN `bigquery-public-data.geo_census_tracts.census_tracts_washington` AS t
    ON ST_INTERSECTS(t.tract_geom, z.zip_code_geom)
),
alloc AS (       -- allocate tract population & income to ZIPs
  SELECT
    p.zip_code,
    a.total_pop * p.share                       AS pop_part,
    a.total_pop * a.income_per_capita * p.share AS income_part
  FROM pairs AS p
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` AS a
    ON a.geo_id = p.geo_id
  WHERE p.share > 0
    AND a.total_pop IS NOT NULL
    AND a.income_per_capita IS NOT NULL
)
SELECT
  zip_code,
  ROUND(SUM(pop_part), 1)                                  AS total_population,
  ROUND(SUM(income_part) / NULLIF(SUM(pop_part), 0), 1)    AS average_individual_income
FROM alloc
GROUP BY zip_code
ORDER BY average_individual_income DESC;