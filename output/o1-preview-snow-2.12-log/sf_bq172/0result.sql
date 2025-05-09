WITH top_drug AS (
    SELECT "drug_name"
    FROM (
        SELECT "drug_name", SUM("total_claim_count") AS "total_claims"
        FROM CMS_DATA.CMS_MEDICARE."PART_D_PRESCRIBER_2014"
        WHERE "nppes_provider_state" = 'NY'
        GROUP BY "drug_name"
        ORDER BY "total_claims" DESC NULLS LAST
        LIMIT 1
    ) AS sub
)
SELECT
    p."nppes_provider_state" AS "State",
    SUM(p."total_claim_count") AS "Total Claim Count",
    ROUND(SUM(p."total_drug_cost"), 4) AS "Total Drug Cost"
FROM
    CMS_DATA.CMS_MEDICARE."PART_D_PRESCRIBER_2014" AS p
    JOIN top_drug ON p."drug_name" = top_drug."drug_name"
GROUP BY
    p."nppes_provider_state"
ORDER BY
    "Total Claim Count" DESC NULLS LAST,
    p."nppes_provider_state"
LIMIT 5;