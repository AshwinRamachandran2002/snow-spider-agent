WITH mutation_samples AS (      -- LGG samples appearing in mutation table
    SELECT DISTINCT
           "Tumor_SampleBarcode" AS "SampleBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"  = 'LGG'
      AND  "FILTER" = 'PASS'
), 

expr AS (                       -- DRG2 expression (log10(normalized_count+1))
    SELECT
        e."ParticipantBarcode",
        LOG(10, e."normalized_count" + 1) AS expr_val
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    INNER JOIN mutation_samples ms
            ON e."SampleBarcode" = ms."SampleBarcode"
    WHERE e."Study"  = 'LGG'
      AND e."Symbol" = 'DRG2'
), 

patient_avg AS (                -- per‑patient average expression
    SELECT
        "ParticipantBarcode",
        AVG(expr_val) AS mean_expr
    FROM expr
    GROUP BY "ParticipantBarcode"
), 

tp53_mut AS (                   -- LGG patients carrying a PASS TP53 mutation
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
), 

combined AS (                   -- expression with mutation status
    SELECT
        p."ParticipantBarcode",
        p.mean_expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS mut_flag
    FROM patient_avg p
    LEFT JOIN tp53_mut m
           ON p."ParticipantBarcode" = m."ParticipantBarcode"
), 

stats AS (                      -- group statistics
    SELECT
        mut_flag,
        COUNT(*)                       AS N,
        SUM(mean_expr)                 AS S,
        SUM(POWER(mean_expr, 2))       AS Q
    FROM combined
    GROUP BY mut_flag
), 

sy AS (SELECT * FROM stats WHERE mut_flag = 'YES'),   -- mutated group
sn AS (SELECT * FROM stats WHERE mut_flag = 'NO')     -- non‑mutated group

SELECT
    sy.N                       AS "Ny",
    sn.N                       AS "Nn",
    sy.S / sy.N                AS "avg_y",
    sn.S / sn.N                AS "avg_n",
    (
        (sy.S / sy.N) - (sn.S / sn.N)
    ) /
    SQRT(
        ( (sy.Q - (sy.S*sy.S)/sy.N) / NULLIF(sy.N - 1,0) ) / sy.N +
        ( (sn.Q - (sn.S*sn.S)/sn.N) / NULLIF(sn.N - 1,0) ) / sn.N
    )                          AS "tscore"
FROM sy, sn;