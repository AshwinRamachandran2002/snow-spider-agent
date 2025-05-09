WITH variant_calls AS (   -- 1. pull every genotype call on chr X SNPs outside the PARs
    SELECT
        c.value:"call_set_name"::STRING                                  AS sample_id ,
        c.value:"genotype"                                               AS genotype_arr
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"
         ,LATERAL FLATTEN( input => "call")                               c
    WHERE "reference_name" = 'X'
      AND "VT" = 'SNP'                            -- single-nucleotide polymorphisms
      AND NOT ( "start" BETWEEN  59999       AND   2699519     -- skip X-PAR1
                OR "start" BETWEEN 154931042  AND 155260559 )  -- skip X-PAR2
      AND c.value:"genotype" IS NOT NULL
      AND ARRAY_SIZE( c.value:"genotype") > 0
),

classified AS (          -- 2. classify each genotype
    SELECT
        sample_id ,
        CASE
            /* homozygous reference: exactly two alleles, both 0 */
            WHEN ARRAY_SIZE(genotype_arr)=2
                 AND genotype_arr[0]::INT = 0
                 AND genotype_arr[1]::INT = 0
                 THEN 'HOMO_REF'

            /* homozygous alternate: two identical non-zero alleles */
            WHEN ARRAY_SIZE(genotype_arr)=2
                 AND genotype_arr[0] IS NOT NULL
                 AND genotype_arr[1] IS NOT NULL
                 AND genotype_arr[0]::INT = genotype_arr[1]::INT
                 AND genotype_arr[0]::INT > 0
                 THEN 'HOMO_ALT'

            /* heterozygous (all remaining callable non-reference cases) */
            ELSE 'HET'
        END                                                            AS category
    FROM variant_calls
),

aggregated AS (          -- 3. aggregate counts & percentages per sample
    SELECT
        sample_id                                           AS "Sample_ID",
        COUNT(*)                                            AS "Callable_Sites",
        COUNT_IF(category = 'HOMO_REF')                     AS "Homozygous_Reference",
        COUNT_IF(category = 'HOMO_ALT')                     AS "Homozygous_Alternate",
        COUNT_IF(category = 'HET')                          AS "Heterozygous",
        /* SNVs = non-reference genotypes */
        COUNT_IF(category IN ('HOMO_ALT','HET'))            AS "SNV_Count",
        /* percentages among SNVs */
        ROUND(
              COUNT_IF(category = 'HET')      * 100.0
              / NULLIF( COUNT_IF(category IN ('HOMO_ALT','HET')), 0)
             ,4)                                            AS "Pct_Heterozygous_in_SNVs",
        ROUND(
              COUNT_IF(category = 'HOMO_ALT') * 100.0
              / NULLIF( COUNT_IF(category IN ('HOMO_ALT','HET')), 0)
             ,4)                                            AS "Pct_HomoAlt_in_SNVs"
    FROM classified
    GROUP BY sample_id
)

SELECT *
FROM   aggregated
ORDER  BY "Pct_Heterozygous_in_SNVs" DESC NULLS LAST,
          "Sample_ID";