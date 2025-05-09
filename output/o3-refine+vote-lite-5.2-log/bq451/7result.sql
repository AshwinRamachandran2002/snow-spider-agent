/*  Genotype summary for chromosome X SNPs outside the two
    pseudo‑autosomal regions (PAR1 & PAR2) in the public
    1000 Genomes BigQuery dataset                                */
WITH filtered_variants AS (
  SELECT
    c.call_set_name AS sample_id,
    c.genotype      AS genotype
  FROM
    `genomics-public-data.1000_genomes.variants` AS v,
    UNNEST(v.call) AS c
  WHERE
        v.reference_name = 'X'
    -- Exclude PAR1 and PAR2 regions
    AND NOT (v.start BETWEEN  59999      AND   2699519
          OR v.start BETWEEN 154931042   AND 155260559)
    -- Keep only biallelic single‑nucleotide polymorphisms
    AND LENGTH(v.reference_bases) = 1
    AND ARRAY_LENGTH(v.alternate_bases) = 1
    AND LENGTH(v.alternate_bases[OFFSET(0)]) = 1
    -- Require at least one allele in genotype array
    AND ARRAY_LENGTH(c.genotype) >= 1
),

categorized AS (
  SELECT
    sample_id,
    CASE
      -- Homozygous reference (both alleles 0; second may be NULL for haploid)
      WHEN genotype[SAFE_OFFSET(0)] = 0
       AND (genotype[SAFE_OFFSET(1)] = 0 OR genotype[SAFE_OFFSET(1)] IS NULL)
      THEN 'hom_ref'

      -- Homozygous alternate (two identical non‑zero alleles)
      WHEN genotype[SAFE_OFFSET(0)] > 0
       AND genotype[SAFE_OFFSET(0)] = genotype[SAFE_OFFSET(1)]
      THEN 'hom_alt'

      -- Heterozygous (alleles differ OR one allele missing) with ≥1 alternate
      WHEN (
              genotype[SAFE_OFFSET(0)] IS DISTINCT FROM genotype[SAFE_OFFSET(1)]
           OR genotype[SAFE_OFFSET(1)] IS NULL
           )
       AND (genotype[SAFE_OFFSET(0)] > 0 OR genotype[SAFE_OFFSET(1)] > 0)
      THEN 'het'
    END AS genotype_class
  FROM filtered_variants
)

SELECT
  sample_id                                                    AS sample,
  COUNTIF(genotype_class IS NOT NULL)                          AS callable_sites,
  COUNTIF(genotype_class = 'hom_ref')                          AS homozygous_reference,
  COUNTIF(genotype_class = 'hom_alt')                          AS homozygous_alternate,
  COUNTIF(genotype_class = 'het')                              AS heterozygous,
  COUNTIF(genotype_class IN ('hom_alt','het'))                 AS snv_sites,
  SAFE_DIVIDE(COUNTIF(genotype_class = 'het'),
              COUNTIF(genotype_class IN ('hom_alt','het')))    AS pct_het_among_snv,
  SAFE_DIVIDE(COUNTIF(genotype_class = 'hom_alt'),
              COUNTIF(genotype_class IN ('hom_alt','het')))    AS pct_hom_alt_among_snv
FROM
  categorized
GROUP BY
  sample
ORDER BY
  pct_het_among_snv DESC,
  sample;