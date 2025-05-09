/*  Genotype summary for non‑PAR single‑nucleotide variants on chromosome X  */
WITH classified AS (
  SELECT
    c.call_set_name AS sample_id,
    CASE
      /* homozygous reference (diploid or hemizygous) */
      WHEN (ARRAY_LENGTH(c.genotype) = 2 AND c.genotype[OFFSET(0)] = 0 AND c.genotype[OFFSET(1)] = 0)
        OR (ARRAY_LENGTH(c.genotype) = 1 AND c.genotype[OFFSET(0)] = 0)
        THEN 'hom_ref'

      /* homozygous (or hemizygous) alternate */
      WHEN (ARRAY_LENGTH(c.genotype) = 2
            AND c.genotype[OFFSET(0)] = c.genotype[OFFSET(1)]
            AND c.genotype[OFFSET(0)] > 0)
        OR  (ARRAY_LENGTH(c.genotype) = 1 AND c.genotype[OFFSET(0)] > 0)
        THEN 'hom_alt'

      /* heterozygous  */
      WHEN ARRAY_LENGTH(c.genotype) = 2
           AND (c.genotype[OFFSET(0)] IS NULL
                OR c.genotype[OFFSET(1)] IS NULL
                OR c.genotype[OFFSET(0)] != c.genotype[OFFSET(1)])
           AND (IFNULL(c.genotype[OFFSET(0)],0) > 0
                OR IFNULL(c.genotype[OFFSET(1)],0) > 0)
        THEN 'het'
    END AS gt_type
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = 'X'
    AND NOT (v.start BETWEEN  59999      AND   2699519)      -- exclude PAR1
    AND NOT (v.start BETWEEN 154931042   AND 155260559)      -- exclude PAR2
    AND ARRAY_LENGTH(v.alternate_bases) = 1                  -- keep SNPs only
    AND ARRAY_LENGTH(c.genotype) >= 1                        -- at least one allele
),
aggregated AS (
  SELECT
    sample_id,
    SUM(CASE WHEN gt_type = 'hom_ref' THEN 1 ELSE 0 END) AS hom_ref,
    SUM(CASE WHEN gt_type = 'hom_alt' THEN 1 ELSE 0 END) AS hom_alt,
    SUM(CASE WHEN gt_type = 'het'     THEN 1 ELSE 0 END) AS het
  FROM classified
  WHERE gt_type IS NOT NULL
  GROUP BY sample_id
)
SELECT
  sample_id,
  (hom_ref + hom_alt + het)                                  AS callable_sites,
  hom_ref,
  hom_alt,
  het,
  (hom_alt + het)                                            AS snv_total,
  ROUND(SAFE_DIVIDE(het,     hom_alt + het) * 100, 4)        AS het_pct_of_snv,
  ROUND(SAFE_DIVIDE(hom_alt, hom_alt + het) * 100, 4)        AS hom_alt_pct_of_snv
FROM aggregated
ORDER BY het_pct_of_snv DESC, sample_id;