WITH hom_ref_counts AS (
    SELECT
        hr.value::STRING AS "Sample",
        COUNT(*)         AS "Homozygous_Reference_Position_Count"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v,
         LATERAL FLATTEN(input => v."hom_ref_call") hr
    WHERE ARRAY_SIZE(v."alternate_bases") = 1      -- exactly one alternate allele
    GROUP BY hr.value
)
SELECT
    "Sample",
    "Homozygous_Reference_Position_Count"
FROM hom_ref_counts
ORDER BY
    "Homozygous_Reference_Position_Count" DESC NULLS LAST,
    "Sample"
LIMIT 10;