/*  Variant-level Hardy-Weinberg statistics plus 1KG allele-frequency
    window: chr17:41 196 311-41 277 499                                         */

WITH genotype_ct AS (         -- observed genotype counts
    SELECT
        v."reference_name",
        v."start",
        v."end",
        v."reference_bases",
        v."alternate_bases",
        v."VT",
        /* 1KG pre-computed allele-frequencies */
        v."AF"       AS "AF_1KG",
        v."AFR_AF",
        v."EUR_AF",
        v."AMR_AF",
        v."ASN_AF",
        /* counts over all sample calls */
        COUNT(*)                                                                  AS "total_genotypes",
        SUM( CASE WHEN f.value:"genotype"[0]::INT = 0
                   AND f.value:"genotype"[1]::INT = 0 THEN 1 ELSE 0 END )         AS "hom_ref",
        SUM( CASE WHEN f.value:"genotype"[0]::INT != f.value:"genotype"[1]::INT THEN 1 ELSE 0 END ) AS "het",
        SUM( CASE WHEN f.value:"genotype"[0]::INT = 1
                   AND f.value:"genotype"[1]::INT = 1 THEN 1 ELSE 0 END )         AS "hom_alt"
    FROM  "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
          LATERAL FLATTEN( INPUT => v."call" ) f
    WHERE v."reference_name" = '17'
      AND v."start" BETWEEN 41196311 AND 41277499
    GROUP BY v."reference_name", v."start", v."end",
             v."reference_bases", v."alternate_bases", v."VT",
             v."AF", v."AFR_AF", v."EUR_AF", v."AMR_AF", v."ASN_AF"
),

stats AS (                     -- allele-frequencies derived from observed genotypes
    SELECT  *,
            (2*"hom_alt" + "het") / (2.0*"total_genotypes")           AS "alt_AF_calc",
            1 - ( (2*"hom_alt" + "het") / (2.0*"total_genotypes") )   AS "ref_AF_calc"
    FROM    genotype_ct
),

final AS (                     -- expected counts & χ² against HWE
    SELECT
        "reference_name",
        "start",
        "end",
        "reference_bases",
        "alternate_bases",
        "VT",
        "total_genotypes",
        "hom_ref",
        "het",
        "hom_alt",
        /* HWE expectations */
        "total_genotypes"*POWER("ref_AF_calc",2)                      AS "exp_hom_ref",
        "total_genotypes"*2*"ref_AF_calc"*"alt_AF_calc"               AS "exp_het",
        "total_genotypes"*POWER("alt_AF_calc",2)                      AS "exp_hom_alt",
        /* χ² statistic */
        POWER("hom_ref" - ("total_genotypes"*POWER("ref_AF_calc",2)),2)
            / NULLIF("total_genotypes"*POWER("ref_AF_calc",2),0)
      + POWER("het" - ("total_genotypes"*2*"ref_AF_calc"*"alt_AF_calc"),2)
            / NULLIF("total_genotypes"*2*"ref_AF_calc"*"alt_AF_calc",0)
      + POWER("hom_alt" - ("total_genotypes"*POWER("alt_AF_calc",2)),2)
            / NULLIF("total_genotypes"*POWER("alt_AF_calc",2),0)      AS "chi_sq",
        /* allele-frequency outputs */
        "ref_AF_calc"                                                 AS "ref_AF",
        "alt_AF_calc"                                                 AS "alt_AF",
        "AF_1KG",         -- overall 1KG alt-allele freq
        "AFR_AF",
        "EUR_AF",
        "AMR_AF",
        "ASN_AF"
    FROM   stats
)

SELECT *
FROM   final
ORDER  BY "start";