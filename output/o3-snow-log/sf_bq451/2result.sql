WITH snv_calls AS (   -- 1. explode every genotype call that is a SNP on chr X outside the two pseudo-autosomal regions
    SELECT
        c.value:"call_set_name"::string                           AS "Sample_ID",
        (c.value:"genotype"[0])::int                              AS allele1,
        (c.value:"genotype"[1])::int                              AS allele2
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v,
         LATERAL FLATTEN(input => v."call") c
    WHERE v."reference_name" = 'X'
          AND NOT (v."start" BETWEEN 59999      AND 2699519)
          AND NOT (v."start" BETWEEN 154931042  AND 155260559)
          -- keep single-nucleotide polymorphisms
          AND LENGTH(v."reference_bases") = 1
          AND ARRAY_SIZE(v."alternate_bases")   = 1
          AND LENGTH((v."alternate_bases"[0])::string) = 1
          -- at least one allele present
          AND ( (c.value:"genotype")[0] IS NOT NULL
             OR (c.value:"genotype")[1] IS NOT NULL )
),
classified AS (       -- 2. classify each call
    SELECT
        "Sample_ID",
        CASE
            WHEN allele1 = 0
                 AND (allele2 = 0 OR allele2 IS NULL)                THEN 'HOMO_REF'
            WHEN allele1 > 0
                 AND (allele2 IS NULL OR allele2 = allele1)          THEN 'HOMO_ALT'
            ELSE                                                         'HET'
        END AS genotype_class
    FROM snv_calls
),
cnts AS (            -- 3. aggregate counts per sample
    SELECT
        "Sample_ID",
        COUNT(*)                                           AS callable_sites,
        SUM(IFF(genotype_class = 'HOMO_REF', 1, 0))        AS homo_ref_cnt,
        SUM(IFF(genotype_class = 'HOMO_ALT', 1, 0))        AS homo_alt_cnt,
        SUM(IFF(genotype_class = 'HET'     , 1, 0))        AS hetero_cnt
    FROM classified
    GROUP BY "Sample_ID"
)
SELECT
    "Sample_ID",
    callable_sites                                        AS "Callable_Sites",
    homo_ref_cnt                                          AS "Homozygous_Reference",
    homo_alt_cnt                                          AS "Homozygous_Alternate",
    hetero_cnt                                            AS "Heterozygous",
    homo_alt_cnt + hetero_cnt                             AS "SNV_Count",
    ROUND(hetero_cnt * 100.0 /
          NULLIF(homo_alt_cnt + hetero_cnt, 0), 4)        AS "Percent_Heterozygous_in_SNVs",
    ROUND(homo_alt_cnt * 100.0 /
          NULLIF(homo_alt_cnt + hetero_cnt, 0), 4)        AS "Percent_Homozygous_Alt_in_SNVs"
FROM cnts
ORDER BY "Percent_Heterozygous_in_SNVs" DESC NULLS LAST,
         "Sample_ID";