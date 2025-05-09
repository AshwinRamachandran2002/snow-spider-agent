WITH top_drug AS (
    SELECT "drug_name"
    FROM "CMS_DATA"."CMS_MEDICARE"."PART_D_PRESCRIBER_2014"
    WHERE "nppes_provider_state" = 'NY' AND "drug_name" IS NOT NULL
    GROUP BY "drug_name"
    ORDER BY SUM("total_claim_count") DESC NULLS LAST
    LIMIT 1
)
SELECT
    top_drug."drug_name" AS "Drug Name",
    "nppes_provider_state" AS "State",
    SUM("total_claim_count") AS "Total Claim Count",
    ROUND(SUM("total_drug_cost"), 4) AS "Total Drug Cost"
FROM
    "CMS_DATA"."CMS_MEDICARE"."PART_D_PRESCRIBER_2014"
    INNER JOIN top_drug ON "CMS_DATA"."CMS_MEDICARE"."PART_D_PRESCRIBER_2014"."drug_name" = top_drug."drug_name"
WHERE
    "nppes_provider_state" IS NOT NULL
GROUP BY
    top_drug."drug_name", "nppes_provider_state"
ORDER BY
    "Total Claim Count" DESC NULLS LAST
LIMIT 5;