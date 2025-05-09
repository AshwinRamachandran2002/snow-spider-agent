/*  Welch’s T test: DRG2 expression (log10-transformed) in LGG patients
    WITH vs WITHOUT a ‘PASS’ TP53 mutation, using only participants
    that appear in the MC3 MAF table for the LGG study               */

WITH
/* ----------------------------------------------------------------- */
/* 1) LGG participants present in the MC3 table (any variant)         */
mc3_lgg_participants AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study" = 'LGG'
),

/* ----------------------------------------------------------------- */
/* 2) Average log-transformed DRG2 expression per patient, restricted
      to those participants                                           */
per_patient_expr AS (
    SELECT
        e."ParticipantBarcode",
        AVG( LOG(10, e."normalized_count" + 1) ) AS avg_log10_expr
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED e
           JOIN mc3_lgg_participants p
                ON e."ParticipantBarcode" = p."ParticipantBarcode"
    WHERE  e."Study"  = 'LGG'
      AND  e."Symbol" = 'DRG2'
    GROUP  BY e."ParticipantBarcode"
),

/* ----------------------------------------------------------------- */
/* 3) LGG patients harboring a TP53 mutation that passed all filters  */
tp53_mutated AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study"       = 'LGG'
      AND  "Hugo_Symbol" = 'TP53'
      AND  "FILTER"      = 'PASS'
),

/* ----------------------------------------------------------------- */
/* 4) Attach TP53-mutation flag (YES/NO)                              */
expr_flagged AS (
    SELECT
        e."ParticipantBarcode",
        e.avg_log10_expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES'
             ELSE 'NO' END               AS tp53_mut
    FROM   per_patient_expr e
           LEFT JOIN tp53_mutated m
                  ON e."ParticipantBarcode" = m."ParticipantBarcode"
),

/* ----------------------------------------------------------------- */
/* 5) Summary stats for the two groups                                */
group_stats AS (
    SELECT
        tp53_mut,                                 -- 'YES' or 'NO'
        COUNT(*)                      AS N,
        AVG(avg_log10_expr)           AS mean_expr,
        VAR_SAMP(avg_log10_expr)      AS var_expr
    FROM   expr_flagged
    GROUP  BY tp53_mut
)

/* ----------------------------------------------------------------- */
/* 6) Welch’s T-score computation                                    */
SELECT
    yes.N              AS "Ny",
    no.N               AS "Nn",
    yes.mean_expr      AS "avg_y",
    no.mean_expr       AS "avg_n",
    /* Welch's T statistic */
    ( yes.mean_expr - no.mean_expr )
      /
    SQRT( (yes.var_expr / yes.N) + (no.var_expr / no.N) )  AS "tscore"
FROM   group_stats yes
       JOIN group_stats no
            ON yes.tp53_mut = 'YES'
           AND no.tp53_mut  = 'NO';