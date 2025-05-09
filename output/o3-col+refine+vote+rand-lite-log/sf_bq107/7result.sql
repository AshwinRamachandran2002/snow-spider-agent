WITH longest_ref AS (
    -- identify the single longest reference contig
    SELECT "name"  AS "reference_name",
           "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703"
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
), variant_loci AS (
    -- collect distinct variant loci on that contig that have
    -- at least one genotype call > 0 (i.e., non-reference)
    SELECT DISTINCT v."variant_id"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_201703" v
    JOIN longest_ref r
      ON v."reference_name" = r."reference_name"
    ,   LATERAL FLATTEN( INPUT => v."call")          c
    ,   LATERAL FLATTEN( INPUT => c.value:"genotype") g
    WHERE g.value::INTEGER > 0
), density AS (
    SELECT COUNT(*) AS variant_count,
           (SELECT "length" FROM longest_ref) AS ref_length
    FROM variant_loci
)
SELECT variant_count / ref_length AS variant_density
FROM density;