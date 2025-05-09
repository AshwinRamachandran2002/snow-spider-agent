/*  Chi–square statistic for association between histological type and
    CDH1-mutation status in BRCA (PanCancer Atlas, Snowflake dialect)         */

WITH

/* 1.  Reliable CDH1–mutation calls (PASS only) ---------------------------- */
mut AS (
    SELECT DISTINCT
           m."ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
    WHERE  m."Study"        = 'BRCA'
      AND  m."Hugo_Symbol"  = 'CDH1'
      AND  m."FILTER"       = 'PASS'
),

/* 2.  BRCA patients with known histology, tagged for mutation presence ----- */
base AS (
    SELECT
        c."patient_id"          AS "ParticipantBarcode",
        c."histological_type",
        CASE WHEN mut."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END
                                 AS "CDH1_mut_present"
    FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
          LEFT JOIN mut
                 ON mut."ParticipantBarcode" = c."patient_id"
    WHERE c."acronym"           = 'BRCA'
      AND c."histological_type" IS NOT NULL
),

/* 3.  Row/column/grand totals --------------------------------------------- */
row_tot AS (
    SELECT "histological_type", COUNT(*) AS row_total
    FROM   base
    GROUP  BY "histological_type"
),
col_tot AS (
    SELECT "CDH1_mut_present", COUNT(*) AS col_total
    FROM   base
    GROUP  BY "CDH1_mut_present"
),
grand_tot AS (
    SELECT COUNT(*) AS grand_total
    FROM   base
),

/* 4.  Keep only categories with marginal totals > 10 ---------------------- */
good_rows AS (
    SELECT "histological_type" FROM row_tot WHERE row_total > 10
),
good_cols AS (
    SELECT "CDH1_mut_present" FROM col_tot WHERE col_total > 10
),

/* 5.  Contingency counts after filtering ---------------------------------- */
contingency AS (
    SELECT
        b."histological_type",
        b."CDH1_mut_present",
        COUNT(*)                          AS obs
    FROM   base b
           JOIN good_rows gr  ON gr."histological_type"   = b."histological_type"
           JOIN good_cols gc  ON gc."CDH1_mut_present"    = b."CDH1_mut_present"
    GROUP  BY b."histological_type", b."CDH1_mut_present"
),

/* 6.  Re-compute totals on the filtered table ----------------------------- */
r_tot AS (
    SELECT "histological_type", SUM(obs) AS row_total
    FROM   contingency
    GROUP  BY "histological_type"
),
c_tot AS (
    SELECT "CDH1_mut_present", SUM(obs) AS col_total
    FROM   contingency
    GROUP  BY "CDH1_mut_present"
),
g_tot AS (
    SELECT SUM(obs) AS grand_total FROM contingency
),

/* 7.  Expected counts and χ² components ----------------------------------- */
chi_components AS (
    SELECT
        ct."histological_type",
        ct."CDH1_mut_present",
        ct.obs,
        (r.row_total * c.col_total) / g.grand_total      AS expected,
        POWER(ct.obs - (r.row_total * c.col_total) / g.grand_total, 2)
        / ( (r.row_total * c.col_total) / g.grand_total) AS chi_piece
    FROM   contingency        ct
           JOIN r_tot         r ON r."histological_type"   = ct."histological_type"
           JOIN c_tot         c ON c."CDH1_mut_present"    = ct."CDH1_mut_present"
           CROSS JOIN g_tot   g
)

/* 8.  Final χ² statistic --------------------------------------------------- */
SELECT
       ROUND(SUM(chi_piece), 4) AS "chi_square_value"
FROM   chi_components;