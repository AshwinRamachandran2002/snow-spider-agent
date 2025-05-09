WITH brca_patients AS (   -- all BRCA cases with a reported histological type
    SELECT DISTINCT 
           "bcr_patient_barcode"   AS "ParticipantBarcode",
           "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
cdh1_mutated AS (         -- BRCA cases harboring at least one PASSed CDH1 mutation
    SELECT DISTINCT 
           "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"        = 'BRCA'
      AND "Hugo_Symbol"  = 'CDH1'
      AND "FILTER"       = 'PASS'
)
SELECT 
       bp."histological_type",
       SUM(CASE WHEN cm."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END) AS "cdh1_mutation_count",
       COUNT(*)                                                         AS "total_patients",
       ROUND(
           100.0 * SUM(CASE WHEN cm."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END)
                 / COUNT(*),
           4
       ) AS "mutation_percentage"
FROM brca_patients bp
LEFT JOIN cdh1_mutated cm
       ON bp."ParticipantBarcode" = cm."ParticipantBarcode"
GROUP BY bp."histological_type"
ORDER BY "mutation_percentage" DESC NULLS LAST, bp."histological_type"
LIMIT 5;