/*  SNP genotypes on chr X (outside PARs) – counts and percentages per sample     */
WITH filtered_variants AS (          -- chromosome‑X SNPs, excluding the two PAR regions
  SELECT
    call
  FROM `genomics-public-data.1000_genomes.variants`
  WHERE reference_name = 'X'
    AND NOT (start BETWEEN  59999     AND   2699519)        -- PAR‑1
    AND NOT (start BETWEEN 154931042  AND 155260559)        -- PAR‑2
    -- keep only single‑nucleotide polymorphisms
    AND LENGTH(reference_bases) = 1
    AND ARRAY_LENGTH(alternate_bases) = 1
    AND LENGTH(alternate_bases[OFFSET(0)]) = 1
),
call_rows AS (                   -- one row per genotype call
  SELECT
    c.call_set_name            AS sample_id,
    c.genotype[OFFSET(0)]      AS a1,          -- first allele
    c.genotype[SAFE_OFFSET(1)] AS a2           -- second allele (NULL if haploid)
  FROM filtered_variants v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE ARRAY_LENGTH(c.genotype) > 0           -- at least one allele present
),
classified AS (                  -- classify each genotype
  SELECT
    sample_id,
    CASE
      WHEN a1 = 0 AND a2 = 0                                   THEN 'hom_ref'
      WHEN a1 IS NOT NULL AND a1 = a2 AND a1 > 0               THEN 'hom_alt'
      WHEN (a1 IS NULL OR a2 IS NULL OR a1 != a2)
           AND (IFNULL(a1,0) > 0 OR IFNULL(a2,0) > 0)          THEN 'het'
      ELSE 'other'
    END AS class
  FROM call_rows
)
SELECT
  sample_id,
  SUM(CASE WHEN class = 'hom_ref' THEN 1 ELSE 0 END) AS homozygous_reference,
  SUM(CASE WHEN class = 'hom_alt' THEN 1 ELSE 0 END) AS homozygous_alternate,
  SUM(CASE WHEN class = 'het'     THEN 1 ELSE 0 END) AS heterozygous,
  SUM(CASE WHEN class IN ('hom_ref','hom_alt','het') THEN 1 ELSE 0 END) AS callable_sites,
  SUM(CASE WHEN class IN ('hom_alt','het') THEN 1 ELSE 0 END)           AS snvs,
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN class = 'het' THEN 1 ELSE 0 END),
      NULLIF(SUM(CASE WHEN class IN ('hom_alt','het') THEN 1 ELSE 0 END),0)
    ) * 100 , 4
  ) AS pct_heterozygous_snvs,
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN class = 'hom_alt' THEN 1 ELSE 0 END),
      NULLIF(SUM(CASE WHEN class IN ('hom_alt','het') THEN 1 ELSE 0 END),0)
    ) * 100 , 4
  ) AS pct_homozygous_alternate_snvs
FROM classified
WHERE class IN ('hom_ref','hom_alt','het')                 -- keep callable genotypes
GROUP BY sample_id
ORDER BY pct_heterozygous_snvs DESC, sample_id;