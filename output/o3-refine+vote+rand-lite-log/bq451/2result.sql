-- SNP genotyping summary per sample on chromosome X
WITH variant_calls AS (
  -- 1.  Keep only chromosome X SNPs outside the two excluded regions
  SELECT
    c.call_set_name AS sample_id,
    c.genotype      AS gt
  FROM `genomics-public-data.1000_genomes.variants` AS v
  JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = 'X'
    AND NOT (v.start BETWEEN  59999       AND   2699519
             OR v.start BETWEEN 154931042  AND 155260559)
    -- single‑nucleotide variants only
    AND LENGTH(v.reference_bases) = 1
    AND ARRAY_LENGTH(v.alternate_bases) = 1
    AND LENGTH(v.alternate_bases[OFFSET(0)]) = 1
    -- genotype array must contain ≥ 1 non‑missing allele ( ≥ 0 )
    AND ARRAY_LENGTH(c.genotype) > 0
    AND EXISTS (SELECT 1 FROM UNNEST(c.genotype) a WHERE a >= 0)
),
classified AS (
  -- 2.  Classify each genotype call
  SELECT
    sample_id,
    CASE
      -- homozygous reference: all non‑missing alleles are 0
      WHEN (
            SELECT COUNT(DISTINCT a) FROM UNNEST(gt) a WHERE a >= 0
           ) = 1
       AND (
            SELECT ANY_VALUE(a) FROM UNNEST(gt) a WHERE a >= 0
           ) = 0
        THEN 'HOM_REF'

      -- homozygous alternate: all non‑missing alleles identical and > 0
      WHEN (
            SELECT COUNT(DISTINCT a) FROM UNNEST(gt) a WHERE a >= 0
           ) = 1
       AND (
            SELECT ANY_VALUE(a) FROM UNNEST(gt) a WHERE a >= 0
           ) > 0
        THEN 'HOM_ALT'

      -- otherwise heterozygous / mixed
      ELSE 'HET'
    END AS genotype_class
  FROM variant_calls
),
aggregated AS (
  -- 3.  Aggregate counts per sample
  SELECT
    sample_id,
    COUNT(*)                                   AS callable_sites,
    COUNTIF(genotype_class = 'HOM_REF')        AS homo_ref_count,
    COUNTIF(genotype_class = 'HOM_ALT')        AS homo_alt_count,
    COUNTIF(genotype_class = 'HET')            AS hetero_count
  FROM classified
  GROUP BY sample_id
)
-- 4.  Final metrics & ordering
SELECT
  sample_id,
  callable_sites,
  homo_ref_count,
  homo_alt_count,
  hetero_count,
  (homo_alt_count + hetero_count)                         AS snv_count,
  ROUND(
        SAFE_DIVIDE(hetero_count , homo_alt_count + hetero_count) * 100,
        4)                                                AS pct_het_snvs,
  ROUND(
        SAFE_DIVIDE(homo_alt_count , homo_alt_count + hetero_count) * 100,
        4)                                                AS pct_hom_alt_snvs
FROM aggregated
ORDER BY pct_het_snvs DESC, sample_id;