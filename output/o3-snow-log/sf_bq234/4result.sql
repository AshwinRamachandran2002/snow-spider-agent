WITH aggregated AS (
    SELECT 
        "nppes_provider_state" AS "state",
        "drug_name",
        SUM("total_claim_count") AS "total_claims"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" IS NOT NULL
    GROUP BY 
        "nppes_provider_state",
        "drug_name"
),
ranked AS (
    SELECT
        "state",
        "drug_name",
        "total_claims",
        ROW_NUMBER() OVER (
            PARTITION BY "state" 
            ORDER BY "total_claims" DESC, "drug_name"
        ) AS rn
    FROM aggregated
)
SELECT
    "state",
    "drug_name"          AS "most_prescribed_medication",
    "total_claims"
FROM ranked
WHERE rn = 1
ORDER BY "state";