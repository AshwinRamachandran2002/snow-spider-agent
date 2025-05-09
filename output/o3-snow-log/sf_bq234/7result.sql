/* Most prescribed medication (highest total Part-D claim count) in each state for 2014 */
SELECT
    "state",
    "drug_name",
    "total_claims"
FROM (
    SELECT
        "nppes_provider_state" AS "state",
        "drug_name",
        SUM("total_claim_count") AS "total_claims"
    FROM CMS_DATA.CMS_MEDICARE."PART_D_PRESCRIBER_2014"
    GROUP BY
        "nppes_provider_state",
        "drug_name"
) aggregated
QUALIFY ROW_NUMBER() OVER (PARTITION BY "state" ORDER BY "total_claims" DESC) = 1
ORDER BY
    "state";