SELECT
  call.call_set_name AS sample_id,

  COUNTIF(
    call.genotype[SAFE_OFFSET(0)] = 0
    AND (call.genotype[SAFE_OFFSET(1)] IS NULL OR call.genotype[SAFE_OFFSET(1)] = 0)
  ) AS homozygous_reference_alleles,

  COUNTIF(
    call.genotype[SAFE_OFFSET(0)] > 0
    AND (call.genotype[SAFE_OFFSET(1)] IS NULL OR call.genotype[SAFE_OFFSET(1)] = call.genotype[SAFE_OFFSET(0)])
    AND (call.genotype[SAFE_OFFSET(1)] IS NULL OR call.genotype[SAFE_OFFSET(1)] > 0)
  ) AS homozygous_alternate_alleles,

  COUNTIF(
    call.genotype[SAFE_OFFSET(1)] IS NOT NULL
    AND call.genotype[SAFE_OFFSET(0)] != call.genotype[SAFE_OFFSET(1)]
    AND (call.genotype[SAFE_OFFSET(0)] > 0 OR call.genotype[SAFE_OFFSET(1)] > 0)
  ) AS heterozygous_alternate_alleles,

  COUNT(*) AS total_callable_sites,

  SUM(
    CASE WHEN
      call.genotype[SAFE_OFFSET(0)] > 0
      OR call.genotype[SAFE_OFFSET(1)] > 0
    THEN 1 ELSE 0 END
  ) AS total_snvs,

  ROUND(
    SAFE_MULTIPLY(
      SAFE_DIVIDE(
        COUNTIF(
          call.genotype[SAFE_OFFSET(1)] IS NOT NULL
          AND call.genotype[SAFE_OFFSET(0)] != call.genotype[SAFE_OFFSET(1)]
          AND (call.genotype[SAFE_OFFSET(0)] > 0 OR call.genotype[SAFE_OFFSET(1)] > 0)
        ),
        SUM(
          CASE WHEN
            call.genotype[SAFE_OFFSET(0)] > 0
            OR call.genotype[SAFE_OFFSET(1)] > 0
          THEN 1 ELSE 0 END
        )
      ), 100
    ), 4
  ) AS percentage_heterozygous_alternate_alleles,

  ROUND(
    SAFE_MULTIPLY(
      SAFE_DIVIDE(
        COUNTIF(
          call.genotype[SAFE_OFFSET(0)] > 0
          AND (call.genotype[SAFE_OFFSET(1)] IS NULL OR call.genotype[SAFE_OFFSET(1)] = call.genotype[SAFE_OFFSET(0)])
          AND (call.genotype[SAFE_OFFSET(1)] IS NULL OR call.genotype[SAFE_OFFSET(1)] > 0)
        ),
        SUM(
          CASE WHEN
            call.genotype[SAFE_OFFSET(0)] > 0
            OR call.genotype[SAFE_OFFSET(1)] > 0
          THEN 1 ELSE 0 END
        )
      ), 100
    ), 4
  ) AS percentage_homozygous_alternate_alleles

FROM
  `genomics-public-data.1000_genomes.variants`,
  UNNEST(call) AS call
WHERE
  reference_name = 'X'
  AND start NOT BETWEEN 59999 AND 2699519
  AND start NOT BETWEEN 154931042 AND 155260559
  AND LENGTH(reference_bases) = 1
  AND ARRAY_LENGTH(alternate_bases) = 1
  AND LENGTH(alternate_bases[ORDINAL(1)]) = 1
  AND call.genotype IS NOT NULL
GROUP BY
  sample_id