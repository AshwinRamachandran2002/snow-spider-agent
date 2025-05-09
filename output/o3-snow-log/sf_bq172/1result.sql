-- 1) Identify the drug with the largest total claim count in New York (NY) for 2014
-- 2) For that drug, aggregate claim counts and drug costs by state
-- 3) Return the five states with the highest claim counts (including NY if applicable)

WITH ny_top_drug AS (
    SELECT
        "drug_name"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" = 'NY'
    GROUP BY "drug_name"
    ORDER BY SUM("total_claim_count") DESC NULLS LAST
    LIMIT 1
),
drug_state_totals AS (
    SELECT
        "nppes_provider_state"                     AS "state",
        SUM("total_claim_count")                   AS "total_claim_count",
        SUM("total_drug_cost")                     AS "total_drug_cost"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "drug_name" = (SELECT "drug_name" FROM ny_top_drug)
    GROUP BY "nppes_provider_state"
)
SELECT
    "state",
    "total_claim_count",
    "total_drug_cost"
FROM drug_state_totals
ORDER BY "total_claim_count" DESC NULLS LAST
LIMIT 5;