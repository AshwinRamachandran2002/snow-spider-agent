/*  Chi-square test for association between histological type and CDH1 mutation
    in TCGA-BRCA patients (PanCancer Atlas)                                       */

WITH brca_clinical AS (          -- 1.  BRCA patients with known histology
    SELECT
        "bcr_patient_barcode"        AS "ParticipantBarcode",
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),

cdh1_mutated AS (                -- 2.  Reliable CDH1 mutation calls (FILTER = 'PASS')
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"        = 'BRCA'
      AND "Hugo_Symbol"  = 'CDH1'
      AND "FILTER"       = 'PASS'
),

status_data AS (                 -- 3.  Mutation status per patient
    SELECT
        c."histological_type",
        CASE
            WHEN m."ParticipantBarcode" IS NOT NULL THEN 'MUTATED'
            ELSE 'WILDTYPE'
        END                                                          AS "mutation_status"
    FROM brca_clinical c
    LEFT JOIN cdh1_mutated m
           ON c."ParticipantBarcode" = m."ParticipantBarcode"
),

counts AS (                      -- 4.  Observed counts
    SELECT
        "histological_type",
        "mutation_status",
        COUNT(*)                                                     AS observed
    FROM status_data
    GROUP BY
        "histological_type",
        "mutation_status"
),

row_totals AS (                  -- 5a. row totals (per histology)
    SELECT
        "histological_type",
        SUM(observed)                                                AS row_total
    FROM counts
    GROUP BY "histological_type"
),

col_totals AS (                  -- 5b. column totals (per mutation status)
    SELECT
        "mutation_status",
        SUM(observed)                                                AS col_total
    FROM counts
    GROUP BY "mutation_status"
),

grand_total AS (                 -- 5c. grand total
    SELECT SUM(observed)                                            AS grand_total
    FROM counts
),

filtered_counts AS (             -- 6.  Exclude sparse rows/cols (totals ≤ 10)
    SELECT
        c."histological_type",
        c."mutation_status",
        c.observed,
        rt.row_total,
        ct.col_total,
        gt.grand_total
    FROM counts            c
    JOIN row_totals        rt ON rt."histological_type" = c."histological_type"
    JOIN col_totals        ct ON ct."mutation_status"    = c."mutation_status"
    CROSS JOIN grand_total gt
    WHERE rt.row_total  > 10         -- keep only sufficiently large marginals
      AND ct.col_total  > 10
),

chi_components AS (              -- 7.  χ² components per cell
    SELECT
        "histological_type",
        "mutation_status",
        observed,
        (row_total * col_total) / CAST(grand_total AS FLOAT)         AS expected,
        POWER(observed - (row_total * col_total) / CAST(grand_total AS FLOAT), 2)
        / ((row_total * col_total) / CAST(grand_total AS FLOAT))     AS chi_sq_component
    FROM filtered_counts
)

-- 8.  Final χ² statistic
SELECT
    SUM(chi_sq_component)                                            AS chi_square_value
FROM chi_components;