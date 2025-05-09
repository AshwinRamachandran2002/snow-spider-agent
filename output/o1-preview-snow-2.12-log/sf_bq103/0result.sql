SELECT
  COUNT(DISTINCT t."start_position", t."reference_bases", alt.value:"alt"::STRING) AS "number_of_variants",
  SUM(DISTINCT t."AN") AS "total_number_of_alleles",
  SUM(TRY_TO_NUMBER(alt.value:"AC"::STRING)) AS "total_allele_count",
  LISTAGG(DISTINCT vep.value:"SYMBOL"::STRING, ', ') AS "distinct_gene_symbols",
  ROUND(((55064852 - 55039447 + 1)::FLOAT / COUNT(DISTINCT t."start_position", t."reference_bases", alt.value:"alt"::STRING)), 4) AS "density_of_mutations"
FROM
  GNOMAD.GNOMAD.V3_GENOMES__CHR1 t,
  LATERAL FLATTEN(input => t."alternate_bases") alt,
  LATERAL FLATTEN(input => alt.value:"vep") vep
WHERE
  t."start_position" BETWEEN 55039447 AND 55064852;