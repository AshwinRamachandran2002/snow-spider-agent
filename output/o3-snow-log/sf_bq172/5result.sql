/* 1) Find the drug with the highest total claim count in New York (2014)
   2) For that drug, show the five states with the greatest total claim counts
      together with their summed claim counts and drug costs                */

WITH ny_drug_totals AS (   -- total prescriptions for each drug in NY
    SELECT
        "drug_name",
        SUM("total_claim_count")            AS "ny_total_claims"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" = 'NY'
    GROUP BY "drug_name"
),

top_ny_drug AS (          -- the single drug with the most NY claims
    SELECT "drug_name"
    FROM ny_drug_totals
    ORDER BY "ny_total_claims" DESC NULLS LAST
    LIMIT 1
),

state_totals AS (         -- totals for that drug across all states
    SELECT
        p."nppes_provider_state"            AS "state",
        SUM(p."total_claim_count")          AS "total_claims",
        SUM(p."total_drug_cost")            AS "total_drug_cost"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014   p
    JOIN top_ny_drug d
      ON p."drug_name" = d."drug_name"
    GROUP BY p."nppes_provider_state"
)

SELECT
    "state",
    "total_claims",
    "total_drug_cost"
FROM state_totals
ORDER BY "total_claims" DESC NULLS LAST
LIMIT 5;