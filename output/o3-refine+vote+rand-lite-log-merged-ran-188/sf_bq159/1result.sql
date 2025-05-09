/*-----------------------------------------------------------
  Chi–square test of independence between histological type
  and CDH1‑mutation status in TCGA‑BRCA patients
-----------------------------------------------------------*/
WITH
/* ---------- 1.  Clinical BRCA cases with a known histology ---------- */
clinical AS (
    SELECT
        "bcr_patient_barcode"                 AS patient_barcode,
        "histological_type"  AS histological_type          -- give an un‑quoted alias
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),

/* ---------- 2.  Patients carrying a reliable CDH1 mutation ---------- */
mutated AS (
    SELECT DISTINCT
        "ParticipantBarcode" AS patient_barcode
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER"      = 'PASS'      -- reliable calls only
),

/* ---------- 3.  Combine clinical & mutation data ---------- */
combined AS (
    SELECT
        c.patient_barcode,
        c.histological_type,
        CASE WHEN m.patient_barcode IS NOT NULL
             THEN 'MUTATED'
             ELSE 'WILD_TYPE'
        END AS mutation_status
    FROM clinical c
    LEFT JOIN mutated m
           ON c.patient_barcode = m.patient_barcode
),

/* ---------- 4.  Raw cross‑tabulation counts ---------- */
raw_counts AS (
    SELECT
        histological_type,
        mutation_status,
        COUNT(*) AS n
    FROM combined
    GROUP BY histological_type, mutation_status
),

/* ---------- 5.  Marginal totals ---------- */
row_totals AS (
    SELECT histological_type, SUM(n) AS row_total
    FROM raw_counts
    GROUP BY histological_type
),
col_totals AS (
    SELECT mutation_status, SUM(n) AS col_total
    FROM raw_counts
    GROUP BY mutation_status
),

/* ---------- 6.  Keep histologies & statuses with marginal total > 10 ---------- */
valid_hist AS (
    SELECT histological_type
    FROM row_totals
    WHERE row_total > 10
),
valid_stat AS (
    SELECT mutation_status
    FROM col_totals
    WHERE col_total > 10
),

/* ---------- 7.  All combinations of retained factors ---------- */
grid AS (
    SELECT
        h.histological_type,
        s.mutation_status
    FROM valid_hist h
    CROSS JOIN valid_stat s
),

/* ---------- 8.  Observed counts on the restricted grid ---------- */
obs AS (
    SELECT
        g.histological_type,
        g.mutation_status,
        COALESCE(rc.n, 0) AS observed
    FROM grid g
    LEFT JOIN raw_counts rc
           ON  rc.histological_type = g.histological_type
           AND rc.mutation_status   = g.mutation_status
),

/* ---------- 9.  Marginals & grand total for filtered table ---------- */
row_tot AS (
    SELECT histological_type, SUM(observed) AS row_total
    FROM obs
    GROUP BY histological_type
),
col_tot AS (
    SELECT mutation_status, SUM(observed) AS col_total
    FROM obs
    GROUP BY mutation_status
),
grand_tot AS (
    SELECT SUM(observed) AS gt FROM obs
),

/* ----------10. Expected counts & χ² components ---------- */
expected AS (
    SELECT
        o.histological_type,
        o.mutation_status,
        o.observed,
        (r.row_total * c.col_total) / gt.gt AS expected
    FROM obs o
    JOIN row_tot r USING (histological_type)
    JOIN col_tot c USING (mutation_status)
    CROSS JOIN grand_tot gt
),

/* ----------11.  Chi‑square statistic ---------- */
chi_sq AS (
    SELECT
        SUM( POWER(observed - expected, 2) / expected ) AS chi_square_value
    FROM expected
)

SELECT chi_square_value
FROM   chi_sq;