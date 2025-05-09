/* -----------------------------------------------
   Summary statistics for gnomAD-v3 variants
   in chr1:55,039,447-55,064,852 (length = 25 406 bp)
   ----------------------------------------------- */
WITH var_alleles AS (            -- 1 row per ALT allele
    SELECT
        v."start_position"                          AS pos,
        v."AN"                                      AS an,
        ab.value:"AC"::NUMBER                       AS ac,
        ab.value                                    AS ab_json         -- keep whole ALT json for VEP
    FROM   GNOMAD.GNOMAD."V3_GENOMES__CHR1"   v
           , LATERAL FLATTEN ( INPUT => v."alternate_bases") ab
    WHERE  v."reference_name" = 'chr1'
      AND  v."start_position" BETWEEN 55039447 AND 55064852
),
gene_syms AS (              -- extract distinct gene symbols per allele
    SELECT DISTINCT
           v.pos,
           vep.value:"SYMBOL"::STRING               AS symbol
    FROM   var_alleles              v
           , LATERAL FLATTEN ( INPUT => v.ab_json:"vep") vep
    WHERE  vep.value:"SYMBOL" IS NOT NULL
),
summary AS (                 -- basic counts
    SELECT
        COUNT(*)  AS variant_count,
        SUM(ac)   AS total_allele_count,
        SUM(an)   AS total_number_of_alleles
    FROM var_alleles
),
gene_list AS (               -- comma–separated list of genes
    SELECT ARRAY_TO_STRING(ARRAY_AGG(DISTINCT symbol), ', ') AS gene_symbols
    FROM   gene_syms
)
SELECT
    s.variant_count                       AS number_of_variants,
    s.total_allele_count                  AS total_allele_count,
    s.total_number_of_alleles             AS total_AN,
    g.gene_symbols                        AS distinct_gene_symbols,
    25406                                 AS region_length_bp,
    ROUND(25406.0 / s.variant_count, 4)   AS length_per_variant_bp
FROM   summary  s
CROSS  JOIN gene_list g;