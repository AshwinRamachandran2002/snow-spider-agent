WITH genotypes AS (
  SELECT
    v."reference_name",
    v."start",
    v."end",
    v."reference_bases",
    ab.value::STRING AS "alternate_bases",
    COALESCE(v."VT", 'Unknown') AS "variant_type",
    CAST(c.value:"genotype"[0]::STRING AS NUMBER) AS "allele0",
    CAST(c.value:"genotype"[1]::STRING AS NUMBER) AS "allele1"
  FROM
    "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
    , LATERAL FLATTEN(input => v."alternate_bases") ab
    , LATERAL FLATTEN(input => v."call") c
  WHERE
    v."reference_name" = '17'
    AND v."start" BETWEEN 41196311 AND 41277499
    AND c.value:"genotype"[0] IS NOT NULL
    AND c.value:"genotype"[1] IS NOT NULL
)

SELECT
  "reference_name",
  "start",
  "end",
  "reference_bases",
  "alternate_bases",
  "variant_type",
  ROUND(
    (
      POWER(
        SUM(IFF("allele0" = 0 AND "allele1" = 0, 1, 0)) -
        POWER(1 - (SUM("allele0" + "allele1") / (2 * COUNT(*))), 2) * COUNT(*),
        2
      ) / NULLIF(POWER(1 - (SUM("allele0" + "allele1") / (2 * COUNT(*))), 2) * COUNT(*), 0)
    ) +
    (
      POWER(
        SUM(IFF(("allele0" = 0 AND "allele1" = 1) OR ("allele0" = 1 AND "allele1" = 0), 1, 0)) -
        2 * (SUM("allele0" + "allele1") / (2 * COUNT(*))) * (1 - (SUM("allele0" + "allele1") / (2 * COUNT(*)))) * COUNT(*),
        2
      ) / NULLIF(2 * (SUM("allele0" + "allele1") / (2 * COUNT(*))) * (1 - (SUM("allele0" + "allele1") / (2 * COUNT(*)))), 0)
    ) +
    (
      POWER(
        SUM(IFF("allele0" = 1 AND "allele1" = 1, 1, 0)) -
        POWER(SUM("allele0" + "allele1") / (2 * COUNT(*)), 2) * COUNT(*),
        2
      ) / NULLIF(POWER(SUM("allele0" + "allele1") / (2 * COUNT(*)), 2) * COUNT(*), 0)
    )
  ,4) AS "chi_squared_score",
  
  SUM(IFF("allele0" = 0 AND "allele1" = 0, 1, 0)) AS "observed_homo_ref",
  SUM(IFF(("allele0" = 0 AND "allele1" = 1) OR ("allele0" = 1 AND "allele1" = 0), 1, 0)) AS "observed_heterozygous",
  SUM(IFF("allele0" = 1 AND "allele1" = 1, 1, 0)) AS "observed_homo_alt",
  
  ROUND(
    POWER(1 - (SUM("allele0" + "allele1") / (2 * COUNT(*))), 2) * COUNT(*), 4
  ) AS "expected_homo_ref",
  ROUND(
    2 * (SUM("allele0" + "allele1") / (2 * COUNT(*))) * (1 - (SUM("allele0" + "allele1") / (2 * COUNT(*)))) * COUNT(*), 4
  ) AS "expected_heterozygous",
  ROUND(
    POWER(SUM("allele0" + "allele1") / (2 * COUNT(*)), 2) * COUNT(*), 4
  ) AS "expected_homo_alt",
  
  ROUND(SUM("allele0" + "allele1") / (2 * COUNT(*)), 4) AS "allele_frequency"

FROM
  genotypes
GROUP BY
  "reference_name",
  "start",
  "end",
  "reference_bases",
  "alternate_bases",
  "variant_type";