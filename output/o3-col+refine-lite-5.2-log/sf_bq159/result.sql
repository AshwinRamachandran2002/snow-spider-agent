/*  Chi‑square test of independence
    Histological type  ×  CDH1‑mutation status  (BRCA only)
    – keeps only histology groups with >10 cases
    – keeps only mutation‑status columns with >10 cases
*/
WITH brca_clinical AS (   -- BRCA patients with known histology
    SELECT
        "bcr_patient_barcode"        AS patient,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
cdh1_mutated AS (         -- reliable CDH1 mutations
    SELECT DISTINCT
        "ParticipantBarcode"         AS patient
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"        = 'BRCA'
      AND "Hugo_Symbol"  = 'CDH1'
      AND "FILTER"       = 'PASS'
),
contingency_raw AS (      -- assign mutation status per patient
    SELECT
        c."histological_type",
        CASE WHEN m.patient IS NOT NULL THEN 'Mutated'
             ELSE 'WildType'
        END                               AS mutation_status
    FROM brca_clinical  c
    LEFT JOIN cdh1_mutated m
           ON c.patient = m.patient
),
-- keep histological categories with >10 patients
valid_histology AS (
    SELECT "histological_type"
    FROM   contingency_raw
    GROUP BY "histological_type"
    HAVING COUNT(*) > 10
),
observed AS (             -- observed counts after filtering
    SELECT
        cr."histological_type",
        cr.mutation_status,
        COUNT(*)                      AS observed
    FROM contingency_raw cr
    WHERE cr."histological_type" IN (SELECT "histological_type" FROM valid_histology)
    GROUP BY cr."histological_type", cr.mutation_status
),
stats AS (                -- add row/column/total marginals
    SELECT
        o.*,
        SUM(o.observed) OVER (PARTITION BY o."histological_type") AS row_total,
        SUM(o.observed) OVER (PARTITION BY o.mutation_status)     AS col_total,
        SUM(o.observed) OVER ()                                   AS grand_total
    FROM observed o
),
chi_components AS (       -- expected counts & χ² contribution
    SELECT
        "histological_type",
        mutation_status,
        observed,
        row_total,
        col_total,
        grand_total,
        (row_total * col_total * 1.0) / grand_total                     AS expected,
        POWER(observed - (row_total * col_total * 1.0) / grand_total,2)
        / ((row_total * col_total * 1.0) / grand_total)                 AS chi_part
    FROM stats
    WHERE col_total > 10        -- remove mutation‑status marginals ≤10
)
SELECT
    ROUND(SUM(chi_part),4)       AS "chi_square_value"
FROM chi_components;