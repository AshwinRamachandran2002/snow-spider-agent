WITH expr_per_participant AS (
    SELECT
        "ParticipantBarcode"                                               AS participant,
        AVG(LOG(10, "normalized_count" + 1))                               AS expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
tp53_mutated AS (
    SELECT DISTINCT
        "ParticipantBarcode"                                               AS participant
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr_with_status AS (
    SELECT
        e.participant,
        e.expr,
        CASE WHEN m.participant IS NOT NULL THEN 1 ELSE 0 END              AS is_mut
    FROM expr_per_participant e
    LEFT JOIN tp53_mutated m
           ON e.participant = m.participant
),
grp_stats AS (
    SELECT
        is_mut,
        COUNT(*)                                                           AS n,
        AVG(expr)                                                          AS mean_expr,
        VAR_SAMP(expr)                                                     AS var_expr
    FROM expr_with_status
    GROUP BY is_mut
),
mut    AS (SELECT * FROM grp_stats WHERE is_mut = 1),
nonmut AS (SELECT * FROM grp_stats WHERE is_mut = 0)
SELECT
    ROUND(
        (mut.mean_expr - nonmut.mean_expr)
        / SQRT( mut.var_expr / mut.n + nonmut.var_expr / nonmut.n )
    , 2)                                                                   AS "t_score"
FROM mut, nonmut
WHERE mut.n      >= 10
  AND nonmut.n   >= 10
  AND mut.var_expr    > 0
  AND nonmut.var_expr > 0;