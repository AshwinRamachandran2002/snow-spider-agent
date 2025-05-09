/*  Top-10 genes with the strongest associations across all studies.
    Step-1 :  join GWAS variants to their mapped genes.
    Step-2 :  within each (study_id , gene_id) pair keep the minimum p-value.
    Step-3 :  for every gene take the best (smallest) of those study–specific minima.
    Step-4 :  order by that overall best p-value and return the 10 strongest genes.     */

WITH mapped AS (           -- Step-1
    SELECT
        g."study_id",
        vg."gene_id",
        g."pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."SA_GWAS"      g
    JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."VARIANT_GENE" vg
         ON  g."chrom" = vg."chr_id"
         AND g."pos"   = vg."position"
         AND g."ref"   = vg."ref_allele"
         AND g."alt"   = vg."alt_allele"
    WHERE g."pval" IS NOT NULL
),

per_study_gene AS (        -- Step-2
    SELECT
        "study_id",
        "gene_id",
        MIN("pval") AS "min_pval"
    FROM mapped
    GROUP BY "study_id", "gene_id"
),

best_overall AS (          -- Step-3
    SELECT
        "gene_id",
        MIN("min_pval") AS "best_pval_overall"
    FROM per_study_gene
    GROUP BY "gene_id"
)

SELECT                      -- Step-4
    "gene_id",
    "best_pval_overall"
FROM best_overall
ORDER BY "best_pval_overall" ASC NULLS LAST
LIMIT 10;