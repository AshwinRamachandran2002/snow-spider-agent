/* Cytobands on chr1 (TCGA-KICH) whose amplification, gain,
   and heterozygous-deletion frequencies each rank in the top 11 */
WITH cytoband_counts AS (        /* tally events per cytoband */
    SELECT
        c."cytoband_name",
        /* amplifications  ≥4 copies */
        SUM(CASE WHEN g."max_copy_number" >= 4 THEN 1 END) AS "amp_cnt",
        /* gains = 3 copies */
        SUM(CASE WHEN g."max_copy_number"  = 3 THEN 1 END) AS "gain_cnt",
        /* heterozygous deletions = 1 copy */
        SUM(CASE WHEN g."max_copy_number"  = 1 THEN 1 END) AS "het_del_cnt"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_GENE_LEVEL_HG38_GDC_R36 g
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38                       c
      ON g."chromosome" = c."chromosome"
     AND g."start_pos"  <= c."hg38_stop"
     AND g."end_pos"    >= c."hg38_start"
    WHERE g."project_short_name" = 'TCGA-KICH'      /* kidney cancer cohort */
      AND g."chromosome"         = 'chr1'
    GROUP BY c."cytoband_name"
),
ranked AS (                    /* rank by each alteration type */
    SELECT
        "cytoband_name",
        RANK() OVER (ORDER BY COALESCE("amp_cnt",0)     DESC NULLS LAST) AS "amp_rnk",
        RANK() OVER (ORDER BY COALESCE("gain_cnt",0)    DESC NULLS LAST) AS "gain_rnk",
        RANK() OVER (ORDER BY COALESCE("het_del_cnt",0) DESC NULLS LAST) AS "het_del_rnk"
    FROM cytoband_counts
)
SELECT
    "cytoband_name"
FROM ranked
WHERE "amp_rnk"  <= 11
  AND "gain_rnk" <= 11
  AND "het_del_rnk" <= 11
ORDER BY "cytoband_name";