-- Task: Calculate the number of pancreatic adenocarcinoma (PAAD) patients who have mutations in the KRAS gene, using clinical patient data and genomic mutation data from TCGA's cancer genomics database, focusing on PAAD studies where the mutations have passed quality filters.
WITH
PAAD_Patients AS (
    SELECT DISTINCT "bcr_patient_barcode" AS "Patient"
    FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
    WHERE "acronym" = 'PAAD'
),
KRAS_Mutations AS (
    SELECT DISTINCT "ParticipantBarcode" AS "Patient"
    FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Hugo_Symbol" = 'KRAS' AND "FILTER" = 'PASS' AND "Study" = 'PAAD'
)
SELECT COUNT(DISTINCT P."Patient") AS "KRAS_Mutated_Patients"
FROM PAAD_Patients P
INNER JOIN KRAS_Mutations K ON P."Patient" = K."Patient";