/* Summary statistics for gnomAD v3 variants on chr1:55 039 447‑55 064 852 */
WITH
  params AS (
    SELECT
      55039447 AS region_start,
      55064852 AS region_end,
      55064852 - 55039447 + 1 AS region_length
  ),

  /* Variants inside the requested interval */
  filtered AS (
    SELECT
      g.start_position,

      /* total allele count across all alternate alleles */
      (SELECT SUM(alt.AC)
       FROM UNNEST(g.alternate_bases) AS alt)        AS variant_ac,

      g.AN                                           AS variant_an,

      /* distinct gene symbols (from VEP annotations) */
      ARRAY(
        SELECT DISTINCT v.SYMBOL
        FROM UNNEST(g.alternate_bases) AS alt
        CROSS JOIN UNNEST(IFNULL(alt.vep, [])) AS v
        WHERE v.SYMBOL IS NOT NULL
      )                                              AS symbols
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` AS g
    CROSS JOIN params
    WHERE g.start_position BETWEEN params.region_start AND params.region_end
  ),

  /* Aggregate across all variants */
  aggregated AS (
    SELECT
      COUNT(*)                                AS variant_count,
      SUM(variant_ac)                         AS total_ac,
      SUM(variant_an)                         AS total_an,
      ARRAY_AGG(DISTINCT s ORDER BY s)        AS gene_symbols
    FROM filtered, UNNEST(symbols) AS s
  )

SELECT
  a.variant_count,
  a.total_ac,
  a.total_an,
  a.gene_symbols,
  p.region_length,
  SAFE_DIVIDE(p.region_length, a.variant_count) AS mutation_density
FROM aggregated AS a
CROSS JOIN params AS p;