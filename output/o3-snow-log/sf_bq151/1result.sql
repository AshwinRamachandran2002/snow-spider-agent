WITH
/* ----------------------------------------------
1.  PAAD patients that have clinical follow-up
---------------------------------------------- */
paad_patients AS (
    SELECT DISTINCT
           "bcr_patient_barcode"          AS "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
    WHERE  "acronym" = 'PAAD'
),

/* ----------------------------------------------
2.  High-quality (PASS) KRAS / TP53 mutations
    reported for PAAD in the MC3 MAF
---------------------------------------------- */
paad_mutations AS (
    SELECT DISTINCT
           "ParticipantBarcode",
           "Hugo_Symbol"
    FROM   PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"  = 'PAAD'
      AND  "FILTER" = 'PASS'
      AND  "Hugo_Symbol" IN ('KRAS','TP53')
),

/* ----------------------------------------------
3.  Per-patient mutation status flags
---------------------------------------------- */
patient_status AS (
    SELECT
        p."ParticipantBarcode",
        MAX( CASE WHEN m."Hugo_Symbol" = 'KRAS' THEN 1 ELSE 0 END )  AS "KRAS_mut",
        MAX( CASE WHEN m."Hugo_Symbol" = 'TP53' THEN 1 ELSE 0 END )  AS "TP53_mut"
    FROM   paad_patients p
           LEFT JOIN paad_mutations m
                  ON p."ParticipantBarcode" = m."ParticipantBarcode"
    GROUP BY
        p."ParticipantBarcode"
),

/* ----------------------------------------------
4.  Build 2×2 contingency table
---------------------------------------------- */
contingency AS (
    SELECT
        SUM( CASE WHEN "KRAS_mut" = 1 AND "TP53_mut" = 1 THEN 1 ELSE 0 END ) AS "a_both",
        SUM( CASE WHEN "KRAS_mut" = 1 AND "TP53_mut" = 0 THEN 1 ELSE 0 END ) AS "b_kras_only",
        SUM( CASE WHEN "KRAS_mut" = 0 AND "TP53_mut" = 1 THEN 1 ELSE 0 END ) AS "c_tp53_only",
        SUM( CASE WHEN "KRAS_mut" = 0 AND "TP53_mut" = 0 THEN 1 ELSE 0 END ) AS "d_neither"
    FROM   patient_status
),

/* ----------------------------------------------
5.  Expected counts & totals
---------------------------------------------- */
expected AS (
    SELECT
        "a_both",
        "b_kras_only",
        "c_tp53_only",
        "d_neither",
        ("a_both" + "b_kras_only")                        AS "row_kras_yes",
        ("c_tp53_only" + "d_neither")                     AS "row_kras_no",
        ("a_both" + "c_tp53_only")                        AS "col_tp53_yes",
        ("b_kras_only" + "d_neither")                     AS "col_tp53_no",
        ("a_both" + "b_kras_only" + "c_tp53_only" + "d_neither")   AS "n_total"
    FROM contingency
),

/* ----------------------------------------------
6.  Chi-squared statistic
---------------------------------------------- */
chi_calc AS (
    SELECT
        "a_both",
        "b_kras_only",
        "c_tp53_only",
        "d_neither",
        "n_total",
        /* expected cell counts */
        ("row_kras_yes" * "col_tp53_yes") / "n_total"     AS "exp_both",
        ("row_kras_yes" * "col_tp53_no")  / "n_total"     AS "exp_kras_only",
        ("row_kras_no"  * "col_tp53_yes") / "n_total"     AS "exp_tp53_only",
        ("row_kras_no"  * "col_tp53_no")  / "n_total"     AS "exp_neither",
        /* chi-square calculation */
        POWER( "a_both"     - (("row_kras_yes" * "col_tp53_yes") / "n_total"), 2 )
            / (("row_kras_yes" * "col_tp53_yes") / "n_total") +
        POWER( "b_kras_only" - (("row_kras_yes" * "col_tp53_no")  / "n_total"), 2 )
            / (("row_kras_yes" * "col_tp53_no")  / "n_total") +
        POWER( "c_tp53_only" - (("row_kras_no"  * "col_tp53_yes") / "n_total"), 2 )
            / (("row_kras_no"  * "col_tp53_yes") / "n_total") +
        POWER( "d_neither"   - (("row_kras_no"  * "col_tp53_no")  / "n_total"), 2 )
            / (("row_kras_no"  * "col_tp53_no")  / "n_total")     AS "chi_squared_statistic"
    FROM expected
)

/* ----------------------------------------------
7.  Final output
---------------------------------------------- */
SELECT
    "a_both"        AS "KRAS_MUT_and_TP53_MUT",
    "b_kras_only"   AS "KRAS_MUT_only",
    "c_tp53_only"   AS "TP53_MUT_only",
    "d_neither"     AS "Neither_mutated",
    "n_total"       AS "Total_patients",
    ROUND( "chi_squared_statistic", 4 )  AS "Chi_Squared_Statistic"
FROM chi_calc;