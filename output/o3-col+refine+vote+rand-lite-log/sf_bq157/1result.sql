/*  Welch t-test for difference in log10-transformed DRG2 expression
    between LGG participants WITH vs WITHOUT a PASS-filtered TP53 mutation   */

WITH
-- LGG participants represented in the mutation table
lgg_participants AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
),

-- LGG participants harbouring a TP53 mutation that passed all filters
tp53_mutated AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),

-- average log10(normalized_count+1) DRG2 expression per participant
expr_per_patient AS (
    SELECT
        e."ParticipantBarcode",
        AVG( LOG(e."normalized_count" + 1 , 10) ) AS avg_log_expr
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"  e
    INNER  JOIN lgg_participants p
            ON e."ParticipantBarcode" = p."ParticipantBarcode"
    WHERE  e."Study"  = 'LGG'
      AND  e."Symbol" = 'DRG2'
    GROUP  BY e."ParticipantBarcode"
),

-- flag each participant as TP53-mutated (YES) or not (NO)
flagged AS (
    SELECT
        x."ParticipantBarcode",
        x.avg_log_expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS tp53_mut
    FROM  expr_per_patient x
    LEFT  JOIN tp53_mutated m
           ON x."ParticipantBarcode" = m."ParticipantBarcode"
),

-- first and second moments of expression in each group
moments AS (
    SELECT
        tp53_mut,
        COUNT(*)                     AS N,
        SUM(avg_log_expr)            AS S,
        SUM(POWER(avg_log_expr,2))   AS Q
    FROM   flagged
    GROUP  BY tp53_mut
),

-- gather group statistics into columns
pivot AS (
    SELECT
        MAX(CASE WHEN tp53_mut = 'YES' THEN N END) AS Ny,
        MAX(CASE WHEN tp53_mut = 'NO'  THEN N END) AS Nn,
        MAX(CASE WHEN tp53_mut = 'YES' THEN S END) AS Sy,
        MAX(CASE WHEN tp53_mut = 'NO'  THEN S END) AS Sn,
        MAX(CASE WHEN tp53_mut = 'YES' THEN Q END) AS Qy,
        MAX(CASE WHEN tp53_mut = 'NO'  THEN Q END) AS Qn
    FROM moments
)

-- final Welch T-score
SELECT
    Ny,
    Nn,
    Sy / Ny                                                AS avg_y,
    Sn / Nn                                                AS avg_n,
    (Qy - Sy*Sy/Ny) / (Ny - 1)                             AS var_y,
    (Qn - Sn*Sn/Nn) / (Nn - 1)                             AS var_n,
    (Sy / Ny - Sn / Nn)
    /
    SQRT( ( (Qy - Sy*Sy/Ny) / (Ny - 1) ) / Ny
        + ( (Qn - Sn*Sn/Nn) / (Nn - 1) ) / Nn )            AS tscore
FROM pivot;