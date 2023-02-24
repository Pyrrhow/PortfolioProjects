-------------------------------------------------------------------------------
-- Exploração Inicial
-------------------------------------------------------------------------------

SELECT 
	*
FROM CovidDB..CovidTable

-- Filtrar e Ordenar Colunas

SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	new_deaths,
	population
FROM CovidDB..CovidTable
WHERE location like '%brazil%'
ORDER BY
	1,2
	
-------------------------------------------------------------------------------
-- Calculos
-------------------------------------------------------------------------------

-- Letalidade

SELECT 
	location,
	date,
	new_cases,
	total_cases,
	new_deaths,
	(total_deaths/total_cases)*100 as Letalidade
FROM CovidDB..CovidTable
--WHERE	location like '%brazil%'
ORDER BY
	1,2

-- Taxa de infectados por País e percentual da população infectada
-- Numero de mortes por país

SELECT 
	location,
	population,
	MAX(total_cases) as ContagemInfectados,
	MAX((total_cases/population))*100 as ppPopulacaoInfectada,
	MAX(CAST(total_deaths AS INT)) as TotalMortes
FROM CovidDB..CovidTable
WHERE continent is not null
GROUP BY
	location, population
ORDER BY
	--ppPopulacaoInfectada desc
	TotalMortes desc

-- Numero de mortes por continente

SELECT 
	location,
	MAX(CAST(total_deaths AS INT)) AS TotalMortes
FROM CovidDB..CovidTable
WHERE
	location = 'World'
	or location = 'Europe'
	or location = 'Asia'
	or location = 'North America'
	or location = 'South America'
	or location = 'Africa'
	or location = 'Oceania'
GROUP BY location, population
ORDER BY TotalMortes desc

-- Soma de infectados e mortes por dia

SELECT 
	date,
	SUM(new_cases) as SomaInfectados,
	SUM(CAST(new_deaths as INT)) as SomaMortes,
	(SUM(CAST(new_deaths as INT))/SUM(new_cases)) as ppMortes
FROM CovidDB..CovidTable
WHERE continent is not null
GROUP BY date
ORDER BY 3 desc

-- Soma de vacinados ate o dia por país

SELECT 
	location,
	date,
	population,
	new_vaccinations,
	SUM(CAST(new_vaccinations as FLOAT)) OVER (PARTITION BY location ORDER BY date)	AS TotalVacinas,
	total_vaccinations
FROM
	CovidDB..CovidTable
WHERE continent is not null and location like '%brazil%'
ORDER BY 1,2


-------------------------------------------------------------------------------
-- CTE
-------------------------------------------------------------------------------

WITH cteVac (Location, Date, Population, New_Vacinations, TotalVacinas )
as
(
SELECT 
	location,
	date,
	population,
	new_vaccinations,
	SUM(CAST(new_vaccinations as FLOAT)) OVER (PARTITION BY location ORDER BY date)	AS TotalVacinas
FROM CovidDB..CovidTable
WHERE continent is not null
)
SELECT 
	*,
	(TotalVacinas / Population) * 100 AS ppVacinada
FROM cteVac


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
	SUM(CAST(new_vaccinations as FLOAT)) OVER (PARTITION BY location ORDER BY date)	AS TotalVacinas
FROM CovidDB..CovidTable
WHERE continent is not null


SELECT 
	*,
	(TotalVacinas / Population) * 100 AS ppVacinada
FROM #ppPopulacaoVacinada

-------------------------------------------------------------------------------
-- Views
-------------------------------------------------------------------------------

CREATE VIEW Letalidade AS
SELECT 
	location,
	date,
	new_cases,
	total_cases,
	new_deaths,
	(total_deaths/total_cases)*100 as Letalidade
FROM CovidDB..CovidTable

CREATE VIEW InfectadosPorPais AS
SELECT 
	location,
	population,
	MAX(total_cases) as ContagemInfectados,
	MAX((total_cases/population))*100 as ppPopulacaoInfectada,
	MAX(CAST(total_deaths AS INT)) as TotalMortes
FROM CovidDB..CovidTable
WHERE continent is not null
GROUP BY
	location, population

CREATE VIEW InfectadosPorContinente AS
SELECT 
	location,
	MAX(CAST(total_deaths AS INT)) AS TotalMortes
FROM CovidDB..CovidTable
WHERE
	location = 'World'
	or location = 'Europe'
	or location = 'Asia'
	or location = 'North America'
	or location = 'South America'
	or location = 'Africa'
	or location = 'Oceania'
GROUP BY location, population

CREATE VIEW SomaMortes AS
SELECT 
	date,
	SUM(new_cases) as SomaInfectados,
	SUM(CAST(new_deaths as INT)) as SomaMortes,
	(SUM(CAST(new_deaths as INT))/SUM(new_cases)) as ppMortes
FROM CovidDB..CovidTable
WHERE continent is not null
GROUP BY date

CREATE VIEW PopulacaoVacinada AS
WITH PopvsVac (Local, Data, Populacao, NovasVacinas, TotalVacinado)
as
(
SELECT 
	location,
	date,
	population,
	new_vaccinations,
	SUM(CAST(new_vaccinations as FLOAT)) OVER (PARTITION BY location ORDER BY date)	AS TotalVacination
FROM CovidDB..CovidTable
WHERE continent is not null
)
SELECT 
	*,
	(TotalVacinado / Populacao) * 100 AS ppVacinado
FROM PopvsVac
