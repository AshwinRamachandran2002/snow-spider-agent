/*--------------------------------------------------------------------
  Common autosomal variants (allele-frequency ≥ 0.05) – distribution
  of the number of samples that share each variant within every
  1000 Genomes super-population.
--------------------------------------------------------------------*/
WITH super_pop_sizes AS (             -- population size of each super-pop
    SELECT
        "Super_Population"                AS super_pop,
        COUNT(*)                          AS pop_size
    FROM  "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
    WHERE "Super_Population" IS NOT NULL
    GROUP BY "Super_Population"
),

/* autosomal variants only, keeping the four allele-frequency columns
   reported in the VCF header (AFR_AF, EUR_AF, AMR_AF, ASN_AF)        */
variant_base AS (
    SELECT
        CONCAT(
            "reference_name", ':',
            "start", ':',
            "reference_bases", ':',
            "alternate_bases"[0]::string
        )                                    AS variant_id,
        "AFR_AF",
        "EUR_AF",
        "AMR_AF",
        "ASN_AF"
    FROM  "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"
    WHERE "reference_name" NOT IN ('X','Y','MT')          -- autosomes
),

/* explode each variant into the super-populations where its
   allele-frequency is ≥ 0.05                                            */
variant_superpop AS (
    SELECT variant_id, 'AFR' AS super_pop, "AFR_AF" AS allele_freq
      FROM variant_base WHERE "AFR_AF" IS NOT NULL AND "AFR_AF" >= 0.05
    UNION ALL
    SELECT variant_id, 'EUR', "EUR_AF"
      FROM variant_base WHERE "EUR_AF" IS NOT NULL AND "EUR_AF" >= 0.05
    UNION ALL
    SELECT variant_id, 'AMR', "AMR_AF"
      FROM variant_base WHERE "AMR_AF" IS NOT NULL AND "AMR_AF" >= 0.05
    UNION ALL
    /* ASN_AF is provided for Asian populations; reuse for EAS and SAS */
    SELECT variant_id, 'EAS', "ASN_AF"
      FROM variant_base WHERE "ASN_AF" IS NOT NULL AND "ASN_AF" >= 0.05
    UNION ALL
    SELECT variant_id, 'SAS', "ASN_AF"
      FROM variant_base WHERE "ASN_AF" IS NOT NULL AND "ASN_AF" >= 0.05
),

/* estimate how many samples in each super-pop carry ≥1 alternate allele
   (Hardy–Weinberg expectation:  n · (1 − (1−p)²) )                     */
variant_sample_estimate AS (
    SELECT
        vsp.variant_id,
        vsp.super_pop,
        sps.pop_size,
        vsp.allele_freq,
        FLOOR(
            sps.pop_size * (1 - POWER(1 - vsp.allele_freq, 2))
        )                                            AS samples_with_variant
    FROM   variant_superpop vsp
    JOIN   super_pop_sizes  sps
           ON sps.super_pop = vsp.super_pop
)

SELECT
    super_pop                              AS "Super_Population",
    pop_size                               AS "Population_Size",
    TRUE                                   AS "Is_Common_Variant_AF>=0.05",
    samples_with_variant                   AS "Samples_With_Variant",
    COUNT(*)                               AS "Variant_Count"
FROM   variant_sample_estimate
GROUP BY super_pop, pop_size, samples_with_variant
ORDER BY super_pop, samples_with_variant;