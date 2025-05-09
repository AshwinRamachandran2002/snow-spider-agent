WITH genotype_data AS (
    SELECT
        v."reference_name",
        v."start",
        v."end",
        v."reference_bases",
        v."alternate_bases"[0]::STRING AS "alternate_bases",
        v."VT" AS "variant_type",
        ROUND(v."AF", 4) AS "allele_frequency",
        c.value:"genotype" AS genotype_array
    FROM
        "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
        LATERAL FLATTEN(input => v."call") c
    WHERE
        v."reference_name" = '17'
        AND v."start" BETWEEN 41196311 AND 41277499
),
genotype_counts AS (
    SELECT
        "reference_name",
        "start",
        "end",
        "reference_bases",
        "alternate_bases",
        "variant_type",
        "allele_frequency",
        COUNT(*) AS total_genotypes,
        COUNT_IF(genotype_array::VARCHAR = '[0,0]') AS observed_homo_ref,
        COUNT_IF(genotype_array::VARCHAR IN ('[0,1]', '[1,0]')) AS observed_heterozygous,
        COUNT_IF(genotype_array::VARCHAR = '[1,1]') AS observed_homo_alt
    FROM genotype_data
    GROUP BY
        "reference_name",
        "start",
        "end",
        "reference_bases",
        "alternate_bases",
        "variant_type",
        "allele_frequency"
)
SELECT
    "reference_name",
    "start",
    "end",
    "reference_bases",
    "alternate_bases",
    "variant_type",
    ROUND(chi_squared_score, 4) AS chi_squared_score,
    observed_homo_ref,
    observed_heterozygous,
    observed_homo_alt,
    ROUND(expected_homo_ref, 4) AS expected_homo_ref,
    ROUND(expected_heterozygous, 4) AS expected_heterozygous,
    ROUND(expected_homo_alt, 4) AS expected_homo_alt,
    "allele_frequency"
FROM (
    SELECT
        *,
        (2 * observed_homo_ref + observed_heterozygous) AS ref_allele_count,
        (2 * observed_homo_alt + observed_heterozygous) AS alt_allele_count,
        (2 * total_genotypes) AS total_alleles,
        ((2 * observed_homo_ref + observed_heterozygous) / (2.0 * total_genotypes)) AS ref_allele_freq,
        ((2 * observed_homo_alt + observed_heterozygous) / (2.0 * total_genotypes)) AS alt_allele_freq,
        POWER(((2 * observed_homo_ref + observed_heterozygous) / (2.0 * total_genotypes)), 2) * total_genotypes AS expected_homo_ref,
        2 * ((2 * observed_homo_ref + observed_heterozygous) / (2.0 * total_genotypes)) * ((2 * observed_homo_alt + observed_heterozygous) / (2.0 * total_genotypes)) * total_genotypes AS expected_heterozygous,
        POWER(((2 * observed_homo_alt + observed_heterozygous) / (2.0 * total_genotypes)), 2) * total_genotypes AS expected_homo_alt,
        CASE WHEN expected_homo_ref > 0 THEN POWER(observed_homo_ref - expected_homo_ref, 2) / expected_homo_ref ELSE 0 END +
        CASE WHEN expected_heterozygous > 0 THEN POWER(observed_heterozygous - expected_heterozygous, 2) / expected_heterozygous ELSE 0 END +
        CASE WHEN expected_homo_alt > 0 THEN POWER(observed_homo_alt - expected_homo_alt, 2) / expected_homo_alt ELSE 0 END AS chi_squared_score
    FROM genotype_counts
) final_results
LIMIT 100;