WITH total AS (
  SELECT
      c."histological_type",
      COUNT(DISTINCT c."bcr_patient_barcode")        AS "total_patients"
  FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
  WHERE c."acronym" = 'BRCA'
  GROUP BY c."histological_type"
),
mutant AS (
  SELECT
      c."histological_type",
      COUNT(DISTINCT c."bcr_patient_barcode")        AS "cdh1_mutant_patients"
  FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
  JOIN (
        SELECT DISTINCT m."ParticipantBarcode"
        FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
        WHERE  m."Study"       = 'BRCA'
          AND  m."Hugo_Symbol" = 'CDH1'
          AND  m."FILTER"      = 'PASS'          -- keep only high-confidence calls
       ) cd
       ON cd."ParticipantBarcode" = c."bcr_patient_barcode"
  WHERE c."acronym" = 'BRCA'
  GROUP BY c."histological_type"
)
SELECT
    t."histological_type",
    t."total_patients",
    COALESCE(m."cdh1_mutant_patients", 0)                                                AS "cdh1_mutant_patients",
    ROUND(100.0 * COALESCE(m."cdh1_mutant_patients", 0) / NULLIF(t."total_patients",0), 2) AS "mutation_percentage"
FROM  total t
LEFT JOIN mutant m
       ON t."histological_type" = m."histological_type"
ORDER BY "mutation_percentage" DESC NULLS LAST
LIMIT 5;