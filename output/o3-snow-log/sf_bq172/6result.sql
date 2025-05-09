/* 1) Find the drug with the greatest total prescriptions in New York in 2014
   2) For that drug, list the 5 states with the largest total claim counts as well as
      their total claim counts and total drug costs                                          */

WITH ny_drug_totals AS (   -- total 2014 claims for every drug within New York
    SELECT
        "drug_name",
        SUM("total_claim_count")   AS total_claims
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" = 'NY'
    GROUP BY "drug_name"
),

top_ny_drug AS (           -- pick the single top-claim drug in NY
    SELECT "drug_name"
    FROM ny_drug_totals
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_claims DESC NULLS LAST) = 1
),

state_totals AS (          -- aggregate claims & costs for that drug across all states
    SELECT
        p."nppes_provider_state"            AS state,
        SUM(p."total_claim_count")          AS total_claims,
        SUM(p."total_drug_cost")            AS total_cost
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014 p
    JOIN top_ny_drug t
      ON p."drug_name" = t."drug_name"
    GROUP BY p."nppes_provider_state"
)

SELECT
    state,
    total_claims,
    total_cost
FROM state_totals
ORDER BY total_claims DESC NULLS LAST
LIMIT 5;