/*  Common autosomal variants (AF ≥ 0.05) – sharing pattern inside each super population  */
WITH sample_superpop AS (        --  map every sample to its super-population
    SELECT  "Sample"                    AS sample_id ,
            "Super_Population"          AS super_pop
    FROM    _1000_GENOMES._1000_GENOMES."SAMPLE_INFO"
    WHERE   "Super_Population" IS NOT NULL
),  pop_size AS (               --  size of each super-population
    SELECT  super_pop,
            COUNT( DISTINCT sample_id ) AS population_size
    FROM    sample_superpop
    GROUP BY super_pop
),  variant_calls AS (          --  explode every VCF-like call (one row per sample / variant)
    SELECT  v."reference_name"                                              AS chr ,
            v."start"                                                       AS pos_start ,
            v."end"                                                         AS pos_end ,
            v."alternate_bases"                                             AS alt_bases ,
            c.value:"call_set_name"::STRING                                 AS sample_id ,
            COALESCE( c.value:"genotype"[0]::INT , 0 )
          + COALESCE( c.value:"genotype"[1]::INT , 0 )                      AS allele_count ,
            v."AFR_AF" , v."EUR_AF" , v."AMR_AF" , v."ASN_AF"
    FROM    _1000_GENOMES._1000_GENOMES."VARIANTS"   v ,
            LATERAL FLATTEN ( input => v."call" )  c
    WHERE   v."reference_name" NOT IN ('X','Y','MT')         -- only autosomes
),  alt_calls AS (             --  keep samples that carry ≥1 alternate allele
    SELECT *
    FROM   variant_calls
    WHERE  allele_count > 0
),  alt_calls_with_pop AS (    --  add the super-population for every alt-carrier
    SELECT  ac.chr , ac.pos_start , ac.pos_end , ac.alt_bases ,
            ss.super_pop ,
            ac.sample_id ,
            ac."AFR_AF" , ac."EUR_AF" , ac."AMR_AF" , ac."ASN_AF"
    FROM    alt_calls          ac
    JOIN    sample_superpop    ss
           ON ac.sample_id = ss.sample_id
),  variant_superpop_counts AS (   -- #samples with the variant inside each super-pop
    SELECT  chr , pos_start , pos_end , alt_bases ,
            super_pop ,
            COUNT( DISTINCT sample_id )                       AS samples_with_alt ,
            MAX("AFR_AF") AS AFR_AF ,
            MAX("EUR_AF") AS EUR_AF ,
            MAX("AMR_AF") AS AMR_AF ,
            MAX("ASN_AF") AS ASN_AF
    FROM    alt_calls_with_pop
    GROUP BY chr , pos_start , pos_end , alt_bases , super_pop
),  variant_superpop_af AS (       --  pick the AF that matches the super-population
    SELECT  *,
            CASE  WHEN super_pop = 'AFR'                THEN AFR_AF
                  WHEN super_pop = 'EUR'                THEN EUR_AF
                  WHEN super_pop = 'AMR'                THEN AMR_AF
                  WHEN super_pop IN ('ASN','EAS','SAS') THEN ASN_AF
            END                                                   AS pop_specific_af
    FROM    variant_superpop_counts
),  common_variants AS (          --  keep only common variants (AF ≥ 0.05)
    SELECT *
    FROM   variant_superpop_af
    WHERE  pop_specific_af >= 0.05
),  variants_grouped AS (         --  how many variants are shared by N samples?
    SELECT  super_pop ,
            samples_with_alt                     AS samples_having_variant ,
            COUNT(*)                            AS variants_shared_by_sample_count
    FROM    common_variants
    GROUP BY super_pop , samples_with_alt
)
SELECT  vg.super_pop ,
        ps.population_size ,
        TRUE                                    AS is_common_variant ,   -- by construction
        vg.samples_having_variant ,
        vg.variants_shared_by_sample_count
FROM    variants_grouped   vg
JOIN    pop_size           ps   ON vg.super_pop = ps.super_pop
ORDER BY vg.super_pop ,
         vg.samples_having_variant;