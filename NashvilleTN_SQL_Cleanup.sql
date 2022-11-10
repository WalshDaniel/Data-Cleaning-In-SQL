-- SELECT *
-- FROM dbo.NshHsng

-- Cleaning up a dataset about Nashville Housing.



-- Cleaning SaleDate 

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NshHsng

UPDATE NshHsng
SET SaleDate = CONVERT(Date, SaleDate)

-- Not converting, trying a different method

ALTER TABLE NshHsng
ADD SaleDateNew Date

UPDATE NshHsng
SET SaleDateNew = CONVERT(Date, SaleDate)

SELECT SaleDateNew
FROM NshHsng

-- Populating Address Data

SELECT *
FROM NshHsng
--WHERE PropertyAddress is null
ORDER BY ParcelID
-- Making an assumption that if ParcelID is the same for a row, then the property address is the same.
-- Self-joining the table to itself, so that if the ParcelID are the same, then the PropertyAddress should also be the same

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NshHsng a
JOIN NshHsng b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NshHsng a
JOIN NshHsng b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Breaking Address columns into individual columns (address, city, state)
-- Using substrings
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) AS City
FROM NshHsng

ALTER TABLE NshHsng
ADD PropertySplitAddress Nvarchar(250)

UPDATE NshHsng
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NshHsng
ADD PropertySplitCity Nvarchar(250)

UPDATE NshHsng
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress))

-- Breaking OwnerAddress using Parsename instead of substring

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NshHsng

ALTER TABLE NshHsng
ADD OwnerSplitAddress Nvarchar(250)

UPDATE NshHsng
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NshHsng
ADD OwnerSplitCity Nvarchar(250)

UPDATE NshHsng
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NshHsng
ADD OwnerSplitState Nvarchar(250)

UPDATE NshHsng
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Looking at SoldAsVacant column, we'll change all entries to 'Y' or 'N'

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM NshHsng
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM NshHsng

UPDATE NshHsng
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-- looking to remove duplicates

WITH row_numCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM NshHsng
--ORDER BY ParcelID
)
SELECT *
FROM row_numCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

--deleting unused columns

ALTER TABLE NshHsng
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE NshHsng
DROP COLUMN SaleDate, SaleDateConverted

