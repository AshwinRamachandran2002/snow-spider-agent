/*-------------------------------------------------------------
  Chi–square test for association between histological type
  and CDH1-mutation status in TCGA-BRCA (PanCancer Atlas)

  – clinical  : histological type  ->  CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
  – mutations : CDH1, ‘PASS’ only ->  MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
  – link key  : Participant/Patient barcodes (TCGA IDs)

  Exclude (i) unknown histology, (ii) histology or mutation
  categories whose marginal totals ≤ 10
-------------------------------------------------------------*/
WITH brca_clinical AS (          -- BRCA cases with known histology
  SELECT
      UPPER("bcr_patient_barcode")        AS patient_barcode,
      "histological_type"
  FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
  WHERE "acronym" = 'BRCA'
    AND "histological_type" IS NOT NULL
),

cdh1_mutated AS (                -- reliable CDH1 mutation calls
  SELECT DISTINCT
         UPPER("ParticipantBarcode")      AS patient_barcode
  FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
  WHERE  "Study"       = 'BRCA'
    AND  "Hugo_Symbol" = 'CDH1'
    AND  "FILTER"      = 'PASS'
),

patient_status AS (              -- assign mutation status
  SELECT
      c.patient_barcode,
      c."histological_type",
      CASE
        WHEN m.patient_barcode IS NOT NULL THEN 'MUTATED'
        ELSE 'WILDTYPE'
      END                       AS mutation_status
  FROM  brca_clinical AS c
  LEFT JOIN cdh1_mutated  AS m
         ON c.patient_barcode = m.patient_barcode
),

raw_counts AS (                  -- contingency table
  SELECT
      "histological_type",
      mutation_status,
      COUNT(*)                  AS obs
  FROM  patient_status
  GROUP BY
      "histological_type",
      mutation_status
),

-- row & column totals
row_totals AS (
  SELECT "histological_type",
         SUM(obs)               AS row_total
  FROM   raw_counts
  GROUP BY "histological_type"
),
col_totals AS (
  SELECT mutation_status,
         SUM(obs)               AS col_total
  FROM   raw_counts
  GROUP BY mutation_status
),
grand_total AS (
  SELECT SUM(obs) AS grand_total FROM raw_counts
),

-- apply marginal-total filter (>10)
filtered_counts AS (
  SELECT
      rc."histological_type",
      rc.mutation_status,
      rc.obs
  FROM  raw_counts      rc
  JOIN  row_totals      rt USING ("histological_type")
  JOIN  col_totals      ct USING (mutation_status)
  WHERE rt.row_total  > 10
    AND ct.col_total  > 10
),

-- compute χ² contribution per cell
chi_prep AS (
  SELECT
      fc."histological_type",
      fc.mutation_status,
      fc.obs,
      rt.row_total,
      ct.col_total,
      gt.grand_total,
      (rt.row_total * ct.col_total) / gt.grand_total          AS exp_val,
      POWER( fc.obs - (rt.row_total * ct.col_total) / gt.grand_total , 2 )
      /     ((rt.row_total * ct.col_total) / gt.grand_total)  AS chi_component
  FROM  filtered_counts fc
  JOIN  row_totals      rt USING ("histological_type")
  JOIN  col_totals      ct USING (mutation_status)
  CROSS JOIN grand_total gt
)

-- final χ² statistic
SELECT
    ROUND(SUM(chi_component), 4) AS chi_square_value
FROM chi_prep;