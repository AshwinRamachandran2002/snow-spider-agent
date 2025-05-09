WITH clinical AS (   -- BRCA patients with a known histological type
    SELECT DISTINCT
        "bcr_patient_barcode"          AS patient,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
cdh1_mutated AS (    -- reliable CDH1 mutations (PASS‑only) in BRCA
    SELECT DISTINCT
        "ParticipantBarcode"           AS patient
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
),
patient_status AS (  -- attach mutation status to every patient
    SELECT
        c.patient,
        c."histological_type",
        CASE WHEN m.patient IS NOT NULL THEN 'Mutated' ELSE 'Not_Mutated' END AS mutation_status
    FROM clinical  c
    LEFT JOIN cdh1_mutated m
           ON c.patient = m.patient
),
cell_counts AS (     -- contingency‑table cells
    SELECT
        "histological_type",
        mutation_status,
        COUNT(*)                          AS obs
    FROM patient_status
    GROUP BY
        "histological_type",
        mutation_status
),
row_totals AS (
    SELECT "histological_type", SUM(obs) AS row_total
    FROM   cell_counts
    GROUP BY "histological_type"
),
col_totals AS (
    SELECT mutation_status, SUM(obs)     AS col_total
    FROM   cell_counts
    GROUP BY mutation_status
),
total_n AS (
    SELECT SUM(row_total) AS N FROM row_totals
),
filtered_cells AS (  -- keep rows / cols with marginal totals > 10
    SELECT
        cc."histological_type",
        cc.mutation_status,
        cc.obs,
        rt.row_total,
        ct.col_total,
        tn.N
    FROM cell_counts  cc
    JOIN row_totals   rt ON cc."histological_type" = rt."histological_type"
    JOIN col_totals   ct ON cc.mutation_status     = ct.mutation_status
    CROSS JOIN total_n tn
    WHERE rt.row_total > 10
      AND ct.col_total > 10
),
chi_components AS (  -- (O‑E)^2 / E for every retained cell
    SELECT
        obs,
        (row_total * col_total) / N                         AS expected,
        POWER(obs - (row_total * col_total) / N, 2)
        / NULLIF((row_total * col_total) / N, 0)            AS chi_piece
    FROM filtered_cells
)
SELECT
    ROUND(SUM(chi_piece), 4)  AS chi_square_value
FROM chi_components;