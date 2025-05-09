/*--------------------------------------------------------------------
  1) Build tract–level 2018 ACS median-income values for Kings County
     (state FIPS 36, county FIPS 047) by averaging the block-group
     medians that roll up to each tract (first 11 digits of GEOID).
  2) Build tract–level average individual-donation amounts for 2020
     New-York donors by (a) truncating donors’ ZIP codes to 5 digits,
     (b) joining to the HUD ZIP→Census-tract cross-walk, and
     (c) averaging the transaction amounts for every tract whose GEOID
         begins with 36047 (Kings County).
  3) Join the two CTEs to list, for every Kings-County census tract,
     its 2018 median household income and its 2020 average donation.
--------------------------------------------------------------------*/
WITH tract_income AS (
    SELECT
        SUBSTR("geo_id",1,11)                       AS "census_tract_geoid",
        AVG("median_income")                        AS "median_income_2018"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR
    WHERE SUBSTR("geo_id",1,5) = '36047'            -- Kings County (NY)
    GROUP BY SUBSTR("geo_id",1,11)
),
tract_donations AS (
    SELECT
        cross."census_tract_geoid"                  AS "census_tract_geoid",
        AVG(donor."transaction_amt")                AS "avg_donation_2020"
    FROM FEC.FEC.INDIVIDUALS_INGEST_2020            AS donor
    JOIN FEC.HUD_ZIPCODE_CROSSWALK.CENSUS_TRACTS_TO_ZIPCODE AS cross
          ON SUBSTR(donor."zip_code",1,5) = cross."zip_code"
    WHERE donor."state" = 'NY'                      -- donors in New York
      AND SUBSTR(cross."census_tract_geoid",1,5) = '36047'  -- Kings County
    GROUP BY cross."census_tract_geoid"
)

SELECT
    inc."census_tract_geoid",
    inc."median_income_2018",
    don."avg_donation_2020"
FROM tract_income  inc
LEFT JOIN tract_donations don
       ON inc."census_tract_geoid" = don."census_tract_geoid"
ORDER BY inc."census_tract_geoid";