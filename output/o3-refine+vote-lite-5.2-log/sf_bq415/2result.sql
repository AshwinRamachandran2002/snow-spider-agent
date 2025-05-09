WITH per_sample_counts AS (
    SELECT
        c.value:"name"::STRING          AS "Sample",
        COUNT(*)                        AS "Homo_Ref_Positions"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220"  v
         , LATERAL FLATTEN(input => v."call")   c
    -- keep only biallelic sites
    WHERE ARRAY_SIZE(v."alternate_bases") = 1
          -- genotype exactly 0/0  (homozygous reference)
          AND c.value:"genotype"[0]::INT = 0
          AND c.value:"genotype"[1]::INT = 0
    GROUP BY c.value:"name"::STRING
)

SELECT  "Sample",
        "Homo_Ref_Positions"
FROM    per_sample_counts
ORDER BY "Homo_Ref_Positions" DESC NULLS LAST,
         "Sample"
LIMIT 10;