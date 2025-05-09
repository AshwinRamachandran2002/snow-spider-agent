WITH ny_drug_totals AS (
    SELECT
        "drug_name",
        SUM("total_claim_count") AS "ny_total_claims"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" = 'NY'
    GROUP BY "drug_name"
),
top_drug AS (   -- drug with the most prescriptions in NY
    SELECT "drug_name"
    FROM ny_drug_totals
    ORDER BY "ny_total_claims" DESC NULLS LAST
    LIMIT 1
),
state_totals AS (
    SELECT
        p."nppes_provider_state"   AS "state",
        SUM(p."total_claim_count") AS "total_claims",
        SUM(p."total_drug_cost")   AS "total_drug_cost"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014 AS p
    JOIN top_drug t
      ON p."drug_name" = t."drug_name"
    WHERE p."nppes_provider_state" IS NOT NULL
    GROUP BY p."nppes_provider_state"
)
SELECT
    "state",
    "total_claims",
    "total_drug_cost"
FROM state_totals
ORDER BY "total_claims" DESC NULLS LAST
LIMIT 5;