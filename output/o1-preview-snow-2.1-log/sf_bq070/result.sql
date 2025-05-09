SELECT
  a."SOPInstanceUID" AS "digital_slide_id",
  a."StudyInstanceUID" AS "case_id",
  a."SeriesInstanceUID" AS "physical_slide_id",
  a."PatientID" AS "patient_id",
  a."collection_id",
  a."SOPInstanceUID" AS "instance_id",
  a."gcs_url" AS "GCS_URL",
  a."Columns" AS "width",
  a."Rows" AS "height",
  a."PixelSpacing" AS "pixel_spacing",
  CASE
    WHEN a."TransferSyntaxUID" IN (
      '1.2.840.10008.1.2.4.50',
      '1.2.840.10008.1.2.4.51',
      '1.2.840.10008.1.2.4.57',
      '1.2.840.10008.1.2.4.70'
    ) THEN 'jpeg'
    WHEN a."TransferSyntaxUID" IN (
      '1.2.840.10008.1.2.4.90',
      '1.2.840.10008.1.2.4.91'
    ) THEN 'jpeg2000'
    ELSE 'other'
  END AS "compression_type",
  'unknown' AS "tissue_type",
  CASE
    WHEN a."collection_id" = 'tcga_luad' THEN 'luad'
    WHEN a."collection_id" = 'tcga_lusc' THEN 'lscc'
    ELSE NULL
  END AS "cancer_subtype"
FROM
  IDC.IDC_V17.DICOM_ALL a
WHERE
  a."collection_id" IN ('tcga_luad', 'tcga_lusc')
  AND a."Modality" = 'SM'
  AND a."TransferSyntaxUID" IN (
    '1.2.840.10008.1.2.4.50',
    '1.2.840.10008.1.2.4.51',
    '1.2.840.10008.1.2.4.57',
    '1.2.840.10008.1.2.4.70',
    '1.2.840.10008.1.2.4.90',
    '1.2.840.10008.1.2.4.91'
  )
ORDER BY
  a."SOPInstanceUID" ASC;