-------------------------------------------------------------------------------
-- Exploração Inicial
-------------------------------------------------------------------------------

SELECT 
	*
FROM
	CovidDB..CovidTable
	
-- Filtrar e Ordenar Colunas

SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	new_deaths,
	population
FROM
	CovidDB..CovidTable
ORDER BY
	1,2

-------------------------------------------------------------------------------
-- Calculos
-------------------------------------------------------------------------------

-- Percentual de mortes total e por dia  

SELECT 
	location,
	date,
	(total_deaths/total_cases)*100 as MortesTotal,
	(new_deaths / new_cases)*100 as MortesDiaria
FROM
	CovidDB..CovidTable
WHERE
	--location like '%brazil%' and
	new_cases > 0 -- caso nao haja novos casos no dia para nao dividir por 0
ORDER BY
	1,2 desc

-- Taxa de infectados por País e percentual da população infectada

SELECT 
	location,
	MAX(total_cases) as ContagemInfectados,
	MAX((total_cases/population))*100 as PercentPopulationInfected,
	population
FROM
	CovidDB..CovidTable
--WHERE
--	population > 1000000
--	location like '%brazil%'
GROUP BY
	location, population
ORDER BY
	PercentPopulationInfected desc

-- Numero de mortes por país

SELECT 
	location,
	MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM
	CovidDB..CovidTable
WHERE
	continent is not null
GROUP BY
	location, population
ORDER BY
	TotalDeathCount desc

-- Numero de mortes por continente

SELECT 
	location,
	MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM
	CovidDB..CovidTable
WHERE
	location = 'World'
	or location = 'Europe'
	or location = 'Asia'
	or location = 'North America'
	or location = 'South America'
	or location = 'Africa'
	or location = 'Oceania'
GROUP BY
	location, population
ORDER BY
	TotalDeathCount desc

-- Soma de infectados e mortes por dia

SELECT 
	date,
	SUM(new_cases) AS SomaInfectados,
	SUM(CAST(new_deaths as INT)) AS SomaMortes,
	(SUM(CAST(new_deaths as INT))/SUM(new_cases)) AS ppMortes
FROM
	CovidDB..CovidTable
WHERE
	continent is not null
GROUP BY
	date
ORDER BY 
	3 desc

-- Soma de vacinados ate o dia por país

SELECT 
	location,
	date,
	population,
	new_vaccinations,
	SUM(CAST(new_vaccinations as FLOAT)) OVER (PARTITION BY location ORDER BY date)	AS TotalVacination
FROM
	CovidDB..CovidTable
WHERE
	continent is not null
	--and location like '%brazil%'
ORDER BY 
	2, 3

-------------------------------------------------------------------------------
-- CTE
-------------------------------------------------------------------------------


WITH PopvsVac (Location, Date, Population, New_Vacinations, TotalVacination )
as
(
SELECT 
	location,
	date,
	population,
	new_vaccinations,
	SUM(CAST(new_vaccinations as FLOAT)) OVER (PARTITION BY location ORDER BY date)	AS TotalVacination
FROM
	CovidDB..CovidTable
WHERE
	continent is not null
)
SELECT 
	*,
	(TotalVacination / Population) * 100 AS ppVacinated
FROM PopvsVac

-------------------------------------------------------------------------------
-- Tabela temporaria
-------------------------------------------------------------------------------


DROP TABLE IF exists #ppPopulacaoVacinada -- caso queira modificar a tabela
CREATE TABLE #ppPopulacaoVacinada
(
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	TotalVacination numeric,
)

INSERT INTO #ppPopulacaoVacinada
SELECT 
	location,
	date,
	population,
	new_vaccinations,
	SUM(CAST(new_vaccinations as FLOAT)) OVER (PARTITION BY location ORDER BY date)	AS TotalVacination
FROM
	CovidDB..CovidTable
WHERE
	continent is not null


SELECT 
	*,
	(TotalVacination / Population) * 100 AS ppVacinated
FROM #ppPopulacaoVacinada

-------------------------------------------------------------------------------
-- Views
-------------------------------------------------------------------------------

CREATE VIEW PopulacaoVacinada AS
WITH PopvsVac (Location, Date, Population, New_Vacinations, TotalVacination )
as
(
SELECT 
	location,
	date,
	population,
	new_vaccinations,
	SUM(CAST(new_vaccinations as FLOAT)) OVER (PARTITION BY location ORDER BY date)	AS TotalVacination
FROM
	CovidDB..CovidTable
WHERE
	continent is not null
)
SELECT 
	*,
	(TotalVacination / Population) * 100 AS ppVacinated
FROM PopvsVac
