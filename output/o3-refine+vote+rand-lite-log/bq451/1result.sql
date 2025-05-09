/*  Genotype statistics for chromosome X SNPs (outside PAR1 & PAR2)  */
WITH snp_calls AS (
  SELECT
    c.call_set_name AS sample_id,
    CASE
      /* 1. homozygous reference: all recorded alleles are 0 */
      WHEN (
        SELECT COUNTIF(allele != 0)
        FROM UNNEST(c.genotype) AS allele
      ) = 0
      THEN 'hom_ref'

      /* 2. homozygous alternate: every allele > 0 AND all identical */
      WHEN (
             SELECT COUNTIF(allele > 0)
             FROM UNNEST(c.genotype) AS allele
           ) = ARRAY_LENGTH(c.genotype)
       AND (
             SELECT COUNT(DISTINCT allele)
             FROM UNNEST(c.genotype) AS allele
           ) = 1
      THEN 'hom_alt'

      /* 3. otherwise → heterozygous (at least one non‑reference allele) */
      ELSE 'het'
    END AS category
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = 'X'
        /* exclude pseudo‑autosomal regions */
        AND NOT (v.start BETWEEN  59999      AND   2699519 )
        AND NOT (v.start BETWEEN 154931042   AND 155260559)
        /* retain true single‑nucleotide variants */
        AND LENGTH(v.reference_bases)            = 1
        AND ARRAY_LENGTH(v.alternate_bases)      = 1
        AND LENGTH(v.alternate_bases[OFFSET(0)]) = 1
        /* keep calls that have at least one allele recorded */
        AND ARRAY_LENGTH(c.genotype) > 0
),
agg AS (
  SELECT
    sample_id,
    COUNTIF(category = 'hom_ref') AS homozygous_reference,
    COUNTIF(category = 'hom_alt') AS homozygous_alternate,
    COUNTIF(category = 'het')     AS heterozygous,
    COUNT(*)                      AS callable_sites
  FROM snp_calls
  GROUP BY sample_id
)
SELECT
  sample_id,
  callable_sites,
  homozygous_reference,
  homozygous_alternate,
  heterozygous,
  (homozygous_alternate + heterozygous)                                       AS snv_total,
  ROUND(
        heterozygous * 100.0 /
        NULLIF(homozygous_alternate + heterozygous, 0), 4
  ) AS pct_heterozygous_snvs,
  ROUND(
        homozygous_alternate * 100.0 /
        NULLIF(homozygous_alternate + heterozygous, 0), 4
  ) AS pct_homozygous_alt_snvs
FROM agg
ORDER BY pct_heterozygous_snvs DESC, sample_id;