WITH sample_counts AS (
  SELECT
    CASE
      WHEN Super_Population IN ('EAS', 'SAS') THEN 'ASN'
      ELSE Super_Population
    END AS Super_Population,
    COUNT(DISTINCT Sample) AS Sample_Count
  FROM
    `genomics-public-data.1000_genomes.sample_info`
  GROUP BY
    CASE
      WHEN Super_Population IN ('EAS', 'SAS') THEN 'ASN'
      ELSE Super_Population
    END
),
variants_per_population AS (
  SELECT
    'AFR' AS Super_Population,
    v.VT AS Variant_Type,
    CONCAT(v.reference_name, ':', v.start, ':', v.reference_bases, ':', a) AS variant_id
  FROM
    `genomics-public-data.1000_genomes.variants` v,
    UNNEST(v.alternate_bases) AS a
  WHERE
    v.reference_name NOT IN ('X', 'Y', 'MT')
    AND v.VT IS NOT NULL
    AND v.AFR_AF >= 0.05
  UNION ALL
  SELECT
    'AMR' AS Super_Population,
    v.VT AS Variant_Type,
    CONCAT(v.reference_name, ':', v.start, ':', v.reference_bases, ':', a) AS variant_id
  FROM
    `genomics-public-data.1000_genomes.variants` v,
    UNNEST(v.alternate_bases) AS a
  WHERE
    v.reference_name NOT IN ('X', 'Y', 'MT')
    AND v.VT IS NOT NULL
    AND v.AMR_AF >= 0.05
  UNION ALL
  SELECT
    'EUR' AS Super_Population,
    v.VT AS Variant_Type,
    CONCAT(v.reference_name, ':', v.start, ':', v.reference_bases, ':', a) AS variant_id
  FROM
    `genomics-public-data.1000_genomes.variants` v,
    UNNEST(v.alternate_bases) AS a
  WHERE
    v.reference_name NOT IN ('X', 'Y', 'MT')
    AND v.VT IS NOT NULL
    AND v.EUR_AF >= 0.05
  UNION ALL
  SELECT
    'ASN' AS Super_Population,
    v.VT AS Variant_Type,
    CONCAT(v.reference_name, ':', v.start, ':', v.reference_bases, ':', a) AS variant_id
  FROM
    `genomics-public-data.1000_genomes.variants` v,
    UNNEST(v.alternate_bases) AS a
  WHERE
    v.reference_name NOT IN ('X', 'Y', 'MT')
    AND v.VT IS NOT NULL
    AND v.ASN_AF >= 0.05
)
SELECT
  vp.Super_Population AS Super_Populations,
  sc.Sample_Count AS Total_Population_Size,
  vp.Variant_Type,
  sc.Sample_Count AS Sample_Count,
  COUNT(DISTINCT vp.variant_id) AS Number_of_Common_Autosomal_Variants
FROM
  variants_per_population vp
JOIN
  sample_counts sc
ON
  vp.Super_Population = sc.Super_Population
GROUP BY
  vp.Super_Population,
  vp.Variant_Type,
  sc.Sample_Count
ORDER BY
  vp.Super_Population,
  vp.Variant_Type;