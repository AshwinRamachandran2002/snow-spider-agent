SELECT
    (SELECT COUNT(DISTINCT "ParticipantBarcode")
     FROM
     (
         SELECT "ParticipantBarcode"
         FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
         WHERE "Study" = 'PAAD' AND "Hugo_Symbol" = 'KRAS' AND "FILTER" = 'PASS'
         INTERSECT
         SELECT "ParticipantBarcode"
         FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
         WHERE "Study" = 'PAAD' AND "Hugo_Symbol" = 'TP53' AND "FILTER" = 'PASS'
     )
    )
    -
    (SELECT COUNT(DISTINCT "bcr_patient_barcode")
     FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
     WHERE "acronym" = 'PAAD'
       AND "bcr_patient_barcode" NOT IN (
         SELECT DISTINCT "ParticipantBarcode"
         FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
         WHERE "Study" = 'PAAD' AND "Hugo_Symbol" IN ('KRAS', 'TP53') AND "FILTER" = 'PASS'
       )
    ) AS "net_difference";