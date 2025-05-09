/*  ------------------------------------------------------------
    Common autosomal variants (AF ≥ 0.05) – distribution by
    number of carrier samples inside each super-population
    ------------------------------------------------------------ */
WITH calls AS (       -- one row per (variant , sample)
    SELECT
        v."reference_name"                                         AS chr,
        v."start"                                                  AS pos,
        TO_VARCHAR(v."names")                                      AS variant_id,
        c.value:"call_set_name"::STRING                            AS sample_id,
        /* number of ALT alleles (0-2) carried by the sample */
        COALESCE(c.value:"genotype"[0]::INT , 0)
      + COALESCE(c.value:"genotype"[1]::INT , 0)                   AS alt_allele_cnt
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"  v
         , LATERAL FLATTEN( INPUT => v."call" )      c
    WHERE v."reference_name" NOT IN ('X','Y','MT')                 -- autosomes only
),
sample_genotypes AS (
    SELECT
        chr,
        pos,
        variant_id,
        si."Super_Population"                                      AS super_pop,
        alt_allele_cnt
    FROM calls  cg
    JOIN "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"  si
      ON cg.sample_id = si."Sample"
),
/* per-variant statistics inside every super-population */
variant_superpop_stats AS (
    SELECT
        chr,
        pos,
        variant_id,
        super_pop,
        SUM(alt_allele_cnt)                                        AS total_alt_alleles,
        COUNT(*) * 2                                               AS total_alleles,
        SUM( IFF(alt_allele_cnt > 0 , 1 , 0) )                     AS carrier_samples
    FROM sample_genotypes
    GROUP BY chr , pos , variant_id , super_pop
),
/* retain only common variants (AF ≥ 0.05) */
common_variants AS (
    SELECT
        *,
        total_alt_alleles / total_alleles                          AS allele_frequency
    FROM variant_superpop_stats
    WHERE total_alt_alleles / total_alleles >= 0.05
),
/* distribution of common variants by #carrier samples */
distribution AS (
    SELECT
        super_pop,
        carrier_samples                                            AS samples_with_variant,
        COUNT(*)                                                   AS variants_shared_by_samples
    FROM common_variants
    GROUP BY super_pop , carrier_samples
),
/* size of every super-population */
pop_sizes AS (
    SELECT
        "Super_Population"                                         AS super_pop,
        COUNT(*)                                                   AS population_size
    FROM "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
    GROUP BY "Super_Population"
)
/* ---------------------------  final result  --------------------------- */
SELECT
    d.super_pop                                                   AS super_population,
    ps.population_size,
    TRUE                                                          AS is_common_variant,   -- AF ≥ 0.05
    d.samples_with_variant,
    d.variants_shared_by_samples
FROM distribution d
JOIN pop_sizes  ps
  ON d.super_pop = ps.super_pop
ORDER BY
    super_population ,
    samples_with_variant;