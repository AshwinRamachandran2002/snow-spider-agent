WITH paad_patients AS (
    /* All pancreatic adenocarcinoma patients in TCGA clinical data */
    SELECT DISTINCT "bcr_patient_barcode" AS "PatientBarcode"
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE "acronym" = 'PAAD'
),
gene_mutations AS (
    /* KRAS or TP53 mutations that passed quality filters in PAAD samples */
    SELECT DISTINCT 
           "ParticipantBarcode" AS "PatientBarcode",
           "Hugo_Symbol"
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"  = 'PAAD'
      AND "FILTER" = 'PASS'
      AND "Hugo_Symbol" IN ('KRAS','TP53')
),
mutation_flags AS (
    /* Flag each patient for presence of KRAS and/or TP53 mutations */
    SELECT
        p."PatientBarcode",
        MAX(CASE WHEN g."Hugo_Symbol" = 'KRAS' THEN 1 ELSE 0 END)  AS "has_KRAS",
        MAX(CASE WHEN g."Hugo_Symbol" = 'TP53' THEN 1 ELSE 0 END)  AS "has_TP53"
    FROM paad_patients p
    LEFT JOIN gene_mutations g
           ON p."PatientBarcode" = g."PatientBarcode"
    GROUP BY p."PatientBarcode"
),
patient_counts AS (
    /* Count patients with both mutations vs. with neither mutation */
    SELECT
        SUM(CASE WHEN "has_KRAS" = 1 AND "has_TP53" = 1 THEN 1 ELSE 0 END) AS both_mutated,
        SUM(CASE WHEN "has_KRAS" = 0 AND "has_TP53" = 0 THEN 1 ELSE 0 END) AS neither_mutated
    FROM mutation_flags
)
SELECT 
    both_mutated - neither_mutated AS net_difference
FROM patient_counts;