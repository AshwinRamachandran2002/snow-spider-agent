WITH clinical_patients AS (
    SELECT DISTINCT bcr_patient_barcode
    FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
    WHERE LOWER(acronym) = 'paad'
),
mutations AS (
    SELECT
        m.ParticipantBarcode,
        MAX(CASE WHEN LOWER(m.Hugo_Symbol) = 'kras' THEN 1 ELSE 0 END) AS has_kras,
        MAX(CASE WHEN LOWER(m.Hugo_Symbol) = 'tp53' THEN 1 ELSE 0 END) AS has_tp53
    FROM
        `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample` AS m
    INNER JOIN
        clinical_patients AS c
    ON
        m.ParticipantBarcode = c.bcr_patient_barcode
    WHERE
        LOWER(m.Study) = 'paad'
        AND m.FILTER = 'PASS'
    GROUP BY
        m.ParticipantBarcode
),
contingency AS (
    SELECT
        SUM(CASE WHEN has_kras = 1 AND has_tp53 = 1 THEN 1 ELSE 0 END) AS both_mutated,
        SUM(CASE WHEN has_kras = 1 AND has_tp53 = 0 THEN 1 ELSE 0 END) AS kras_only,
        SUM(CASE WHEN has_kras = 0 AND has_tp53 = 1 THEN 1 ELSE 0 END) AS tp53_only,
        SUM(CASE WHEN has_kras = 0 AND has_tp53 = 0 THEN 1 ELSE 0 END) AS neither_mutated
    FROM
        mutations
),
calculations AS (
    SELECT
        both_mutated,
        kras_only,
        tp53_only,
        neither_mutated,
        (both_mutated + kras_only) AS row1_total,
        (tp53_only + neither_mutated) AS row2_total,
        (both_mutated + tp53_only) AS col1_total,
        (kras_only + neither_mutated) AS col2_total,
        (both_mutated + kras_only + tp53_only + neither_mutated) AS grand_total
    FROM
        contingency
),
chi_squared_components AS (
    SELECT
        (both_mutated - ((row1_total * col1_total) / grand_total)) * (both_mutated - ((row1_total * col1_total) / grand_total)) / ((row1_total * col1_total) / grand_total) AS chi_both_mutated,
        (kras_only - ((row1_total * col2_total) / grand_total)) * (kras_only - ((row1_total * col2_total) / grand_total)) / ((row1_total * col2_total) / grand_total) AS chi_kras_only,
        (tp53_only - ((row2_total * col1_total) / grand_total)) * (tp53_only - ((row2_total * col1_total) / grand_total)) / ((row2_total * col1_total) / grand_total) AS chi_tp53_only,
        (neither_mutated - ((row2_total * col2_total) / grand_total)) * (neither_mutated - ((row2_total * col2_total) / grand_total)) / ((row2_total * col2_total) / grand_total) AS chi_neither_mutated
    FROM
        calculations
),
result AS (
    SELECT
        (chi_both_mutated + chi_kras_only + chi_tp53_only + chi_neither_mutated) AS chi_squared_value
    FROM
        chi_squared_components
)
SELECT ROUND(chi_squared_value, 4) AS chi_squared_value
FROM result