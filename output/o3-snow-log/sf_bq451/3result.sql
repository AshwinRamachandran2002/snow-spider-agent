WITH snp_calls AS (   -- 1. take all SNP calls on chr X outside the two excluded regions
    SELECT
        c.value:"call_set_name"::STRING                           AS "Sample_ID",
        (c.value:"genotype"[0])::INT                              AS allele1,
        (c.value:"genotype"[1])::INT                              AS allele2
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"  v,
         LATERAL FLATTEN(input => v."call")           c
    WHERE  v."reference_name" = 'X'
      AND  v."VT" = 'SNP'                                  -- single-nucleotide polymorphisms
      AND  NOT ( v."start" BETWEEN  59999      AND  2699519
                 OR v."start" BETWEEN 154931042 AND 155260559 )
      AND  ARRAY_SIZE( c.value:"genotype") > 0            -- at least one allele (callable)
),

classified AS (        -- 2. classify each genotype
    SELECT
        "Sample_ID",
        CASE
            WHEN allele1 = 0
                 AND ( allele2 = 0 OR allele2 IS NULL )                     THEN 'homo_ref'
            WHEN allele1 > 0
                 AND ( allele2 = allele1 OR allele2 IS NULL )               THEN 'homo_alt'
            WHEN ( allele2 IS NULL OR allele1 <> allele2 )
                 AND ( COALESCE(allele1,0) > 0 OR COALESCE(allele2,0) > 0 ) THEN 'het'
            ELSE NULL
        END AS genotype_class
    FROM snp_calls
),

agg AS (               -- 3. aggregate per sample
    SELECT
        "Sample_ID",
        COUNT(*)                                                     AS callable_sites,
        SUM( CASE WHEN genotype_class = 'homo_ref' THEN 1 END )      AS homozygous_reference,
        SUM( CASE WHEN genotype_class = 'homo_alt' THEN 1 END )      AS homozygous_alternate,
        SUM( CASE WHEN genotype_class = 'het'      THEN 1 END )      AS heterozygous
    FROM   classified
    WHERE  genotype_class IS NOT NULL
    GROUP  BY "Sample_ID"
)

-- 4. final output with SNV counts and percentages
SELECT
    "Sample_ID",
    callable_sites                                      AS "Callable_Sites",
    homozygous_reference                                AS "Homozygous_Reference",
    homozygous_alternate                                AS "Homozygous_Alternate",
    heterozygous                                        AS "Heterozygous",
    homozygous_alternate + heterozygous                AS "SNVs",
    ROUND( heterozygous         * 100.0
           / NULLIF( homozygous_alternate + heterozygous , 0 ), 4 )
                                                       AS "Pct_Heterozygous_in_SNVs",
    ROUND( homozygous_alternate * 100.0
           / NULLIF( homozygous_alternate + heterozygous , 0 ), 4 )
                                                       AS "Pct_Homozygous_Alt_in_SNVs"
FROM   agg
ORDER  BY "Pct_Heterozygous_in_SNVs" DESC NULLS LAST,
          "Sample_ID";