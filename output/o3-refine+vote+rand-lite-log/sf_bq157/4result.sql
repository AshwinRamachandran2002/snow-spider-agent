WITH lgg_samples AS (          -- LGG tumor samples found in MC3
    SELECT DISTINCT
           "Tumor_SampleBarcode"  AS sample_barcode,
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study" = 'LGG'
),
mutated_patients AS (          -- LGG participants with a PASS‑filtered TP53 mutation
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"       = 'LGG'
      AND  "Hugo_Symbol" = 'TP53'
      AND  "FILTER"      = 'PASS'
),
expr_per_sample AS (           -- DRG2 log10(normalized_count+1) for those samples
    SELECT
        s."ParticipantBarcode",
        LOG(e."normalized_count" + 1, 10)            AS log_expr      -- Snowflake: LOG(value, base)
    FROM   lgg_samples  s
    JOIN   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
           ON e."SampleBarcode" = s.sample_barcode
          AND e."Symbol"        = 'DRG2'
),
expr_per_patient AS (          -- average expression per participant
    SELECT
        "ParticipantBarcode",
        AVG(log_expr)                              AS avg_expr
    FROM   expr_per_sample
    GROUP BY "ParticipantBarcode"
),
labelled AS (                  -- label participants as TP53‑mutated or not
    SELECT
        p."ParticipantBarcode",
        p.avg_expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS tp53_mut
    FROM   expr_per_patient p
    LEFT  JOIN mutated_patients m
           ON p."ParticipantBarcode" = m."ParticipantBarcode"
),
group_stats AS (               -- compute N, S, Q for each group
    SELECT
        tp53_mut,
        COUNT(*)                 AS N,
        SUM(avg_expr)            AS S,
        SUM(avg_expr * avg_expr) AS Q
    FROM   labelled
    GROUP BY tp53_mut
),
pivot_stats AS (               -- pivot YES / NO into single row
    SELECT
        MAX(CASE WHEN tp53_mut = 'YES' THEN N END) AS Ny,
        MAX(CASE WHEN tp53_mut = 'NO'  THEN N END) AS Nn,
        MAX(CASE WHEN tp53_mut = 'YES' THEN S END) AS Sy,
        MAX(CASE WHEN tp53_mut = 'NO'  THEN S END) AS Sn,
        MAX(CASE WHEN tp53_mut = 'YES' THEN Q END) AS Qy,
        MAX(CASE WHEN tp53_mut = 'NO'  THEN Q END) AS Qn
    FROM   group_stats
),
final_stats AS (               -- means, variances, Welch T‑score
    SELECT
        Ny,
        Nn,
        Sy / Ny                                        AS avg_y,
        Sn / Nn                                        AS avg_n,
        (Qy - (Sy * Sy) / Ny) / (Ny - 1)               AS var_y,
        (Qn - (Sn * Sn) / Nn) / (Nn - 1)               AS var_n
    FROM   pivot_stats
)
SELECT
    Ny,
    Nn,
    avg_y,
    avg_n,
    (avg_y - avg_n) / SQRT( (var_y / Ny) + (var_n / Nn) ) AS tscore
FROM   final_stats;