WITH expression_data AS (
    SELECT DISTINCT "case_barcode", 
           LOG(10, "normalized_count") AS log_expression
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA' 
      AND "HGNC_gene_symbol" = 'TP53' 
      AND "normalized_count" > 0
),

mutation_data AS (
    SELECT "case_barcode", "Variant_Classification"
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA' 
      AND "Hugo_Symbol" = 'TP53'
),

cases_multiple_mutations AS (
    SELECT "case_barcode"
    FROM mutation_data
    GROUP BY "case_barcode"
    HAVING COUNT(DISTINCT "Variant_Classification") > 1
),

mutation_per_case AS (
    SELECT "case_barcode", MIN("Variant_Classification") AS "Variant_Classification"
    FROM mutation_data
    WHERE "case_barcode" NOT IN (SELECT "case_barcode" FROM cases_multiple_mutations)
    GROUP BY "case_barcode"
),

final_data AS (
    SELECT 
        ed."case_barcode",
        COALESCE(mp."Variant_Classification", 'No_Mutation') AS "Variant_Classification",
        ed.log_expression
    FROM expression_data ed
    LEFT JOIN mutation_per_case mp
        ON ed."case_barcode" = mp."case_barcode"
    -- Exclude cases with multiple mutation types
    WHERE ed."case_barcode" NOT IN (
        SELECT "case_barcode" FROM cases_multiple_mutations
    )
),

grand_mean AS (
    SELECT AVG(log_expression) AS grand_mean
    FROM final_data
),

group_stats AS (
    SELECT 
        "Variant_Classification",
        COUNT(*) AS n_j,
        AVG(log_expression) AS group_mean
    FROM final_data
    GROUP BY "Variant_Classification"
),

ssb AS (
    SELECT SUM(gs.n_j * POWER(gs.group_mean - gm.grand_mean, 2)) AS SSB
    FROM group_stats gs
    CROSS JOIN grand_mean gm
),

ssw AS (
    SELECT SUM(POWER(fd.log_expression - gs.group_mean,2)) AS SSW
    FROM final_data fd
    JOIN group_stats gs ON fd."Variant_Classification" = gs."Variant_Classification"
),

degrees_of_freedom AS (
    SELECT 
        (SELECT COUNT(DISTINCT "Variant_Classification") FROM final_data) - 1 AS df_between,
        (SELECT COUNT(*) FROM final_data) - (SELECT COUNT(DISTINCT "Variant_Classification") FROM final_data) AS df_within
),

mean_squares AS (
    SELECT 
        ssb.SSB / df.df_between AS mean_square_between,
        ssw.SSW / df.df_within AS mean_square_within
    FROM ssb, ssw, degrees_of_freedom df
),

f_statistic AS (
    SELECT mean_squares.mean_square_between / mean_squares.mean_square_within AS F_statistic
    FROM mean_squares
)

SELECT 
    (SELECT COUNT(*) FROM final_data) AS "Total_samples",
    (SELECT COUNT(DISTINCT "Variant_Classification") FROM final_data) AS "Number_of_mutation_types",
    ROUND(mean_squares.mean_square_between, 4) AS "Mean_square_between",
    ROUND(mean_squares.mean_square_within, 4) AS "Mean_square_within",
    ROUND(f_statistic.F_statistic, 4) AS "F_statistic"
FROM mean_squares
CROSS JOIN f_statistic;