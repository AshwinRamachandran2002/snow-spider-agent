/*  Variant–level Hardy-Weinberg summary for chr17 : 41 196 311-41 277 499  */
WITH variant_expanded AS (  ---------------------------------------------------
    SELECT
        v."reference_name",
        v."start",
        v."end",
        v."reference_bases",
        alt.value::STRING                                AS "alt_base",
        v."VT",
        /* 1KG reported allele-frequency columns we also want to show */
        v."AF",
        v."AFR_AF",
        v."EUR_AF",
        v."ASN_AF",
        v."AMR_AF",
        /* genotype alleles per call */
        c.value:"genotype"[0]::NUMBER                    AS allele1,
        c.value:"genotype"[1]::NUMBER                    AS allele2
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"  v,
         LATERAL FLATTEN(input => v."alternate_bases") alt,
         LATERAL FLATTEN(input => v."call")            c
    WHERE v."reference_name" = '17'
      AND v."start" BETWEEN 41196311 AND 41277499
),
genotype_counts AS ( ----------------------------------------------------------
    SELECT
        "reference_name",
        "start",
        "end",
        "reference_bases",
        "alt_base",
        "VT",
        "AF",
        "AFR_AF",
        "EUR_AF",
        "ASN_AF",
        "AMR_AF",
        COUNT(*)                                           AS n_genotypes,
        COUNT_IF(allele1 = 0 AND allele2 = 0)              AS obs_hom_ref,
        COUNT_IF(allele1 != allele2)                       AS obs_het,
        COUNT_IF(allele1 = 1 AND allele2 = 1)              AS obs_hom_alt
    FROM variant_expanded
    GROUP BY "reference_name","start","end","reference_bases","alt_base","VT",
             "AF","AFR_AF","EUR_AF","ASN_AF","AMR_AF"
),
hwe AS ( ---------------------------------------------------------------------
    SELECT
        gc.*,
        /* q = observed alternate-allele frequency, p = reference-allele freq */
        (2*obs_hom_alt + obs_het)::FLOAT / NULLIF(n_genotypes*2,0)      AS alt_AF_computed,
        1 - ((2*obs_hom_alt + obs_het)::FLOAT / NULLIF(n_genotypes*2,0)) AS ref_AF_computed
    FROM genotype_counts gc
)
SELECT
    "reference_name",
    "start",
    "end",
    "reference_bases",
    "alt_base"                                    AS "alternate_base",
    "VT",
    n_genotypes,
    obs_hom_ref,
    obs_het,
    obs_hom_alt,
    /*  expected genotype counts under Hardy-Weinberg equilibrium  */
    (n_genotypes*POWER(ref_AF_computed,2))                            AS exp_hom_ref,
    (2*n_genotypes*ref_AF_computed*alt_AF_computed)                   AS exp_het,
    (n_genotypes*POWER(alt_AF_computed,2))                            AS exp_hom_alt,
    /*  χ² goodness-of-fit statistic  */
    NVL(POWER(obs_hom_ref - (n_genotypes*POWER(ref_AF_computed,2)),2) /
        NULLIF((n_genotypes*POWER(ref_AF_computed,2)),0),0)
  + NVL(POWER(obs_het - (2*n_genotypes*ref_AF_computed*alt_AF_computed),2) /
        NULLIF((2*n_genotypes*ref_AF_computed*alt_AF_computed),0),0)
  + NVL(POWER(obs_hom_alt - (n_genotypes*POWER(alt_AF_computed,2)),2) /
        NULLIF((n_genotypes*POWER(alt_AF_computed,2)),0),0)           AS chi_sq,
    /*  allele-frequency fields  */
    alt_AF_computed                                                  AS alt_AF_observed,
    "AF"                                                             AS AF_1KG_overall,
    "AFR_AF",
    "EUR_AF",
    "ASN_AF",
    "AMR_AF"
FROM hwe
ORDER BY "start", "alternate_base";