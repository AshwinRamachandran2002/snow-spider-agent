WITH expr_per_participant AS (
    /* 1. Average log10(normalized_count+1) expression of DRG2 per participant in LGG */
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE
        "Study" = 'LGG'
        AND "Symbol" = 'DRG2'
    GROUP BY
        "ParticipantBarcode"
),
tp53_mutated AS (
    /* 2. LGG participants harbouring a PASS-filtered TP53 mutation */
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE
        "Study" = 'LGG'
        AND "Hugo_Symbol" = 'TP53'
        AND "FILTER" = 'PASS'
),
grouped_expr AS (
    /* 3. Label each participant as MUT (TP53-mut) or WT (non-mut) */
    SELECT
        e."ParticipantBarcode",
        e.expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'MUT' ELSE 'WT' END AS grp
    FROM expr_per_participant e
    LEFT JOIN tp53_mutated m
        ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
group_stats AS (
    /* 4. Compute counts and sums needed for Welch’s t-test; keep groups with ≥10 samples */
    SELECT
        grp,
        COUNT(*)            AS n,
        SUM(expr)           AS s,
        SUM(expr * expr)    AS q
    FROM grouped_expr
    GROUP BY grp
    HAVING COUNT(*) >= 10
),
pivot_stats AS (
    /* 5. Pivot the two groups into one row */
    SELECT
        MAX(CASE WHEN grp = 'MUT' THEN n END) AS ny,
        MAX(CASE WHEN grp = 'MUT' THEN s END) AS sy,
        MAX(CASE WHEN grp = 'MUT' THEN q END) AS qy,
        MAX(CASE WHEN grp = 'WT'  THEN n END) AS nn,
        MAX(CASE WHEN grp = 'WT'  THEN s END) AS sn,
        MAX(CASE WHEN grp = 'WT'  THEN q END) AS qn
    FROM group_stats
)
SELECT
    /* 6. Welch’s t-score, rounded to 2 decimals */
    ROUND(
        ( (sy/ny) - (sn/nn) )
        /
        SQRT(
            ( (qy - sy*sy/ny) / (ny - 1) ) / ny
          + ( (qn - sn*sn/nn) / (nn - 1) ) / nn
        )
    , 2) AS t_score
FROM pivot_stats
/* 7. Ensure variances are positive and both groups are present */
WHERE
      ny IS NOT NULL AND nn IS NOT NULL
  AND ( (qy - sy*sy/ny) / (ny - 1) ) > 0
  AND ( (qn - sn*sn/nn) / (nn - 1) ) > 0;