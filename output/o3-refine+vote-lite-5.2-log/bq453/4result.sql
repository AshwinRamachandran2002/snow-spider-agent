/*  Variant–level Hardy‑Weinberg χ² statistics (chr 17: 41 196 311‑41 277 499)
    using the public 1000 Genomes BigQuery release                          */

WITH region_variants AS (
  SELECT
    reference_name,
    start,
    `end`,
    reference_bases,
    ARRAY(SELECT DISTINCT alt FROM UNNEST(alternate_bases) alt)           AS alternate_bases,
    CASE
      WHEN LENGTH(reference_bases)=1
           AND ARRAY_LENGTH(alternate_bases)=1
           AND LENGTH(alternate_bases[OFFSET(0)])=1                      THEN 'SNP'
      ELSE 'OTHER'
    END                                                                  AS variant_type,
    call,
    AF , AFR_AF , AMR_AF , ASN_AF , EUR_AF                               -- 1KG allele‑freq fields
  FROM `genomics-public-data.1000_genomes.variants`
  WHERE reference_name = '17'
    AND start BETWEEN 41196311 AND 41277499
),

--  Flatten diploid genotype calls
genotype_calls AS (
  SELECT
    reference_name,
    start,
    `end`,
    reference_bases,
    alternate_bases,
    variant_type,
    AF, AFR_AF, AMR_AF, ASN_AF, EUR_AF,
    c.genotype AS gt
  FROM region_variants, UNNEST(call) AS c
  WHERE ARRAY_LENGTH(c.genotype) = 2          -- keep only diploid calls
),

--  Observed genotype counts (0/0, 0/1 or 1/0, 1/1 ; only first alt allele considered)
obs AS (
  SELECT
    reference_name,
    start,
    `end`,
    reference_bases,
    alternate_bases,
    variant_type,
    AF, AFR_AF, AMR_AF, ASN_AF, EUR_AF,
    COUNT(*)                                                               AS total_genotypes,
    SUM(CASE WHEN gt[OFFSET(0)] = 0 AND gt[OFFSET(1)] = 0 THEN 1 END)      AS hom_ref_obs,
    SUM(CASE WHEN gt[OFFSET(0)] = 1 AND gt[OFFSET(1)] = 1 THEN 1 END)      AS hom_alt_obs,
    SUM(CASE
          WHEN (gt[OFFSET(0)] = 0 AND gt[OFFSET(1)] = 1)
            OR (gt[OFFSET(0)] = 1 AND gt[OFFSET(1)] = 0) THEN 1 END)       AS het_obs
  FROM genotype_calls
  GROUP BY reference_name, start, `end`,
           reference_bases, alternate_bases, variant_type,
           AF, AFR_AF, AMR_AF, ASN_AF, EUR_AF
),

--  Allele counts / frequencies and Hardy–Weinberg expectations
calc AS (
  SELECT
    *,
    2*hom_ref_obs + het_obs                                               AS ref_allele_count,
    2*hom_alt_obs + het_obs                                               AS alt_allele_count
  FROM obs
),

freqs AS (
  SELECT
    *,
    SAFE_DIVIDE(ref_allele_count, 2*total_genotypes)                      AS p,   -- ref allele freq
    SAFE_DIVIDE(alt_allele_count, 2*total_genotypes)                      AS q    -- alt allele freq
  FROM calc
)

SELECT
  reference_name,
  start,
  `end`,
  reference_bases,
  alternate_bases,
  variant_type,

  /* χ² statistic for Hardy–Weinberg equilibrium */
  SAFE_DIVIDE(POW(hom_ref_obs - total_genotypes*POW(p,2), 2),
              total_genotypes*POW(p,2)) +
  SAFE_DIVIDE(POW(het_obs      - total_genotypes*2*p*q , 2),
              total_genotypes*2*p*q ) +
  SAFE_DIVIDE(POW(hom_alt_obs  - total_genotypes*POW(q,2), 2),
              total_genotypes*POW(q,2))                                    AS chi_squared,

  /* Observed & expected genotype counts */
  total_genotypes,
  hom_ref_obs                     AS observed_hom_ref,
  het_obs                         AS observed_het,
  hom_alt_obs                     AS observed_hom_alt,
  total_genotypes*POW(p,2)        AS expected_hom_ref,
  total_genotypes*2*p*q           AS expected_het,
  total_genotypes*POW(q,2)        AS expected_hom_alt,

  /* Allele frequencies */
  p                               AS ref_allele_freq,
  q                               AS alt_allele_freq,
  AF                              AS alt_allele_freq_1kg,
  AFR_AF,
  AMR_AF,
  ASN_AF,
  EUR_AF
FROM freqs
ORDER BY start;