/*--------------------------------------------------------------
   Common autosomal variants (AF ≥ 0.05) by super-population
   – counts of how many variants are shared by each exact number
     of samples in that super-population
--------------------------------------------------------------*/
WITH sample_pop AS (        /* sample ↔ super-population map  */
    SELECT
        "Sample"                   AS sample_name ,
        "Super_Population"         AS super_population
    FROM _1000_GENOMES._1000_GENOMES.SAMPLE_INFO
    WHERE "Super_Population" IS NOT NULL
),
pop_size AS (               /* size of every super-population  */
    SELECT
        super_population ,
        COUNT(DISTINCT sample_name) AS population_size
    FROM sample_pop
    GROUP BY super_population
),
/*--- explode genotypes, keep only autosomes ------------------*/
flattened AS (
    SELECT
        v."reference_name"                      AS chr ,
        v."start"                              AS pos ,
        v."alternate_bases"::STRING            AS alt_bases ,
        f.value:"call_set_name"::STRING        AS sample_name ,
        f.value:"genotype"[0]::INT             AS g0 ,
        f.value:"genotype"[1]::INT             AS g1
    FROM _1000_GENOMES._1000_GENOMES.VARIANTS v ,
         LATERAL FLATTEN(input => v."call") f
    WHERE v."reference_name" NOT IN ('X','Y','MT')          -- autosomes only
),
/*--- keep only samples that carry ≥1 alternate allele --------*/
variant_genotypes AS (
    SELECT
        chr , pos , alt_bases , sample_name ,
        (g0 + g1)               AS alt_allele_cnt        -- 0,1 or 2
    FROM flattened
    WHERE (g0 + g1) > 0                                  -- non-reference
),
/*--- attach super-population to every carrier ----------------*/
variant_sample_pop AS (
    SELECT
        vg.chr , vg.pos , vg.alt_bases ,
        sp.super_population ,
        vg.sample_name ,
        vg.alt_allele_cnt
    FROM variant_genotypes vg
    JOIN sample_pop sp
      ON vg.sample_name = sp.sample_name
),
/*--- per-variant counts inside each super-population ---------*/
variant_pop_counts AS (
    SELECT
        chr , pos , alt_bases , super_population ,
        COUNT(DISTINCT sample_name)     AS alt_sample_count ,
        SUM(alt_allele_cnt)             AS total_alt_alleles
    FROM variant_sample_pop
    GROUP BY chr , pos , alt_bases , super_population
),
/*--- keep only “common” variants (AF ≥ 0.05) -----------------*/
freq_calc AS (
    SELECT
        vpc.* ,
        ps.population_size ,
        total_alt_alleles / (2.0 * ps.population_size) AS allele_frequency
    FROM variant_pop_counts vpc
    JOIN pop_size ps
      ON vpc.super_population = ps.super_population
    WHERE total_alt_alleles / (2.0 * ps.population_size) >= 0.05
),
/*--- final aggregation: how many variants share the same      *
 *    alt-sample count in each super-population                */
final_counts AS (
    SELECT
        super_population ,
        population_size ,
        TRUE                         AS is_common_variant ,
        alt_sample_count ,
        COUNT(*)                     AS variant_count
    FROM freq_calc
    GROUP BY super_population , population_size , alt_sample_count
)
SELECT
    super_population ,
    population_size ,
    is_common_variant ,
    alt_sample_count ,
    variant_count
FROM final_counts
ORDER BY super_population , alt_sample_count;