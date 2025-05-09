WITH snp_calls AS (
    /* 1.  Keep only chromosome-X single-nucleotide variants outside PAR regions,
          then explode the “call” array so we have one row per sample             */
    SELECT
        c.value:"call_set_name"::STRING                         AS "Sample_ID",
        c.value:"genotype"[0]::INT                              AS allele1,
        c.value:"genotype"[1]::INT                              AS allele2
    FROM _1000_GENOMES._1000_GENOMES."VARIANTS"  v,
         LATERAL FLATTEN(input => v."call")        c
    WHERE v."reference_name" = 'X'
      AND NOT (v."start" BETWEEN 59999      AND 2699519)          -- PAR-1
      AND NOT (v."start" BETWEEN 154931042  AND 155260559)        -- PAR-2
      /*  single-nucleotide (length = 1) and biallelic  */
      AND LENGTH(v."reference_bases") = 1
      AND ARRAY_SIZE(v."alternate_bases") = 1
      AND LENGTH(TO_VARCHAR(v."alternate_bases"[0])) = 1
      /*  at least one allele present (callable) */
      AND (c.value:"genotype"[0] IS NOT NULL OR c.value:"genotype"[1] IS NOT NULL)
),
/* 2.  Classify each genotype call */
classified AS (
    SELECT
        "Sample_ID",
        CASE
            WHEN COALESCE(allele1,0) = 0
             AND COALESCE(allele2,0) = 0                       THEN 'HOM_REF'
            WHEN allele1 = allele2
             AND allele1  > 0                                  THEN 'HOM_ALT'
            WHEN (allele1 IS NULL OR allele2 IS NULL
                  OR allele1 <> allele2)
             AND (COALESCE(allele1,0) > 0
                  OR COALESCE(allele2,0) > 0)                  THEN 'HET'
            ELSE 'OTHER'
        END                                                    AS category
    FROM snp_calls
),
/* 3.  Aggregate counts per sample */
agg AS (
    SELECT
        "Sample_ID",
        COUNT(*)                                                    AS callable_sites,
        SUM(IFF(category='HOM_REF',1,0))                           AS hom_ref,
        SUM(IFF(category='HOM_ALT',1,0))                           AS hom_alt,
        SUM(IFF(category='HET'    ,1,0))                           AS het,
        SUM(IFF(category IN ('HOM_ALT','HET'),1,0))                AS snvs
    FROM classified
    WHERE category IN ('HOM_REF','HOM_ALT','HET')                  -- ignore “OTHER”
    GROUP BY "Sample_ID"
)
/* 4.  Final report with percentages */
SELECT
    "Sample_ID",
    callable_sites                          AS "Callable_Sites",
    hom_ref                                 AS "Homozygous_Reference",
    hom_alt                                 AS "Homozygous_Alternate",
    het                                     AS "Heterozygous",
    snvs                                    AS "Total_SNVs",
    ROUND(het      * 100.0 / snvs, 4)       AS "Pct_Heterozygous_in_SNVs",
    ROUND(hom_alt * 100.0 / snvs, 4)        AS "Pct_Homozygous_Alt_in_SNVs"
FROM agg
ORDER BY "Pct_Heterozygous_in_SNVs" DESC NULLS LAST,
         "Sample_ID";