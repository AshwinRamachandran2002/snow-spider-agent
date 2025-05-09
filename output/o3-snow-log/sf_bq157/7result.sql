/*  Welch’s t-score for log10-transformed DRG2 expression
    between LGG participants WITH and WITHOUT a PASS TP53 mutation  */

WITH
/* -----------------------------------------------------------
   All LGG participants that have at least one mutation record
------------------------------------------------------------*/
lgg_cases AS (
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study" = 'LGG'              -- LGG cohort only
),

/* -----------------------------------------------------------
   LGG participants harbouring a TP53 mutation that passed all
   filters
------------------------------------------------------------*/
tp53_mut AS (
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"       = 'LGG'
      AND  "Hugo_Symbol" = 'TP53'
      AND  "FILTER"      = 'PASS'
),

/* -----------------------------------------------------------
   Per-participant mean of log10(normalized_count + 1) for DRG2
------------------------------------------------------------*/
expr AS (
    SELECT
        ge."ParticipantBarcode",
        AVG( LOG(10, ge."normalized_count" + 1) )  AS avg_log_expr
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"  ge
           JOIN lgg_cases lc
             ON ge."ParticipantBarcode" = lc."ParticipantBarcode"
    WHERE  ge."Symbol" = 'DRG2'
    GROUP BY ge."ParticipantBarcode"
),

/* -----------------------------------------------------------
   Label each participant by TP53-mutation status
------------------------------------------------------------*/
labelled AS (
    SELECT
        CASE WHEN tm."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS mut_tp53,
        e.avg_log_expr
    FROM   expr e
           LEFT JOIN tp53_mut tm
                  ON e."ParticipantBarcode" = tm."ParticipantBarcode"
),

/* -----------------------------------------------------------
   Compute S(Σg), Q(Σg²) and N for each group
------------------------------------------------------------*/
summarised AS (
    SELECT
        mut_tp53,
        COUNT(*)::FLOAT                AS n,
        SUM(avg_log_expr)::FLOAT       AS s,
        SUM( POWER(avg_log_expr,2) )::FLOAT AS q
    FROM   labelled
    GROUP BY mut_tp53
),

/* -----------------------------------------------------------
   Pivot to single row & calculate Welch’s t-score
------------------------------------------------------------*/
calc AS (
    SELECT
        MAX( CASE WHEN mut_tp53 = 'YES' THEN n END ) AS ny,
        MAX( CASE WHEN mut_tp53 = 'NO'  THEN n END ) AS nn,
        MAX( CASE WHEN mut_tp53 = 'YES' THEN s END ) AS sy,
        MAX( CASE WHEN mut_tp53 = 'NO'  THEN s END ) AS sn,
        MAX( CASE WHEN mut_tp53 = 'YES' THEN q END ) AS qy,
        MAX( CASE WHEN mut_tp53 = 'NO'  THEN q END ) AS qn
    FROM   summarised
)

SELECT
    ny,                                            -- # LGG cases with TP53 mutation
    nn,                                            -- # LGG cases without TP53 mutation
    sy/ny                 AS avg_y,                -- mean log-expr (mut)
    sn/nn                 AS avg_n,                -- mean log-expr (non-mut)
    /* Welch’s t-statistic */
    ( (sy/ny) - (sn/nn) ) /
    SQRT(
        ( (qy - POWER(sy,2)/ny) / (ny-1) ) / ny   +   -- variance term (mut)
        ( (qn - POWER(sn,2)/nn) / (nn-1) ) / nn       -- variance term (non-mut)
    )                       AS tscore
FROM calc;