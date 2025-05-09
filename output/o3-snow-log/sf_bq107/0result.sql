WITH longest AS (                                    -- reference having the greatest length
    SELECT  "name"  AS reference_name,
            "length"
    FROM    GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
all_variants AS (                                    -- union of all variant rows
    SELECT  "reference_name",
            "variant_id",
            "call"
    FROM    GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    UNION ALL
    SELECT  "reference_name",
            "variant_id",
            "call"
    FROM    GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
),
qualified_variants AS (                             -- variants with at least one genotype > 0
    SELECT DISTINCT av."variant_id"
    FROM    all_variants av
            JOIN longest l
              ON av."reference_name" = l.reference_name
            ,LATERAL FLATTEN(input => av."call")               c
            ,LATERAL FLATTEN(input => c.value:"genotype")      g
    WHERE   g.value::NUMBER > 0
)
SELECT  l.reference_name,
        l."length"                                        AS reference_length,
        COUNT(qv."variant_id")                            AS variant_count,
        COUNT(qv."variant_id")::FLOAT / l."length"        AS variant_density
FROM    longest l
LEFT JOIN qualified_variants qv  ON 1=1
GROUP BY l.reference_name, l."length";