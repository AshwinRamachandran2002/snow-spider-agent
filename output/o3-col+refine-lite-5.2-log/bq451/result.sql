-- Genotype summary for chr X SNVs (callable region only)
WITH classified AS (
  SELECT
    c.call_set_name AS sample_id,
    CASE
      -- homozygous reference: two alleles present and both are 0
      WHEN c.genotype[OFFSET(0)] = 0
           AND c.genotype[SAFE_OFFSET(1)] IS NOT NULL
           AND c.genotype[SAFE_OFFSET(1)] = 0                       THEN 'hom_ref'

      -- homozygous alternate: two alleles present, identical, and > 0
      WHEN c.genotype[OFFSET(0)] > 0
           AND c.genotype[SAFE_OFFSET(1)] IS NOT NULL
           AND c.genotype[OFFSET(0)] = c.genotype[SAFE_OFFSET(1)]   THEN 'hom_alt'

      -- all other callable genotypes (including haploid or mixed)
      ELSE                                                            'het'
    END AS class
  FROM   `genomics-public-data.1000_genomes.variants`  AS v
  JOIN   UNNEST(v.call) AS c
  WHERE  v.reference_name = 'X'
    -- callable site (≥ 1 allele recorded)
    AND  ARRAY_LENGTH(c.genotype) >= 1

    -- exclude PAR‑1 and PAR‑2 / XTR coordinates
    AND  NOT ( (v.start BETWEEN  59999     AND  2699519)
            OR (v.start BETWEEN 154931042  AND 155260559) )

    -- restrict to single‑nucleotide polymorphisms
    AND  ARRAY_LENGTH(v.alternate_bases) = 1
    AND  LENGTH(v.reference_bases)       = 1
    AND  LENGTH(v.alternate_bases[OFFSET(0)]) = 1
),
agg AS (
  SELECT
    sample_id,
    COUNT(*)                                     AS callable_sites,
    SUM(IF(class = 'hom_ref', 1, 0))             AS hom_ref_cnt,
    SUM(IF(class = 'hom_alt', 1, 0))             AS hom_alt_cnt,
    SUM(IF(class = 'het',      1, 0))            AS het_cnt,
    -- SNVs are the non‑reference genotypes
    SUM(IF(class IN ('hom_alt','het'), 1, 0))    AS snv_cnt
  FROM   classified
  GROUP BY sample_id
)
SELECT
  sample_id,
  callable_sites,
  hom_ref_cnt,
  hom_alt_cnt,
  het_cnt,
  snv_cnt,
  ROUND(100 * het_cnt     / NULLIF(snv_cnt, 0), 2) AS pct_het_among_snvs,
  ROUND(100 * hom_alt_cnt / NULLIF(snv_cnt, 0), 2) AS pct_hom_alt_among_snvs
FROM   agg
ORDER BY
  pct_het_among_snvs DESC,
  sample_id;