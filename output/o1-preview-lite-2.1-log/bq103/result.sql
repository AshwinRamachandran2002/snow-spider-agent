WITH 
  variant_counts AS (
    SELECT
      COUNT(*) AS Number_of_variants,
      SUM(AN) AS Total_Number_of_Alleles
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
    WHERE
      start_position BETWEEN 55039447 AND 55064852
  ),
  allele_counts AS (
    SELECT
      SUM(alt_base.AC) AS Total_Allele_Count
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` t
    CROSS JOIN UNNEST(t.alternate_bases) AS alt_base
    WHERE
      t.start_position BETWEEN 55039447 AND 55064852
  )
SELECT
  variant_counts.Number_of_variants,
  allele_counts.Total_Allele_Count,
  variant_counts.Total_Number_of_Alleles,
  ROUND(CAST(variant_counts.Number_of_variants AS FLOAT64) / (55064852 - 55039447 + 1), 4) AS Mutation_Density
FROM variant_counts, allele_counts;