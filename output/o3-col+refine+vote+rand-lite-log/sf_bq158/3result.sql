WITH total AS (
    SELECT 
        "histological_type",
        COUNT(DISTINCT "bcr_patient_barcode") AS n_total
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
    GROUP BY "histological_type"
),
mut AS (
    SELECT 
        c."histological_type",
        COUNT(DISTINCT m."ParticipantBarcode") AS n_mut
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"  c
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"                m
      ON c."bcr_patient_barcode" = m."ParticipantBarcode"
    WHERE c."acronym" = 'BRCA'
      AND m."Hugo_Symbol" = 'CDH1'
    GROUP BY c."histological_type"
)
SELECT
    t."histological_type"                    AS "Histological_Type",
    t.n_total                                AS "Total_BRCA_Patients",
    COALESCE(m.n_mut, 0)                     AS "CDH1_Mutant_Patients",
    ROUND(COALESCE(m.n_mut, 0) * 100.0 / NULLIF(t.n_total, 0), 2) 
                                             AS "Percent_CDH1_Mutated"
FROM total t
LEFT JOIN mut m
       ON t."histological_type" = m."histological_type"
ORDER BY "Percent_CDH1_Mutated" DESC NULLS LAST,
         "Total_BRCA_Patients" DESC
LIMIT 5;