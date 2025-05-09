WITH mc3_lgg AS (                         -- LGG tumour samples listed in MC3
    SELECT DISTINCT
           "ParticipantBarcode",
           "Tumor_SampleBarcode"                         AS "SampleBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study" = 'LGG'
),
tp53_mutated AS (                         -- LGG patients with a PASS TP53 mutation
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"       = 'LGG'
      AND  "Hugo_Symbol" = 'TP53'
      AND  "FILTER"      = 'PASS'
),
expr_per_sample AS (                      -- log10‑transformed DRG2 expression
    SELECT
        e."ParticipantBarcode",
        e."SampleBarcode",
        LOG(10, e."normalized_count" + 1)               AS "log_expr"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
           JOIN mc3_lgg m
             ON e."SampleBarcode" = m."SampleBarcode"
    WHERE  e."Symbol" = 'DRG2'
),
expr_per_patient AS (                     -- average log‑expression per patient
    SELECT
        "ParticipantBarcode",
        AVG("log_expr")                                   AS "avg_expr"
    FROM   expr_per_sample
    GROUP  BY "ParticipantBarcode"
),
patients_with_status AS (                 -- tag patients as TP53‑mutated YES/NO
    SELECT
        p."ParticipantBarcode",
        p."avg_expr",
        CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 'YES'
             ELSE 'NO' END                               AS "tp53_mut"
    FROM   expr_per_patient p
           LEFT JOIN tp53_mutated t
             ON p."ParticipantBarcode" = t."ParticipantBarcode"
),
group_stats AS (                          -- n, mean, variance per group
    SELECT
        "tp53_mut",
        COUNT(*)                       AS n,
        AVG("avg_expr")                AS mean_expr,
        VAR_SAMP("avg_expr")           AS var_expr
    FROM   patients_with_status
    GROUP  BY "tp53_mut"
),
t_score AS (                              -- Welch’s t‑statistic
    SELECT
        yes.n                                                AS "Ny",
        no.n                                                 AS "Nn",
        ROUND(yes.mean_expr, 4)                              AS "avg_y",
        ROUND(no.mean_expr, 4)                               AS "avg_n",
        ROUND(
            (yes.mean_expr - no.mean_expr)
            /
            SQRT( (yes.var_expr / yes.n) + (no.var_expr / no.n) )
        , 4)                                                 AS "tscore"
    FROM   group_stats yes
           JOIN group_stats no
             ON yes."tp53_mut" = 'YES'
            AND no."tp53_mut"  = 'NO'
)
SELECT *
FROM   t_score;