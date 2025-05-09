/*  Chi-square statistic for association between BRCA histological type
    and CDH1-mutation status (reliable mutations only; categories with
    marginal totals ≤10 are excluded).                                          */

WITH
/* -------------------------------------------------------------------------- */
/* 1.  Clinical BRCA patients having a reported histology                     */
brca_clinical AS (
    SELECT
        c."bcr_patient_barcode"       AS "ParticipantBarcode",
        c."histological_type"
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"  c
    WHERE
        c."acronym" = 'BRCA'
        AND c."histological_type" IS NOT NULL
),

/* -------------------------------------------------------------------------- */
/* 2.  Reliable CDH1-mutation carriers in BRCA                                */
cdh1_mutated AS (
    SELECT DISTINCT
        m."ParticipantBarcode"
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"  m
    WHERE
        m."Study"        = 'BRCA'
        AND m."Hugo_Symbol" = 'CDH1'
        AND m."FILTER"      = 'PASS'
),

/* -------------------------------------------------------------------------- */
/* 3.  Combine clinical records with mutation flag (1 = mutated, 0 = wild-type)*/
combo AS (
    SELECT
        bc."histological_type",
        CASE WHEN cm."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS "CDH1_mut_flag"
    FROM
        brca_clinical                      bc
        LEFT JOIN cdh1_mutated             cm
               ON bc."ParticipantBarcode" = cm."ParticipantBarcode"
),

/* -------------------------------------------------------------------------- */
/* 4.  Keep only histology rows & mutation columns with >10 participants      */
hist_keep AS (
    SELECT "histological_type"
    FROM   combo
    GROUP BY "histological_type"
    HAVING COUNT(*) > 10
),
flag_keep AS (
    SELECT "CDH1_mut_flag"
    FROM   combo
    GROUP BY "CDH1_mut_flag"
    HAVING COUNT(*) > 10
),
filtered AS (
    SELECT *
    FROM   combo
    WHERE  "histological_type" IN (SELECT "histological_type" FROM hist_keep)
      AND  "CDH1_mut_flag"     IN (SELECT "CDH1_mut_flag"     FROM flag_keep)
),

/* -------------------------------------------------------------------------- */
/* 5.  Observed counts (contingency table)                                    */
observed AS (
    SELECT
        "histological_type",
        "CDH1_mut_flag",
        COUNT(*) AS obs
    FROM   filtered
    GROUP BY "histological_type", "CDH1_mut_flag"
),

/* 6.  Grand, row, and column totals                                          */
grand_total AS (SELECT SUM(obs) AS gt FROM observed),
row_tot AS (
    SELECT "histological_type", SUM(obs) AS rt
    FROM   observed
    GROUP BY "histological_type"
),
col_tot AS (
    SELECT "CDH1_mut_flag", SUM(obs) AS ct
    FROM   observed
    GROUP BY "CDH1_mut_flag"
),

/* -------------------------------------------------------------------------- */
/* 7.  Cell-wise χ² contributions                                             */
chi_cells AS (
    SELECT
        o."histological_type",
        o."CDH1_mut_flag",
        o.obs                                            AS observed_n,
        (r.rt * c.ct) / gt.gt::FLOAT                    AS expected_n,
        POWER(o.obs - ((r.rt * c.ct) / gt.gt), 2)
        / ((r.rt * c.ct) / gt.gt)                       AS chi_contrib
    FROM      observed     o
    JOIN      row_tot      r  ON o."histological_type" = r."histological_type"
    JOIN      col_tot      c  ON o."CDH1_mut_flag"     = c."CDH1_mut_flag"
    CROSS JOIN grand_total gt
)

/* -------------------------------------------------------------------------- */
/* 8.  Overall chi-square statistic                                           */
SELECT
    ROUND(SUM(chi_contrib), 6) AS "chi_square_statistic"
FROM
    chi_cells;