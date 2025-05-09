SELECT
    "nppes_provider_state" AS "State",
    "drug_name" AS "Most_Prescribed_Medication"
FROM (
    SELECT
        "nppes_provider_state",
        "drug_name",
        SUM("total_claim_count") AS "total_claims",
        ROW_NUMBER() OVER (
            PARTITION BY "nppes_provider_state" 
            ORDER BY SUM("total_claim_count") DESC NULLS LAST
        ) AS rn
    FROM "CMS_DATA"."CMS_MEDICARE"."PART_D_PRESCRIBER_2014"
    GROUP BY
        "nppes_provider_state",
        "drug_name"
) sub
WHERE rn = 1
ORDER BY "State" ASC NULLS LAST;