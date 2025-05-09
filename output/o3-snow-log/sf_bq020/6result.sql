WITH genomic_counts AS (           -- variants per reference in genomic table
    SELECT "reference_name", COUNT(*) AS variant_count
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
    GROUP BY "reference_name"
),
transcript_counts AS (             -- variants per reference in transcriptome table
    SELECT "reference_name", COUNT(*) AS variant_count
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    GROUP BY "reference_name"
),
combined_counts AS (               -- total variants per reference
    SELECT "reference_name",
           SUM(variant_count) AS total_variants
    FROM (
        SELECT * FROM genomic_counts
        UNION ALL
        SELECT * FROM transcript_counts
    )
    GROUP BY "reference_name"
),
density_calc AS (                  -- attach length and compute density
    SELECT cc."reference_name",
           cc.total_variants,
           ref."length",
           cc.total_variants / ref."length" AS variant_density
    FROM combined_counts cc
    JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 ref
      ON cc."reference_name" = ref."name"
    WHERE ref."length" > 0
)
SELECT "reference_name"           -- reference with highest variant density
FROM density_calc
ORDER BY variant_density DESC NULLS LAST
LIMIT 1;