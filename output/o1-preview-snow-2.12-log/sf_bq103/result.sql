WITH variants AS (
  SELECT *
  FROM "GNOMAD"."GNOMAD"."V3_GENOMES__CHR1"
  WHERE "start_position" BETWEEN 55039447 AND 55064852
),
num_variants AS (
  SELECT COUNT(*) AS num_variants
  FROM variants
),
total_number_of_alleles AS (
  SELECT SUM("AN") AS total_number_of_alleles
  FROM variants
),
total_allele_count AS (
  SELECT SUM((f.value:"AC")::INT) AS total_allele_count
  FROM variants v,
       LATERAL FLATTEN(input => v."alternate_bases") f
),
density_of_mutations AS (
  SELECT ROUND(((55064852 - 55039447 + 1)::FLOAT / num_variants.num_variants), 4) AS density_of_mutations
  FROM num_variants
),
distinct_gene_symbols AS (
  SELECT LISTAGG(DISTINCT gene_symbol, ', ') WITHIN GROUP (ORDER BY gene_symbol) AS distinct_gene_symbols
  FROM (
    SELECT vep_item.value:"SYMBOL"::STRING AS gene_symbol
    FROM variants v,
         LATERAL FLATTEN(input => v."alternate_bases") f,
         LATERAL FLATTEN(input => f.value:"vep") vep_item
    WHERE vep_item.value:"SYMBOL"::STRING IS NOT NULL AND vep_item.value:"SYMBOL"::STRING <> ''
  )
)
SELECT
  nv.num_variants,
  tna.total_number_of_alleles,
  tac.total_allele_count,
  dm.density_of_mutations,
  dgs.distinct_gene_symbols
FROM num_variants nv
CROSS JOIN total_number_of_alleles tna
CROSS JOIN total_allele_count tac
CROSS JOIN density_of_mutations dm
CROSS JOIN distinct_gene_symbols dgs;