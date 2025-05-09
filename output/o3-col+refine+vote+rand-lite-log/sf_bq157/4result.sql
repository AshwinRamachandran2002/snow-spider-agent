WITH
/* ───────────────────────────────────────────────
   LGG participants that have at least 1 mutation
   (ensures we analyse only samples that appear
   in the MC3 table, per the requirement)
   ─────────────────────────────────────────────── */
lgg_patients AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
),

/* ───────────────────────────────────────────────
   LGG participants carrying a PASS TP53 mutation
   ─────────────────────────────────────────────── */
tp53_mut AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),

/* ───────────────────────────────────────────────
   Per-patient average log10-transformed DRG2
   expression (only LGG + only patients present
   in MC3 table)
   ─────────────────────────────────────────────── */
expr_by_patient AS (
    SELECT
        e."ParticipantBarcode",
        AVG(LOG(10, e."normalized_count" + 1)) AS "avg_log_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    WHERE e."Study"              = 'LGG'
      AND e."Symbol"             = 'DRG2'
      AND e."ParticipantBarcode" IN (SELECT "ParticipantBarcode" FROM lgg_patients)
    GROUP BY e."ParticipantBarcode"
),

/* ───────────────────────────────────────────────
   Aggregate (N , Σx , Σx²) for mutated group
   ─────────────────────────────────────────────── */
mut AS (
    SELECT
        COUNT(*)                        AS "Ny",
        SUM("avg_log_expr")             AS "Sy",
        SUM(POWER("avg_log_expr", 2))   AS "Qy"
    FROM expr_by_patient
    WHERE "ParticipantBarcode" IN (SELECT "ParticipantBarcode" FROM tp53_mut)
),

/* ───────────────────────────────────────────────
   Aggregate (N , Σx , Σx²) for non-mutated group
   ─────────────────────────────────────────────── */
wt AS (
    SELECT
        COUNT(*)                        AS "Nn",
        SUM("avg_log_expr")             AS "Sn",
        SUM(POWER("avg_log_expr", 2))   AS "Qn"
    FROM expr_by_patient
    WHERE "ParticipantBarcode" NOT IN (SELECT "ParticipantBarcode" FROM tp53_mut)
)

/* ───────────────────────────────────────────────
   Welch’s T-score
   ─────────────────────────────────────────────── */
SELECT
    mut."Ny",
    wt."Nn",
    mut."Sy" / mut."Ny" AS "avg_y",
    wt."Sn" / wt."Nn"   AS "avg_n",
    (
        (mut."Sy" / mut."Ny") - (wt."Sn" / wt."Nn")
    )
    /
    SQRT(
          ( (mut."Qy" - POWER(mut."Sy", 2) / mut."Ny") / (mut."Ny" - 1) ) / mut."Ny"
        + ( (wt."Qn" - POWER(wt."Sn", 2) / wt."Nn") / (wt."Nn" - 1) ) / wt."Nn"
    )                             AS "T_score"
FROM mut, wt;