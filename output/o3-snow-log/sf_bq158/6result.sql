WITH
-- all BRCA participants with a reported histological type
BRCA_CLINICAL AS (
    SELECT DISTINCT
        "bcr_patient_barcode" AS participant_id,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE
        "acronym" = 'BRCA'
        AND "histological_type" IS NOT NULL
),

-- BRCA participants who harbor at least one CDH1 mutation
CDH1_MUTATED AS (
    SELECT DISTINCT
        "ParticipantBarcode" AS participant_id
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE
        "Study" = 'BRCA'
        AND "Hugo_Symbol" = 'CDH1'
        AND "FILTER" = 'PASS'          -- keep only high-confidence calls
)

SELECT
    bc."histological_type",
    COUNT(DISTINCT bc.participant_id)                                          AS "total_participants",
    COUNT(DISTINCT CASE WHEN cm.participant_id IS NOT NULL THEN bc.participant_id END)
                                                                                AS "cdh1_mutated_participants",
    100.0 * COUNT(DISTINCT CASE WHEN cm.participant_id IS NOT NULL THEN bc.participant_id END)
         / COUNT(DISTINCT bc.participant_id)                                   AS "percent_cdh1_mutated"
FROM BRCA_CLINICAL bc
LEFT JOIN CDH1_MUTATED cm
       ON bc.participant_id = cm.participant_id
GROUP BY bc."histological_type"
ORDER BY "percent_cdh1_mutated" DESC NULLS LAST
LIMIT 5;