/*-----------------------------------------------------------
  Chi–square statistic for association between histological
  type and CDH1–mutation status in TCGA‑BRCA patients
-----------------------------------------------------------*/
WITH

/* 1.  Clinical BRCA patients with a known histological type */
clinical AS (
    SELECT DISTINCT
           "bcr_patient_barcode"          AS participant_barcode,
           "histological_type"            AS hist_type
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE  "acronym" = 'BRCA'
      AND  "histological_type" IS NOT NULL
      AND  TRIM("histological_type") <> ''
),

/* 2.  Reliable CDH1 mutation calls (FILTER = 'PASS')        */
cdh1_mutated_patients AS (
    SELECT DISTINCT
           "ParticipantBarcode"           AS participant_barcode
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"       = 'BRCA'
      AND  "Hugo_Symbol" = 'CDH1'
      AND  "FILTER"      = 'PASS'
),

/* 3.  Merge clinical and mutation data, assign status       */
patient_status AS (
    SELECT
           c.hist_type,
           CASE
               WHEN m.participant_barcode IS NOT NULL THEN 'Mutated'
               ELSE 'Wildtype'
           END AS mutation_status
    FROM   clinical c
           LEFT JOIN cdh1_mutated_patients m
                  ON c.participant_barcode = m.participant_barcode
),

/* 4.  Contingency counts                                   */
raw_counts AS (
    SELECT
           hist_type,
           mutation_status,
           COUNT(*) AS cnt
    FROM   patient_status
    GROUP  BY hist_type, mutation_status
),

/* 5.  Remove histological types or mutation classes with
       marginal totals ≤ 10                                 */
filtered_counts AS (
    SELECT *
    FROM   (
        SELECT
               hist_type,
               mutation_status,
               cnt,
               SUM(cnt) OVER (PARTITION BY hist_type)        AS row_total,
               SUM(cnt) OVER (PARTITION BY mutation_status)  AS col_total
        FROM   raw_counts
    )
    WHERE  row_total > 10
      AND  col_total > 10
),

/* 6.  Re‑calculate totals after filtering                  */
contingency AS (
    SELECT
           hist_type,
           mutation_status,
           cnt,
           SUM(cnt) OVER (PARTITION BY hist_type)        AS row_total,
           SUM(cnt) OVER (PARTITION BY mutation_status)  AS col_total,
           SUM(cnt) OVER ()                              AS grand_total
    FROM   filtered_counts
)

/* 7.  Chi‑square statistic                                 */
SELECT
       SUM( POWER(cnt - (row_total * col_total / grand_total), 2)
            / (row_total * col_total / grand_total) )  AS chi_square_value
FROM   contingency;