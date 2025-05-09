WITH region_variants AS (          -- un-nest all alt alleles + VEP annotations
    SELECT
        v."start_position",
        v."end_position",
        v."AN",                                                -- total alleles for the site
        alt.value:"AC"::NUMBER      AS allele_count,           -- allele count for each alt allele
        vep.value:"SYMBOL"::STRING  AS gene_symbol             -- gene symbol from VEP
    FROM GNOMAD.GNOMAD."V3_GENOMES__CHR1"  AS v,
         LATERAL FLATTEN(input => v."alternate_bases")         AS alt,
         LATERAL FLATTEN(input => alt.value:"vep")             AS vep
    WHERE v."reference_name" = 'chr1'
      AND v."start_position" BETWEEN 55039447 AND 55064852
),

per_variant AS (                     -- collapse back to one row per variant
    SELECT
        "start_position",
        "end_position",
        "AN",
        SUM(allele_count) AS variant_ac
    FROM region_variants
    GROUP BY "start_position", "end_position", "AN"
),

stats AS (                           -- summary numbers
    SELECT
        COUNT(*)            AS num_variants,
        SUM(variant_ac)     AS total_allele_count,
        SUM("AN")           AS total_number_of_alleles
    FROM per_variant
),

gene_list AS (                       -- distinct gene symbols
    SELECT
        LISTAGG(DISTINCT gene_symbol, ',') 
            WITHIN GROUP (ORDER BY gene_symbol) AS distinct_gene_symbols
    FROM region_variants
    WHERE gene_symbol IS NOT NULL AND gene_symbol <> ''
)

SELECT
    s.num_variants,
    s.total_allele_count,
    s.total_number_of_alleles,
    g.distinct_gene_symbols,
    (55064852 - 55039447 + 1)::FLOAT / s.num_variants  AS mutation_density   -- bp per variant
FROM stats s
CROSS JOIN gene_list g;