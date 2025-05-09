SELECT
  icm.Imaging_Assay_Type,
  'Level2' AS Available_Data_Levels
FROM
  `isb-cgc-bq.HTAN_versioned.imaging_channel_metadata_r5` AS icm
WHERE
  icm.HTAN_Center = 'HTAN WUSTL'
GROUP BY
  icm.Imaging_Assay_Type;