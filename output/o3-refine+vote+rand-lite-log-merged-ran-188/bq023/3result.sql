WITH ny_donations AS (                 -- 1. 2020 NY individual contributions
  SELECT
    SUBSTR(zip_code, 1, 5) AS zip5,    -- keep first 5 digits of ZIP
    transaction_amt
  FROM `bigquery-public-data.fec.indiv20`
  WHERE state = 'NY'
    AND zip_code IS NOT NULL
    AND transaction_amt > 0
),

donations_to_tract AS (                -- 2. map 5-digit ZIP → census tract
  SELECT
    x.census_tract_geoid AS tract_geoid,
    d.transaction_amt
  FROM ny_donations AS d
  JOIN `bigquery-public-data.hud_zipcode_crosswalk.zipcode_to_census_tracts` AS x
    ON d.zip5 = x.zip_code
  WHERE x.census_tract_geoid LIKE '36047%'         -- 36-047 = Kings County
),

avg_donation AS (                      -- 3. average contribution per tract
  SELECT
    tract_geoid,
    AVG(transaction_amt) AS avg_donation_amt
  FROM donations_to_tract
  GROUP BY tract_geoid
)

-- 4. merge with 2018 ACS median household income
SELECT
  a.tract_geoid           AS census_tract_geoid,
  ROUND(a.avg_donation_amt, 2) AS avg_donation_amount,
  b.median_income
FROM avg_donation AS a
JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS b
  ON a.tract_geoid = b.geo_id
ORDER BY census_tract_geoid;