/*  Hardy‑Weinberg statistics for all bi‑allelic 1000 G variants
    on chr 17 between 41 196 311 and 41 277 499                    */
WITH variants_filtered AS (
  SELECT
    reference_name,
    start                                 AS start_pos,
    `end`                                 AS end_pos,
    reference_bases,
    alternate_bases[SAFE_OFFSET(0)]       AS alternate_base,
    COALESCE(VT , SVTYPE ,                -- not always present
             CASE
               WHEN LENGTH(reference_bases) = 1
                    AND LENGTH(alternate_bases[SAFE_OFFSET(0)]) = 1 THEN 'SNP'
               WHEN LENGTH(reference_bases)  > LENGTH(alternate_bases[SAFE_OFFSET(0)]) THEN 'DEL'
               WHEN LENGTH(reference_bases)  < LENGTH(alternate_bases[SAFE_OFFSET(0)]) THEN 'INS'
               ELSE 'OTHER'
             END)                         AS variant_type,
    AF                                     AS AF_1000G,
    call
  FROM `genomics-public-data.1000_genomes.variants`
  WHERE reference_name = '17'
    AND start BETWEEN 41196311 AND 41277499
    AND ARRAY_LENGTH(alternate_bases) = 1            -- keep bi‑allelic sites
),

call_level AS (
  SELECT
    v.reference_name,
    v.start_pos,
    v.end_pos,
    v.reference_bases,
    v.alternate_base,
    v.variant_type,
    v.AF_1000G,
    c.genotype                                AS gt
  FROM variants_filtered v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE ARRAY_LENGTH(c.genotype) = 2          -- diploid calls
    AND NOT EXISTS (
      SELECT 1 FROM UNNEST(c.genotype) g WHERE g < 0          -- exclude no‑calls
    )
),

genotype_counts AS (
  SELECT
    reference_name,
    start_pos,
    end_pos,
    reference_bases,
    alternate_base,
    variant_type,
    AF_1000G,
    SUM(CASE WHEN gt[OFFSET(0)] = 0 AND gt[OFFSET(1)] = 0 THEN 1 ELSE 0 END) AS hom_ref_obs,
    SUM(CASE WHEN gt[OFFSET(0)] = 1 AND gt[OFFSET(1)] = 1 THEN 1 ELSE 0 END) AS hom_alt_obs,
    SUM(CASE WHEN gt[OFFSET(0)] != gt[OFFSET(1)]                              THEN 1 ELSE 0 END) AS het_obs
  FROM call_level
  GROUP BY reference_name, start_pos, end_pos, reference_bases,
           alternate_base, variant_type, AF_1000G
),

stats AS (
  SELECT
    *,
    hom_ref_obs + het_obs + hom_alt_obs                             AS total_genotypes,
    SAFE_DIVIDE(2 * hom_alt_obs + het_obs,
                2 * (hom_ref_obs + het_obs + hom_alt_obs))          AS alt_AF_obs
  FROM genotype_counts
),

expectations AS (
  SELECT
    *,
    total_genotypes * POW(1 - alt_AF_obs, 2)            AS hom_ref_exp,
    total_genotypes * 2 * alt_AF_obs * (1 - alt_AF_obs) AS het_exp,
    total_genotypes * POW(alt_AF_obs, 2)                AS hom_alt_exp
  FROM stats
)

SELECT
  reference_name,
  start_pos                           AS start,
  end_pos                             AS `end`,
  reference_bases,
  alternate_base                      AS alternate_bases,
  variant_type,
  ROUND(
        (POW(hom_ref_obs - hom_ref_exp, 2) / NULLIF(hom_ref_exp ,0)) +
        (POW(het_obs     - het_exp    , 2) / NULLIF(het_exp     ,0)) +
        (POW(hom_alt_obs - hom_alt_exp, 2) / NULLIF(hom_alt_exp ,0))
  ,4)                                 AS chi_squared,
  total_genotypes,
  hom_ref_obs,
  het_obs,
  hom_alt_obs,
  ROUND(hom_ref_exp ,4)               AS hom_ref_exp,
  ROUND(het_exp     ,4)               AS het_exp,
  ROUND(hom_alt_exp ,4)               AS hom_alt_exp,
  ROUND(alt_AF_obs  ,4)               AS alt_AF_obs,
  AF_1000G
FROM expectations
ORDER BY start;