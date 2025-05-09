WITH expr_mut AS (
    /* 1.  TP53 expression joined with TP53 mutation class (or Wildtype)  */
    SELECT
        e."sample_barcode",
        COALESCE(m."mutation_type", 'Wildtype')          AS "mutation_type",
        LOG(10, e."normalized_count")                    AS "log_expr"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM" e
    LEFT JOIN (
        SELECT DISTINCT
               "sample_barcode_tumor"                    AS "sample_barcode",
               "Variant_Classification"                  AS "mutation_type"
        FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
        WHERE "project_short_name" = 'TCGA-BRCA'
          AND "Hugo_Symbol"        = 'TP53'
    ) m
      ON e."sample_barcode" = m."sample_barcode"
    WHERE e."project_short_name" = 'TCGA-BRCA'
      AND e."HGNC_gene_symbol"   = 'TP53'
), stats AS (
    /* 2.  Overall counts and grand mean */
    SELECT
        COUNT(*)                         AS "N",
        COUNT(DISTINCT "mutation_type")  AS "k",
        AVG("log_expr")                  AS "grand_mean"
    FROM expr_mut
), group_stats AS (
    /* 3.  Per-mutation-type sample size and mean */
    SELECT
        "mutation_type",
        COUNT(*)        AS "n_j",
        AVG("log_expr") AS "group_mean"
    FROM expr_mut
    GROUP BY "mutation_type"
), ssb AS (
    /* 4.  Sum of Squares Between groups */
    SELECT
        SUM(gs."n_j" * POWER(gs."group_mean" - s."grand_mean", 2)) AS "SSB"
    FROM group_stats gs, stats s
), ssw AS (
    /* 5.  Sum of Squares Within groups */
    SELECT
        SUM(POWER(em."log_expr" - gs."group_mean", 2)) AS "SSW"
    FROM expr_mut em
    JOIN group_stats gs USING ("mutation_type")
), final AS (
    /* 6.  Degrees of freedom and mean squares */
    SELECT
        s."N",
        s."k",
        b."SSB",
        w."SSW",
        (s."k" - 1)        AS "df_between",
        (s."N" - s."k")    AS "df_within"
    FROM stats s, ssb b, ssw w
)
SELECT
    "N"                                            AS total_samples,
    "k"                                            AS mutation_type_count,
    ("SSB" / "df_between")                         AS MSB,
    ("SSW" / "df_within")                          AS MSW,
    (("SSB" / "df_between") / ("SSW" / "df_within")) AS F_statistic
FROM final;