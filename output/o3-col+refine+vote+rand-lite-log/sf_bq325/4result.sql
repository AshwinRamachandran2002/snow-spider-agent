WITH per_gene_study_min AS (        -- 1. best p-value within every (gene,study)
    SELECT
        "gene_id",
        "study_id",
        MIN("pval") AS "min_pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.DISEASE_VARIANT_GENE
    GROUP BY "gene_id", "study_id"
),

top_pairs AS (                      -- 2. global TOP-10 of those minima
    SELECT *
    FROM per_gene_study_min
    ORDER BY "min_pval" ASC
    LIMIT 10
),

picked_variants AS (                -- 3. fetch the actual variant rows
    SELECT
        tp."gene_id",
        tp."study_id",
        dvg."tag_chrom"       AS "chrom",
        dvg."tag_pos"         AS "pos",
        dvg."tag_ref"         AS "ref",
        dvg."tag_alt"         AS "alt",
        tp."min_pval"         AS "pval",
        ROW_NUMBER() OVER (           -- tie-break when multiple variants
            PARTITION BY tp."gene_id", tp."study_id"
            ORDER BY dvg."tag_chrom", dvg."tag_pos"
        ) AS rn
    FROM top_pairs tp
    JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.DISEASE_VARIANT_GENE dvg
      ON  dvg."gene_id"  = tp."gene_id"
      AND dvg."study_id" = tp."study_id"
      AND dvg."pval"     = tp."min_pval"
)

SELECT
    pv."gene_id",
    g."gene_name",
    pv."study_id",
    pv."chrom",
    pv."pos",
    pv."ref",
    pv."alt",
    pv."pval"
FROM picked_variants pv
LEFT JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.GENES g
  ON g."gene_id" = pv."gene_id"
WHERE pv.rn = 1                     -- keep one row per (gene,study)
ORDER BY pv."pval" ASC;