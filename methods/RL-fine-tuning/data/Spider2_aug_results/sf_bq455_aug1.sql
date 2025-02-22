-- Task: Identify all series where the ImageType is 'LOCALIZER' or the TransferSyntaxUID is either '1.2.840.10008.1.2.4.70' or '1.2.840.10008.1.2.4.51'.

SELECT 
  "SeriesInstanceUID"
FROM 
  IDC.IDC_V17."DICOM_ALL" AS bid
WHERE 
  "ImageType" = 'LOCALIZER' OR
  "TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51')
LIMIT 100;