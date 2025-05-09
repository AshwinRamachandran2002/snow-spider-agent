WITH clinical AS (
    SELECT DISTINCT
           "bcr_patient_barcode"      AS "ParticipantBarcode",
           "histological_type"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE  "acronym" = 'BRCA'                     -- BRCA study only
       AND "histological_type" IS NOT NULL        -- known histology
),
cdh1_mut AS (
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study"        = 'BRCA'                -- BRCA study only
       AND "Hugo_Symbol"  = 'CDH1'                -- gene of interest
       AND "FILTER"       = 'PASS'                -- reliable calls
),
patient_status AS (                                -- mark mutation presence/absence
    SELECT
           c."histological_type",
           CASE WHEN m."ParticipantBarcode" IS NULL
                    THEN 'WildType'
                ELSE 'Mutated'
           END                                   AS "MutationStatus"
    FROM   clinical c
    LEFT JOIN cdh1_mut m
           ON c."ParticipantBarcode" = m."ParticipantBarcode"
),
observed AS (                                     -- contingency counts
    SELECT
           "histological_type",
           "MutationStatus",
           COUNT(*)                              AS "obs_count"
    FROM   patient_status
    GROUP BY
           "histological_type",
           "MutationStatus"
),
row_totals AS (
    SELECT "histological_type",
           SUM("obs_count") AS "row_total"
    FROM   observed
    GROUP BY "histological_type"
),
col_totals AS (
    SELECT "MutationStatus",
           SUM("obs_count") AS "col_total"
    FROM   observed
    GROUP BY "MutationStatus"
),
grand_total AS (
    SELECT SUM("obs_count") AS "grand_total"
    FROM   observed
),
filtered_obs AS (                                 -- exclude marginal totals ≤10
    SELECT o.*
    FROM   observed        o
    JOIN   row_totals      r ON o."histological_type" = r."histological_type"  AND r."row_total"  > 10
    JOIN   col_totals      c ON o."MutationStatus"    = c."MutationStatus"     AND c."col_total"  > 10
),
row_totals2 AS (
    SELECT "histological_type",
           SUM("obs_count") AS "row_total"
    FROM   filtered_obs
    GROUP BY "histological_type"
),
col_totals2 AS (
    SELECT "MutationStatus",
           SUM("obs_count") AS "col_total"
    FROM   filtered_obs
    GROUP BY "MutationStatus"
),
grand_total2 AS (
    SELECT SUM("obs_count") AS "grand_total"
    FROM   filtered_obs
),
expected AS (                                     -- expected counts per cell
    SELECT
           f."histological_type",
           f."MutationStatus",
           f."obs_count",
           (r."row_total" * c."col_total") / g."grand_total" AS "exp_count"
    FROM   filtered_obs f
    JOIN   row_totals2  r ON f."histological_type" = r."histological_type"
    JOIN   col_totals2  c ON f."MutationStatus"    = c."MutationStatus"
    CROSS JOIN grand_total2 g
),
chi_square_calc AS (                               -- χ² statistic
    SELECT SUM( POWER(("obs_count" - "exp_count"), 2) / NULLIF("exp_count",0) )
           AS "chi_square_value"
    FROM   expected
)
SELECT "chi_square_value"
FROM   chi_square_calc;