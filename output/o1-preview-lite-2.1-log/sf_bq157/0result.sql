WITH LGG_Patients AS (
    SELECT DISTINCT c."bcr_patient_barcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    WHERE c."acronym" = 'LGG'
),
DRG2_Data AS (
    SELECT g."ParticipantBarcode", LN(g."normalized_count") AS log_expression
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" g
    WHERE g."Symbol" = 'DRG2'
),
TP53_Mutations AS (
    SELECT DISTINCT m."ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
    WHERE m."Hugo_Symbol" = 'TP53' AND m."FILTER" = 'PASS'
),
Combined_Data AS (
    SELECT d."ParticipantBarcode", d.log_expression,
        CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS TP53_Mutation
    FROM DRG2_Data d
    JOIN LGG_Patients lgg ON d."ParticipantBarcode" = lgg."bcr_patient_barcode"
    LEFT JOIN TP53_Mutations t ON d."ParticipantBarcode" = t."ParticipantBarcode"
)
SELECT
    COUNT(CASE WHEN TP53_Mutation = 'YES' THEN 1 END) AS Ny,
    COUNT(CASE WHEN TP53_Mutation = 'NO' THEN 1 END) AS Nn,
    ROUND(AVG(CASE WHEN TP53_Mutation = 'YES' THEN log_expression END), 4) AS avg_y,
    ROUND(AVG(CASE WHEN TP53_Mutation = 'NO' THEN log_expression END), 4) AS avg_n,
    ROUND(
        (AVG(CASE WHEN TP53_Mutation = 'YES' THEN log_expression END) - AVG(CASE WHEN TP53_Mutation = 'NO' THEN log_expression END)) 
        / SQRT( 
            (VAR_SAMP(CASE WHEN TP53_Mutation = 'YES' THEN log_expression END) / COUNT(CASE WHEN TP53_Mutation = 'YES' THEN 1 END)) 
            + (VAR_SAMP(CASE WHEN TP53_Mutation = 'NO' THEN log_expression END) / COUNT(CASE WHEN TP53_Mutation = 'NO' THEN 1 END)) 
        ), 4
    ) AS tscore
FROM Combined_Data;