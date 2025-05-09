WITH expr AS (   -- average log10(normalized_count+1) of DRG2 per participant
    SELECT
        "ParticipantBarcode"                                       AS patient,
        AVG( LOG(10, "normalized_count" + 1) )                     AS expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study"  = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
mutated AS (      -- LGG participants with TP53 mutation and FILTER = 'PASS'
    SELECT DISTINCT
        "ParticipantBarcode" AS patient
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"       = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),
expr_group AS (   -- label each participant as MUT (TP53‑mut) or WT
    SELECT
        e.patient,
        e.expr,
        CASE WHEN m.patient IS NOT NULL THEN 'MUT' ELSE 'WT' END AS grp
    FROM expr e
    LEFT JOIN mutated m
           ON e.patient = m.patient
),
stats AS (        -- N, Σx, Σx² for each group
    SELECT
        grp,
        COUNT(*)              AS n,
        SUM(expr)             AS S,
        SUM(expr*expr)        AS Q
    FROM expr_group
    GROUP BY grp
),
calc AS (         -- means & variances for Welch’s t‑test
    SELECT
        mut.n                                            AS n1,
        wt.n                                             AS n2,
        mut.S / mut.n                                    AS mean1,
        wt.S / wt.n                                      AS mean2,
        (mut.Q - mut.S*mut.S/mut.n) / NULLIF(mut.n-1,0)  AS var1,
        (wt.Q  - wt.S*wt.S/wt.n ) / NULLIF(wt.n-1 ,0)    AS var2
    FROM (SELECT * FROM stats WHERE grp = 'MUT') mut,
         (SELECT * FROM stats WHERE grp = 'WT' ) wt
)
SELECT
    ROUND( (mean1 - mean2) / SQRT( var1/n1 + var2/n2 ), 2 ) AS "t_score"
FROM calc
WHERE n1 >= 10
  AND n2 >= 10
  AND var1 > 0
  AND var2 > 0;