WITH per_variant_stats AS (
    SELECT t."start_position",
           t."AN",
           SUM(ab.value:"AC"::INT) AS "total_AC"
    FROM GNOMAD.GNOMAD."V3_GENOMES__CHR1" t,
         TABLE(FLATTEN(input => t."alternate_bases")) ab
    WHERE t."start_position" BETWEEN 55039447 AND 55064852
    GROUP BY t."start_position", t."AN"
),
gene_symbols AS (
    SELECT DISTINCT vep.value:"SYMBOL"::STRING AS "gene_symbol"
    FROM GNOMAD.GNOMAD."V3_GENOMES__CHR1" t,
         TABLE(FLATTEN(input => t."alternate_bases")) ab,
         TABLE(FLATTEN(input => ab.value:"vep")) vep
    WHERE t."start_position" BETWEEN 55039447 AND 55064852
)
SELECT
    (SELECT COUNT(*) FROM per_variant_stats) AS "number_of_variants",
    (SELECT SUM("total_AC") FROM per_variant_stats) AS "total_allele_count",
    (SELECT SUM("AN") FROM per_variant_stats) AS "total_number_of_alleles",
    ROUND( (55064852 - 55039447 + 1)::FLOAT / (SELECT COUNT(*) FROM per_variant_stats), 4 ) AS "density_of_mutations",
    (SELECT LISTAGG(DISTINCT "gene_symbol", ', ') WITHIN GROUP (ORDER BY "gene_symbol") FROM gene_symbols) AS "gene_symbols";