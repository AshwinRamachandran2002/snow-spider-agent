/*  Region: chr1:55,039,447-55,064,852  (length = 25,406 bp)  */
/*  gnomAD v3 genomes ‑ chromosome-1 table: GNOMAD.GNOMAD.V3_GENOMES__CHR1  */

WITH region AS (          -- all variants that fall in the interval
    SELECT *
    FROM   GNOMAD.GNOMAD."V3_GENOMES__CHR1"
    WHERE  "start_position" BETWEEN 55039447 AND 55064852
),

/* sum the allele counts across every alternate allele of every variant   */
allele_totals AS (
    SELECT SUM(ab.value:"AC"::NUMBER) AS total_allele_count
    FROM   region
           ,LATERAL FLATTEN( INPUT => region."alternate_bases") ab
),

/* collect every distinct gene symbol reported by VEP                     */
genes AS (
    SELECT DISTINCT vep.value:"SYMBOL"::STRING AS gene_symbol
    FROM   region
           ,LATERAL FLATTEN( INPUT => region."alternate_bases") ab
           ,LATERAL FLATTEN( INPUT => ab.value:"vep")             vep
    WHERE  vep.value:"SYMBOL" IS NOT NULL
),

gene_list AS (
    SELECT LISTAGG(gene_symbol, ',') WITHIN GROUP (ORDER BY gene_symbol) AS gene_symbols
    FROM   genes
),

/* basic variant counts and total AN                                       */
variant_stats AS (
    SELECT COUNT(*) AS num_variants,
           SUM("AN") AS total_an
    FROM   region
)

/* ----------------------------------------------------------------------- */
SELECT  v.num_variants,
        a.total_allele_count,
        v.total_an,
        g.gene_symbols,
        /* mutation density = region length / #variants                    */
        ( (55064852 - 55039447 + 1)::FLOAT / NULLIF(v.num_variants,0) ) 
            AS mutation_density
FROM    variant_stats v
        CROSS JOIN allele_totals a
        CROSS JOIN gene_list    g;