WITH per_call AS (
  SELECT
    c.call_set_name AS sample_id,
    CASE
      -- homozygous reference: all alleles are 0
      WHEN (SELECT COUNTIF(a > 0) FROM UNNEST(c.genotype) AS a) = 0
        THEN 'hom_ref'

      -- homozygous alternate: all alleles are the same number > 0
      WHEN (SELECT COUNTIF(a > 0) FROM UNNEST(c.genotype) AS a) = ARRAY_LENGTH(c.genotype)
           AND (SELECT COUNT(DISTINCT a) FROM UNNEST(c.genotype) AS a) = 1
        THEN 'hom_alt'

      -- heterozygous: at least one alt allele present
      WHEN (SELECT COUNTIF(a > 0) FROM UNNEST(c.genotype) AS a) > 0
        THEN 'het'
      ELSE NULL
    END AS gt_type
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = 'X'
    -- Exclude pseudo‑autosomal regions
    AND v.start NOT BETWEEN  59999      AND   2699519
    AND v.start NOT BETWEEN 154931042   AND 155260559
    -- Keep true SNPs only (1‑bp ref, exactly one 1‑bp alt)
    AND ARRAY_LENGTH(v.alternate_bases)      = 1
    AND LENGTH(v.reference_bases)            = 1
    AND LENGTH(v.alternate_bases[OFFSET(0)]) = 1
    -- Callable genotypes
    AND ARRAY_LENGTH(c.genotype) > 0
),
per_sample AS (
  SELECT
    sample_id,
    COUNTIF(gt_type = 'hom_ref') AS hom_ref,
    COUNTIF(gt_type = 'hom_alt') AS hom_alt,
    COUNTIF(gt_type = 'het')     AS het
  FROM per_call
  GROUP BY sample_id
)
SELECT
  sample_id,
  hom_ref + hom_alt + het                                     AS callable_sites,
  hom_ref,
  hom_alt,
  het,
  hom_alt + het                                               AS snv_total,
  ROUND(SAFE_DIVIDE(het,      hom_alt + het) * 100, 4) AS het_pct_of_snv,
  ROUND(SAFE_DIVIDE(hom_alt,  hom_alt + het) * 100, 4) AS hom_alt_pct_of_snv
FROM per_sample
ORDER BY het_pct_of_snv DESC, sample_id;