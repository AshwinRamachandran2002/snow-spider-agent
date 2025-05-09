WITH
/* ---------------- 1.  Clinical BRCA cohort with known histology ---------------- */
clinical_brca AS (
    SELECT
        "bcr_patient_barcode"                AS participant_id,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
      AND "histological_type" NOT IN ('[Not Applicable]', '[Unknown]', 'Unknown')
),

/* ---------------- 2.  Reliable CDH1‑mutation carriers ---------------- */
cdh1_mutated AS (
    SELECT DISTINCT
        "ParticipantBarcode"                 AS participant_id
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
),

/* ---------------- 3.  Assign mutation status per patient ---------------- */
histology_status AS (
    SELECT
        c."histological_type",
        CASE
            WHEN m.participant_id IS NOT NULL THEN 'Mutated'
            ELSE 'Wildtype'
        END                                   AS mutation_status
    FROM clinical_brca c
    LEFT JOIN cdh1_mutated m
           ON c.participant_id = m.participant_id
),

/* ---------------- 4.  Raw contingency counts ---------------- */
raw_counts AS (
    SELECT
        "histological_type",
        mutation_status,
        COUNT(*)                              AS n
    FROM histology_status
    GROUP BY "histological_type", mutation_status
),

/* ---------------- 5.  Marginal totals ---------------- */
row_totals AS (
    SELECT "histological_type", SUM(n) AS row_total
    FROM raw_counts
    GROUP BY "histological_type"
),
col_totals AS (
    SELECT mutation_status, SUM(n) AS col_total
    FROM raw_counts
    GROUP BY mutation_status
),

/* ---------------- 6.  Exclude strata with marginal totals ≤ 10 ---------------- */
filtered_counts AS (
    SELECT rc.*
    FROM raw_counts        rc
    JOIN row_totals        rt ON rc."histological_type" = rt."histological_type"
    JOIN col_totals        ct ON rc.mutation_status     = ct.mutation_status
    WHERE rt.row_total > 10
      AND ct.col_total > 10
),

/* Recompute margins after filtering */
f_row_totals AS (
    SELECT "histological_type", SUM(n) AS row_total
    FROM filtered_counts
    GROUP BY "histological_type"
),
f_col_totals AS (
    SELECT mutation_status, SUM(n) AS col_total
    FROM filtered_counts
    GROUP BY mutation_status
),
f_grand_total AS (
    SELECT SUM(n) AS grand_total FROM filtered_counts
),

/* ---------------- 7.  Chi‑square components ---------------- */
chi_components AS (
    SELECT
        fc."histological_type",
        fc.mutation_status,
        fc.n,
        (frt.row_total * fct.col_total) / fgt.grand_total                         AS expected,
        POWER(fc.n - (frt.row_total * fct.col_total) / fgt.grand_total, 2)
        / ((frt.row_total * fct.col_total) / fgt.grand_total)                     AS chi_component
    FROM filtered_counts fc
    JOIN f_row_totals  frt ON fc."histological_type" = frt."histological_type"
    JOIN f_col_totals  fct ON fc.mutation_status     = fct.mutation_status
    CROSS JOIN f_grand_total fgt
),

/* ---------------- 8.  Aggregate Chi‑square statistic ---------------- */
chi_square AS (
    SELECT SUM(chi_component) AS chi_square_value
    FROM   chi_components
)

SELECT chi_square_value
FROM   chi_square;