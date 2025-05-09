WITH lgg_mc3 AS (   -- LGG samples that have mutation information
    SELECT DISTINCT 
           "ParticipantBarcode",
           "Tumor_SampleBarcode" AS "SampleBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study" = 'LGG'
), 
tp53_mutated_pts AS (   -- LGG participants with a PASS TP53 mutation
    SELECT DISTINCT 
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"        = 'LGG'
      AND  "Hugo_Symbol"  = 'TP53'
      AND  "FILTER"       = 'PASS'
), 
drg2_expr AS (          -- DRG2 expression (log10(norm_cnt+1)) for LGG samples present in MC3
    SELECT  
        e."ParticipantBarcode",
        LOG(10, e."normalized_count" + 1) AS "log_expr"      -- Snowflake: LOG(base, expr)
    FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
          JOIN lgg_mc3 mc 
                ON e."SampleBarcode" = mc."SampleBarcode"
    WHERE e."Study"  = 'LGG'
      AND e."Symbol" = 'DRG2'
), 
pt_avg_expr AS (        -- patient‑level average of the log‑transformed expression
    SELECT  
        "ParticipantBarcode",
        AVG("log_expr") AS "avg_expr"
    FROM    drg2_expr
    GROUP BY "ParticipantBarcode"
), 
pt_flag AS (            -- label patients as TP53‑mutated (is_mut = 1) or not (0)
    SELECT  
        p."ParticipantBarcode",
        p."avg_expr",
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS "is_mut"
    FROM   pt_avg_expr p
           LEFT JOIN tp53_mutated_pts m
                  ON p."ParticipantBarcode" = m."ParticipantBarcode"
), 
agg AS (                -- aggregate sums, squared sums and counts for the two groups
    SELECT
        SUM(CASE WHEN "is_mut" = 1 THEN "avg_expr"          ELSE 0 END)               AS S_y,
        SUM(CASE WHEN "is_mut" = 1 THEN POWER("avg_expr",2) ELSE 0 END)               AS Q_y,
        SUM(CASE WHEN "is_mut" = 1 THEN 1                   ELSE 0 END)               AS N_y,
        SUM(CASE WHEN "is_mut" = 0 THEN "avg_expr"          ELSE 0 END)               AS S_n,
        SUM(CASE WHEN "is_mut" = 0 THEN POWER("avg_expr",2) ELSE 0 END)               AS Q_n,
        SUM(CASE WHEN "is_mut" = 0 THEN 1                   ELSE 0 END)               AS N_n
    FROM   pt_flag
), 
stats AS (              -- means, variances and final T‑score
    SELECT
        N_y,
        N_n,
        S_y / N_y                                                    AS avg_y,
        S_n / N_n                                                    AS avg_n,
        (Q_y - POWER(S_y,2)/N_y) / NULLIF(N_y - 1,0)                 AS var_y,
        (Q_n - POWER(S_n,2)/N_n) / NULLIF(N_n - 1,0)                 AS var_n
    FROM agg
)
SELECT
    N_y,
    N_n,
    ROUND(avg_y,6)  AS avg_y,
    ROUND(avg_n,6)  AS avg_n,
    ROUND( (avg_y - avg_n) / SQRT( var_y / N_y + var_n / N_n ), 6) AS tscore
FROM stats;