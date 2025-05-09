WITH total AS (   -- total BRCA cases per histology
    SELECT
        "histological_type",
        COUNT(DISTINCT "bcr_patient_barcode") AS "total_cases"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
    GROUP BY "histological_type"
),
mutated AS (      -- BRCA cases with a PASS-filtered CDH1 mutation per histology
    SELECT
        c."histological_type",
        COUNT(DISTINCT c."bcr_patient_barcode") AS "cdh1_mut_cases"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    JOIN (
        SELECT DISTINCT "ParticipantBarcode"
        FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
        WHERE "Study" = 'BRCA'
          AND "Hugo_Symbol" = 'CDH1'
          AND "FILTER" = 'PASS'
    ) m
      ON c."bcr_patient_barcode" = m."ParticipantBarcode"
    WHERE c."acronym" = 'BRCA'
    GROUP BY c."histological_type"
)
SELECT
    t."histological_type",
    t."total_cases",
    COALESCE(m."cdh1_mut_cases",0)                       AS "cdh1_mut_cases",
    ROUND(100.0 * COALESCE(m."cdh1_mut_cases",0) 
                 / NULLIF(t."total_cases",0), 2)         AS "cdh1_mut_pct"
FROM total t
LEFT JOIN mutated m
       ON t."histological_type" = m."histological_type"
ORDER BY "cdh1_mut_pct" DESC NULLS LAST
LIMIT 5;