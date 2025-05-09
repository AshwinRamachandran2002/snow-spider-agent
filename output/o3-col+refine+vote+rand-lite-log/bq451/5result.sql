WITH classified AS (
  SELECT
    c.call_set_name AS sample_id,
    CASE
      -- homozygous reference: every allele is 0
      WHEN (SELECT COUNTIF(g <> 0 OR g IS NULL)
            FROM UNNEST(c.genotype) AS g) = 0                       THEN 'hom_ref'

      -- homozygous alternate: all alleles identical, non-null, > 0
      WHEN (SELECT COUNT(DISTINCT g)
            FROM UNNEST(c.genotype) AS g
            WHERE g IS NOT NULL) = 1
           AND (SELECT MIN(g)
                FROM UNNEST(c.genotype) AS g) > 0                   THEN 'hom_alt'

      -- otherwise heterozygous
      ELSE 'het'
    END AS gt_class
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = 'X'
    -- single-nucleotide variant
    AND LENGTH(v.reference_bases) = 1
    AND ARRAY_LENGTH(v.alternate_bases) = 1
    AND LENGTH(v.alternate_bases[OFFSET(0)]) = 1
    -- exclude PAR1 & PAR2
    AND NOT (v.start BETWEEN 59999 AND 2699519)
    AND NOT (v.start BETWEEN 154931042 AND 155260559)
    -- genotype array must contain alleles
    AND ARRAY_LENGTH(c.genotype) > 0
),

per_sample AS (
  SELECT
    sample_id,
    COUNTIF(gt_class = 'hom_ref') AS hom_ref_ct,
    COUNTIF(gt_class = 'hom_alt') AS hom_alt_ct,
    COUNTIF(gt_class = 'het')     AS het_ct
  FROM classified
  GROUP BY sample_id
)

SELECT
  sample_id,
  hom_ref_ct + hom_alt_ct + het_ct                              AS callable_sites,
  hom_ref_ct,
  hom_alt_ct,
  het_ct,
  hom_alt_ct + het_ct                                           AS snv_ct,
  ROUND(100 * het_ct     / NULLIF(hom_alt_ct + het_ct, 0), 2)   AS pct_het_in_snv,
  ROUND(100 * hom_alt_ct / NULLIF(hom_alt_ct + het_ct, 0), 2)   AS pct_hom_alt_in_snv
FROM per_sample
ORDER BY pct_het_in_snv DESC, sample_id;