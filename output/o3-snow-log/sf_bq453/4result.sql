/*  Variant–level HWE summary for chr17 : 41 196 311-41 277 499                     */
WITH variant_counts AS (
    SELECT
        v."reference_name",
        v."start",
        v."end",
        v."reference_bases",
        v."VT",
        v."HWE",
        v."AF",
        v."AFR_AF",
        v."EUR_AF",
        v."ASN_AF",
        v."AMR_AF",
        v."alternate_bases",
        /* observed genotype counts */
        COUNT(*)                                                        AS total_genotypes,
        SUM( IFF(c.value:"genotype"[0]::INT = 0 
              AND c.value:"genotype"[1]::INT = 0 , 1, 0) )              AS obs_hom_ref,
        SUM( IFF(c.value:"genotype"[0]::INT <> c.value:"genotype"[1]::INT , 1, 0) ) AS obs_het,
        SUM( IFF(c.value:"genotype"[0]::INT = 1 
              AND c.value:"genotype"[1]::INT = 1 , 1, 0) )              AS obs_hom_alt
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
         LATERAL FLATTEN(input => v."call") c
    WHERE v."reference_name" = '17'
      AND v."start" BETWEEN 41196311 AND 41277499
    GROUP BY
        v."reference_name", v."start", v."end", v."reference_bases",
        v."VT", v."HWE", v."AF", v."AFR_AF", v."EUR_AF", v."ASN_AF",
        v."AMR_AF", v."alternate_bases"
)

SELECT
    vc."reference_name",
    vc."start",
    vc."end",
    vc."reference_bases",
    alt.value::STRING                                           AS "alternate_base",
    vc."VT",
    vc."HWE"                                                    AS "chi_squared",
    vc.total_genotypes,
    vc.obs_hom_ref,
    vc.obs_het,
    vc.obs_hom_alt,
    /* expected genotype counts under HWE using global AF */
    ROUND(vc.total_genotypes * POWER(1 - vc."AF", 2)              , 4) AS exp_hom_ref,
    ROUND(vc.total_genotypes * 2 * vc."AF" * (1 - vc."AF")        , 4) AS exp_het,
    ROUND(vc.total_genotypes * POWER(vc."AF", 2)                  , 4) AS exp_hom_alt,
    /* allele frequencies */
    vc."AF",
    vc."AFR_AF",
    vc."EUR_AF",
    vc."ASN_AF",
    vc."AMR_AF"
FROM variant_counts vc,
     LATERAL FLATTEN(input => vc."alternate_bases") alt
ORDER BY vc."start", alt.value::STRING;