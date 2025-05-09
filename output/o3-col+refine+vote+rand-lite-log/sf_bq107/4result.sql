WITH max_ref AS (
    SELECT
        "name"   AS reference_name,
        "length" AS reference_length
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
var_sites AS (
    SELECT
        COUNT(DISTINCT v."start") AS variant_site_count
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v,
         LATERAL FLATTEN(INPUT => v."call") f,
         max_ref
    WHERE v."reference_name" = max_ref.reference_name
      AND (
            f.value:"genotype"[0]::INT > 0
         OR f.value:"genotype"[1]::INT > 0
          )
)
SELECT
    max_ref.reference_name,
    max_ref.reference_length,
    var_sites.variant_site_count,
    var_sites.variant_site_count / max_ref.reference_length::FLOAT AS variant_density_per_bp
FROM max_ref, var_sites;