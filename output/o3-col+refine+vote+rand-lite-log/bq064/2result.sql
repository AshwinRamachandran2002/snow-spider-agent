-- Population & income allocated from 2017 ACS census-tracts to nearby ZIPs
-- centred on 47.685833 N, -122.191667 W (5-mile / 8046.72 m radius)

WITH
params AS (
  SELECT
    ST_GEOGPOINT(-122.191667, 47.685833) AS target_pt,
    8046.72                              AS radius_m      -- 5 miles in metres
),

/* 1. ZIP codes whose internal point falls within the 5-mile radius */
nearby_zips AS (
  SELECT
    z.zip_code,
    z.zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
  CROSS JOIN params AS p
  WHERE ST_DWITHIN(
          ST_GEOGPOINT(z.internal_point_lon, z.internal_point_lat),
          p.target_pt,
          p.radius_m )
),

/* 2. Washington-state census tracts (geometry + 2017 ACS pop & income) */
wa_tracts AS (
  SELECT
    a.geo_id,
    a.total_pop,
    a.income_per_capita,
    g.tract_geom
  FROM `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` AS a
  JOIN `bigquery-public-data.geo_census_tracts.census_tracts_washington` AS g
  USING (geo_id)
),

/* 3. Area–weighted allocation of each tract’s metrics to intersecting ZIPs */
alloc AS (
  SELECT
    z.zip_code,
    -- weight = share of tract’s area that lies inside the ZIP polygon
    SAFE_DIVIDE(
      ST_AREA( ST_INTERSECTION(z.zip_code_geom, t.tract_geom) ),
      ST_AREA( t.tract_geom )
    ) AS w,
    t.total_pop,
    t.income_per_capita
  FROM nearby_zips  AS z
  JOIN wa_tracts    AS t
  ON  ST_INTERSECTS(z.zip_code_geom, t.tract_geom)
  WHERE ST_AREA( ST_INTERSECTION(z.zip_code_geom, t.tract_geom) ) > 0
),

/* 4. Aggregate to ZIP-code level */
zip_summary AS (
  SELECT
    zip_code,
    SUM( w * total_pop )                                       AS pop_alloc,
    SAFE_DIVIDE( SUM( w * total_pop * income_per_capita ),
                 SUM( w * total_pop ) )                        AS pc_income_avg
  FROM alloc
  GROUP BY zip_code
)

SELECT
  zip_code,
  ROUND(pop_alloc,       1) AS total_population,
  ROUND(pc_income_avg,   1) AS avg_individual_income
FROM zip_summary
ORDER BY avg_individual_income DESC;