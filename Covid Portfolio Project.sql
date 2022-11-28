-- check to see if data where imported correctly
select *
from CovidDB..CovidVacinations
order by 1

-- studie the data

SELECT 
	location, date, new_cases, new_deaths
FROM 
	CovidDB..CovidDeaths
ORDER BY 
	1,2



-- What percentage of the population was infected?

SELECT 
	location, date, population, total_cases, ROUND((total_cases/population)*100, 2) AS PopulaionInfected
FROM 
	CovidDB..CovidDeaths
WHERE
	location like '%bra%'
ORDER BY 
	1,2

-- How deadly?
-- Total cases VS Total Deaths

SELECT 
	location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM 
	CovidDB..CovidDeaths
WHERE
	location like '%peru%'
ORDER BY 
	1,2

-- Countries with highest Infection Rate compared to Population for population > 10,000,000

SELECT 
	location, 
	population, 
	MAX(total_cases) as HighestInfectionCount,
	MAX(ROUND((total_cases/population)*100, 2)) AS PopulaionInfected
FROM 
	CovidDB..CovidDeaths
WHERE
	population > 10000000
GROUP BY
	location, population
ORDER BY
	4 DESC

-- Countries with highest Death Count per Population
-- total_deaths was saved as nvarchar not INT 
-- filter location where continent is blank so it shows only contries

SELECT 
	location,
	MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM 
	CovidDB..CovidDeaths
WHERE 
	continent <> ' '
GROUP BY
	location
ORDER BY
	TotalDeathCount DESC


-- Highest Death Count per Population by Continent

SELECT 
	location,
	ROUND (MAX(CAST(total_deaths AS FLOAT))/1000000, 2) as TotalDeathCountMilions
FROM 
	CovidDB..CovidDeaths
WHERE 
	continent = ' ' AND
	location <> 'World' AND
	location <> 'High income' AND
	location <> 'Upper middle income' AND
	location <> 'Lower middle income' AND
	location <> 'Low income' AND
	location <> 'International'
GROUP BY
	location
ORDER BY
	TotalDeathCountMilions DESC

-- Highest Death Count per Population by Income

SELECT 
	location,
	MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM 
	CovidDB..CovidDeaths
WHERE 
	continent = ' ' AND
	location = 'World' OR
	location = 'International' OR
	location = 'High income' OR
	location = 'Upper middle income' OR
	location = 'Lower middle income' OR
	location = 'Low income' 
GROUP BY
	location
ORDER BY
	TotalDeathCount DESC

-- Global Analysis
-- Show how many Infected, Deaths and Death Percentage of the World Daily
-- New cases > 0 so it doens´t divide by 0 
-- 

SELECT
	date, 
	SUM(new_cases) as WorldInfected, 
	SUM(CAST(new_deaths AS INT)) AS WorldDeath,
	SUM(CAST(new_deaths AS INT)) /SUM(new_cases) * 100 AS WorldDeathPercentage
FROM 
	CovidDB..CovidDeaths
WHERE
	CONVERT(date, DATE) between '2020-01-23' and '2020-01-30'
GROUP BY
	date
ORDER BY
	 date

-- Show Total Infected, Deaths and Death Percentage of the World 2020

SELECT
	SUM(new_cases) as TotalInfected, 
	SUM(CAST(new_deaths AS INT)) AS TotalDeath,
	SUM(CAST(new_deaths AS INT)) /SUM(new_cases) * 100 AS TotalDeathPercentage
FROM 
	CovidDB..CovidDeaths
WHERE
	CONVERT(date, DATE) between '2020-01-23' and '2020-12-31'

-- Show Total Infected, Deaths and Death Percentage of the World 2021

SELECT
	SUM(new_cases) as TotalInfected, 
	SUM(CAST(new_deaths AS INT)) AS TotalDeath,
	SUM(CAST(new_deaths AS INT)) /SUM(new_cases) * 100 AS TotalDeathPercentage
FROM 
	CovidDB..CovidDeaths
WHERE
	CONVERT(date, DATE) between '2021-01-01' and '2021-12-31'

-- Show Total Infected, Deaths and Death Percentage of the World 2022

SELECT
	SUM(new_cases) as TotalInfected, 
	SUM(CAST(new_deaths AS INT)) AS TotalDeath,
	SUM(CAST(new_deaths AS INT)) /SUM(new_cases) * 100 AS TotalDeathPercentage
FROM 
	CovidDB..CovidDeaths
WHERE
	CONVERT(date, DATE) between '2022-01-01' and '2022-12-31'

-- Show Total Infected, Deaths and Death Percentage of the World 

SELECT
	SUM(new_cases) as TotalInfected, 
	SUM(CAST(new_deaths AS INT)) AS TotalDeath,
	SUM(CAST(new_deaths AS INT)) /SUM(new_cases) * 100 AS TotalDeathPercentage
FROM 
	CovidDB..CovidDeaths
WHERE
	new_cases > 0

-- Show Total vacinnated by day

SELECT
	date, 
	SUM(CAST(total_vaccinations as float)) as TotalVac,
	SUM(CAST(new_vaccinations as float)) as NewVac
FROM 
	CovidDB..CovidVacinations
GROUP BY
	date
ORDER BY
	 date

SELECT
	dea.continent, 
	dea.location,  
	dea.date, 
	dea.population, 
	vac.new_vaccinations
FROM
	CovidDB..CovidDeaths dea
	JOIN	CovidDB..CovidVacinations vac
	ON	dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent <> ' '
ORDER BY
	2,3

SELECT
	dea.continent, 
	dea.location,  
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
FROM
	CovidDB..CovidDeaths dea
	JOIN	CovidDB..CovidVacinations vac
	ON	dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent <> ' '
ORDER BY
	2,3


-- CTE so we can do calculations with the rolling people vaccinated count

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT
	dea.continent, 
	dea.location,  
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM
	CovidDB..CovidDeaths dea
		JOIN	CovidDB..CovidVacinations vac
		ON	dea.location = vac.location
		AND dea.date = vac.date
WHERE
	dea.continent <> ' '
)
SELECT *, ROUND((RollingPeopleVaccinated/Population) * 100, 2) AS PercentageVaccinated
FROM PopVsVac
ORDER BY 2,3

CREATE VIEW PercentPopulationVaccinated AS
SELECT
	dea.continent, 
	dea.location,  
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM
	CovidDB..CovidDeaths dea
		JOIN	CovidDB..CovidVacinations vac
		ON	dea.location = vac.location
		AND dea.date = vac.date
WHERE
	dea.continent <> ' '