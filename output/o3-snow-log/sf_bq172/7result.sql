WITH ny_drug_totals AS (
    /* Total 2014 prescriptions for each drug written in New York */
    SELECT
        "drug_name",
        SUM("total_claim_count") AS "ny_total_claims"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" = 'NY'
    GROUP BY "drug_name"
),
top_drug AS (
    /* Drug with the highest number of NY prescriptions */
    SELECT "drug_name"
    FROM ny_drug_totals
    ORDER BY "ny_total_claims" DESC NULLS LAST
    LIMIT 1
)
SELECT
    "nppes_provider_state"                AS "state",
    SUM("total_claim_count")              AS "total_claim_counts",
    SUM("total_drug_cost")                AS "total_drug_costs"
FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
WHERE "drug_name" = (SELECT "drug_name" FROM top_drug)
GROUP BY "nppes_provider_state"
ORDER BY "total_claim_counts" DESC NULLS LAST
LIMIT 5;