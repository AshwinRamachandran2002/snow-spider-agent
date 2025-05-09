WITH ny_drug_totals AS (
    /* 1.  Aggregate claim counts by drug for prescribers located in New York */
    SELECT
        "drug_name",
        SUM("total_claim_count") AS total_claims_ny
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" = 'NY'
    GROUP BY "drug_name"
), top_drug AS (
    /* 2.  Identify the single drug with the highest number of NY prescriptions */
    SELECT
        "drug_name"
    FROM ny_drug_totals
    ORDER BY total_claims_ny DESC NULLS LAST
    LIMIT 1
), state_level_totals AS (
    /* 3.  For that drug, compute state-level totals across the U.S. */
    SELECT
        p."nppes_provider_state"      AS state,
        SUM(p."total_claim_count")    AS total_claims,
        SUM(p."total_drug_cost")      AS total_drug_cost
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014 p
    JOIN top_drug d
      ON p."drug_name" = d."drug_name"
    GROUP BY
        p."nppes_provider_state"
)
SELECT
    state,
    total_claims,
    total_drug_cost
FROM state_level_totals
ORDER BY total_claims DESC NULLS LAST
LIMIT 5;