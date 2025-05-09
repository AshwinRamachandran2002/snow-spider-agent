/*  Genotype summary for chromosome X SNPs outside the two PAR regions  */
WITH per_call AS (
  SELECT
    c.call_set_name AS sample_id,
    CASE
      /* homozygous reference: exactly two alleles and both are 0 -------- */
      WHEN ARRAY_LENGTH(c.genotype) = 2
           AND (SELECT LOGICAL_AND(g = 0) FROM UNNEST(c.genotype) AS g)
      THEN 'hom_ref'

      /* homozygous alternate: exactly two identical alleles > 0 ---------- */
      WHEN ARRAY_LENGTH(c.genotype) = 2
           AND (SELECT LOGICAL_AND(g > 0)  FROM UNNEST(c.genotype) AS g)
           AND (SELECT COUNT(DISTINCT g)   FROM UNNEST(c.genotype) AS g) = 1
      THEN 'hom_alt'

      /* all remaining callable genotypes are treated as heterozygous ---- */
      ELSE 'het'
    END AS gt_class
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = 'X'
    AND v.VT = 'SNP'                                   -- single‑nucleotide variants
    AND NOT (v.start BETWEEN  59999      AND  2699519  -- exclude PAR‑1
             OR v.start BETWEEN 154931042 AND 155260559) -- exclude PAR‑2
    AND ARRAY_LENGTH(c.genotype) > 0                   -- callable genotypes
)

SELECT
  sample_id                                                     AS sample,
  COUNTIF(gt_class = 'hom_ref')                                 AS homozygous_reference,
  COUNTIF(gt_class = 'hom_alt')                                 AS homozygous_alternate,
  COUNTIF(gt_class = 'het')                                     AS heterozygous,
  COUNT(*)                                                      AS callable_sites,
  COUNTIF(gt_class IN ('hom_alt', 'het'))                       AS snv_sites,
  SAFE_DIVIDE(COUNTIF(gt_class = 'het'),
              NULLIF(COUNTIF(gt_class IN ('hom_alt', 'het')), 0)) * 100
                                                                AS pct_het_among_snvs,
  SAFE_DIVIDE(COUNTIF(gt_class = 'hom_alt'),
              NULLIF(COUNTIF(gt_class IN ('hom_alt', 'het')), 0)) * 100
                                                                AS pct_hom_alt_among_snvs
FROM per_call
GROUP BY sample_id
ORDER BY pct_het_among_snvs DESC, sample;