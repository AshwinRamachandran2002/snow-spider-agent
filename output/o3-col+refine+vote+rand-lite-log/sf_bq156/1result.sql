WITH expr AS (
    -- average log10(normalized_count + 1) expression of DRG2 per participant
    SELECT
        "ParticipantBarcode",
        AVG( LOG("normalized_count" + 1 , 10) ) AS expr_log10
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
tp53_mut AS (
    -- LGG participants carrying a PASS-filtered TP53 mutation
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
expr_flag AS (
    -- attach mutation flag (1 = TP53-mut, 0 = wild-type)
    SELECT
        e."ParticipantBarcode",
        e.expr_log10,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS tp53_mut
    FROM expr e
    LEFT JOIN tp53_mut m
      ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (
    -- aggregates needed for Welch’s t-test
    SELECT
        tp53_mut,
        COUNT(*)                         AS N,
        SUM(expr_log10)                  AS S,
        SUM(POWER(expr_log10,2))         AS Q
    FROM expr_flag
    GROUP BY tp53_mut
),
calc AS (
    -- split aggregates into mutant (y) and wild-type (n) groups
    SELECT
        MIN(CASE WHEN tp53_mut = 1 THEN N END) AS Ny,
        MIN(CASE WHEN tp53_mut = 0 THEN N END) AS Nn,
        MIN(CASE WHEN tp53_mut = 1 THEN S END) AS Sy,
        MIN(CASE WHEN tp53_mut = 0 THEN S END) AS Sn,
        MIN(CASE WHEN tp53_mut = 1 THEN Q END) AS Qy,
        MIN(CASE WHEN tp53_mut = 0 THEN Q END) AS Qn
    FROM stats
),
vars AS (
    -- means (g), variances (V) for each group
    SELECT
        Ny,
        Nn,
        Sy / Ny                                                  AS gy,
        Sn / Nn                                                  AS gn,
        (Qy - Sy*Sy/ Ny) / NULLIF(Ny - 1,0)                      AS Vy,
        (Qn - Sn*Sn/ Nn) / NULLIF(Nn - 1,0)                      AS Vn
    FROM calc
)
-- Welch’s t-score (rounded to 2 decimals); returned only if both groups meet size/variance criteria
SELECT
    ROUND( (gy - gn) / SQRT( Vy / Ny + Vn / Nn ) , 2 ) AS "t_score_DRG2_LGG"
FROM vars
WHERE Ny >= 10
  AND Nn >= 10
  AND Vy > 0
  AND Vn > 0;