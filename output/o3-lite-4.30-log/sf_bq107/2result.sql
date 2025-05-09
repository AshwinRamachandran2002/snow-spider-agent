WITH longest_ref AS (
    SELECT "name" AS reference_name,
           "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703"
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
), 
variant_sites AS (
    SELECT DISTINCT v."start"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_201703" v
    JOIN longest_ref lr
      ON v."reference_name" = lr.reference_name,
         LATERAL FLATTEN(input => v."call") c
    WHERE ARRAY_MAX(c.value:"genotype")::INT > 0
), 
counts AS (
    SELECT COUNT(*) AS variant_count
    FROM variant_sites
)
SELECT TO_DECIMAL(ROUND(counts.variant_count / lr."length", 4), 10, 4) AS variant_density
FROM counts
CROSS JOIN longest_ref lr;