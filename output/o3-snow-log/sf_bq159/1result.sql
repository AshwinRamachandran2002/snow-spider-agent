WITH clinical AS (
    SELECT 
        "bcr_patient_barcode" AS participant,
        "histological_type"   AS histological_type     -- give an un-quoted alias
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE 
        "acronym" = 'BRCA'
        AND "histological_type" IS NOT NULL
), 

cdh1_mutated AS (
    SELECT DISTINCT 
        "ParticipantBarcode" AS participant
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE 
        "Study"       = 'BRCA'
        AND "Hugo_Symbol" = 'CDH1'
        AND "FILTER"   = 'PASS'
), 

patient_status AS (
    SELECT 
        c.participant,
        c.histological_type,
        CASE 
            WHEN m.participant IS NOT NULL THEN 'Mutated'
            ELSE 'Wildtype'
        END AS mutation_status
    FROM clinical c
    LEFT JOIN cdh1_mutated m
        ON c.participant = m.participant
), 

counts AS (
    SELECT 
        histological_type,
        mutation_status,
        COUNT(*) AS n
    FROM patient_status
    GROUP BY histological_type, mutation_status
), 

row_tot AS (
    SELECT histological_type, SUM(n) AS row_total
    FROM counts
    GROUP BY histological_type
), 

col_tot AS (
    SELECT mutation_status, SUM(n) AS col_total
    FROM counts
    GROUP BY mutation_status
), 

valid_rows AS (
    SELECT histological_type 
    FROM row_tot 
    WHERE row_total > 10
), 

valid_cols AS (
    SELECT mutation_status 
    FROM col_tot 
    WHERE col_total > 10
), 

filtered_counts AS (
    SELECT c.*
    FROM counts c
    JOIN valid_rows vr  ON c.histological_type = vr.histological_type
    JOIN valid_cols vc  ON c.mutation_status   = vc.mutation_status
), 

filtered_row_tot AS (
    SELECT histological_type, SUM(n) AS row_total
    FROM filtered_counts
    GROUP BY histological_type
), 

filtered_col_tot AS (
    SELECT mutation_status, SUM(n) AS col_total
    FROM filtered_counts
    GROUP BY mutation_status
), 

filtered_grand_tot AS (
    SELECT SUM(n) AS grand_total
    FROM filtered_counts
), 

expected_vs_observed AS (
    SELECT 
        f.histological_type,
        f.mutation_status,
        f.n AS observed,
        (fr.row_total * fc.col_total) / fg.grand_total::FLOAT AS expected
    FROM filtered_counts   f
    JOIN filtered_row_tot  fr ON f.histological_type = fr.histological_type
    JOIN filtered_col_tot  fc ON f.mutation_status   = fc.mutation_status
    CROSS JOIN filtered_grand_tot fg
), 

chi_calc AS (
    SELECT 
        SUM( POWER(observed - expected, 2) / expected ) AS chi_square_value
    FROM expected_vs_observed
)

SELECT chi_square_value
FROM chi_calc;