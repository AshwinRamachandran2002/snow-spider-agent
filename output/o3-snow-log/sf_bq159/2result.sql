WITH clinical_brca AS (
    -- BRCA patients with known histological type
    SELECT 
        "bcr_patient_barcode"        AS participant,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE 
          "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
mutated_patients AS (
    -- Reliable CDH1 mutations (FILTER = 'PASS')
    SELECT DISTINCT
        "ParticipantBarcode" AS participant
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE 
          "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
),
clinical_with_status AS (
    -- Add mutation-status flag to clinical data
    SELECT
        c.participant,
        c."histological_type",
        CASE 
            WHEN m.participant IS NOT NULL THEN 'Mutated' 
            ELSE 'Not_Mutated' 
        END                         AS mutation_status
    FROM clinical_brca c
    LEFT JOIN mutated_patients m
           ON c.participant = m.participant
),
obs_table AS (
    -- Observed counts
    SELECT
        "histological_type",
        mutation_status,
        COUNT(*) AS n
    FROM clinical_with_status
    GROUP BY
        "histological_type",
        mutation_status
),
row_totals AS (
    SELECT "histological_type",
           SUM(n) AS row_total
    FROM obs_table
    GROUP BY "histological_type"
    HAVING SUM(n) > 10          -- keep histological types with >10 patients
),
col_totals AS (
    SELECT mutation_status,
           SUM(n) AS col_total
    FROM obs_table
    GROUP BY mutation_status
    HAVING SUM(n) > 10          -- keep mutation categories with >10 patients
),
filtered_obs AS (
    -- Observed counts after marginal-total filters
    SELECT o."histological_type",
           o.mutation_status,
           o.n
    FROM obs_table o
    JOIN row_totals r
      ON o."histological_type" = r."histological_type"
    JOIN col_totals c
      ON o.mutation_status     = c.mutation_status
),
grand_total AS (
    SELECT SUM(n) AS grand_total
    FROM filtered_obs
),
expected_tbl AS (
    -- Expected counts under independence
    SELECT
        f."histological_type",
        f.mutation_status,
        f.n                                        AS observed,
        (r.row_total * c.col_total) / gt.grand_total::FLOAT AS expected
    FROM filtered_obs f
    JOIN row_totals r
      ON f."histological_type" = r."histological_type"
    JOIN col_totals c
      ON f.mutation_status     = c.mutation_status
    CROSS JOIN grand_total gt
),
chi_square_calc AS (
    SELECT 
        SUM( POWER(observed - expected, 2) / expected ) AS chi_square_value
    FROM expected_tbl
)
SELECT chi_square_value
FROM chi_square_calc;