WITH total_claims AS (
    SELECT
        "nppes_provider_state",
        "drug_name",
        SUM("total_claim_count") AS "total_claims"
    FROM
        "CMS_DATA"."CMS_MEDICARE"."PART_D_PRESCRIBER_2014"
    GROUP BY
        "nppes_provider_state", "drug_name"
),
ranked_claims AS (
    SELECT
        "nppes_provider_state",
        "drug_name",
        ROW_NUMBER() OVER (
            PARTITION BY "nppes_provider_state"
            ORDER BY "total_claims" DESC NULLS LAST
        ) AS rn
    FROM
        total_claims
)
SELECT
    "nppes_provider_state" AS "State",
    "drug_name" AS "Most_Prescribed_Medication"
FROM
    ranked_claims
WHERE
    rn = 1
ORDER BY
    "State";