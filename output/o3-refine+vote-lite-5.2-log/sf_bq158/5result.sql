WITH brca_clinical AS (
    /* all BRCA patients with a recorded histological type */
    SELECT
        "bcr_patient_barcode"      AS patient_barcode,
        "histological_type"
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE
        "acronym" = 'BRCA'
        AND "histological_type" IS NOT NULL
),
cdh1_mutated_patients AS (
    /* BRCA patients who carry at least one PASS‑filtered CDH1 mutation */
    SELECT DISTINCT
        "ParticipantBarcode" AS patient_barcode
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE
        "Study" = 'BRCA'
        AND "Hugo_Symbol" = 'CDH1'
        AND "FILTER" = 'PASS'
),
histology_mut_flag AS (
    /* flag each patient as mutated or not */
    SELECT
        c."histological_type",
        CASE WHEN m.patient_barcode IS NOT NULL THEN 1 ELSE 0 END AS is_mutated
    FROM
        brca_clinical c
        LEFT JOIN cdh1_mutated_patients m
               ON c.patient_barcode = m.patient_barcode
)
SELECT
    "histological_type"                            AS histological_type,
    COUNT(*)                                       AS total_patients,
    SUM(is_mutated)                                AS mutated_patients,
    (SUM(is_mutated) * 100.0) / COUNT(*) AS mutation_percentage
FROM
    histology_mut_flag
GROUP BY
    "histological_type"
ORDER BY
    mutation_percentage DESC NULLS LAST,
    "histological_type"
LIMIT 5;