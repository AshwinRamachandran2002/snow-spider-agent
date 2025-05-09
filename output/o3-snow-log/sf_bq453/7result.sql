/*  Variant summary on chr17: 41 196 311-41 277 499                                   */
WITH genotype_stats AS (     -- 1.  observed genotype & allele counts
    SELECT
        v."reference_name",
        v."start",
        COUNT(*)                                                        AS "total_genotypes",
        SUM( CASE WHEN c.value:"genotype"[0]=0 AND c.value:"genotype"[1]=0 THEN 1 ELSE 0 END)  AS "obs_hom_ref",
        SUM( CASE WHEN c.value:"genotype"[0]<>c.value:"genotype"[1]                       THEN 1 ELSE 0 END)  AS "obs_het",
        SUM( CASE WHEN c.value:"genotype"[0]=1 AND c.value:"genotype"[1]=1 THEN 1 ELSE 0 END)  AS "obs_hom_alt",
        SUM( 2 - (c.value:"genotype"[0] + c.value:"genotype"[1]) )                          AS "ref_allele_count",
        SUM(     (c.value:"genotype"[0] + c.value:"genotype"[1]) )                          AS "alt_allele_count"
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"  v,
         LATERAL FLATTEN( input => v."call") c
    WHERE v."reference_name" = '17'
      AND v."start" BETWEEN 41196311 AND 41277499
    GROUP BY v."reference_name", v."start"
),
hwe AS (                 -- 2.  expected genotype counts under HWE + calculated AF
    SELECT
        g.*,
        g."alt_allele_count" * 1.0 / (g."total_genotypes"*2)                                   AS "calc_AF",
        g."total_genotypes" *           POW(1 - (g."alt_allele_count"*1.0)/(g."total_genotypes"*2), 2)   AS "exp_hom_ref",
        2 * g."total_genotypes" * (g."alt_allele_count"*1.0)/(g."total_genotypes"*2)
                                   * (1 - (g."alt_allele_count"*1.0)/(g."total_genotypes"*2))  AS "exp_het",
        g."total_genotypes" *           POW(  (g."alt_allele_count"*1.0)/(g."total_genotypes"*2), 2)     AS "exp_hom_alt"
    FROM genotype_stats g
)
SELECT
    v."reference_name",
    v."start",
    v."end",
    v."reference_bases",
    alt.value::STRING                                         AS "alternate_base",
    v."VT"                                                    AS "variant_type",
    v."HWE"                                                   AS "chi_sq",
    h."total_genotypes",
    h."obs_hom_ref",
    h."obs_het",
    h."obs_hom_alt",
    h."exp_hom_ref",
    h."exp_het",
    h."exp_hom_alt",
    h."calc_AF"                                               AS "calculated_AF",
    v."AF",        -- overall AF supplied by 1KG
    v."AFR_AF",
    v."EUR_AF",
    v."AMR_AF",
    v."ASN_AF"
FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
JOIN hwe              h  ON v."reference_name" = h."reference_name"
                         AND v."start"          = h."start"
,    LATERAL FLATTEN( input => v."alternate_bases") alt           -- distinct alternate alleles
WHERE v."reference_name" = '17'
  AND v."start" BETWEEN 41196311 AND 41277499
ORDER BY v."start";