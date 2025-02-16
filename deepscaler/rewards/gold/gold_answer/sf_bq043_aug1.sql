-- Task: Retrieve the gender, vital status, and days to death for bladder cancer patients with CDKN2A mutations in the 'TCGA-BLCA' project, using clinical data from the Genomic Data Commons Release 39 and somatic mutation data from the hg19 human genome reference in Feb 2017.
SELECT
  case_list."Variant_Type" AS "Variant_Type",
  case_list."case_barcode" AS "case_barcode",
  clinical."demo__gender" AS "gender",
  clinical."demo__vital_status" AS "vital_status",
  clinical."demo__days_to_death" AS "days_to_death"
FROM (
  SELECT
    mutation."case_barcode",
    mutation."Variant_Type"
  FROM
    "TCGA"."TCGA_VERSIONED"."SOMATIC_MUTATION_HG19_DCC_2017_02" AS mutation
  WHERE
    mutation."Hugo_Symbol" = 'CDKN2A'
    AND mutation."project_short_name" = 'TCGA-BLCA'
  GROUP BY
    mutation."case_barcode",
    mutation."Variant_Type"
) AS case_list
INNER JOIN
  "TCGA"."TCGA_VERSIONED"."CLINICAL_GDC_R39" AS clinical
ON
  case_list."case_barcode" = clinical."submitter_id"
ORDER BY
  case_list."case_barcode";