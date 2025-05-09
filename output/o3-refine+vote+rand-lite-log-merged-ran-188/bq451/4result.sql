-- Description:  Per-sample summary of chromosome-X SNP genotypes
--   • keeps only single-nucleotide sites outside PAR1 / PAR2  
--   • classifies each genotype (homo-ref / homo-alt / hetero)  
--   • reports callable-site counts, SNV counts, and % breakdown  
--   • ordered by heterozygous-SNV percentage (desc)

WITH x_snp AS (
  SELECT
    v.start,
    c.call_set_name AS sample_id,
    c.genotype
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = 'X'
    -- outside pseudo-autosomal regions
    AND NOT ( (v.start BETWEEN   59999     AND   2699519)
           OR (v.start BETWEEN 154931042   AND 155260559) )
    -- single-nucleotide reference & all ALT alleles are 1-bp
    AND LENGTH(v.reference_bases) = 1
    AND ARRAY_LENGTH(v.alternate_bases) > 0
    AND ARRAY_LENGTH(
          ARRAY(
            SELECT alt
            FROM UNNEST(v.alternate_bases) AS alt
            WHERE LENGTH(alt) = 1
          )
        ) = ARRAY_LENGTH(v.alternate_bases)
    -- genotype must contain at least one allele
    AND ARRAY_LENGTH(c.genotype) >= 1
),
classified AS (
  SELECT
    sample_id,
    CASE
      -- homozygous reference (haploid or diploid)
      WHEN (ARRAY_LENGTH(genotype)=1 AND genotype[OFFSET(0)] = 0) OR
           (ARRAY_LENGTH(genotype)=2 AND genotype[OFFSET(0)] = 0 AND genotype[OFFSET(1)] = 0)
      THEN 'homo_ref'

      -- homozygous alternate (haploid or diploid)
      WHEN (ARRAY_LENGTH(genotype)=1 AND genotype[OFFSET(0)] > 0) OR
           (ARRAY_LENGTH(genotype)=2 AND genotype[OFFSET(0)] > 0
                                   AND genotype[OFFSET(0)] = genotype[OFFSET(1)])
      THEN 'homo_alt'

      -- everything else (different alleles, any −1, etc.)
      ELSE 'hetero'
    END AS category
  FROM x_snp
),
per_sample AS (
  SELECT
    sample_id,
    COUNTIF(category = 'homo_ref') AS homo_ref,
    COUNTIF(category = 'homo_alt') AS homo_alt,
    COUNTIF(category = 'hetero')   AS hetero
  FROM classified
  GROUP BY sample_id
)
SELECT
  sample_id,
  homo_ref + homo_alt + hetero                                   AS callable_sites,
  homo_ref,
  homo_alt,
  hetero,
  homo_alt + hetero                                              AS snv_count,
  SAFE_DIVIDE(hetero  , NULLIF(homo_alt + hetero, 0)) * 100      AS pct_hetero_snv,
  SAFE_DIVIDE(homo_alt, NULLIF(homo_alt + hetero, 0)) * 100      AS pct_homo_alt_snv
FROM per_sample
ORDER BY pct_hetero_snv DESC, sample_id;