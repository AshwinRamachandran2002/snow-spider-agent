WITH mc3_lgg AS (          -- LGG tumour samples present in MC3
    SELECT DISTINCT
           "ParticipantBarcode",
           "Tumor_SampleBarcode"            AS "SampleBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study" = 'LGG'
),

tp53_mut_patients AS (     -- LGG patients harbouring a PASS TP53 mutation
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"       = 'LGG'
      AND  "Hugo_Symbol" = 'TP53'
      AND  "FILTER"      = 'PASS'
),

patient_expr AS (          -- mean log‑transformed DRG2 expression per patient
    SELECT
        e."ParticipantBarcode",
        AVG( LOG(10, e."normalized_count" + 1) ) AS mean_expr   -- log10(x+1)
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
           JOIN mc3_lgg m
             ON e."ParticipantBarcode" = m."ParticipantBarcode"
            AND e."SampleBarcode"      = m."SampleBarcode"
    WHERE  e."Study"  = 'LGG'
      AND  e."Symbol" = 'DRG2'
    GROUP  BY e."ParticipantBarcode"
),

labelled AS (              -- flag patients as TP53‑mutated (YES/NO)
    SELECT
        p."ParticipantBarcode",
        p.mean_expr,
        CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS tp53_mut
    FROM   patient_expr p
           LEFT JOIN tp53_mut_patients t
             ON p."ParticipantBarcode" = t."ParticipantBarcode"
),

group_stats AS (           -- counts and sums needed for Welch’s t‑test
    SELECT
        tp53_mut,
        COUNT(*)                      AS n,
        SUM(mean_expr)                AS s,
        SUM(mean_expr * mean_expr)    AS q
    FROM   labelled
    GROUP  BY tp53_mut
),

vals AS (                  -- derive means and variances for the two groups
    SELECT
        (SELECT n FROM group_stats WHERE tp53_mut = 'YES')                                 AS ny,
        (SELECT n FROM group_stats WHERE tp53_mut = 'NO')                                  AS nn,
        (SELECT s / n FROM group_stats WHERE tp53_mut = 'YES')                             AS avg_y,
        (SELECT s / n FROM group_stats WHERE tp53_mut = 'NO')                              AS avg_n,
        (SELECT (q - (s * s) / n) / (n - 1) FROM group_stats WHERE tp53_mut = 'YES')       AS var_y,
        (SELECT (q - (s * s) / n) / (n - 1) FROM group_stats WHERE tp53_mut = 'NO')        AS var_n
)

SELECT
    ny                        AS "Ny",          -- patients with TP53 mutation
    nn                        AS "Nn",          -- patients without mutation
    avg_y                     AS "avg_y",       -- mean DRG2 expression (mutated)
    avg_n                     AS "avg_n",       -- mean DRG2 expression (non‑mutated)
    (avg_y - avg_n) /
    SQRT( var_y / ny + var_n / nn )             AS "tscore"   -- Welch’s t‑score
FROM vals;