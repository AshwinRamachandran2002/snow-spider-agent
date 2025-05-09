WITH per_sample_site AS (
    SELECT
        c.value:"name"::STRING                           AS "Sample_ID"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_VARIANTS_20150220"   v
         ,LATERAL FLATTEN(input => v."call")            c          -- one row per sample‑call
    WHERE ARRAY_SIZE(v."alternate_bases") = 1                      -- exactly one ALT allele in this site
      AND c.value:"genotype"[0]::INTEGER = 0                       -- first allele is reference
      AND c.value:"genotype"[1]::INTEGER = 0                       -- second allele is reference
)
SELECT
    "Sample_ID",
    COUNT(*) AS "HomRef_SingleAlt_Sites"
FROM per_sample_site
GROUP BY "Sample_ID"
ORDER BY "HomRef_SingleAlt_Sites" DESC NULLS LAST, "Sample_ID"
LIMIT 10;