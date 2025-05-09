SELECT
    r."name" AS "highest_density_reference_sequence"
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703" r
JOIN (
    SELECT
        "reference_name",
        COUNT(*) AS "variant_count"
    FROM (
        SELECT "reference_name"
        FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_TRANSCRIPTOME_201703"
        UNION ALL
        SELECT "reference_name"
        FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_201703"
    )
    GROUP BY "reference_name"
) v
    ON r."name" = v."reference_name"
ORDER BY (v."variant_count" / r."length") DESC NULLS LAST
LIMIT 1;