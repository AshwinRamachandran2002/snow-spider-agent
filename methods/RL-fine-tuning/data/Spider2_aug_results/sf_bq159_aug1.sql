-- Task: Compute the counts of BRCA patients by histological type and presence or absence of CDH1 gene mutations using data from the PanCancer Atlas. Focus on patients with known histological types and consider only reliable mutation entries. Match clinical and mutation data using ParticipantBarcode.

WITH
    table1 AS (
        SELECT
            "histological_type" AS "Histological_Type",
            "bcr_patient_barcode" AS "ParticipantBarcode"
        FROM 
            "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
        WHERE 
            "acronym" = 'BRCA' 
            AND "histological_type" IS NOT NULL      
    ),
    table2 AS (
        SELECT
            "ParticipantBarcode"
        FROM 
            "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
        WHERE 
            "Study" = 'BRCA' 
            AND "Hugo_Symbol" = 'CDH1'
            AND "FILTER" = 'PASS'  
        GROUP BY
            "ParticipantBarcode"
    )

SELECT 
    t1."Histological_Type",
    CASE 
        WHEN t2."ParticipantBarcode" IS NULL THEN 'NO' 
        ELSE 'YES' 
    END AS "CDH1_Mutation",
    COUNT(*) AS "Patient_Count"
FROM
    table1 AS t1
LEFT JOIN
    table2 AS t2 
    ON t1."ParticipantBarcode" = t2."ParticipantBarcode"
GROUP BY
    t1."Histological_Type", "CDH1_Mutation";