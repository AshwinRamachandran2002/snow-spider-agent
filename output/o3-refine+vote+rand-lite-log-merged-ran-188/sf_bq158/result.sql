WITH brca_clinical AS (
    SELECT
        "bcr_patient_barcode"              AS patient_id,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
total_per_type AS (
    SELECT
        "histological_type",
        COUNT(DISTINCT patient_id) AS total_patients
    FROM brca_clinical
    GROUP BY "histological_type"
),
cdh1_mutated_patients AS (
    SELECT DISTINCT
        "ParticipantBarcode" AS patient_id
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
),
mutated_per_type AS (
    SELECT
        bc."histological_type",
        COUNT(DISTINCT bc.patient_id) AS mutated_patients
    FROM brca_clinical bc
    JOIN cdh1_mutated_patients mp
      ON bc.patient_id = mp.patient_id
    GROUP BY bc."histological_type"
),
percent_table AS (
    SELECT
        t."histological_type",
        COALESCE(m.mutated_patients, 0)            AS mutated_patients,
        t.total_patients,
        (COALESCE(m.mutated_patients, 0) * 100.0) 
          / t.total_patients                       AS mutation_percentage
    FROM total_per_type t
    LEFT JOIN mutated_per_type m
      ON t."histological_type" = m."histological_type"
)
SELECT
    "histological_type",
    mutated_patients,
    total_patients,
    ROUND(mutation_percentage, 4) AS mutation_percentage
FROM percent_table
ORDER BY mutation_percentage DESC NULLS LAST,
         "histological_type"
LIMIT 5;