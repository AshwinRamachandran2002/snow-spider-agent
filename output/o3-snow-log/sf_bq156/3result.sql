WITH expr AS (
    SELECT 
        "ParticipantBarcode",
        AVG(LOG("normalized_count" + 1, 10)) AS expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE 
        "Symbol" = 'DRG2'
        AND "Study" = 'LGG'
    GROUP BY 
        "ParticipantBarcode"
),
mut AS (
    SELECT DISTINCT 
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE 
        "Hugo_Symbol" = 'TP53'
        AND "FILTER" = 'PASS'
        AND "Study" = 'LGG'
),
expr_grp AS (
    SELECT 
        e."ParticipantBarcode",
        e.expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS mutated
    FROM expr e
    LEFT JOIN mut m
        ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (
    SELECT 
        mutated,
        COUNT(*)                           AS N,
        SUM(expr)                          AS S,
        SUM(expr * expr)                   AS Q
    FROM expr_grp
    GROUP BY mutated
),
calc AS (
    SELECT
        MIN(CASE WHEN mutated = 1 THEN N END) AS N_y,
        MIN(CASE WHEN mutated = 1 THEN S END) AS S_y,
        MIN(CASE WHEN mutated = 1 THEN Q END) AS Q_y,
        MIN(CASE WHEN mutated = 0 THEN N END) AS N_n,
        MIN(CASE WHEN mutated = 0 THEN S END) AS S_n,
        MIN(CASE WHEN mutated = 0 THEN Q END) AS Q_n
    FROM stats
),
vars AS (
    SELECT
        N_y, S_y, Q_y, N_n, S_n, Q_n,
        (Q_y - S_y * S_y / N_y) / NULLIF(N_y - 1, 0) AS var_y,
        (Q_n - S_n * S_n / N_n) / NULLIF(N_n - 1, 0) AS var_n
    FROM calc
    WHERE 
        N_y >= 10 
        AND N_n >= 10
)
SELECT 
    ROUND(
        ( (S_y / N_y) - (S_n / N_n) )
        /
        SQRT( var_y / N_y + var_n / N_n )
    , 2) AS t_score
FROM vars
WHERE 
    var_y > 0 
    AND var_n > 0;