WITH total AS (  -- total number of BRCA patients per histological type
    SELECT 
        c."histological_type",
        COUNT(DISTINCT c."bcr_patient_barcode") AS "total_patients"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    WHERE c."acronym" = 'BRCA'
    GROUP BY c."histological_type"
),
mutant AS (      -- BRCA patients carrying a CDH1 mutation per histological type
    SELECT 
        c."histological_type",
        COUNT(DISTINCT m."ParticipantBarcode") AS "mutant_patients"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
          ON m."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE m."Study" = 'BRCA'
      AND m."Hugo_Symbol" = 'CDH1'
    GROUP BY c."histological_type"
)
SELECT
    t."histological_type",
    t."total_patients",
    COALESCE(m."mutant_patients", 0)                                    AS "cdh1_mutant_patients",
    ROUND(100.0 * COALESCE(m."mutant_patients", 0) / NULLIF(t."total_patients", 0), 2)
                                                                         AS "cdh1_mutation_percentage"
FROM total t
LEFT JOIN mutant m
       ON t."histological_type" = m."histological_type"
ORDER BY "cdh1_mutation_percentage" DESC NULLS LAST
LIMIT 5;