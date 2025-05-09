/*  Welch-T test for DRG2 expression (log10-transformed) between TP53-mutant
    and wild-type LGG patients                                            */

WITH
/* LGG participants appearing in the mutation table --------------------- */
lgg_participants AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
),

/* LGG participants whose tumour harbours a PASS TP53 mutation ----------- */
tp53_mut AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),

/* Log10-transformed DRG2 expression for LGG samples --------------------- */
expr AS (
    SELECT
        e."ParticipantBarcode",
        LOG(10, e."normalized_count" + 1)                       AS log_expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    INNER JOIN lgg_participants p
            ON p."ParticipantBarcode" = e."ParticipantBarcode"
    WHERE e."Symbol" = 'DRG2'
),

/* Per-patient mean log10 expression and TP53-status --------------------- */
per_patient AS (
    SELECT
        e."ParticipantBarcode",
        AVG(e.log_expr)                                                AS avg_log_expr,
        CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS mutated
    FROM expr e
    LEFT JOIN tp53_mut t
           ON t."ParticipantBarcode" = e."ParticipantBarcode"
    GROUP BY e."ParticipantBarcode", mutated
),

/* Group counts, means, variances --------------------------------------- */
group_stats AS (
    SELECT
        mutated,                                   -- 1 = TP53-mutant, 0 = WT
        COUNT(*)              AS n,
        AVG(avg_log_expr)     AS mean,
        VAR_SAMP(avg_log_expr) AS var
    FROM per_patient
    GROUP BY mutated
)

/* Welch T-score --------------------------------------------------------- */
SELECT
    (y.mean - n.mean)
    /
    SQRT( y.var / y.n + n.var / n.n )       AS "T_score"
FROM
    (SELECT * FROM group_stats WHERE mutated = 1) y,
    (SELECT * FROM group_stats WHERE mutated = 0) n;