WITH coloc_filt AS (   -- step-1: filter coloc table by all fixed criteria
    SELECT
        "left_study",
        "right_study",
        "coloc_log2_h4_h3"
    FROM OPEN_TARGETS_GENETICS_1.GENETICS.VARIANT_DISEASE_COLOC
    WHERE "right_gene_id"     = 'ENSG00000169174'
      AND "coloc_h4"          > 0.8
      AND "coloc_h3"          < 0.02
      AND "right_bio_feature" = 'IPSC'
      AND "left_chrom"        = '1'
      AND "left_pos"          = 55029009
      AND "left_ref"          = 'C'
      AND "left_alt"          = 'T'
),
filt AS (               -- step-2: keep only rows whose GWAS trait mentions “lesterol levels”
    SELECT c.*
    FROM coloc_filt c
    JOIN OPEN_TARGETS_GENETICS_1.GENETICS.STUDIES s
      ON s."study_id" = c."left_study"
    WHERE s."trait_reported" ILIKE '%lesterol levels%'
),
stats AS (              -- step-3: aggregate statistics
    SELECT
        AVG("coloc_log2_h4_h3")                                 AS avg_log2_h4_h3,
        VAR_SAMP("coloc_log2_h4_h3")                            AS var_log2_h4_h3,
        MAX("coloc_log2_h4_h3") - MIN("coloc_log2_h4_h3")       AS max_min_diff_log2_h4_h3,
        MAX("coloc_log2_h4_h3")                                 AS max_val
    FROM filt
),
max_study AS (          -- step-4: obtain the right_study responsible for the maximum value
    SELECT "right_study"
    FROM filt, stats
    WHERE filt."coloc_log2_h4_h3" = stats.max_val
    ORDER BY "right_study"        -- deterministic tie-break
    LIMIT 1
)
SELECT
    stats.avg_log2_h4_h3,
    stats.var_log2_h4_h3,
    stats.max_min_diff_log2_h4_h3,
    max_study."right_study" AS qtl_source_of_max_log2_h4_h3
FROM stats
CROSS JOIN max_study;