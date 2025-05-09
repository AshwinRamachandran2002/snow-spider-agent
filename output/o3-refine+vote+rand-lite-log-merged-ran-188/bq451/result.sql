--  Genotype-class summary for chr X SNPs (non-PAR) in the public 1000 Genomes dataset
WITH snv_calls AS (
  SELECT
    c.call_set_name AS sample_id,
    /* classify each non-empty genotype */
    CASE
      WHEN ARRAY_LENGTH(c.genotype) = 0                             THEN NULL       -- skip empty
      WHEN (SELECT COUNTIF(a > 0) FROM UNNEST(c.genotype) a) = 0    THEN 'hom_ref'  -- all ref
      WHEN (SELECT COUNT(DISTINCT a)  FROM UNNEST(c.genotype) a) = 1
           AND (SELECT COUNTIF(a > 0) FROM UNNEST(c.genotype) a) =
               ARRAY_LENGTH(c.genotype)                             THEN 'hom_alt'  -- all same alt
      ELSE 'het'                                                                   -- mixed / other
    END AS gt_class
  FROM
    `genomics-public-data.1000_genomes.variants`,
    UNNEST(call) AS c
  WHERE
        reference_name = 'X'
    AND NOT (start BETWEEN  59999     AND   2699519)      -- exclude PAR-1
    AND NOT (start BETWEEN 154931042  AND 155260559)      -- exclude PAR-2
    AND LENGTH(reference_bases) = 1                       -- SNP filter
    AND ARRAY_LENGTH(alternate_bases) = 1
    AND LENGTH(alternate_bases[OFFSET(0)]) = 1            -- SNP filter
)
SELECT
  sample_id                                   AS sample,
  COUNT(*)                                    AS callable_sites,
  COUNTIF(gt_class = 'hom_ref')               AS hom_ref_cnt,
  COUNTIF(gt_class = 'hom_alt')               AS hom_alt_cnt,
  COUNTIF(gt_class = 'het')                   AS het_cnt,
  COUNTIF(gt_class IN ('hom_alt','het'))      AS snv_cnt,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(gt_class = 'het'),
      COUNTIF(gt_class IN ('hom_alt','het'))
    ) * 100, 2)                               AS pct_het_in_snv,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(gt_class = 'hom_alt'),
      COUNTIF(gt_class IN ('hom_alt','het'))
    ) * 100, 2)                               AS pct_homalt_in_snv
FROM snv_calls
WHERE gt_class IS NOT NULL
GROUP BY sample_id
ORDER BY pct_het_in_snv DESC, sample;