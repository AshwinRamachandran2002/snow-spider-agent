WITH mutated_patients AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER"      = 'PASS'
),
base AS (
    SELECT  c."bcr_patient_barcode" AS patient_id,
            c."histological_type",
            CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS is_mut
    FROM  "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    LEFT JOIN mutated_patients m
           ON m."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE c."acronym" = 'BRCA'
      AND c."histological_type" IS NOT NULL
),
eligible_histos AS (   -- keep only histology groups with >10 patients
    SELECT "histological_type"
    FROM   base
    GROUP  BY "histological_type"
    HAVING COUNT(*) > 10
),
eligible AS (
    SELECT *
    FROM   base
    WHERE  "histological_type" IN (SELECT "histological_type" FROM eligible_histos)
),
cont AS (              -- observed counts
    SELECT  "histological_type",
            SUM(is_mut)            AS mutated,
            COUNT(*) - SUM(is_mut) AS wildtype
    FROM    eligible
    GROUP BY "histological_type"
),
totals AS (            -- marginal totals
    SELECT  SUM(mutated)               AS total_mutated,
            SUM(wildtype)              AS total_wildtype,
            SUM(mutated+wildtype)      AS grand_total
    FROM    cont
),
chi_components AS (
    SELECT
        SUM(
              POWER(mutated - ((mutated+wildtype)*total_mutated/grand_total), 2)
              / ((mutated+wildtype)*total_mutated/grand_total)
            + POWER(wildtype - ((mutated+wildtype)*total_wildtype/grand_total), 2)
              / ((mutated+wildtype)*total_wildtype/grand_total)
        ) AS chi_square_value
    FROM cont, totals
)
SELECT ROUND(chi_square_value, 4) AS chi_square_value
FROM   chi_components;