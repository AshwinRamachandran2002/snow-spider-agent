WITH hom_ref_counts AS (
    SELECT
        c.value:"name"::STRING      AS "sample",
        COUNT(*)                    AS "hom_ref_positions"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220" v
         ,LATERAL FLATTEN(input => v."call") c
    WHERE ARRAY_SIZE(v."alternate_bases") = 1                         -- exactly one ALT allele
      AND c.value:"genotype"[0]::INT = 0                              -- first allele = reference
      AND c.value:"genotype"[1]::INT = 0                              -- second allele = reference
    GROUP BY "sample"
)

SELECT
    h."sample",
    h."hom_ref_positions"
FROM hom_ref_counts h
ORDER BY h."hom_ref_positions" DESC NULLS LAST
LIMIT 10;