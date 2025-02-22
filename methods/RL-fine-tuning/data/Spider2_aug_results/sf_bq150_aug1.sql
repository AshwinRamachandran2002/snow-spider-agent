-- Task: Calculate the average log10-transformed TP53 expression levels for each Variant_Type in TCGA-BRCA samples.
WITH
cohortExpr AS (
  SELECT
    "sample_barcode",
    LOG(10, "normalized_count") AS "expr"
  FROM
    "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
  WHERE
    "project_short_name" = 'TCGA-BRCA'
    AND "HGNC_gene_symbol" = 'TP53'
    AND "normalized_count" IS NOT NULL
    AND "normalized_count" > 0
),
cohortVar AS (
  SELECT
    "Variant_Type",
    "sample_barcode_tumor" AS "sample_barcode"
  FROM
    "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"
  WHERE
    "SYMBOL" = 'TP53'
),
cohort AS (
  SELECT
    e."sample_barcode" AS "sample_barcode",
    v."Variant_Type" AS "Variant_Type",
    e."expr"
  FROM
    cohortExpr e
  JOIN
    cohortVar v
  ON
    e."sample_barcode" = v."sample_barcode"
)
SELECT
  "Variant_Type",
  AVG("expr") AS "average_expr",
  COUNT("sample_barcode") AS "n"
FROM
  cohort
GROUP BY
  "Variant_Type";