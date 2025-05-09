WITH clinical_braca AS (
    /*  All BRCA patients with available histological type  */
    SELECT
        "patient_id"                    AS patient_id,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE
        "acronym" = 'BRCA'
        AND "histological_type" IS NOT NULL
), cdh1_mutated AS (
    /*  Unique BRCA patients whose tumors carry a PASS‑filtered CDH1 mutation  */
    SELECT DISTINCT
        "ParticipantBarcode"            AS patient_id
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE
        "Study"        = 'BRCA'
        AND "Hugo_Symbol" = 'CDH1'
        AND "FILTER"      = 'PASS'
)
SELECT
    cb."histological_type"                                               AS "histological_type",
    COUNT(CASE WHEN cm.patient_id IS NOT NULL THEN 1 END)                AS "cdh1_mutated_patients",
    COUNT(*)                                                             AS "total_patients",
    ROUND(
        100.0 * COUNT(CASE WHEN cm.patient_id IS NOT NULL THEN 1 END)
        / NULLIF(COUNT(*), 0)
    , 4)                                                                 AS "cdh1_mutation_percentage"
FROM clinical_braca cb
LEFT JOIN cdh1_mutated cm
       ON cb.patient_id = cm.patient_id
GROUP BY cb."histological_type"
ORDER BY "cdh1_mutation_percentage" DESC NULLS LAST,
         "histological_type"
LIMIT 5;