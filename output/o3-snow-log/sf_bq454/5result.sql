/*---------------------------------------------------------------
  Common (AF ≥ 0.05) AUTOSOMAL variants – distribution of carriers
  across super-populations, using the pre-computed population
  allele-frequency fields in the VARIANTS table to avoid the very
  expensive per–sample FLATTEN of every genotype call.
----------------------------------------------------------------*/
WITH super_pop_samples AS (    -- map each sample to its super-population
    SELECT
        "Sample"              AS sample_id,
        "Super_Population"
    FROM _1000_GENOMES._1000_GENOMES.SAMPLE_INFO
    WHERE "Super_Population" IS NOT NULL
),
super_pop_size AS (           -- size of every super-population
    SELECT
        "Super_Population",
        COUNT(DISTINCT sample_id) AS population_size
    FROM super_pop_samples
    GROUP BY "Super_Population"
),
/*----------------------------------------------------------------
  Unpivot the per-population allele-frequency columns so that every
  row represents one (variant , super-population) pair.
----------------------------------------------------------------*/
variant_af_unpivot AS (
    SELECT  v."reference_name"  AS chromosome ,
            v."start"           AS start_pos ,
            v."alternate_bases" AS alt_bases ,
            'AFR'               AS super_pop ,
            v."AFR_AF"          AS af
    FROM _1000_GENOMES._1000_GENOMES.VARIANTS v
    WHERE v."reference_name" NOT IN ('X','Y','MT')
          AND v."AFR_AF" IS NOT NULL
          AND v."AFR_AF" >= 0.05

    UNION ALL
    SELECT  v."reference_name", v."start", v."alternate_bases",
            'EUR', v."EUR_AF"
    FROM _1000_GENOMES._1000_GENOMES.VARIANTS v
    WHERE v."reference_name" NOT IN ('X','Y','MT')
          AND v."EUR_AF" IS NOT NULL
          AND v."EUR_AF" >= 0.05

    UNION ALL
    SELECT  v."reference_name", v."start", v."alternate_bases",
            'AMR', v."AMR_AF"
    FROM _1000_GENOMES._1000_GENOMES.VARIANTS v
    WHERE v."reference_name" NOT IN ('X','Y','MT')
          AND v."AMR_AF" IS NOT NULL
          AND v."AMR_AF" >= 0.05

    UNION ALL
    SELECT  v."reference_name", v."start", v."alternate_bases",
            'EAS', v."ASN_AF"   -- 1000 G uses ASN for East Asian
    FROM _1000_GENOMES._1000_GENOMES.VARIANTS v
    WHERE v."reference_name" NOT IN ('X','Y','MT')
          AND v."ASN_AF" IS NOT NULL
          AND v."ASN_AF" >= 0.05
),
/*----------------------------------------------------------------
  Translate allele-frequency to an estimated number of samples
  carrying ≥1 alternate allele in that super-population.  Because
  AF is per-allele, the expected number of carriers is rounded up.
----------------------------------------------------------------*/
variant_sample_counts AS (
    SELECT
        v.super_pop,
        v.chromosome,
        v.start_pos,
        v.alt_bases,
        v.af,
        sps.population_size,
        LEAST( CEIL( v.af * sps.population_size )        /* # carriers  */
             , sps.population_size)  AS samples_with_alt  -- cannot exceed pop size
    FROM variant_af_unpivot v
    JOIN super_pop_size   sps
      ON v.super_pop = sps."Super_Population"
)
/*----------------------------------------------------------------
  Final aggregation: for each super-population, count how many
  variants are shared by exactly N samples.
----------------------------------------------------------------*/
SELECT
    super_pop                                     AS super_population ,
    population_size                               AS population_size ,
    TRUE                                          AS is_common_variant ,
    samples_with_alt                              AS samples_having_variant ,
    COUNT(*)                                      AS variants_shared_by_that_many_samples
FROM variant_sample_counts
GROUP BY super_pop , population_size , samples_with_alt
ORDER BY super_pop , samples_with_alt;