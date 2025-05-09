WITH gene_expr AS (   /* 1. IGF2 expression per LGG participant */
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10 , "normalized_count" + 1) ) AS expr          -- log10(normalized_count + 1)
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE
        "Study"  = 'LGG'
        AND "Symbol" = 'IGF2'
        AND "normalized_count" IS NOT NULL
    GROUP BY
        "ParticipantBarcode"
),
clin AS (            /* 2. clinical records with valid ICD-O-3 histology */
    SELECT
        "bcr_patient_barcode"       AS ParticipantBarcode,
        "icd_o_3_histology"         AS hist
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE
        "icd_o_3_histology" IS NOT NULL
        AND NOT REGEXP_LIKE("icd_o_3_histology", '^\[.*\]$')
),
merged AS (          /* 3. join expression with clinical */
    SELECT
        g.expr,
        c.hist
    FROM gene_expr g
    JOIN clin c
      ON g."ParticipantBarcode" = c.ParticipantBarcode
),
ranks AS (           /* 4. first rank & tie count for average-rank calculation */
    SELECT
        hist,
        expr,
        RANK()  OVER(ORDER BY expr)              AS r_first,
        COUNT(*) OVER(PARTITION BY expr)         AS tie_cnt
    FROM merged
),
ranked AS (          /* 5. average rank per sample */
    SELECT
        hist,
        expr,
        (r_first + (tie_cnt - 1) / 2.0)          AS avg_rank
    FROM ranks
),
grp_stats AS (       /* 6. Sᵢ, Qᵢ, nᵢ per histology (require >1 sample) */
    SELECT
        hist,
        COUNT(*)                      AS n_i,
        SUM(avg_rank)                 AS S_i,
        SUM(POWER(avg_rank,2))        AS Q_i
    FROM ranked
    GROUP BY hist
    HAVING COUNT(*) > 1
),
totals AS (          /* 7. totals for H formula */
    SELECT
        SUM(n_i)                    AS N,
        SUM(S_i)                    AS S_sum,
        SUM(Q_i)                    AS Q_sum,
        SUM(S_i * S_i / n_i)        AS part1
    FROM grp_stats
),
H_calc AS (          /* 8. Kruskal-Wallis H score */
    SELECT
        (N - 1) * (part1 - (S_sum * S_sum) / N)
        / NULLIF( (Q_sum - (S_sum * S_sum) / N), 0)   AS kw_h_score,
        N                                             AS total_samples,
        (SELECT COUNT(*) FROM grp_stats)             AS total_groups
    FROM totals
)
SELECT
    total_groups,
    total_samples,
    kw_h_score
FROM H_calc
ORDER BY kw_h_score DESC NULLS LAST;