SELECT
    t.sample_name,
    t.hom_ref_positions
FROM (
    SELECT
        f.value:"name"::STRING AS sample_name,
        COUNT(*)               AS hom_ref_positions
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" v,
         LATERAL FLATTEN(input => v."call") f
    WHERE ARRAY_SIZE(v."alternate_bases") = 1
      AND f.value:"genotype"[0]::INT = 0
      AND f.value:"genotype"[1]::INT = 0
    GROUP BY f.value:"name"::STRING
) t
ORDER BY t.hom_ref_positions DESC NULLS LAST, t.sample_name
LIMIT 10;