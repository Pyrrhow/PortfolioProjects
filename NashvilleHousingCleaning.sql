SELECT
	*
FROM
	PortfolioDB..NashvilleHousing
-------------------------------------------------------------------------------
-- Standardize Date Format
-------------------------------------------------------------------------------

SELECT
	SaleDate,
	CONVERT(Date,SaleDate)
FROM
	PortfolioDB..NashvilleHousing

-- rename column

EXEC sp_rename 'dbo.NashvilleHousing.SaleDate', 'OldSaleDate', 'COLUMN';

-- create column
ALTER TABLE NashvilleHousing
ADD SaleDate Date;

-- set converted column data
UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,OldSaleDate)

-------------------------------------------------------------------------------
-- Populate Property Address Data
-------------------------------------------------------------------------------

-- There are some null values for the Property Adress

SELECT 
	PropertyAddress
FROM
	PortfolioDB..NashvilleHousing
WHERE 
	PropertyAddress is null

-- The ParcelID and the PropertyAddress have a relationship

SELECT 
	ParcelID,
	PropertyAddress
FROM
	PortfolioDB..NashvilleHousing
ORDER BY
	1

-- Joining the table with it self

SELECT 
	a.[UniqueID ],
	a.ParcelID, 
	a.PropertyAddress,
	b.[UniqueID ],
	b.ParcelID, 
	b.PropertyAddress,
	ISNULL(a.PropertyAddress,b.PropertyAddress) as CopiedAddress
FROM
	PortfolioDB..NashvilleHousing a
JOIN
	PortfolioDB..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
WHERE a.PropertyAddress is null

-- Copy the PropertyAddress based on the ParcelID

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM
	PortfolioDB..NashvilleHousing a
JOIN
	PortfolioDB..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
WHERE a.PropertyAddress is null

-------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Addres, City, State)
-------------------------------------------------------------------------------

-- property address

SELECT
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 ,LEN(PropertyAddress))  as City
FROM
	PortfolioDB..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 ,LEN(PropertyAddress))

-- owner address

SELECT
	PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS Adress,
	PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS City,
	PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS State
FROM
	PortfolioDB..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-------------------------------------------------------------------------------
-- Change Y and N to Yes and No in Sold as Vacant Column
-------------------------------------------------------------------------------

SELECT
	DISTINCT(SoldAsVacant),
	COUNT (SoldAsVacant)
FROM 
	PortfolioDB..NashvilleHousing
GROUP BY
	SoldAsVacant
ORDER BY
	2

SELECT
	SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM 
	PortfolioDB..NashvilleHousing
WHERE
	SoldAsVacant = 'Y'
	or SoldAsVacant = 'N'

UPDATE NashvilleHousing
SET SoldAsVacant =	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						 WHEN SoldAsVacant = 'N' THEN 'No'
						 ELSE SoldAsVacant
						 END
FROM 
	PortfolioDB..NashvilleHousing


-------------------------------------------------------------------------------
-- Remove Duplicates
-------------------------------------------------------------------------------

-- If Parcel ID, Property Address, Sale Date, Sale Price, Legal Reference
-- is the same, I will asume its a duplicate

WITH RowNumCTE AS(
	SELECT
		*,
		ROW_NUMBER() OVER 
		(
			PARTITION BY 
				ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
			ORDER BY
				UniqueID
		) row_num
	FROM 
		PortfolioDB..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

-------------------------------------------------------------------------------
-- Delete Duplicated Columns
-------------------------------------------------------------------------------

SELECT 
	* 
FROM 
	PortfolioDB..NashvilleHousing

ALTER TABLE PortfolioDB..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, OldSaleDate