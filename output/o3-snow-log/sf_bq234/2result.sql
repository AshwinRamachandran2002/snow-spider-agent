WITH state_drug_totals AS (
    SELECT
        "nppes_provider_state"       AS "state",
        "drug_name",
        SUM("total_claim_count")     AS "total_prescriptions"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    GROUP BY
        "nppes_provider_state",
        "drug_name"
)
SELECT
    "state",
    "drug_name"                     AS "most_prescribed_medication",
    "total_prescriptions"
FROM state_drug_totals
QUALIFY
    ROW_NUMBER() OVER (
        PARTITION BY "state"
        ORDER BY "total_prescriptions" DESC NULLS LAST,
                 "drug_name"           ASC
    ) = 1
ORDER BY
    "state";