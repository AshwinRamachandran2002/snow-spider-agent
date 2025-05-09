WITH total_cases AS (
    SELECT 
        c."histological_type",
        COUNT(DISTINCT c."bcr_patient_barcode") AS "total_cases"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    WHERE c."acronym" = 'BRCA'
    GROUP BY c."histological_type"
),  
cdh1_mutants AS (
    SELECT 
        c."histological_type",
        COUNT(DISTINCT m."ParticipantBarcode") AS "cdh1_mutant_cases"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
          ON c."bcr_patient_barcode" = m."ParticipantBarcode"
    WHERE m."Study" = 'BRCA'
      AND m."Hugo_Symbol" = 'CDH1'
    GROUP BY c."histological_type"
)
SELECT 
    t."histological_type",
    t."total_cases",
    COALESCE(m."cdh1_mutant_cases", 0) AS "cdh1_mutant_cases",
    ROUND(100.0 * COALESCE(m."cdh1_mutant_cases", 0) / NULLIF(t."total_cases", 0), 2) AS "mutation_percent"
FROM total_cases t
LEFT JOIN cdh1_mutants m
       ON t."histological_type" = m."histological_type"
ORDER BY "mutation_percent" DESC NULLS LAST
LIMIT 5;