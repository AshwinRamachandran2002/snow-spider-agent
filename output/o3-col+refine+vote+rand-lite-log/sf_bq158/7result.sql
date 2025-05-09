WITH mut AS (
    SELECT
        c."histological_type",
        COUNT(DISTINCT m."ParticipantBarcode") AS mut_cnt
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"               m
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
          ON m."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE m."Study"        = 'BRCA'
      AND m."Hugo_Symbol"  = 'CDH1'
    GROUP BY c."histological_type"
),
tot AS (
    SELECT
        c."histological_type",
        COUNT(DISTINCT c."bcr_patient_barcode") AS tot_cnt
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    WHERE c."acronym" = 'BRCA'
    GROUP BY c."histological_type"
)
SELECT
    t."histological_type",
    ROUND(100.0 * COALESCE(m.mut_cnt, 0) / t.tot_cnt, 2) AS "cdh1_mutation_percentage"
FROM tot t
LEFT JOIN mut m
       ON t."histological_type" = m."histological_type"
WHERE t.tot_cnt > 0
ORDER BY "cdh1_mutation_percentage" DESC NULLS LAST
LIMIT 5;