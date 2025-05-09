WITH filtered_variants AS (                         -- 1. keep only X-chromosome SNPs outside the excluded regions
    SELECT  "call"
    FROM    _1000_GENOMES._1000_GENOMES."VARIANTS"
    WHERE   "reference_name" = 'X'
      AND   "VT" = 'SNP'
      AND   NOT ( ("start" BETWEEN 59999       AND 2699519)
              OR  ("start" BETWEEN 154931042   AND 155260559) )
),
exploded_calls AS (                                -- 2. split the CALL array into one row per sample
    SELECT
        cal.value:"call_set_name"::string                    AS sample_id,
        cal.value:"genotype"[0]::int                        AS allele1,
        cal.value:"genotype"[1]::int                        AS allele2
    FROM   filtered_variants,
           LATERAL FLATTEN(input => filtered_variants."call") cal
    WHERE  ARRAY_SIZE(cal.value:"genotype") >= 1             -- at least one allele present
),
categorized AS (                                  -- 3. classify each genotype
    SELECT
        sample_id,
        CASE
            WHEN allele1 = 0 AND allele2 = 0                                      THEN 'homo_ref'
            WHEN allele1 IS NOT NULL AND allele1 > 0 AND allele1 = allele2        THEN 'homo_alt'
            WHEN (allele1 <> allele2 OR allele2 IS NULL OR allele1 IS NULL)
                 AND (COALESCE(allele1,0) > 0 OR COALESCE(allele2,0) > 0)         THEN 'het'
            ELSE 'other'
        END AS category
    FROM   exploded_calls
)
SELECT
    sample_id                                                AS "Sample_ID",
    COUNT(*)                                                 AS "Callable_Sites",
    SUM(CASE WHEN category = 'homo_ref' THEN 1 ELSE 0 END)   AS "Homozygous_Reference",
    SUM(CASE WHEN category = 'homo_alt' THEN 1 ELSE 0 END)   AS "Homozygous_Alternate",
    SUM(CASE WHEN category = 'het'      THEN 1 ELSE 0 END)   AS "Heterozygous",
    SUM(CASE WHEN category IN ('homo_alt','het')
             THEN 1 ELSE 0 END)                              AS "SNV_Count",
    ROUND(
        SUM(CASE WHEN category = 'het' THEN 1 ELSE 0 END) * 100.0
        / NULLIF( SUM(CASE WHEN category IN ('homo_alt','het') THEN 1 ELSE 0 END), 0)
    , 4)                                                     AS "Pct_Het_SNVs",
    ROUND(
        SUM(CASE WHEN category = 'homo_alt' THEN 1 ELSE 0 END) * 100.0
        / NULLIF( SUM(CASE WHEN category IN ('homo_alt','het') THEN 1 ELSE 0 END), 0)
    , 4)                                                     AS "Pct_HomAlt_SNVs"
FROM   categorized
WHERE  category IN ('homo_ref','homo_alt','het')             -- ignore uncategorised rows
GROUP  BY sample_id
ORDER  BY "Pct_Het_SNVs" DESC NULLS LAST,
          "Sample_ID";