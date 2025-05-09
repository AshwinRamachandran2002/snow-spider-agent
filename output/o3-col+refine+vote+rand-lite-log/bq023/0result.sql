/*  Kings County (Brooklyn, NY) – 2020 average individual-donation amount
    matched to 2018 ACS median household income by Census tract            */

-- ── 1) isolate 2020 FEC donations coming from New-York ZIP codes ─────────────────
WITH ny_donations AS (
  SELECT
    SUBSTR(zip_code,1,5)          AS zip5,          -- ZIP-5 only
    transaction_amt
  FROM `bigquery-public-data.fec.indiv20`
  WHERE state = 'NY'
    AND REGEXP_CONTAINS(zip_code, r'^\d{5}')        -- keep rows that begin with 5 digits
),

-- ── 2) map those ZIP-5 codes to Census-tract GEOIDs via HUD cross-walk ───────────
donations_by_tract AS (
  SELECT
    cw.census_tract_geoid,
    AVG(nd.transaction_amt)       AS avg_donation   -- tract-level average
  FROM ny_donations AS nd
  JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS cw
    ON nd.zip5 = cw.zip_code
  WHERE cw.census_tract_geoid LIKE '36047%'         -- 36 = NY, 047 = Kings County
  GROUP BY cw.census_tract_geoid
)

-- ── 3) merge the donation metric with 2018 ACS median income ─────────────────────
SELECT
  acs.geo_id                      AS census_tract_geoid,
  acs.median_income,
  COALESCE(db.avg_donation,0)     AS avg_donation
FROM `bigquery-public-data.census_bureau_acs.censustract_2018_5yr`  AS acs
LEFT JOIN donations_by_tract AS db
  ON acs.geo_id = db.census_tract_geoid
WHERE acs.geo_id LIKE '36047%'                    -- Kings County tracts only
ORDER BY census_tract_geoid;