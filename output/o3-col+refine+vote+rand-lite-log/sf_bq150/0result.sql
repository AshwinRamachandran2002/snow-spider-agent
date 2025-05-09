WITH /* ---------------------------------------------------------
     1.  mutation classes per BRCA sample for TP53
----------------------------------------------------------------*/
mut AS (
    SELECT DISTINCT
        m."sample_barcode_tumor"     AS "sample_barcode",
        m."Variant_Classification"   AS "mut_class"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3" m
    WHERE m."project_short_name" = 'TCGA-BRCA'
      AND m."Hugo_Symbol"        = 'TP53'
),
/* ---------------------------------------------------------
     2.  TP53 RNA-Seq expression (log10 transformed)
----------------------------------------------------------------*/
expr AS (
    SELECT
        r."sample_barcode",
        LN(r."normalized_count") / LN(10)         AS "log10_expr"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM" r
    WHERE r."project_short_name" = 'TCGA-BRCA'
      AND r."HGNC_gene_symbol"   = 'TP53'
      AND r."normalized_count"  > 0          -- exclude zeros / nulls
),
/* ---------------------------------------------------------
     3.  Dataset labelled by mutation class (or Wild_Type)
----------------------------------------------------------------*/
dataset AS (
    SELECT
        COALESCE(m."mut_class", 'Wild_Type') AS "group_label",
        e."log10_expr"
    FROM expr e
    LEFT JOIN mut m
           ON e."sample_barcode" = m."sample_barcode"
),
/* ---------------------------------------------------------
     4.  Grand mean & total N
----------------------------------------------------------------*/
grand AS (
    SELECT
        COUNT(*)               AS "N",
        AVG("log10_expr")      AS "grand_mean"
    FROM dataset
),
/* ---------------------------------------------------------
     5.  Per-group counts and means
----------------------------------------------------------------*/
grp AS (
    SELECT
        "group_label",
        COUNT(*)               AS "n_j",
        AVG("log10_expr")      AS "mean_j"
    FROM dataset
    GROUP BY "group_label"
),
/* ---------------------------------------------------------
     6.  Sum of Squares Between groups (SSB)
----------------------------------------------------------------*/
ssb AS (
    SELECT
        SUM(g."n_j" * POWER(g."mean_j" - gr."grand_mean", 2)) AS "SSB"
    FROM grp g, grand gr
),
/* ---------------------------------------------------------
     7.  Sum of Squares Within groups (SSW)
----------------------------------------------------------------*/
ssw AS (
    SELECT
        SUM(POWER(d."log10_expr" - g."mean_j", 2)) AS "SSW"
    FROM dataset d
    JOIN grp g USING ("group_label")
),
/* ---------------------------------------------------------
     8.  Assemble ANOVA components
----------------------------------------------------------------*/
anova AS (
    SELECT
        gr."N"                                         AS "total_samples",
        (SELECT COUNT(*) FROM grp)                     AS "n_groups",
        ssb."SSB",
        ssw."SSW"
    FROM grand gr, ssb, ssw
)
SELECT
    "total_samples",
    "n_groups",
    /* Mean Square Between Groups                                  */
    "SSB" / ("n_groups" - 1)                                 AS "MS_between",
    /* Mean Square Within Groups                                   */
    "SSW" / ("total_samples" - "n_groups")                    AS "MS_within",
    /* F-statistic                                                */
    ("SSB" / ("n_groups" - 1)) / 
    ("SSW" / ("total_samples" - "n_groups"))                  AS "F_statistic"
FROM anova;