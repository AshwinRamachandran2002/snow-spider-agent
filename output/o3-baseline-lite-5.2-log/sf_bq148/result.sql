SELECT
  "gene_name",
  VAR_SAMP("HTSeq__FPKM_UQ") AS "expression_variance"
FROM
  "TCGA"."TCGA_VERSIONED"."RNASEQ_HG38_GDC_R28"
WHERE
  "project_short_name" = 'TCGA-BRCA'
  AND "sample_type_name" = 'Solid Tissue Normal'
  AND "gene_type" = 'protein_coding'
GROUP BY
  "gene_name"
ORDER BY
  "expression_variance" DESC NULLS LAST,
  "gene_name"
LIMIT 5;