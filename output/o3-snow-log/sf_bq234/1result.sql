/*  Most prescribed (highest total claim count) medication in each U.S. state for 2014  */
WITH state_drug_totals AS (
    SELECT
        "nppes_provider_state"                  AS state ,
        "drug_name"                             AS medication ,
        SUM("total_claim_count")                AS total_prescriptions
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" IS NOT NULL      -- keep rows with a state value
    GROUP BY
        state ,
        medication
),
ranked AS (
    SELECT
        state ,
        medication ,
        total_prescriptions ,
        ROW_NUMBER() OVER (PARTITION BY state
                           ORDER BY total_prescriptions DESC NULLS LAST , medication)  AS rn
    FROM state_drug_totals
)
SELECT
    state ,
    medication            AS most_prescribed_medication ,
    total_prescriptions
FROM ranked
WHERE rn = 1                     -- highest-volume medication per state
ORDER BY state;