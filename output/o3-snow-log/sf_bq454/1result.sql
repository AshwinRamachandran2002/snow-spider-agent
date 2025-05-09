/* -----------------------------------------------------------------
   Distribution of COMMON (allele-frequency ≥ 0.05) AUTOSOMAL
   variants across super-populations in the 1000 Genomes dataset
   – uses pre-computed population-specific allele-frequencies,
     avoids per-sample flattening to stay within the time limit.
------------------------------------------------------------------*/

WITH
/* 1.  Super-population sizes (number of distinct samples) ------ */
pop_size AS (
    SELECT
        "Super_Population"           AS super_pop ,
        COUNT(DISTINCT "Sample")     AS population_size
    FROM   _1000_GENOMES._1000_GENOMES.SAMPLE_INFO
    WHERE  "Super_Population" IS NOT NULL
    GROUP  BY "Super_Population"
),

/* 2.  Keep only autosomal variants that are common (AF ≥ 0.05)
        in at least one population – greatly reduces the scan   */
variant_common AS (
    SELECT *
    FROM   _1000_GENOMES._1000_GENOMES.VARIANTS
    WHERE  "reference_name" NOT IN ('X','Y','MT')
      AND ( NVL("AFR_AF",0) >= 0.05
         OR NVL("AMR_AF",0) >= 0.05
         OR NVL("EUR_AF",0) >= 0.05
         OR NVL("ASN_AF",0) >= 0.05 )
),

/* 3.  Un-pivot the four population-specific AF columns so that
        each variant appears once per super-population for which
        it is common                                              */
variant_af_superpop AS (
    SELECT
        vc."reference_name",
        vc."start",
        vc."alternate_bases",
        sp.value:"pop"::STRING   AS super_pop,
        sp.value:"af" ::FLOAT    AS af
    FROM   variant_common vc,
           LATERAL FLATTEN( INPUT => ARRAY_CONSTRUCT(
               OBJECT_CONSTRUCT('pop','AFR','af',vc."AFR_AF"),
               OBJECT_CONSTRUCT('pop','AMR','af',vc."AMR_AF"),
               OBJECT_CONSTRUCT('pop','EUR','af',vc."EUR_AF"),
               OBJECT_CONSTRUCT('pop','ASN','af',vc."ASN_AF")
           ) ) sp
    WHERE  sp.value:"af"::FLOAT >= 0.05          -- still common
),

/* 4.  Estimate how many samples in each super-population carry
        the variant (≈ pop_size × AF), then count how many
        variants are shared by exactly that number of samples     */
variant_distribution AS (
    SELECT
        vasp.super_pop,
        CAST(ROUND(ps.population_size * vasp.af, 0) AS INTEGER)
            AS samples_with_alt,
        COUNT(*)                                     AS variants_count
    FROM   variant_af_superpop  vasp
           JOIN pop_size ps
             ON ps.super_pop = vasp.super_pop
    GROUP  BY vasp.super_pop,
             CAST(ROUND(ps.population_size * vasp.af, 0) AS INTEGER)
)

/* 5.  Final result -------------------------------------------- */
SELECT
    vd.super_pop,
    ps.population_size,                 -- total samples in pop
    TRUE    AS is_common_variant_af_ge_0_05,
    vd.samples_with_alt,                -- N samples sharing variant
    vd.variants_count                   -- how many such variants
FROM   variant_distribution vd
       JOIN pop_size ps  USING (super_pop)
ORDER  BY vd.super_pop,
         vd.samples_with_alt;