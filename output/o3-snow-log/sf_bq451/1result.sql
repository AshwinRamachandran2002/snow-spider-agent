WITH filtered_variants AS (                -- 1.  keep only SNPs on chr X outside the excluded regions
    SELECT *
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"
    WHERE "reference_name" = 'X'
      AND "VT" = 'SNP'
      AND NOT ( ("start" BETWEEN 59999        AND 2699519)
             OR ("start" BETWEEN 154931042 AND 155260559) )
),
calls AS (                                 -- 2.  explode the call array to one row per sample / variant
    SELECT
        c.value:"call_set_name"::string AS sample_id,
        c.value:"genotype"              AS genotype_array
    FROM filtered_variants fv,
         LATERAL FLATTEN(input => fv."call") c
),
alleles AS (                               -- 3.  pull the two alleles, treating –1 as NULL
    SELECT
        sample_id,
        NULLIF(genotype_array[0]::int, -1) AS a1,
        NULLIF(genotype_array[1]::int, -1) AS a2
    FROM calls
    WHERE genotype_array IS NOT NULL
      AND ARRAY_SIZE(genotype_array) > 0          -- at least one allele present
),
categorized AS (                            -- 4.  classify each genotype
    SELECT
        sample_id,
        CASE
            WHEN a1 = 0 AND (a2 = 0 OR a2 IS NULL)                 THEN 'HOMO_REF'
            WHEN a1 IS NOT NULL AND a1 > 0 AND a1 = a2             THEN 'HOMO_ALT'
            WHEN (a1 > 0 OR a2 > 0)                                THEN 'HET'
            ELSE 'OTHER'
        END AS category
    FROM alleles
)
SELECT                                       -- 5.  aggregate, calculate percentages, order as required
    sample_id                                                    AS "Sample_ID",
    COUNT_IF(category IN ('HOMO_REF','HOMO_ALT','HET'))          AS "Callable_Sites",
    COUNT_IF(category = 'HOMO_REF')                              AS "Homozygous_Reference",
    COUNT_IF(category = 'HOMO_ALT')                              AS "Homozygous_Alternate",
    COUNT_IF(category = 'HET')                                   AS "Heterozygous",
    (COUNT_IF(category = 'HOMO_ALT') + COUNT_IF(category = 'HET'))            AS "Total_SNVs",
    ROUND(
          (COUNT_IF(category = 'HET')::FLOAT
          / NULLIF(COUNT_IF(category IN ('HET','HOMO_ALT')),0)) * 100
         ,4)                                                     AS "Pct_Het_in_SNVs",
    ROUND(
          (COUNT_IF(category = 'HOMO_ALT')::FLOAT
          / NULLIF(COUNT_IF(category IN ('HET','HOMO_ALT')),0)) * 100
         ,4)                                                     AS "Pct_HomAlt_in_SNVs"
FROM categorized
GROUP BY sample_id
ORDER BY "Pct_Het_in_SNVs" DESC NULLS LAST, "Sample_ID";