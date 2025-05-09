WITH expr AS (           /* log10‑transformed TP53 expression in BRCA primary‑tumour samples */
    SELECT
        "sample_barcode",
        LOG(10 , "normalized_count")      AS log_expr
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"   > 0
      AND SUBSTR("sample_barcode", 14, 2) = '01'        -- primary‑tumour samples
),
mut_raw AS (              /* every TP53 mutation in the same cohort                           */
    SELECT
        "sample_barcode_tumor"            AS sample_barcode,
        "Variant_Classification"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
),
mut AS (                  /* one mutation type per sample (alphabetically first if >1)        */
    SELECT
        sample_barcode,
        MIN("Variant_Classification")     AS mutation_type
    FROM mut_raw
    GROUP BY sample_barcode
),
combined AS (             /* merge expression with mutation status                            */
    SELECT
        e."sample_barcode",
        e.log_expr,
        COALESCE(m.mutation_type, 'Wild_Type') AS mutation_type
    FROM expr e
    LEFT JOIN mut m
           ON e."sample_barcode" = m.sample_barcode
),
group_stats AS (          /* nᵢ and  x̄ᵢ  for each mutation class                              */
    SELECT
        mutation_type,
        COUNT(*)          AS n_i,
        AVG(log_expr)     AS mean_i
    FROM combined
    GROUP BY mutation_type
),
overall AS (              /* grand totals                                                     */
    SELECT
        COUNT(*)          AS N,
        AVG(log_expr)     AS grand_mean
    FROM combined
),
ssb AS (                  /* Sum of Squares Between groups                                    */
    SELECT
        SUM(gs.n_i * POWER(gs.mean_i - o.grand_mean, 2)) AS ss_between
    FROM group_stats gs
    CROSS JOIN overall o
),
ssw AS (                  /* Sum of Squares Within groups                                     */
    SELECT
        SUM(POWER(c.log_expr - gs.mean_i, 2)) AS ss_within
    FROM combined c
    JOIN group_stats gs
      ON c.mutation_type = gs.mutation_type
),
kval AS (                 /* number of groups                                                 */
    SELECT COUNT(*) AS k FROM group_stats
)
SELECT
    o.N                                                AS total_samples,
    k.k                                                AS mutation_type_count,
    ROUND(ssb.ss_between / (k.k - 1)      , 4)         AS mean_square_between,
    ROUND(ssw.ss_within  / (o.N - k.k)    , 4)         AS mean_square_within,
    ROUND( (ssb.ss_between / (k.k - 1))
          / (ssw.ss_within  / (o.N - k.k)), 4)         AS f_statistic
FROM overall o
CROSS JOIN kval  k
CROSS JOIN ssb
CROSS JOIN ssw;