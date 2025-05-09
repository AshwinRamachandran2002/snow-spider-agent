WITH common_autosomal_variants AS (               -- 1. autosomal variants, AF ≥ 0.05
    SELECT
        v."reference_name",
        v."start",
        v."reference_bases",
        v."alternate_bases"[0]::string AS alt_base,
        v."call"                       AS calls,
        /* unique key: chr:pos:ref>alt */
        v."reference_name" || ':' || v."start"::string || ':' ||
        v."reference_bases" || '>' || v."alternate_bases"[0]::string  AS variant_key
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
    WHERE v."reference_name" NOT IN ('X','Y','MT')     -- autosomes only
      AND v."AF" >= 0.05                                -- common variants
),

per_call AS (                                           -- 2. explode calls array
    SELECT
        cav.variant_key,
        f.value AS call_obj
    FROM common_autosomal_variants cav,
         LATERAL FLATTEN(input => cav.calls) f
),

call_with_sample AS (                                   -- 3. pull sample & genotype
    SELECT
        pc.variant_key,
        pc.call_obj:"call_set_name"::string AS sample_name,
        pc.call_obj:"genotype"              AS genotype_array
    FROM per_call pc
),

alt_allele_calls AS (                                   -- 4. retain carriers (≥1 alt allele)
    SELECT DISTINCT
        cws.variant_key,
        si."Super_Population"   AS super_population,
        cws.sample_name
    FROM call_with_sample cws
    CROSS JOIN LATERAL FLATTEN(input => cws.genotype_array) g
    JOIN "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO" si
      ON cws.sample_name = si."Sample"
    WHERE g.value::int > 0                              -- carrier if any alt allele
      AND si."Super_Population" IS NOT NULL
),

carrier_counts AS (                                     -- 5. # carriers per variant/pop
    SELECT
        variant_key,
        super_population,
        COUNT(DISTINCT sample_name) AS carrier_sample_count
    FROM alt_allele_calls
    GROUP BY variant_key, super_population
),

variant_distribution AS (                               -- 6. histogram per population
    SELECT
        super_population,
        carrier_sample_count,
        COUNT(*) AS variant_count
    FROM carrier_counts
    GROUP BY super_population, carrier_sample_count
),

population_sizes AS (                                   -- 7. total samples per population
    SELECT
        "Super_Population"        AS super_population,
        COUNT(DISTINCT "Sample")  AS population_size
    FROM "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"
    WHERE "Super_Population" IS NOT NULL
    GROUP BY "Super_Population"
)

-- 8. final output
SELECT
    vd.super_population,
    ps.population_size,
    TRUE AS is_common_variant,          -- AF ≥ 0.05 by construction
    vd.carrier_sample_count,
    vd.variant_count
FROM variant_distribution vd
JOIN population_sizes ps
  ON vd.super_population = ps.super_population
ORDER BY vd.super_population, vd.carrier_sample_count;