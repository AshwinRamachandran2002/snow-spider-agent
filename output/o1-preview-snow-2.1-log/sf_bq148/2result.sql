SELECT "gene_name", STDDEV("HTSeq__FPKM") AS "Expression_Variability"
FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28
WHERE "project_short_name" = 'TCGA-BRCA'
  AND "sample_type_name" = 'Solid Tissue Normal'
  AND "gene_type" = 'protein_coding'
  AND "HTSeq__FPKM" IS NOT NULL
GROUP BY "gene_name"
HAVING COUNT("HTSeq__FPKM") > 1
ORDER BY "Expression_Variability" DESC NULLS LAST
LIMIT 5;