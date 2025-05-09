WITH ny_drug_totals AS (      -- total claims for each drug in New York
    SELECT
        "drug_name",
        SUM("total_claim_count") AS "ny_total_claims"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" = 'NY'
    GROUP BY "drug_name"
),
top_ny_drug AS (              -- the single drug with the most NY claims
    SELECT "drug_name"
    FROM ny_drug_totals
    QUALIFY ROW_NUMBER() OVER (ORDER BY "ny_total_claims" DESC) = 1
),
state_totals AS (             -- aggregate claims & cost for that drug by state
    SELECT
        "nppes_provider_state" AS "state",
        SUM("total_claim_count")  AS "total_claims",
        SUM("total_drug_cost")    AS "total_drug_cost"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "drug_name" = (SELECT "drug_name" FROM top_ny_drug)
      AND "nppes_provider_state" IS NOT NULL
    GROUP BY "nppes_provider_state"
)
SELECT
    "state",
    "total_claims",
    "total_drug_cost"
FROM state_totals
ORDER BY "total_claims" DESC NULLS LAST
LIMIT 5;