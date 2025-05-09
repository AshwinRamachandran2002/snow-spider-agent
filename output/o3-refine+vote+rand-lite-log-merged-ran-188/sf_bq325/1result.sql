/*  Return the 10 genes whose variants show the strongest GWAS
    associations across all studies.
    -------------------------------------------------------------------
    – First keep, for every study, only its 500 most-significant
      variants (p-value ≤ 5 × 10⁻⁸).  This reduces the data volume
      dramatically yet safely retains the variants that can
      contribute to the global top-10 list.
*/

WITH gwas_top AS (          -- ≤ 500 best variants per study
    SELECT
        "study_id",
        "chrom",
        "pos",
        "ref",
        "alt",
        "pval",
        ROW_NUMBER() OVER (
            PARTITION BY "study_id"
            ORDER BY "pval"               -- lowest p-values first
        ) AS rn
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.SA_GWAS
    WHERE "pval" <= 5e-8                  -- genome-wide significance
    QUALIFY rn <= 500
),

joined AS (                 -- map each variant to a gene
    SELECT
        g."study_id",
        vg."gene_id",
        g."chrom",
        g."pos",
        g."ref",
        g."alt",
        g."pval"
    FROM gwas_top                                             g
    JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.VARIANT_GENE vg
      ON  g."chrom" = vg."chr_id"
      AND g."pos"   = vg."position"
      AND g."ref"   = vg."ref_allele"
      AND g."alt"   = vg."alt_allele"
),

per_study_gene_best AS (    -- best variant per (study , gene)
    SELECT
        "study_id",
        "gene_id",
        "chrom",
        "pos",
        "ref",
        "alt",
        "pval",
        ROW_NUMBER() OVER (
            PARTITION BY "study_id", "gene_id"
            ORDER BY "pval"
        ) AS rn
    FROM joined
    QUALIFY rn = 1
),

per_gene_best AS (          -- best association per gene across studies
    SELECT
        "gene_id",
        "study_id",
        "chrom",
        "pos",
        "ref",
        "alt",
        "pval",
        ROW_NUMBER() OVER (
            PARTITION BY "gene_id"
            ORDER BY "pval"
        ) AS gene_rn
    FROM per_study_gene_best
)

SELECT
    "gene_id",
    "study_id",
    "chrom",
    "pos",
    "ref",
    "alt",
    "pval"
FROM per_gene_best
WHERE gene_rn = 1           -- overall best per gene
ORDER BY "pval" ASC
LIMIT 10;