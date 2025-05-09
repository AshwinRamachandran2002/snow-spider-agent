WITH snp_variants AS (                           -- chr X SNPs outside the excluded regions
    SELECT DISTINCT v."call"
    FROM _1000_GENOMES._1000_GENOMES."VARIANTS"  v,
         LATERAL FLATTEN(INPUT => v."alternate_bases") alt
    WHERE v."reference_name" = 'X'
      AND NOT ( (v."start" BETWEEN 59999      AND 2699519)
             OR (v."start" BETWEEN 154931042 AND 155260559) )
      AND LENGTH(v."reference_bases") = 1
      AND LENGTH(alt.value::string) = 1          -- keep only 1-bp alternate bases
),
exploded_calls AS (                              -- one row per sample / variant
    SELECT
        c.value:"call_set_name"::string  AS sample_id,
        c.value:"genotype"[0]::int       AS g0,
        c.value:"genotype"[1]::int       AS g1
    FROM snp_variants sv,
         LATERAL FLATTEN(INPUT => sv."call") c
    WHERE c.value:"genotype"[0] IS NOT NULL       -- require at least one allele
),
classified AS (                                  -- classify each genotype
    SELECT
        sample_id,
        CASE WHEN g0 = 0 AND g1 = 0                            THEN 1 ELSE 0 END AS hom_ref,
        CASE WHEN g0 > 0 AND g1 > 0 AND g0 = g1               THEN 1 ELSE 0 END AS hom_alt,
        CASE WHEN (g0 IS NULL AND g1 > 0)
               OR (g1 IS NULL AND g0 > 0)
               OR (g0 <> g1 AND (COALESCE(g0,0) > 0 OR COALESCE(g1,0) > 0))
             THEN 1 ELSE 0 END                                  AS het
    FROM exploded_calls
)
SELECT
    sample_id                                                   AS "Sample_ID",
    SUM(hom_ref)                                                AS "Homozygous_Reference",
    SUM(hom_alt)                                                AS "Homozygous_Alternate",
    SUM(het)                                                    AS "Heterozygous",
    SUM(hom_ref) + SUM(hom_alt) + SUM(het)                      AS "Callable_Sites",
    SUM(hom_alt) + SUM(het)                                     AS "SNVs",
    ROUND( (SUM(het)      * 100.0) /
           NULLIF(SUM(hom_alt) + SUM(het), 0), 4)               AS "Pct_Heterozygous_in_SNVs",
    ROUND( (SUM(hom_alt) * 100.0) /
           NULLIF(SUM(hom_alt) + SUM(het), 0), 4)               AS "Pct_Homozygous_Alternate_in_SNVs"
FROM classified
GROUP BY sample_id
ORDER BY "Pct_Heterozygous_in_SNVs" DESC NULLS LAST,
         "Sample_ID";