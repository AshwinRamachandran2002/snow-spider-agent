-- Task: For each BRCA patient, list their histological type and whether they have a CDH1 mutation. Limit the result to 100 rows.
WITH
    table1 AS (
        SELECT
            "histological_type" AS "data1",
            "bcr_patient_barcode" AS "ParticipantBarcode"
        FROM
            "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
        WHERE
            "acronym" = 'BRCA'
            AND "histological_type" IS NOT NULL
    ),
    table2 AS (
        SELECT
            "Hugo_Symbol" AS "symbol",
            "ParticipantBarcode"
        FROM
            "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
        WHERE
            "Study" = 'BRCA'
            AND "Hugo_Symbol" = 'CDH1'
            AND "FILTER" = 'PASS'
        GROUP BY
            "ParticipantBarcode", "symbol"
    )
SELECT
    n1."ParticipantBarcode",
    n1."data1" AS "histological_type",
    CASE
        WHEN n2."ParticipantBarcode" IS NULL THEN 'NO'
        ELSE 'YES'
    END AS "has_CDH1_mutation"
FROM
    table1 AS n1
LEFT JOIN
    table2 AS n2
    ON n1."ParticipantBarcode" = n2."ParticipantBarcode"
LIMIT 100;