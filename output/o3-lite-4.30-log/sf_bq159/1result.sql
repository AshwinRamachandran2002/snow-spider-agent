WITH
/* 1.  BRCA patients with known histology */
clinical_brca AS (
    SELECT  "bcr_patient_barcode" AS PATIENT_ID ,
            "histological_type"   AS HISTOLOGICAL_TYPE
    FROM    PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE   "acronym" = 'BRCA'
      AND   "histological_type" IS NOT NULL
),
/* 2.  Patients carrying a reliable CDH1 mutation (FILTER = 'PASS') */
cdh1_mut_patients AS (
    SELECT DISTINCT "ParticipantBarcode" AS PATIENT_ID
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"       = 'BRCA'
      AND  "Hugo_Symbol" = 'CDH1'
      AND  "FILTER"      = 'PASS'
),
/* 3.  Build yes / no mutation flag for every BRCA patient */
base AS (
    SELECT  c.HISTOLOGICAL_TYPE,
            CASE WHEN m.PATIENT_ID IS NULL
                 THEN 'No_CDH1_mut'
                 ELSE 'CDH1_mut'
            END AS CDH1_STATUS
    FROM    clinical_brca        c
    LEFT JOIN cdh1_mut_patients  m
           ON c.PATIENT_ID = m.PATIENT_ID
),
/* 4.  Keep histology groups with > 10 total cases */
valid_histology AS (
    SELECT  HISTOLOGICAL_TYPE
    FROM    base
    GROUP BY HISTOLOGICAL_TYPE
    HAVING  COUNT(*) > 10
),
filtered_base AS (
    SELECT  b.*
    FROM    base            b
    JOIN    valid_histology v
      ON    b.HISTOLOGICAL_TYPE = v.HISTOLOGICAL_TYPE
),
/* 5.  Contingency‑table cell counts */
cell_counts AS (
    SELECT  HISTOLOGICAL_TYPE,
            CDH1_STATUS,
            COUNT(*) AS OBSERVED
    FROM    filtered_base
    GROUP BY HISTOLOGICAL_TYPE, CDH1_STATUS
),
/* 6.  Add row, column and grand totals */
totals AS (
    SELECT  HISTOLOGICAL_TYPE,
            CDH1_STATUS,
            OBSERVED,
            SUM(OBSERVED) OVER (PARTITION BY HISTOLOGICAL_TYPE) AS ROW_TOTAL,
            SUM(OBSERVED) OVER (PARTITION BY CDH1_STATUS)        AS COL_TOTAL,
            SUM(OBSERVED) OVER ()                                AS GRAND_TOTAL
    FROM    cell_counts
)
/* 7.  Pearson chi‑square statistic */
SELECT
    ROUND(
        SUM(
            POWER(OBSERVED - (ROW_TOTAL * COL_TOTAL) / GRAND_TOTAL, 2)
            / ((ROW_TOTAL * COL_TOTAL) / GRAND_TOTAL)
        ),
        4
    ) AS chi_square_value
FROM totals
WHERE COL_TOTAL > 10;