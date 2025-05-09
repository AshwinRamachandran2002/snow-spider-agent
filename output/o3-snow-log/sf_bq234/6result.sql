WITH state_drug_totals AS (
    SELECT
        "nppes_provider_state"  AS state,
        "drug_name",
        SUM("total_claim_count") AS total_prescriptions
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" IS NOT NULL
    GROUP BY
        state,
        "drug_name"
),
ranked AS (
    SELECT
        state,
        "drug_name",
        total_prescriptions,
        ROW_NUMBER() OVER (
            PARTITION BY state
            ORDER BY total_prescriptions DESC NULLS LAST, "drug_name"
        ) AS rn
    FROM state_drug_totals
)
SELECT
    state,
    "drug_name"          AS most_prescribed_medication,
    total_prescriptions  AS prescription_count
FROM ranked
WHERE rn = 1
ORDER BY state;