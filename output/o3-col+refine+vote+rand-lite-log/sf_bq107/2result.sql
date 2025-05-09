WITH longest AS (
    /* identify the single longest reference sequence */
    SELECT "name" AS "reference_name",
           "length"
    FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER  BY "length" DESC NULLS LAST
    LIMIT  1
)
SELECT  l."reference_name",
        l."length",
        COUNT(DISTINCT v."start")                     AS "variant_sites",
        COUNT(DISTINCT v."start") / l."length"::FLOAT AS "variant_density"
FROM    longest l
JOIN    GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v
          ON v."reference_name" = l."reference_name"
,       LATERAL FLATTEN(input => v."call")            c      -- expand call array
,       LATERAL FLATTEN(input => c.value:"genotype")  g      -- expand genotype array
WHERE   g.value::NUMBER > 0                                 -- at least one alt-allele
GROUP BY l."reference_name", l."length";