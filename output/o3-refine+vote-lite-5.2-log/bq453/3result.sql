/*  Variant summary for chr17: 41 196 311‑41 277 499
    – reference / alternate info
    – variant type
    – Hardy‑Weinberg χ² value supplied in the HWE field
    – observed & expected genotype counts (based on sample genotypes)
    – allele frequencies (global + 1 KG super‑pops)
*/
WITH region_variants AS (      -- variants inside the requested interval
  SELECT
    reference_name,
    start,
    `end`,
    reference_bases,
    alternate_bases,           -- ARRAY<STRING>
    VT,
    HWE,
    AF,
    AFR_AF,
    AMR_AF,
    ASN_AF,
    EUR_AF,
    call                       -- ARRAY<STRUCT<>>
  FROM `genomics-public-data.1000_genomes.variants`
  WHERE reference_name = '17'
    AND start BETWEEN 41196311 AND 41277499
    AND ARRAY_LENGTH(alternate_bases) = 1          -- keep bi‑allelic sites
),
genotype_stats AS (            -- tally genotypes & derive sample allele freq
  SELECT
    reference_name,
    start,
    `end`,
    reference_bases,
    alternate_bases[OFFSET(0)]                     AS alt_base,
    VT,
    HWE,
    AF,
    AFR_AF,
    AMR_AF,
    ASN_AF,
    EUR_AF,

    COUNTIF(ARRAY_LENGTH(c.genotype)=2)                                 AS total_genotypes,

    COUNTIF(ARRAY_LENGTH(c.genotype)=2
            AND c.genotype[OFFSET(0)]=0
            AND c.genotype[OFFSET(1)]=0)                                AS obs_hom_ref,

    COUNTIF(ARRAY_LENGTH(c.genotype)=2
            AND ((c.genotype[OFFSET(0)]=0 AND c.genotype[OFFSET(1)]=1)
                 OR (c.genotype[OFFSET(0)]=1 AND c.genotype[OFFSET(1)]=0))) AS obs_het,

    COUNTIF(ARRAY_LENGTH(c.genotype)=2
            AND c.genotype[OFFSET(0)]=1
            AND c.genotype[OFFSET(1)]=1)                                AS obs_hom_alt,

    -- sample ALT allele frequency
    SUM(IF(ARRAY_LENGTH(c.genotype)=2,
           c.genotype[OFFSET(0)] + c.genotype[OFFSET(1)],0))
         / (2*COUNTIF(ARRAY_LENGTH(c.genotype)=2))                      AS p_alt
  FROM region_variants, UNNEST(call) AS c
  GROUP BY
    reference_name, start, `end`, reference_bases, alt_base,
    VT, HWE, AF, AFR_AF, AMR_AF, ASN_AF, EUR_AF
)

SELECT
  reference_name,
  start,
  `end`,
  reference_bases,
  alt_base                                   AS alternate_bases,
  VT                                         AS variant_type,
  HWE                                        AS chi_squared,
  total_genotypes,
  obs_hom_ref,
  obs_het,
  obs_hom_alt,
  ROUND(total_genotypes * POWER(1 - p_alt, 2), 4)      AS exp_hom_ref,
  ROUND(total_genotypes * 2 * p_alt * (1 - p_alt), 4)  AS exp_het,
  ROUND(total_genotypes * POWER(p_alt, 2), 4)          AS exp_hom_alt,
  AF                                                   AS global_AF,
  AFR_AF,
  AMR_AF,
  ASN_AF,
  EUR_AF
FROM genotype_stats
ORDER BY start;