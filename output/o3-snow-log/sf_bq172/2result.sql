WITH ny_drug_counts AS (          -- 1.  Find total claims for each drug in NY
    SELECT
        "drug_name",
        SUM(COALESCE("total_claim_count",0)) AS "ny_total_claims"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014
    WHERE "nppes_provider_state" = 'NY'
    GROUP BY "drug_name"
),

top_ny_drug AS (                  -- 2.  Pick the single drug with the most NY claims
    SELECT
        "drug_name"
    FROM ny_drug_counts
    ORDER BY "ny_total_claims" DESC NULLS LAST
    LIMIT 1
),

drug_state_totals AS (            -- 3.  Aggregate that drug’s stats for every state
    SELECT
        p."nppes_provider_state"          AS "state",
        SUM(COALESCE(p."total_claim_count",0)) AS "total_claims",
        SUM(COALESCE(p."total_drug_cost",0))   AS "total_drug_cost"
    FROM CMS_DATA.CMS_MEDICARE.PART_D_PRESCRIBER_2014 p
    JOIN top_ny_drug d
      ON p."drug_name" = d."drug_name"
    WHERE p."nppes_provider_state" IS NOT NULL
    GROUP BY p."nppes_provider_state"
)

-- 4.  Return the five states with the highest claim counts for that drug
SELECT
    "state",
    "total_claims",
    "total_drug_cost"
FROM drug_state_totals
ORDER BY "total_claims" DESC NULLS LAST
LIMIT 5;