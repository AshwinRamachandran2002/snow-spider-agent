WITH brca_clinical AS (   -- all BRCA patients with a recorded histological type
    SELECT DISTINCT
           "bcr_patient_barcode"        AS "ParticipantBarcode",
           "histological_type"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE  "acronym" = 'BRCA'
      AND  "histological_type" IS NOT NULL
),
brca_cdh1_mutated AS (    -- BRCA patients carrying at least one CDH1 mutation
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study"       = 'BRCA'
      AND  "Hugo_Symbol" = 'CDH1'
)
SELECT
    c."histological_type"                                                     AS "Histological_Type",
    COUNT(DISTINCT c."ParticipantBarcode")                                    AS "Total_Patients",
    COUNT(DISTINCT CASE WHEN m."ParticipantBarcode" IS NOT NULL
                        THEN c."ParticipantBarcode" END)                      AS "Mutated_Patients",
    ROUND(
        COUNT(DISTINCT CASE WHEN m."ParticipantBarcode" IS NOT NULL
                            THEN c."ParticipantBarcode" END) * 100.0
        / COUNT(DISTINCT c."ParticipantBarcode"), 4)                          AS "Mutation_Percentage"
FROM   brca_clinical c
LEFT JOIN brca_cdh1_mutated m
       ON c."ParticipantBarcode" = m."ParticipantBarcode"
GROUP BY c."histological_type"
ORDER BY "Mutation_Percentage" DESC NULLS LAST,
         "Histological_Type"
LIMIT 5;