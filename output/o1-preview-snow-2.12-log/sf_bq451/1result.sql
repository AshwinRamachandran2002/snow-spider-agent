SELECT
    sample_id,
    COUNT(CASE WHEN genotype_class = 'hom_ref' THEN 1 END) AS homozygous_reference_alleles,
    COUNT(CASE WHEN genotype_class = 'hom_alt' THEN 1 END) AS homozygous_alternate_alleles,
    COUNT(CASE WHEN genotype_class = 'het_alt' THEN 1 END) AS heterozygous_alternate_alleles,
    COUNT(*) AS total_callable_sites,
    COUNT(CASE WHEN genotype_class IN ('hom_alt', 'het_alt') THEN 1 END) AS total_SNVs,
    ROUND(
        100.0 * COUNT(CASE WHEN genotype_class = 'het_alt' THEN 1 END) /
        NULLIF(COUNT(CASE WHEN genotype_class IN ('hom_alt', 'het_alt') THEN 1 END), 0), 4
    ) AS percentage_heterozygous_alternate_alleles,
    ROUND(
        100.0 * COUNT(CASE WHEN genotype_class = 'hom_alt' THEN 1 END) /
        NULLIF(COUNT(CASE WHEN genotype_class IN ('hom_alt', 'het_alt') THEN 1 END), 0), 4
    ) AS percentage_homozygous_alternate_alleles
FROM
(
    SELECT
        f.value:"call_set_name"::STRING AS sample_id,
        CASE
            WHEN
                (ARRAY_SIZE(f.value:"genotype") = 1 AND TRY_TO_NUMBER(f.value:"genotype"[0]::STRING) = 0)
                OR (ARRAY_SIZE(f.value:"genotype") = 2 AND TRY_TO_NUMBER(f.value:"genotype"[0]::STRING) = 0 AND TRY_TO_NUMBER(f.value:"genotype"[1]::STRING) = 0)
            THEN 'hom_ref'
            WHEN
                (ARRAY_SIZE(f.value:"genotype") = 1 AND TRY_TO_NUMBER(f.value:"genotype"[0]::STRING) > 0)
                OR (ARRAY_SIZE(f.value:"genotype") = 2 AND TRY_TO_NUMBER(f.value:"genotype"[0]::STRING) = TRY_TO_NUMBER(f.value:"genotype"[1]::STRING) AND TRY_TO_NUMBER(f.value:"genotype"[0]::STRING) > 0)
            THEN 'hom_alt'
            WHEN
                ARRAY_SIZE(f.value:"genotype") = 2
                AND TRY_TO_NUMBER(f.value:"genotype"[0]::STRING) != TRY_TO_NUMBER(f.value:"genotype"[1]::STRING)
                AND TRY_TO_NUMBER(f.value:"genotype"[0]::STRING) >= 0
                AND TRY_TO_NUMBER(f.value:"genotype"[1]::STRING) >= 0
                AND (TRY_TO_NUMBER(f.value:"genotype"[0]::STRING) > 0 OR TRY_TO_NUMBER(f.value:"genotype"[1]::STRING) > 0)
            THEN 'het_alt'
            ELSE 'other'
        END AS genotype_class
    FROM
        "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" t,
        LATERAL FLATTEN(input => t."call") f
    WHERE
        t."reference_name" = 'X'
        AND (t."start" < 60000 OR t."start" > 2699519)
        AND (t."start" < 154931042 OR t."start" > 155260559)
        AND LENGTH(t."reference_bases") = 1
        AND ARRAY_SIZE(t."alternate_bases") = 1
        AND t."alternate_bases"[0] IS NOT NULL
        AND LENGTH(t."alternate_bases"[0]::STRING) = 1
) sub
WHERE sample_id IS NOT NULL
GROUP BY sample_id;