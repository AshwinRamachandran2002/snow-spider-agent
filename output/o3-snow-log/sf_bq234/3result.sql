WITH state_drug_totals AS (
    SELECT
        "nppes_provider_state"      AS "state",
        UPPER("drug_name")          AS "drug_name",
        SUM("total_claim_count")    AS "total_prescriptions"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    GROUP BY
        "nppes_provider_state",
        UPPER("drug_name")
),
state_ranked AS (
    SELECT
        "state",
        "drug_name",
        "total_prescriptions",
        RANK() OVER (
            PARTITION BY "state"
            ORDER BY "total_prescriptions" DESC NULLS LAST, "drug_name"
        ) AS "rnk"
    FROM state_drug_totals
)
SELECT
    "state",
    "drug_name",
    "total_prescriptions"
FROM state_ranked
WHERE "rnk" = 1
ORDER BY "state";