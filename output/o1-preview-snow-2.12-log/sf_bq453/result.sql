SELECT
    t."reference_name",
    t."start",
    t."end",
    t."reference_bases",
    t."alternate_bases",
    t."variant_type",
    ROUND(
        (
            CASE WHEN t."exp_homo_ref" > 0 THEN (POWER(t."obs_homo_ref" - t."exp_homo_ref", 2) / t."exp_homo_ref") ELSE 0 END +
            CASE WHEN t."exp_het" > 0 THEN (POWER(t."obs_het" - t."exp_het", 2) / t."exp_het") ELSE 0 END +
            CASE WHEN t."exp_homo_alt" > 0 THEN (POWER(t."obs_homo_alt" - t."exp_homo_alt", 2) / t."exp_homo_alt") ELSE 0 END
        ), 4
    ) AS "chi_squared_score",
    t."total_genotypes",
    t."obs_homo_ref",
    ROUND(t."exp_homo_ref", 4) AS "exp_homo_ref",
    t."obs_het",
    ROUND(t."exp_het", 4) AS "exp_het",
    t."obs_homo_alt",
    ROUND(t."exp_homo_alt", 4) AS "exp_homo_alt",
    t."allele_frequency",
    t."oneKG_allele_frequency"
FROM
(
    SELECT
        v."reference_name",
        v."start",
        v."end",
        v."reference_bases",
        alt.value::STRING AS "alternate_bases",
        v."VT" AS "variant_type",
        COUNT(DISTINCT c.value:"call_set_name") AS "total_genotypes",
        SUM(CASE WHEN c.value:"genotype"[0] = 0 AND c.value:"genotype"[1] = 0 THEN 1 ELSE 0 END) AS "obs_homo_ref",
        SUM(CASE WHEN (c.value:"genotype"[0] = 0 AND c.value:"genotype"[1] = 1) OR (c.value:"genotype"[0] = 1 AND c.value:"genotype"[1] = 0) THEN 1 ELSE 0 END) AS "obs_het",
        SUM(CASE WHEN c.value:"genotype"[0] = 1 AND c.value:"genotype"[1] = 1 THEN 1 ELSE 0 END) AS "obs_homo_alt",
        COUNT(DISTINCT c.value:"call_set_name") * POWER(1 - NVL(v."AF", 0), 2) AS "exp_homo_ref",
        COUNT(DISTINCT c.value:"call_set_name") * 2 * NVL(v."AF", 0) * (1 - NVL(v."AF", 0)) AS "exp_het",
        COUNT(DISTINCT c.value:"call_set_name") * POWER(NVL(v."AF", 0), 2) AS "exp_homo_alt",
        v."AF" AS "allele_frequency",
        v."AFR_AF" AS "oneKG_allele_frequency"
    FROM
        "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
        LATERAL FLATTEN(input => v."alternate_bases") alt,
        LATERAL FLATTEN(input => v."call") c
    WHERE
        v."reference_name" = '17' AND
        v."start" BETWEEN 41196311 AND 41277499
    GROUP BY
        v."reference_name",
        v."start",
        v."end",
        v."reference_bases",
        alt.value::STRING,
        v."VT",
        v."AF",
        v."AFR_AF"
) t;